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
    payable(company).transfer((_mintPriceInKlay * fee) / 1000);
    payable(owner).transfer((_mintPriceInKlay * (1000 - fee)) / 1000);
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
    return super.tokenURI(tokenId);
  }

  function _burn(uint256 tokenId) internal override(KIP17, KIP17URIStorage) {
    super._burn(tokenId);
  }
}
