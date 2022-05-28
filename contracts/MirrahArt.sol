// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./access/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract MirrahArt is InitializableOwnable, ERC721Enumerable {

  /* ========== HELPER STRUCTURES ========== */

  enum Currency { 
    USDC, 
    DAI
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

  /* ========== STATE VARIABLES ========== */

  mapping (uint256 => Stage) private currentStage;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address artist_,
    address developer_,
    address usdc_,
    address dai_
  ) ERC721("TestMirrahArt", "TestMirrah") {
    initOwner(msg.sender);
    artist = artist_;
    developer = developer_;
    usdc = usdc_;
    dai = dai_;
    mintMultiple(address(this), 30);
  }

  /* ========== VIEWS ========== */

  function tokenForCurrency(Currency currency) public view returns (address currencyAddress) {
    if (currency == Currency.USDC) {
      return usdc;
    } else if (currency == Currency.DAI) {
      return dai;
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
    safeTransferFrom(address(this), msg.sender, id);
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
      uint amount = dollarAmount * IERC20Metadata(tokenAddress).decimals();
      require(IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount), "Payment didn't go through");
      _;
    }
}
