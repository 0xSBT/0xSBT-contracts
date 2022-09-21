// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/KIP17URIStorage.sol";
import "@klaytn/contracts/access/Ownable.sol";
import "@klaytn/contracts/utils/Counters.sol";

contract SoulBoundToken is KIP17, Ownable, KIP17Enumerable, KIP17URIStorage {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 constant MAX_SCORE = 100;

  Counters.Counter private _tokenIdCounter;
  uint256 private _mintPriceInKlay;
  string baseURIFront;
  string baseURIBack;

  struct voteContents {
    uint256 culture;
    uint256 transparency;
    uint256 authority;
  }

  mapping(address => voteContents) public scores;
  mapping(address => mapping(address => voteContents)) public committees;
  mapping(address => uint256) public totalVoter;
  mapping(address => bool) public listedDaos;

  address[] public daos;

  constructor(string memory name, string memory symbol) KIP17(name, symbol) {
    _mintPriceInKlay = 0; // 0 klay initially.
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

  // Initially, it is ownable function.
  function safeMintWithTokenURI(address to, string memory _tokenURI) external payable {
    require(msg.value == _mintPriceInKlay, "minting price is not valid");
    _tokenIdCounter.increment();
    uint256 tokenId = _tokenIdCounter.current();
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, _tokenURI);
  }

  function vote(address dao, uint256[3] memory voteScore) external {
    require(balanceOf(msg.sender) != 0, "You have no right to vote");
    require(listedDaos[dao] == true, "not a listed dao");
    require(voteScore[0] <= MAX_SCORE && voteScore[1] < MAX_SCORE && voteScore[2] < MAX_SCORE, "Score is not valid");

    voteContents memory newVote = voteContents({ culture: voteScore[0], transparency: voteScore[1], authority: voteScore[2] });

    committees[msg.sender][dao] = newVote;
    scores[dao].culture += voteScore[0];
    scores[dao].transparency += voteScore[1];
    scores[dao].authority += voteScore[2];
    totalVoter[dao] += 1;
  }

  function manageDao(address dao, bool support) external onlyOwner {
    if (support) {
      listedDaos[dao] = true;
      daos.push(dao);
    } else {
      listedDaos[dao] = false;
    }
  }

  function viewScore(address dao) public view returns (uint256[] memory) {
    uint256 totalVoterInfo = totalVoter[dao];

    uint256[] memory score = new uint256[](3);

    score[0] = scores[dao].culture / totalVoterInfo;
    score[1] = scores[dao].transparency / totalVoterInfo;
    score[2] = scores[dao].authority / totalVoterInfo;

    return score;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(KIP17, KIP17Enumerable) {
    if (to != address(0)) {
      require(from == address(0), "Err: token is SOUL BOUND");
    }
    KIP17Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(KIP17) {
    super._afterTokenTransfer(from, to, tokenId);
  }

  // add "interfaceId == type(ISoulBoundToken).interfaceId" after create interface in ISoulBoundToken.sol
  function supportsInterface(bytes4 interfaceId) public view override(KIP17, KIP17Enumerable) returns (bool) {
    return KIP17.supportsInterface(interfaceId) || KIP17Enumerable.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 tokenId) public view override(KIP17, KIP17URIStorage) returns (string memory) {
    require(_exists(tokenId), "KIP17URIStorage: URI query for nonexistent token");
    return string(abi.encodePacked(baseURIFront, Strings.toString(tokenId), baseURIBack));
  }

  function burn(uint256 tokenId) public onlyOwner {
    _burn(tokenId);
  }

  function _burn(uint256 tokenId) internal override(KIP17, KIP17URIStorage) onlyOwner {
    address owner = KIP17.ownerOf(tokenId);

    clearVoteHistory(owner);

    KIP17URIStorage._burn(tokenId);
  }

  function clearVoteHistory(address owner) internal {
    for (uint256 i = 0; i < daos.length; i++) {
      if (listedDaos[daos[i]]) {
        scores[daos[i]].culture -= committees[owner][daos[i]].culture;
        scores[daos[i]].transparency -= committees[owner][daos[i]].transparency;
        scores[daos[i]].authority -= committees[owner][daos[i]].authority;
        totalVoter[daos[i]] -= 1;
      }
    }
  }

  function withdrawKlay() external onlyOwner {
    payable(msg.sender).transfer(payable(address(this)).balance);
  }
}
