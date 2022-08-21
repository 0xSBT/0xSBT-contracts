// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../Interfaces/IVoting.sol";
import "../Interfaces/ITreasury.sol";
import "../Interfaces/IPoolRouter.sol"; // Pangea swap
import "../Interfaces/IConcentratedLiquidityPoolFactory.sol";
import "../Interfaces/IKSP.sol"; // Klayswap
import "../Interfaces/IKSLP.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP17/extensions/IKIP17Enumerable.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP7/IKIP7.sol";

contract Treasury is Ownable, ITreasury {
    
    using SafeMath for uint256;

    uint256 private withdrawOrder = 0;
    
    IKIP17Enumerable public governToken;
    IVoting public voteContract;
    IPoolRouter public pangeaRouter;
    IConcentratedLiquidityPoolFactory public pangeaPoolFactory;
    IKSP public ksp;

    mapping (uint256 => Withdraw) public withdrawList;
    mapping (address => bool) public whiteListToken;

    constructor(address _governToken, address _voteContract, address _ksp, address _pangeaPoolRouter, address _pangeaPoolFactory) {
        governToken = IKIP17Enumerable(_governToken);
        voteContract = IVoting(_voteContract);
        ksp = IKSP(_ksp);
        pangeaRouter = IPoolRouter(_pangeaPoolRouter);
        pangeaPoolFactory = IConcentratedLiquidityPoolFactory(_pangeaPoolFactory);
    }

    receive () payable external {}

    modifier whiteList(address token) {
        require (whiteListToken[token], "Can't use this token");
        _;
    }

    //////////// WITHDRAW ///////////

    function makeVoteForWithdraw(string memory agenda, address token, uint256 amount) external onlyOwner {
        require (balanceOfToken(token) >= amount, "Not enough balance");

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

    /////////// INVESTMENT ///////////

    function swapTokenUsingPangea(address inToken, address outToken, uint256 amount) public whiteList(outToken) onlyOwner {
        require (balanceOfToken(inToken) >= amount, "Not enough token to swap");

        address pool = pangeaPoolFactory.getPools(inToken, outToken, 0, 1)[0];

        ExactInputSingleParams memory newParams = ExactInputSingleParams({
            tokenIn: inToken,
            amountIn: amount,
            amountOutMinimum: 0,
            pool: pool,
            to: outToken,
            unwrap: false
        });

        pangeaRouter.exactInputSingle(newParams);
    }

    function addLiquidityInKlayswap(address tokenA, address tokenB) public whiteList(tokenA) whiteList(tokenB) onlyOwner {
        require (checkBalance(tokenA) || checkBalance(tokenB), "No token");

        uint256 amountA = balanceOfToken(tokenA);
        uint256 amountB = balanceOfToken(tokenB);

        address pool = ksp.tokenToPool(tokenA, tokenB);

        if (amountA > 0 && amountB > 0){
            uint256 estimatedA = estimateSupply(tokenB, amountB, pool);
            uint256 estimatedB = estimateSupply(tokenA, amountA, pool);

            if (amountB >= estimatedB) {
                swapTokenUsingPangea(tokenB, tokenA, (amountB - estimatedB).div(2));
                IKSLP(pool).addKctLiquidity(balanceOfToken(tokenA), balanceOfToken(tokenB));
            }
            else {
                swapTokenUsingPangea(tokenA, tokenB, (amountA - estimatedA).div(2));
                IKSLP(pool).addKctLiquidity(balanceOfToken(tokenA), balanceOfToken(tokenB));
            }
        }
    }

    function estimateSupply(address token, uint256 amount, address pool) internal view returns (uint256) {
        require(token == tokenA || token == tokenB);

        uint256 pos = IKSLP(pool).estimatePos(token, amount);
        uint256 neg = IKSLP(pool).estimateNeg(token, amount);

        return (pos + neg)/2;
    }

    function checkBalance(address token) internal view returns (bool) {
        return IKIP7(token).balanceOf(address(this)) > 0;
    }

    function balanceOfToken(address token) internal view returns (uint256) {
        return IKIP7(token).balanceOf(address(this));
    }
}