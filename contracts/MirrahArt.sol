// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

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
    PRESHIPPING,
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
  }

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
    destroy: 3000
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
      return Stage.PRESHIPPING;
    } else if (stage == Stage.PRESHIPPING) {
      return Stage.FINISHED;
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

  function nextStagePrice(uint256 tokenId) public view returns (uint16 price) {
    Stage stage = nextStage(nftDetails[tokenId].stage);
    if (stage == Stage.NEW) {
      return 0;
    } else if (stage == Stage.MODELING) {
      return 750;
    } else if (stage == Stage.FIRING) {
      return 500;
    } else if (stage == Stage.COLORING) {
      return 1000;
    } else if (stage == Stage.PRESHIPPING) {
      return 0;
    }
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function buyFromContract(
    uint tokenId,
    Currency currency
  ) external
    nonReentrant
    paid(currency, prices.nft) {
    require(ownerOf(tokenId) == address(this), "Token not for sale");
    prices.nft = prices.nft + prices.nftIncrement;
    _tokenApprovals[tokenId] = msg.sender;
    transferFrom(address(this), msg.sender, tokenId);
    nftDetails[tokenId].stage = Stage.NEW;
  }

  function requestStateUpdate(
    uint256 tokenId,
    Currency currency
  ) external
    nonReentrant
    paid(currency, nextStagePrice(tokenId))
    approvedForAction(tokenId) {
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestUserInput(
    uint256 tokenId,
    Currency currency,
    uint8 slot,
    string memory input
  ) external
    nonReentrant
    paid(currency, prices.userInput)
    approvedForAction(tokenId) {
      prices.userInput += prices.modificationIncrement;
      if (slot == 0) {
        nftDetails[tokenId].userInputOne = input;
      } else if (slot == 1) {
        nftDetails[tokenId].userInputTwo = input;
      } else if (slot == 1) {
        nftDetails[tokenId].userInputThree = input;
      } else {
        revert();
      }
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestModification(
    uint256 tokenId,
    Currency currency,
    uint8 slot,
    uint8 choise
  ) external
    nonReentrant
    paid(currency, prices.modification)
    approvedForAction(tokenId) {
      prices.modification += prices.modificationIncrement;
      if (slot == 0) {
        nftDetails[tokenId].modificationOne = choise;
      } else if (slot == 1) {
        nftDetails[tokenId].modificationTwo = choise;
      } else if (slot == 1) {
        nftDetails[tokenId].modificationThree = choise;
      } else {
        revert();
      }
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestFinalStage(
    uint256 tokenId,
    Currency currency,
    bool ship
  ) external
    nonReentrant
    paid(currency, ship ? prices.shipping : prices.destroy)
    approvedForAction(tokenId) {
      if (ship) {
        prices.shipping += prices.modificationIncrement;
      } else {
        prices.destroy += prices.modificationIncrement;
      }
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function moveNftToNextStage(
    uint256 tokenId
  ) external onlyAdminOrOwner {
    nftDetails[tokenId].stage = nextStage(nftDetails[tokenId].stage);
    nftDetails[tokenId].nftBeingUpdated = false;
  }

  // Unlikely to be used but might be required if art process declares so
  function setNftStage(
      uint256 tokenId,
      Stage stage
    ) external onlyAdminOrOwner {
    nftDetails[tokenId].stage = stage;
  }

  function setArtistAddress(address newArtist) external onlyOwner {
    artist = newArtist;
  }

  function setDeveloperAddress(address newDeveloper) external onlyOwner {
    developer = newDeveloper;
  }

  function setStablesAddress(address[] memory addresses) external onlyOwner {
    require(addresses.length == 3, "Wrong number of tokens");
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

  /* ========== MODIFIERS ========== */

  modifier approvedForAction(uint tokenId) {
    require(!nftDetails[tokenId].nftBeingUpdated, "Artist works on NFT");
    Stage stage = nftDetails[tokenId].stage;
    // require(stage != Stage.NEW, "NFT is new");
    require(stage != Stage.FINISHED, "Artwork already complete");
    bool isApprovedOrOwner = (ownerOf(tokenId) == _msgSenderERC721A()||
            isApprovedForAll(_msgSenderERC721A(), _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());
    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    _;
  }

  modifier paid(Currency currency, uint16 dollarAmount) {
    address tokenAddress = tokenForCurrency(currency);
    uint amount = dollarAmount * (10 ** IERC20Metadata(tokenAddress).decimals());
    IERC20 token = IERC20(tokenAddress);
    require(token.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
    require(token.transferFrom(msg.sender, address(this), amount), "Payment didn't go through");
    _;
  }
}
