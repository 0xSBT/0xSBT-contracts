// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IVoting {

    struct Vote {
        uint256 id; //id of vote
        string agenda; //title (agenda) of vote
        uint256 threshold; //threshold
        address proposer; //proposer
        uint256 pros; //yes on vote
        uint256 cons; //no on vote
        uint256 startTime; //start time
        uint256 endTime; //end time. period = endTime - startTime
        bool checkEnd; //check vote
        bool checkExecuted; //check execution
    }

    function propose(string memory agenda) external returns (uint256);

    function yesOnVote(uint256 id) external;

    function noOnVote(uint256 id) external;

    function endVote(uint256 id) external returns (uint256, uint256);

    function executeVote(uint256 id) external;

    function viewVote(uint256 id) external view returns (Vote memory);

    function viewNumberOfVoteMake(address user) external view returns (uint256);

    function viewUserVote(uint256 _id, address user) external view returns (bool);

    function viewCurrentVoteId() external view returns (uint256);

    function viewYourVote(address user) external view returns (uint256[] memory);
}