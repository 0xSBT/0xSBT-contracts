// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Interfaces/IVoting.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Voting is Ownable, IVoting {

    using SafeMath for uint256;

    uint256 public voteCount = 0; //Number of votes in contract
    
    IERC721Enumerable public governToken;
    
    uint256 public votePeriod = 7 days;
    uint256 public threshold = 200;

    uint256 public immutable MinVotePeriod = 1 days;
    uint256 public immutable MaxVotePeriod = 15 days;

    uint256 public immutable minThresholdPercentage = 100; // 10%
    uint256 public immutable maxThresholdPercentage = 500; // 50%

    mapping (address => mapping(uint256 => bool)) public userVote;
    mapping (address => mapping(uint256 => bool)) public userYesOrNo;
    mapping (address => uint256) public latestVote;

    mapping (address => bool) public proposers;
    mapping (address => bool) public managers;

    event proposed(uint256 id, address proposer, uint256 startTime);
    event yes(address user);
    event no(address user);

    mapping (uint256 => Vote) public votes;
    mapping (address => uint256[]) public userProposal;

    constructor(address _governToken) {
        require (_governToken != address(0), "Zero address");

        governToken = IERC721Enumerable(_governToken);
        proposers[msg.sender] = true;
        managers[msg.sender] = true;
    }

    modifier onlyProposers() {
        require (proposers[msg.sender], "You are not a proposer");
        _;
    }

    modifier onlyManagers() {
        require (managers[msg.sender], "You are not a proposer");
        _;
    }
    
    function propose(string memory agenda) external virtual override onlyProposers returns (uint256) {
        if (latestVote[msg.sender] != 0) {
            require (votes[latestVote[msg.sender]].checkEnd == true, "One active vote per address");
        }  

        uint256 start = block.timestamp;
        uint256 end = start + votePeriod;

        
        Vote memory newVote = Vote({
            id: voteCount,
            agenda: agenda,
            threshold: governToken.totalSupply().mul(threshold).div(10000),
            pros: 0,
            cons: 0,
            proposer: msg.sender,
            startTime: start,
            endTime: end,
            checkEnd: false,
            checkExecuted: false
        });

        votes[voteCount] = newVote;
        latestVote[msg.sender] = voteCount;
        userProposal[msg.sender].push(voteCount);

        emit proposed(voteCount, msg.sender, start);

        voteCount++;
        
        return newVote.id;
    }

    function yesOnVote(uint256 id) external virtual override {
        require (id <= voteCount - 1, "Not exist");
        require (!userVote[msg.sender][id], "You already vote");

        userVote[msg.sender][id] = true;
        userYesOrNo[msg.sender][id] = true;

        votes[id].pros += 1;

        emit yes(msg.sender);
    }

    function noOnVote(uint256 id) external virtual override {
        require (id <= voteCount - 1, "Not exist");
        require (!userVote[msg.sender][id], "You already vote");

        userVote[msg.sender][id] = true;
        userYesOrNo[msg.sender][id] = false;
        
        votes[id].cons += 1;

        emit no(msg.sender);
    }

    function endVote(uint256 id) external virtual override returns (uint256, uint256) {
        require (id <= voteCount - 1, "Not exist");
        require (votes[id].proposer == msg.sender || msg.sender == owner(), "You are not a proposer or owner of contract");
        require (votes[id].endTime <= block.timestamp, "Not done yet");
        votes[id].checkEnd = true;

        return (votes[id].pros, votes[id].cons);
    }

    function executeVote(uint256 id) external virtual override {
        require (id <= voteCount - 1, "Not exist");
        require (votes[id].proposer == msg.sender || msg.sender == owner(), "You are not a proposer or owner of contract");
        require (votes[id].checkEnd, "Not done yet");
        
        votes[id].checkExecuted = true;
    }

    /////////////// MUTABLE FUNCTIONS ///////////////

    function updateThreshold(uint256 _threshold) external onlyManagers{
        require (
            minThresholdPercentage <= _threshold 
            && 
            _threshold <= maxThresholdPercentage, "Out of Range"
        );
        threshold = _threshold;
    }

    function changeVotePeriod(uint256 period) public onlyManagers {
        require (period >= MinVotePeriod && period <= MaxVotePeriod, "Out of Range");

        votePeriod = period;
    }

    function addProposers(address[] memory newProposers) external onlyManagers{
        require (newProposers.length != 0, "No new proposers");

        for (uint256 i = 0; i < newProposers.length - 1; i ++) {
            proposers[newProposers[i]] = true;
        }
    }
    
    // You must leave at least 1 proposer
    function removeProposers(address[] memory deleteProposers) external onlyManagers{
        require (deleteProposers.length != 0, "No new proposers");

        for (uint256 i = 0; i < deleteProposers.length - 1; i ++) {
            proposers[deleteProposers[i]] = false;
        }
    }

    function addManagers(address[] memory newManagers) external onlyOwner{
        require (newManagers.length != 0, "No new proposers");

        for (uint256 i = 0; i < newManagers.length - 1; i ++) {
            managers[newManagers[i]] = true;
        }
    }

    // You must leave at least 1 manager
    function removeManagers(address[] memory deleteManagers) external onlyOwner{
        require (deleteManagers.length != 0, "No new proposers");

        for (uint256 i = 0; i < deleteManagers.length - 1; i ++) {
            managers[deleteManagers[i]] = true;
        }
    }

    /////////////// VIEW FUNCTIONS ///////////////

    function viewVote(uint256 id) public virtual override view returns (Vote memory) {
        require (id <= voteCount - 1, "Not exist");

        return votes[id];
    }
    
    function viewNumberOfVoteMake(address user) public virtual override view returns (uint256) {
        return userProposal[user].length;
    } 

    function viewUserVote(uint256 _id, address user) public virtual override view returns (bool) {
        return userVote[user][_id];
    }

    function viewCurrentVoteId() public virtual override view returns (uint256) {
        return voteCount - 1;
    }

    function viewYourVote(address user) public virtual override view returns (uint256[] memory) {
        return userProposal[user];
    }
}