// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

/// @notice pool router interface.
interface IPoolRouter {
    struct ExactInputSingleParams {
        address tokenIn; 
        uint256 amountIn;
        uint256 amountOutMinimum; 
        address pool;
        address to; 
        bool unwrap; 
    }

    struct ExactInputParams {
        address tokenIn; 
        uint256 amountIn; 
        uint256 amountOutMinimum; 
        address[] path; 
        address to; 
        bool unwrap; 
    }

    struct ExactOutputSingleParams {
        address tokenIn; 
        uint256 amountOut; 
        uint256 amountInMaximum;
        address pool; 
        address to; 
        bool unwrap;
    }

    struct ExactOutputParams {
        address tokenIn;
        uint256 amountOut;
        uint256 amountInMaximum;
        address[] path; 
        address to; 
        bool unwrap;
    }

    /// @notice Swap amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swap amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as ExactOutputSingleParams in calldata
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactOutputParams in calldata
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Recover mistakenly sent tokens
    function sweep(
        address token,
        uint256 amount,
        address recipient
    ) external payable;
}