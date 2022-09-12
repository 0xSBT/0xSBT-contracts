// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ITreasury {

    struct Withdraw {
        address token;
        uint256 amount;
        uint256 voteId;
        bool withdrawn;
    }

    function makeVoteForWithdraw(string memory agenda, address token, uint256 amount) external;

    function withdrawWithVote(uint256 order, address receiver) external;

    function emergencyWithdraw(address token, address receiver, uint256 amount) external;
}