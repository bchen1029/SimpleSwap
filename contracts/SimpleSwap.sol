// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    using Address for address;
    using SafeMath for uint256;

    address private _tokenA;
    address private _tokenB;

    uint256 private _reserveA;
    uint256 private _reserveB;

    constructor(address tokenA, address tokenB) ERC20("Simple Swap", "SLP") {
        require(tokenA.isContract(), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(tokenB.isContract(), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(tokenA != tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");

        _tokenA = tokenA;
        _tokenB = tokenB;
    }

    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256 amountOut) {
        address tokenA = getTokenA();
        address tokenB = getTokenB();

        require(tokenIn == tokenA || tokenIn == tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == tokenA || tokenOut == tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        ERC20(tokenIn).approve(address(this), amountIn);
        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        (uint256 reserveA, uint256 reserveB) = getReserves();
        uint256 tokenInBalance = ERC20(tokenIn).balanceOf(address(this));
        uint256 actualTokenIn = tokenIn == tokenA ? tokenInBalance.sub(reserveA) : tokenInBalance.sub(reserveB);

        uint256 reserveOut = tokenOut == tokenA ? reserveA : reserveB;
        uint256 reserveIn = tokenIn == tokenA ? reserveA : reserveB;

        // Δy = y Δx  / (x + Δx)
        // ref: https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol#L43
        uint256 numerator = actualTokenIn.mul(reserveOut);
        uint256 denominator = reserveIn.add(actualTokenIn);
        amountOut = numerator.div(denominator);
        require(amountOut > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");

        _reserveA = tokenIn == tokenA ? _reserveA.add(actualTokenIn) : _reserveA.sub(amountOut);
        _reserveB = tokenIn == tokenA ? _reserveB.sub(amountOut) : _reserveB.add(actualTokenIn);
        ERC20(tokenOut).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, tokenIn, tokenOut, actualTokenIn, amountOut);
    }

    function addLiquidity(
        uint256 amountAIn,
        uint256 amountBIn
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        address tokenA = getTokenA();
        address tokenB = getTokenB();

        (uint256 reserveA, uint256 reserveB) = getReserves(); // get current reserve

        uint256 actualAmountA = amountAIn;
        uint256 actualAmountB = amountBIn;

        if (totalSupply() > 0) {
            actualAmountA = Math.min(amountAIn, reserveA.mul(amountBIn).div(reserveB));
            actualAmountB = Math.min(amountBIn, reserveB.mul(amountAIn).div(reserveA));
        }

        ERC20(tokenA).transferFrom(msg.sender, address(this), actualAmountA);
        ERC20(tokenB).transferFrom(msg.sender, address(this), actualAmountB);

        amountA = ERC20(tokenA).balanceOf(address(this)).sub(reserveA);
        amountB = ERC20(tokenB).balanceOf(address(this)).sub(reserveB);
        liquidity = Math.sqrt(amountA.mul(amountB));

        _mint(msg.sender, liquidity);

        _reserveA = _reserveA.add(amountA); // update reserve
        _reserveB = _reserveB.add(amountB); // update reserve

        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        (uint256 reserveA, uint256 reserveB) = getReserves();
        uint256 totalSupply = totalSupply();
        uint256 repayAmountA = liquidity.mul(reserveA).div(totalSupply);
        uint256 repayAmountB = liquidity.mul(reserveB).div(totalSupply);

        address tokenA = getTokenA();
        address tokenB = getTokenB();
        ERC20(tokenA).transfer(msg.sender, repayAmountA);
        ERC20(tokenB).transfer(msg.sender, repayAmountB);

        uint256 balanceA = ERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(tokenB).balanceOf(address(this));
        amountA = reserveA.sub(balanceA);
        amountB = reserveB.sub(balanceB);

        transfer(address(this), liquidity);
        _burn(address(this), liquidity);

        _reserveA = balanceA; // TODO: here should prevent reentrancy
        _reserveB = balanceB; // TODO: here should prevent reentrancy

        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function getReserves() public view returns (uint256 reserveA, uint256 reserveB) {
        reserveA = _reserveA;
        reserveB = _reserveB;
    }

    function getTokenA() public view returns (address tokenA) {
        tokenA = _tokenA;
    }

    function getTokenB() public view returns (address tokenB) {
        tokenB = _tokenB;
    }
}
