// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { InitializableOwnable } from "./access/InitializableOwnable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC721A } from "./erc721a/contracts/ERC721A.sol";

contract MirrahArt is InitializableOwnable, ERC721A, ERC721Holder, ReentrancyGuard {

  /* ========== HELPER STRUCTURES ========== */

  enum Currency {
    USDC, 
    DAI,
    USDT
  }

  enum Stage {
    NEW,
    MODELING,
    FIRING,
    COLORING,
    PREFINAL,
    FINISHED
  }

  struct NftDetails {
    Stage stage;
    bool nftBeingUpdated;
    uint8 modificationOne;
    uint8 modificationTwo;
    uint8 modificationThree;
    string userInputOne;
    string userInputTwo;
    string userInputThree;
    uint8 colorChoice;
    string contactDetails;
  }

  struct Prices {
    uint16 nft;
    uint16 nftIncrement;
    uint16 modificationIncrement;
    uint16 modification;
    uint16 userInput;
    uint16 modeling;
    uint16 firing;
    uint16 coloring;
    uint16 shipping;
    uint16 destroy;
    uint16 maxTokenIndexForSale;
  }

  error WrongStage(Stage stage);
  error WorkInProgress();
  error ArtworkCompleted();

  /* ========== CONSTANTS ========== */

  address public artist;
  address public developer;
  address public usdc;
  address public dai;
  address public usdt;

  /* ========== STATE VARIABLES ========== */

  Prices public prices = Prices({
    nft: 10000,
    nftIncrement: 250,
    modificationIncrement: 100,
    modification: 750,
    userInput: 1500,
    modeling: 750,
    firing: 500,
    coloring: 1000,
    shipping: 1500,
    destroy: 3000,
    maxTokenIndexForSale: 4
  });
  mapping (uint256 => NftDetails) public nftDetails;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address artist_,
    address developer_,
    address usdc_,
    address dai_,
    address usdt_
  ) ERC721A("TestMirrahArt", "TestMirrah") {
    initOwner(msg.sender);
    addAdmin(artist_);
    artist = artist_;
    developer = developer_;
    usdc = usdc_;
    dai = dai_;
    usdt = usdt_;
    _mint(address(this), 30);
    transferOwnership(developer_);
  }

  /* ========== VIEWS ========== */

  function nextStage(
    Stage stage
  ) public pure returns (Stage next) {
    if (stage == Stage.NEW) {
      return Stage.MODELING;
    } else if (stage == Stage.MODELING) {
      return Stage.FIRING;
    } else if (stage == Stage.FIRING) {
      return Stage.COLORING;
    } else if (stage == Stage.COLORING) {
      return Stage.PREFINAL;
    } else if (stage == Stage.PREFINAL) {
      return Stage.FINISHED;
    } else {
      revert WrongStage(stage);
    }
  }

  function tokenForCurrency(Currency currency) public view returns (address currencyAddress) {
    if (currency == Currency.USDC) {
      return usdc;
    } else if (currency == Currency.DAI) {
      return dai;
    } else if (currency == Currency.USDT) {
      return usdt;
    }
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function buyFromContract(
    uint tokenId,
    Currency currency
  ) external
    nonReentrant {
    require(ownerOf(tokenId) == address(this) && tokenId <= prices.maxTokenIndexForSale, "Token not for sale");
    pay(currency, prices.nft);
    prices.nft = prices.nft + prices.nftIncrement;
    _tokenApprovals[tokenId].value = msg.sender;
    safeTransferFrom(address(this), msg.sender, tokenId);
    nftDetails[tokenId].stage = Stage.NEW;
  }

  function requestStateUpdate(
    uint256 tokenId,
    Currency currency
  ) external
    nonReentrant {
      Stage stage = checkIfApprovedForAction(tokenId);
      Stage stageNext = nextStage(stage);
      uint16 currentPrice;
      if (stageNext == Stage.MODELING) {
        currentPrice = prices.modeling;
        prices.modeling += prices.modificationIncrement;
      } else if (stageNext == Stage.FIRING) {
        currentPrice = prices.firing;
        prices.firing += prices.modificationIncrement;
      } else if (stageNext == Stage.COLORING) {
        currentPrice = prices.coloring;
        prices.coloring += prices.modificationIncrement;
      } else {
        revert();
      }
      pay(currency, currentPrice);
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestUserInput(
    uint256 tokenId,
    Currency currency,
    uint8 slot,
    string memory input
  ) external
    nonReentrant {
      checkIfApprovedForAction(tokenId);
      pay(currency, prices.userInput);
      prices.userInput += prices.modificationIncrement;
      if (slot == 0) {
        nftDetails[tokenId].userInputOne = input;
      } else if (slot == 1) {
        nftDetails[tokenId].userInputTwo = input;
      } else if (slot == 2) {
        nftDetails[tokenId].userInputThree = input;
      } else {
        revert();
      }
  }

  function requestModification(
    uint256 tokenId,
    Currency currency,
    uint8 choice1,
    uint8 choice2,
    uint8 choice3
  ) external
    nonReentrant {
      Stage stage = checkIfApprovedForAction(tokenId);
      if (nftDetails[tokenId].stage != Stage.COLORING) {
        revert WrongStage(stage);
      }
      pay(currency, prices.modification);
      prices.modification += prices.modificationIncrement;
      nftDetails[tokenId].modificationOne = choice1;
      nftDetails[tokenId].modificationTwo = choice2;
      nftDetails[tokenId].modificationThree = choice3;
  }

  function requestColoring(
    uint256 tokenId,
    Currency currency,
    uint8 choice
  ) external
    nonReentrant {
      Stage stage = checkIfApprovedForAction(tokenId);
      if (nftDetails[tokenId].stage != Stage.COLORING) {
        revert WrongStage(stage);
      }
      pay(currency, prices.coloring);
      prices.coloring += prices.modificationIncrement;
      nftDetails[tokenId].colorChoice = choice;
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestFinalStage(
    uint256 tokenId,
    Currency currency,
    bool ship,
    string memory optionalContactDetails
  ) external
    nonReentrant {
      Stage stage = checkIfApprovedForAction(tokenId);
      if (stage != Stage.COLORING && stage != Stage.PREFINAL) {
        revert WrongStage(stage);
      }
      pay(currency, ship ? prices.shipping : prices.destroy);
      if (ship) {
        prices.shipping += prices.modificationIncrement;
      } else {
        prices.destroy += prices.modificationIncrement;
      }
      nftDetails[tokenId].contactDetails = optionalContactDetails;
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setMaxSaleIndex(
    uint16 index
  ) external onlyAdminOrOwner {
    prices.maxTokenIndexForSale = index;
  }

  function setNftStage(
      uint256 tokenId,
      Stage stage
    ) external onlyAdminOrOwner {
    nftDetails[tokenId].stage = stage;
    nftDetails[tokenId].nftBeingUpdated = false;
  }

  function setArtistAddress(address newArtist) external onlyOwner {
    artist = newArtist;
  }

  function setDeveloperAddress(address newDeveloper) external onlyOwner {
    developer = newDeveloper;
  }

  function setStablesAddress(address[] memory addresses) external onlyOwner {
    require(addresses.length == 3, "Mismatch");
    usdc = addresses[0];
    dai = addresses[1];
    usdt = addresses[2];
  }

  function withdrawAllOfToken(
    IERC20 tokenToWithdraw
  ) external onlyAdminOrOwner {
      uint balance = tokenToWithdraw.balanceOf(address(this));
      uint artistShare = 4 * balance / 5;
      require(tokenToWithdraw.transfer(artist, artistShare));
      require(tokenToWithdraw.transfer(developer, balance - artistShare));
  }

  /* ========== INTERNAL ========== */

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://s.nft.mirrah.art/one/metadata/";
  }

  function checkIfApprovedForAction(uint tokenId) internal view returns (Stage stage) {
    if (nftDetails[tokenId].nftBeingUpdated) 
      revert WorkInProgress();
    Stage currentStage = nftDetails[tokenId].stage;
    if (currentStage == Stage.FINISHED) 
      revert ArtworkCompleted();
    bool isApprovedOrOwner = (ownerOf(tokenId) == _msgSenderERC721A()||
            isApprovedForAll(_msgSenderERC721A(), _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());
    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    return currentStage;
  }

  function pay(Currency currency, uint16 dollarAmount) internal {
    address tokenAddress = tokenForCurrency(currency);
    uint amount = dollarAmount * (10 ** IERC20Metadata(tokenAddress).decimals());
    IERC20 token = IERC20(tokenAddress);
    require(token.transferFrom(msg.sender, address(this), amount), "PaymentFailed");
  }
}
