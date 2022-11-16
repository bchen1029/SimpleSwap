// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    constructor() ERC20("aa", "bb") {}

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        return 123;
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn)
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        return (1, 23, 4);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        return (12, 3);
    }

    function getReserves() external view returns (uint256 reserveA, uint256 reserveB) {
        return (1, 23);
    }

    function getTokenA() external view returns (address tokenA) {
        return address(this);
    }

    function getTokenB() external view returns (address tokenB) {
        return address(this);
    }
}
