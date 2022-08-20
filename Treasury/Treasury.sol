// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Interfaces/IVoting.sol";
import "../Interfaces/ITreasury.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP17/extensions/IKIP17Enumerable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP7/IKIP7.sol";

contract Treasury is Ownable, ITreasury {
    
    using SafeMath for uint256;

    uint256 private withdrawOrder = 0;
    
    IKIP17Enumerable public governToken;
    IVoting public voteContract;

    mapping (uint256 => Withdraw) public withdrawList;

    constructor(address _governToken, address _voteContract) {
        governToken = IKIP17Enumerable(_governToken);
        voteContract = IVoting(_voteContract);
    }

    function makeVoteForWithdraw(string memory agenda, address token, uint256 amount) external onlyOwner {
        require (IKIP7(token).balanceOf(address(this)) >= amount, "Not enough balance");

        uint256 _voteId = voteContract.propose(agenda);

        Withdraw memory newList = Withdraw({
            token: token,
            amount: amount,
            voteId: _voteId,
            withdrawn: false
        });

        withdrawList[withdrawOrder] = newList;

        

        withdrawOrder += 1;
    }

    function withdrawWithVote(uint256 order, address receiver) external onlyOwner {
        require (order <= withdrawOrder - 1, "Incorrect order");
        require (!withdrawList[order].withdrawn, "Already withdrawn");
        
        uint256 voteId = withdrawList[order].voteId;
        address token = withdrawList[order].token;
        uint256 amount = withdrawList[order].amount;

        IVoting.Vote memory voteInfo = voteContract.viewVote(voteId);

        require (
            voteInfo.checkEnd 
            && voteInfo.threshold <= (voteInfo.pros + voteInfo.cons)
            && (voteInfo.pros > voteInfo.cons), "Can't withdraw");

        voteContract.executeVote(voteId);

        IKIP7(token).transfer(receiver, amount);

        withdrawList[order].withdrawn = true;
    }

    function emergencyWithdraw(address token, address receiver, uint256 amount) external onlyOwner {
        IKIP7(token).transfer(receiver, amount);
    }
}