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

  struct voteContents {
    uint256 culture;
    uint256 transparency;
    uint267 authority;
  }
  
  mapping(address => voteContents) public scores;
  mapping(address => mapping(dao => voteContents)) public committees;
  mapping(address => bool) public listedDaos;

  uint256[] public daos;

  constructor(
    string memory name,
    string memory symbol,
  ) KIP17(name, symbol) {
    _mintPriceInKlay = 0; // 0 klay initially.
  }

  function setMintPrice(uint256 mintPrice) public onlyOwner {
    _mintPriceInKlay = mintPrice;
  }

  // implement for minting test
  function safeMintWithTokenURI(address to, string memory _tokenURI) external payable {
    require(msg.value == _mintPriceInKlay, "minting price is not valid");
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }

  function vote(address dao, uint256[3] memory voteScore) external {
    require (balanceOf(msg.sender) != 0, "You have no right to vote");
    require (listedDaos[dao] == true, "not a listed dao");

    voteContents memory newVote = voteContents {
        voteScore[0],
        voteScore[1],
        voteScore[2]
    };

    committees[msg.sender][dao] = newVote;
    scores[dao] = newVote;
  }

  function manageDao(address dao, bool support) external {
    require (msg.sender == owner || balanceOf(msg.sender) != 0, "You can't manage daos");

    if (support) {
        listedDaos[dao] = true;
        daos.push(dao);
    } else {
        listedDaos[dao] = false;
    }
  }

  function viewScores(address dao) public view returns (uint256[3] memory) {
    uint256 totalVoter = totalSupply();

    uint256[3] memory scores;

    scores[0] = scores[dao].culture / totalVoter;
    scores[1] = scores[dao].transparency / totalVoter;
    scores[2] = scores[dao].authority / totalVoter;

    return scores;
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

    clearVoteHistory(owner);

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

  function clearVoteHistory(address owner) internal {
    for (uint256 i = 0; i < daos.length; i++) {
        if (listedDaos[daos[i]]) {
            scores[daos[i]].culture -= committees[owner][daos[i]].culture;
            scores[daos[i]].transparency -= committees[owner][daos[i]].transparency;
            scores[daos[i]].authority -= committees[owner][daos[i]].authority;
        }
    }
  }

  function withdrawKlay() external onlyOwner {
    payable(msg.sender).transfer(payable(address(this)).balance);
  }
}
