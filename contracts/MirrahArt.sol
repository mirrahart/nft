// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import { InitializableOwnable } from "./access/InitializableOwnable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract MirrahArt is InitializableOwnable, ERC721Enumerable, ERC721Holder {

  /* ========== HELPER STRUCTURES ========== */

  enum Currency { 
    USDC, 
    DAI,
    USDT
  }

  enum Stage { 
    MODIFICATIONS, 
    FIRING,
    COLORING, 
    SHIPPING, 
    FINISHED 
  }

  /* ========== CONSTANTS ========== */

  address public artist;
  address public developer;
  address public usdc;
  address public dai;
  address public usdt;

  /* ========== STATE VARIABLES ========== */

  mapping (uint256 => Stage) private currentStage;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address artist_,
    address developer_,
    address usdc_,
    address dai_,
    address usdt_
  ) ERC721("TestMirrahArt", "TestMirrah") {
    initOwner(msg.sender);
    artist = artist_;
    developer = developer_;
    usdc = usdc_;
    dai = dai_;
    usdt = usdt_;
    mintMultiple(address(this), 30);
  }

  /* ========== VIEWS ========== */

  function tokenForCurrency(Currency currency) public view returns (address currencyAddress) {
    if (currency == Currency.USDC) {
      return usdc;
    } else if (currency == Currency.DAI) {
      return dai;
    } else if (currency == Currency.USDT) {
      return usdt;
    }
  }

  function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: No token");
    Stage stage = currentStage[tokenId];
    string memory uri = 
      string(
          abi.encodePacked(
              'https://s.nft.mirrah.art/one/metadata/',
              Strings.toString(tokenId),
              '/',
              stage,
              '.json'
          )
      );
    return uri;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function buyFromContract(
    uint id, 
    Currency currency
  ) external paid(currency, 500) {
    require(ownerOf(id) == address(this), "Token not for sale");
    _approve(msg.sender, id);
    transferFrom(address(this), msg.sender, id);
  }

  function requestStateUpdate(
    uint256 tokenId
  ) external {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function mintMultiple(
    address to_, 
    uint256 count_
  ) public onlyAdminOrOwner {
    for (uint256 i = 0; i < count_; i++) {
      uint256 id = totalSupply();
      _mint(to_, id);
    }
  }

  function setArtistAddress(address newArtist) external onlyOwner {
    artist = newArtist;
  }

  function setDeveloperAddress(address newDeveloper) external onlyOwner {
    developer = newDeveloper;
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

    modifier paid(Currency currency, uint dollarAmount) {
      address tokenAddress = tokenForCurrency(currency);
      uint amount = dollarAmount * (10 ** IERC20Metadata(tokenAddress).decimals());
      IERC20 token = IERC20(tokenAddress);
      require(token.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
      require(token.transferFrom(msg.sender, address(this), amount), "Payment didn't go through");
      _;
    }
}
