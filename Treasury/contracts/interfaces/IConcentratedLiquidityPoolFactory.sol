

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import "./IPoolFactory.sol";

/// @notice Pool deployment interface.
interface IConcentratedLiquidityPoolFactory is IPoolFactory {

    function deployPool(bytes calldata deployData) external returns (address pool);

    function configAddress(bytes32 data) external returns (address pool);

    function isPool(address pool) external returns (bool ok);

    function totalPoolsCount() external view returns (uint256 total);

    function getPoolAddress(uint256 idx) external view returns (address pool);

    function poolsCount(address token0, address token1) external view returns (uint256 count);
    
    function getPools(
        address token0,
        address token1,
        uint256 startIndex,
        uint256 count
    ) external view returns (address[] memory pairPools);
}