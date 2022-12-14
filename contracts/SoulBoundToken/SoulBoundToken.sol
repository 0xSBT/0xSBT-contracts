// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17Pausable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17URIStorage.sol";
import "@klaytn/contracts/access/Ownable.sol";
import "@klaytn/contracts/utils/Counters.sol";

contract SoulBoundToken is KIP17, Ownable, KIP17Enumerable, KIP17Pausable, KIP17URIStorage {
  using Counters for Counters.Counter;
  using Strings for uint256;

  Counters.Counter private _tokenIdCounter;
  uint256 private _mintPriceInKlay;
  uint256 constant fee = 30; // 3%
  string baseURIFront;
  string baseURIBack;

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

  function setbaseURI(string memory front, string memory back) public onlyOwner {
      baseURIFront = front;
      baseURIBack = back;
  }

  function safeMint(address to) external payable {
    require(msg.value == _mintPriceInKlay, "minting price is not valid");
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, tokenURI(tokenId));
  }

  function safeMintWithTokenURI(address to, string memory _tokenURI) external payable {
    require(msg.value == _mintPriceInKlay, "minting price is not valid");
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
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
    super._beforeTokenTransfer(from, to, tokenId);
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
    return string(abi.encodePacked(baseURIFront, Strings.toString(tokenId), baseURIBack));
  }

  function _burn(uint256 tokenId) internal override(KIP17, KIP17URIStorage) {
    super._burn(tokenId);
  }
}
