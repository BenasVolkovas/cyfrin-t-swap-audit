// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/PoolFactory.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AuditTests is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function test_getInputAmountBasedOnOutput_CalculatesTheInputIncorrectly()
        external
    {
        uint256 initialBalance = 1_000_000 ether;
        uint256 wethReserves = 100 ether;
        uint256 poolTokenReserves = 100_000 ether;
        uint256 wethBuyAmount = 1 ether;
        uint256 expectedPoolTokensSellAmount = ((poolTokenReserves *
            wethReserves) * 1000) / ((wethReserves - wethBuyAmount) * 997);

        // Setup tokens and pool
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(
            address(poolToken),
            address(weth),
            "LTokenA",
            "LA"
        );

        // Mint tokens for liquidity provider and usr
        weth.mint(liquidityProvider, initialBalance);
        poolToken.mint(liquidityProvider, initialBalance);

        weth.mint(user, initialBalance);
        poolToken.mint(user, initialBalance);

        // Add liquidity (100_000 pool tokens, 100 weth)
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), wethReserves);
        poolToken.approve(address(pool), poolTokenReserves);
        pool.deposit(
            wethReserves,
            wethReserves,
            poolTokenReserves,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // Try to get input amount based on output
        vm.startPrank(user);
        uint256 poolTokensSellAmount = pool.getInputAmountBasedOnOutput(
            wethBuyAmount,
            poolTokenReserves,
            wethReserves
        );

        assertEq(
            poolTokensSellAmount,
            expectedPoolTokensSellAmount,
            "Incorrect pool tokens sell amount"
        );
    }
}
