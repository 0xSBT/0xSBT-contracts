// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./interfaces/ITreasury.sol";
import "./interfaces/IPoolRouter.sol"; // Pangea swap
import "./interfaces/IConcentratedLiquidityPoolFactory.sol";
import "./interfaces/IConcentratedLiquidityPool.sol";
import "./interfaces/IKSP.sol"; // Klayswap
import "./interfaces/IKSLP.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@klaytn/contracts/KIP/token/KIP17/extensions/IKIP17Enumerable.sol";
import "@klaytn/contracts/KIP/token/KIP7/IKIP7.sol";

contract Treasury is OwnableUpgradeable, ITreasury {
  using SafeMath for uint256;

  uint256 private withdrawOrder;

  IKIP17Enumerable public governToken;
  IPoolRouter public pangeaRouter;
  IConcentratedLiquidityPoolFactory public pangeaPoolFactory;
  IKSP public ksp;

  mapping(uint256 => Withdraw) public withdrawList;
  mapping(address => bool) public whiteListToken;
  address[] public investingPool;

  function initialize(
    address _governToken,
    address _ksp,
    address _pangeaPoolRouter,
    address _pangeaPoolFactory
  ) public initializer {
    __Ownable_init();

    withdrawOrder = 0;

    governToken = IKIP17Enumerable(_governToken);
    pangeaRouter = IPoolRouter(_pangeaPoolRouter);
    pangeaPoolFactory = IConcentratedLiquidityPoolFactory(_pangeaPoolFactory);
    ksp = IKSP(_ksp);
    IKIP7(ksp).approve(ksp, uint256(-1));
  }

  receive() external payable {}

  modifier whiteList(address token) {
    require(whiteListToken[token], "Can't use this token");
    _;
  }

  //////////// WITHDRAW ///////////

  function withdrawFund(
    address token,
    address receiver,
    uint256 amount
  ) external onlyOwner {
    IKIP7(token).transfer(receiver, amount);
  }

  /////////// INVESTMENT ///////////

  function swapTokenUsingPangea(
    address inToken,
    address outToken,
    uint256 amount
  ) public whiteList(outToken) onlyOwner {
    require(balanceOfToken(inToken) >= amount, "Not enough token to swap");

    if (IKIP7(inToken).allowance(address(pangeaRouter) < amount)) {
      approveWhenNeeded(inToken, address(pangeaRouter), amount);
    }

    address pool = pangeaPoolFactory.getPools(inToken, outToken, 0, 1)[0];

    ExactInputSingleParams memory newParams = ExactInputSingleParams({ tokenIn: inToken, amountIn: amount, amountOutMinimum: 0, pool: pool, to: outToken, unwrap: false });

    pangeaRouter.exactInputSingle(newParams);
  }

  function swapTokenUsingKlayswap(
    address inToken,
    address outToken,
    uint256 amount
  ) public whiteList(outToken) onlyOwner {
    require(balanceOfToken(inToken) >= amount, "Not enough token to swap");

    if (IKIP7(inToken).allowance(address(ksp) < amount)) {
      approveWhenNeeded(inToken, address(ksp), amount);
    }

    address pool = ksp.tokenToPool(tokenA, tokenB);

    address[] memory path = new address[](0);

    if (inToken == address(0)) {
      ksp.exchangeKlayPos(outToken, amount, path);
    } else {
      ksp.exchangeKctPos(inToken, amount, outToken, 0, path);
    }
  }

  function addLiquidityInKlayswap(address tokenA, address tokenB) public whiteList(tokenA) whiteList(tokenB) onlyOwner {
    require(checkBalance(tokenA) || checkBalance(tokenB), "No token");

    uint256 amountA = balanceOfToken(tokenA);
    uint256 amountB = balanceOfToken(tokenB);

    address pool = ksp.tokenToPool(tokenA, tokenB);

    if (IKIP7(tokenA).allowance(pool) == 0) {
      approveWhenNeeded(tokenA, pool, uint256(-1));
    }

    if (IKIP7(tokenB).allowance(pool) == 0) {
      approveWhenNeeded(tokenB, pool, uint256(-1));
    }

    if (amountA > 0 && amountB > 0) {
      uint256 estimatedA = estimateSupply(tokenB, amountB, pool);
      uint256 estimatedB = estimateSupply(tokenA, amountA, pool);

      if (amountB >= estimatedB) {
        swapTokenUsingPangea(tokenB, tokenA, (amountB - estimatedB).div(2));
        IKSLP(pool).addKctLiquidity(balanceOfToken(tokenA), balanceOfToken(tokenB));
      } else {
        swapTokenUsingPangea(tokenA, tokenB, (amountA - estimatedA).div(2));
        IKSLP(pool).addKctLiquidity(balanceOfToken(tokenA), balanceOfToken(tokenB));
      }
    }

    investingPool.push(pool);
  }

  function claimRewardAndSwap(address token) public whiteList(token) onlyOwner {
    require(investingPool.length != 0, "Nothing to claim");

    for (uint256 i = 0; i < investingPool.length - 1; i++) {
      IKSLP(investingPool[i]).claimReward();
    }

    swapTokenUsingKlayswap(address(ksp), token, balanceOfToken(ksp));
  }

  function removeLiquidityAndZap(address pool, address tokenToZap) public whiteList(tokenToZap) onlyOwner {
    require(balanceOfToken(pool) != 0, "We don't have input LP token");

    IKSLP(pool).removeLiquidity(balanceOfToken(pool));

    address tokenA = IKSLP(pool).tokenA;
    address tokenB = IKSLP(pool).tokenB;

    address pangeaPool = pangeaPoolFactory.getPools(tokenA, tokenB, 0, 1)[0];

    (uint256 tokenAInKsp, uint256 tokenBInKsp) = IKSLP(pool).getCurrentPool();
    (uint256 tokenAInPangea, uint256 tokenBInPangea) = IConcentratedLiquidityPool(pangeaPool).getReserves();

    if (tokenToZap == tokenA) {
      if (tokenAInKsp > tokenAInPangea) {
        swapTokenUsingKlayswap(tokenB, tokenA, balanceOfToken(tokenB));
      } else {
        swapTokenUsingPangea(tokenB, tokenA, balanceOfToken(tokenB));
      }
    } else if (tokenToZap == tokenB) {
      if (tokenBInKsp > tokenBInPangea) {
        swapTokenUsingKlayswap(tokenA, tokenB, balanceOfToken(tokenA));
      } else {
        swapTokenUsingPangea(tokenA, tokenB, balanceOfToken(tokenA));
      }
    } else {
      if (tokenAInKsp + tokenBInKsp > tokenAInPangea + tokenBInPangea) {
        swapTokenUsingKlayswap(tokenA, tokenToZap, balanceOfToken(tokenA));
        swapTokenUsingKlayswap(tokenB, tokenToZap, balanceOfToken(tokenB));
      } else {
        swapTokenUsingPangea(tokenA, tokenToZap, balanceOfToken(tokenA));
        swapTokenUsingPangea(tokenB, tokenToZap, balanceOfToken(tokenB));
      }
    }
  }

  /////////// UTILS ///////////

  function approveWhenNeeded(
    address token,
    address to,
    uint256 amount
  ) internal {
    IKIP7(token).approve(to, amount);
  }

  function estimateSupply(
    address token,
    uint256 amount,
    address pool
  ) internal view returns (uint256) {
    require(token == tokenA || token == tokenB);

    uint256 pos = IKSLP(pool).estimatePos(token, amount);
    uint256 neg = IKSLP(pool).estimateNeg(token, amount);

    return (pos + neg) / 2;
  }

  function checkBalance(address token) internal view returns (bool) {
    return IKIP7(token).balanceOf(address(this)) > 0;
  }

  function balanceOfToken(address token) internal view returns (uint256) {
    return IKIP7(token).balanceOf(address(this));
  }

  /////////// PROXY ///////////

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyByOwnGov returns (bool, bytes memory) {
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    // require(success, "execute failed");
    require(success, success ? "" : _getRevertMsg(result));
    return (success, result);
  }

  function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) return "Governance::timelock::executeTransaction: Transaction execution reverted.";

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    return abi.decode(_returnData, (string)); // All that remains is the revert string
  }
}
