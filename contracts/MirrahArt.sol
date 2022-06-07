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
    MODIFICATIONS,
    USER_INPUT,
    MODELING,
    FIRING,
    COLORING,
    SHIPPING,
    DESTROY,
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

  /* ========== CONSTANTS ========== */

  address public artist;
  address public developer;
  address public usdc;
  address public dai;
  address public usdt;
  uint16 public priceIncrement = 250;

  /* ========== STATE VARIABLES ========== */

  uint16 public nftPrice = 10000;
  mapping (uint256 => NftDetails) public nftDetails;
  mapping (Stage => uint16) public currentStagePrices;

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
    currentStagePrices[Stage.MODIFICATIONS] = 750;
    currentStagePrices[Stage.USER_INPUT] = 1500;
    currentStagePrices[Stage.MODELING] = 1000;
    currentStagePrices[Stage.FIRING] = 500;
    currentStagePrices[Stage.COLORING] = 1000;
    currentStagePrices[Stage.SHIPPING] = 1500;
    currentStagePrices[Stage.DESTROY] = 3000;
    transferOwnership(developer_);
  }

  /* ========== VIEWS ========== */

  function nextStagePrice(Stage stage) public view returns (uint16 price) {
    return currentStagePrices[stage] + priceIncrement;
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

  function _baseURI() internal view virtual override returns (string memory) {
    return "https://s.nft.mirrah.art/one/metadata/";
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function buyFromContract(
    uint tokenId,
    Currency currency
  ) external
    nonReentrant
    paid(currency, nftPrice) {
    require(ownerOf(tokenId) == address(this), "Token not for sale");
    nftPrice = nftPrice + priceIncrement;
    _tokenApprovals[tokenId] = msg.sender;
    transferFrom(address(this), msg.sender, tokenId);
    nftDetails[tokenId].stage = Stage.MODIFICATIONS;
  }

  function requestStateUpdate(
    uint256 tokenId,
    Currency currency
  ) external 
    nonReentrant
    paid(currency, currentStagePrices[nftDetails[tokenId].stage])
    approvedForAction(tokenId) {
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestUserInput(
    uint256 tokenId,
    Currency currency,
    string memory input
  ) external 
    nonReentrant
    paid(currency, currentStagePrices[Stage.USER_INPUT])
    approvedForAction(tokenId) {
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestModification(
    uint256 tokenId,
    Currency currency,
    uint8 choise
  ) external 
    nonReentrant
    paid(currency, currentStagePrices[Stage.MODIFICATIONS])
    approvedForAction(tokenId) {
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  function requestFinalStage(
    uint256 tokenId,
    Currency currency,
    bool ship
  ) external 
    nonReentrant
    paid(currency, ship ? currentStagePrices[Stage.SHIPPING] : currentStagePrices[Stage.DESTROY])
    approvedForAction(tokenId) {
      nftDetails[tokenId].nftBeingUpdated = true;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function moveNftToNextStage(
    uint256 tokenId
  ) external onlyAdminOrOwner {
    Stage stage = nftDetails[tokenId].stage;
    if (stage == Stage.MODIFICATIONS) {
      nftDetails[tokenId].stage = Stage.USER_INPUT;
    } else if (stage == Stage.USER_INPUT) {
      nftDetails[tokenId].stage = Stage.MODELING;
    } else if (stage == Stage.USER_INPUT) {
      nftDetails[tokenId].stage = Stage.MODELING;
    } else if (stage == Stage.MODELING) {
      nftDetails[tokenId].stage = Stage.FIRING;
    } else if (stage == Stage.FIRING) {
      nftDetails[tokenId].stage = Stage.COLORING;
    } else if (stage == Stage.COLORING) {
      nftDetails[tokenId].stage = Stage.SHIPPING;
    } else if (stage == Stage.SHIPPING) {
      nftDetails[tokenId].stage = Stage.FINISHED;
    } else if (stage == Stage.DESTROY) {
      nftDetails[tokenId].stage = Stage.FINISHED;
    } else {
      return;
    }
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

  /* ========== MODIFIERS ========== */

  modifier approvedForAction(uint tokenId) {
    require(!nftDetails[tokenId].nftBeingUpdated, "Artist works on NFT");
    Stage stage = nftDetails[tokenId].stage;
    require(stage != Stage.NEW, "NFT is new");
    require(stage != Stage.FINISHED, "Artwork already complete");
    bool isApprovedOrOwner = (ownerOf(tokenId) == _msgSenderERC721A()||
            isApprovedForAll(_msgSenderERC721A(), _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());
    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    currentStagePrices[stage] = currentStagePrices[stage] + priceIncrement;
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
