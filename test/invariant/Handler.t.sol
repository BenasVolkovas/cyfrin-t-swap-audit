// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool internal pool;
    ERC20Mock internal wethToken;
    ERC20Mock internal poolToken;

    address internal liquidityProvider = makeAddr("lp");
    address internal swapper = makeAddr("swapper");

    int256 public expectedDeltaWethAmount;
    int256 public expectedDeltaPoolTokenAmount;
    int256 public actualDeltaWethAmount;
    int256 public actualDeltaPoolTokenAmount;

    int256 public startingWethAmount;
    int256 public startingPoolTokenAmount;
    int256 public endingWethAmount;
    int256 public endingPoolTokenAmount;

    constructor(TSwapPool _pool) {
        pool = _pool;
        wethToken = ERC20Mock(_pool.getWeth());
        poolToken = ERC20Mock(_pool.getPoolToken());
    }

    function deposit(uint256 wethAmount) public {
        uint256 minWethAmount = pool.getMinimumWethDepositAmount();
        wethAmount = bound(wethAmount, minWethAmount, type(uint64).max);

        // Get actual starting amounts
        startingWethAmount = int256(wethToken.balanceOf(address(pool)));
        startingPoolTokenAmount = int256(poolToken.balanceOf(address(pool)));

        // Get expected deltas
        expectedDeltaWethAmount = int256(wethAmount);
        expectedDeltaPoolTokenAmount = int256(
            pool.getPoolTokensToDepositBasedOnWeth(wethAmount)
        );

        // Deposit
        vm.startPrank(liquidityProvider);
        wethToken.mint(liquidityProvider, uint256(expectedDeltaWethAmount));
        poolToken.mint(
            liquidityProvider,
            uint256(expectedDeltaPoolTokenAmount)
        );
        wethToken.approve(address(pool), uint256(expectedDeltaWethAmount));
        poolToken.approve(address(pool), uint256(expectedDeltaPoolTokenAmount));

        pool.deposit(
            wethAmount,
            0,
            uint256(expectedDeltaPoolTokenAmount),
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // Get actual ending amounts
        endingWethAmount = int256(wethToken.balanceOf(address(pool)));
        endingPoolTokenAmount = int256(poolToken.balanceOf(address(pool)));

        actualDeltaWethAmount =
            int256(endingWethAmount) -
            int256(startingWethAmount);
        actualDeltaPoolTokenAmount =
            int256(endingPoolTokenAmount) -
            int256(startingPoolTokenAmount);
    }

    function swapFromOutputWeth(uint256 outputWeth) public {
        uint256 minWethAmount = pool.getMinimumWethDepositAmount();
        outputWeth = bound(
            outputWeth,
            minWethAmount,
            wethToken.balanceOf(address(pool))
        );

        if (outputWeth >= wethToken.balanceOf(address(pool))) {
            return;
        }

        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth,
            poolToken.balanceOf(address(pool)),
            wethToken.balanceOf(address(pool))
        );

        if (poolTokenAmount >= type(uint64).max) {
            return;
        }

        // Get actual starting amounts
        startingWethAmount = int256(wethToken.balanceOf(address(pool)));
        startingPoolTokenAmount = int256(poolToken.balanceOf(address(pool)));

        // Get expected deltas
        expectedDeltaWethAmount = -1 * int256(outputWeth);
        expectedDeltaPoolTokenAmount = int256(poolTokenAmount);

        if (poolToken.balanceOf(swapper) < poolTokenAmount) {
            poolToken.mint(
                swapper,
                poolTokenAmount - poolToken.balanceOf(swapper)
            );
        }

        vm.startPrank(swapper);
        poolToken.approve(address(pool), poolTokenAmount);
        pool.swapExactOutput(
            poolToken,
            wethToken,
            outputWeth,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // Get actual ending amounts
        endingWethAmount = int256(wethToken.balanceOf(address(pool)));
        endingPoolTokenAmount = int256(poolToken.balanceOf(address(pool)));

        actualDeltaWethAmount =
            int256(endingWethAmount) -
            int256(startingWethAmount);
        actualDeltaPoolTokenAmount =
            int256(endingPoolTokenAmount) -
            int256(startingPoolTokenAmount);
    }
}
