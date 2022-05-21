// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./access/InitializableOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MirrahArt is InitializableOwnable, ERC721Enumerable {

  using Strings for uint256;

  mapping (uint256 => string) private tokenState;

  constructor() ERC721("MirrahArt", "Mirrah") {
    initOwner(msg.sender);
  }

  function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: No token");
    string memory savedState = tokenState[tokenId];
    string memory state;
    if (bytes(savedState).length == 0) {
      state = "default";
    } else {
      state = savedState;
    }
    string memory uri = 
      string(
          abi.encodePacked(
              'https://s.nft.mirrah.art/one/metadata/',
              Strings.toString(tokenId),
              '/',
              state,
              '.json'
          )
      );
    return uri;
  }

  function mintMultiple(
    address to_, 
    uint256 count_
  ) external onlyAdminOrOwner {
    for (uint256 i = 0; i < count_; i++) {
      uint256 id = totalSupply();
      _mint(to_, id);
    }
  }

  function requestStateUpdate(uint256 tokenId)
    external {
      require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
  }
}
