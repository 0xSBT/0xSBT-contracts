// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IKSP {
    function exchangeKlayPos(address token, uint256 amount, address[] memory path) external payable;
    function exchangeKctPos(address tokenA, uint256 amountA, address tokenB, uint256 amountB, address[] memory path) external;
    function exchangeKlayNeg(address token, uint256 amount, address[] memory path) external payable;
    function exchangeKctNeg(address tokenA, uint256 amountA, address tokenB, uint256 amountB, address[] memory path) external;
    function tokenToPool(address tokenA, address tokenB) external view returns (address);
    function poolExist(address pool) external view returns (bool);
    function transfer(address _to, uint _value) external returns (bool);
}