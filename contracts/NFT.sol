// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MirrahArt is ERC721, Ownable {

  using Counters for Counters.Counter;
  using Strings for uint256;
  Counters.Counter private _tokenIds;

  mapping (uint256 => string) private _tokenURIs;
  
  constructor() ERC721("MirrahArt", "Mirrah") {}

  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual {
    _tokenURIs[tokenId] = _tokenURI;
  }

  function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory _tokenURI = _tokenURIs[tokenId];
    return _tokenURI;
  }

  function mint(address recipient)
    public
    onlyOwner
    returns (uint256) {
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _mint(recipient, newItemId);
    string memory uri = 
      string(
          abi.encodePacked(
              'https://nft.mirrah.art/memorable/metadata/',
              Strings.toString(newItemId),
              '.json'
          )
      );
    
    _setTokenURI(newItemId, uri);
    return newItemId;
  }
}
