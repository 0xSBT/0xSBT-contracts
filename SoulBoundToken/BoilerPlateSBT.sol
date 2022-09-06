// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts@1.0.1/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts@1.0.1/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts@1.0.1/KIP/token/KIP17/extensions/KIP17Pausable.sol";
import "@klaytn/contracts@1.0.1/KIP/token/KIP17/extensions/KIP17URIStorage.sol";
import "@klaytn/contracts@1.0.1/access/Ownable.sol";
import "@klaytn/contracts@1.0.1/utils/Counters.sol";

contract SoulBoundToken is KIP17, Ownable, KIP17Enumerable, KIP17Pausable, KIP17URIStorage {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIdCounter;
  uint256 private _mintPriceInKlay;
  uint256 constant fee = 30; // 3%

  address public company;

  constructor(
    string memory name,
    string memory symbol,
    address company_
  ) KIP17(name, symbol) {
    company = company_;
  }

  function setMintPrice(uint256 mintPrice) public onlyOwner {
    _mintPriceInKlay = mintPrice;
  }

  // implement for minting test
  function safeMintWithTokenURI(address to, string memory _tokenURI) external payable {
    require(msg.value == _mintPriceInKlay, "minting price is not valid");
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    payable(company).transfer(msg.value);
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(KIP17, KIP17Enumerable, KIP17Pausable) {
    require(from == address(0), "Err: token is SOUL BOUND");
    require(!paused(), "KIP17Pausable: token transfer while paused");
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(KIP17) {
    super._afterTokenTransfer(from, to, tokenId);
  }

  // add "interfaceId == type(ISoulBoundToken).interfaceId" after create interface in ISoulBoundToken.sol
  function supportsInterface(bytes4 interfaceId) public view override(KIP17, KIP17Enumerable, KIP17Pausable) returns (bool) {
    return KIP17.supportsInterface(interfaceId) || KIP17Enumerable.supportsInterface(interfaceId) || KIP17Pausable.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override(KIP17, KIP17URIStorage) returns (string memory) {
    require(_exists(tokenId), "KIP17URIStorage: URI query for nonexistent token");

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = _baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString())) : "";
  }

  function _burn(uint256 tokenId) internal override(KIP17, KIP17URIStorage) {
    address owner = KIP17.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    _balances[owner] -= 1;
    delete _owners[tokenId];

    emit Transfer(owner, address(0), tokenId);

    _afterTokenTransfer(owner, address(0), tokenId);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}
