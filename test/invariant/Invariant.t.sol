// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is StdInvariant, Test {
    int256 constant STARTING_WETH = 50 ether;
    int256 constant STARTING_POOL_TOKEN = 100 ether;

    Handler internal handler;
    ERC20Mock internal wethToken;
    ERC20Mock internal poolToken;

    PoolFactory internal poolFactory;
    TSwapPool internal pool; // WETH/POOL_TOKEN

    function setUp() public {
        wethToken = new ERC20Mock();
        poolToken = new ERC20Mock();
        poolFactory = new PoolFactory(address(wethToken));
        pool = TSwapPool(poolFactory.createPool(address(poolToken)));
        handler = new Handler(pool);

        // Create initial x & y balances
        poolToken.mint(address(this), uint256(STARTING_POOL_TOKEN));
        wethToken.mint(address(this), uint256(STARTING_WETH));

        // Approve pool to transfer tokens
        poolToken.approve(address(pool), uint256(STARTING_POOL_TOKEN));
        wethToken.approve(address(pool), uint256(STARTING_WETH));

        // Add initial liquidity with deposit
        pool.deposit(
            uint256(STARTING_WETH),
            uint256(STARTING_WETH),
            uint256(STARTING_POOL_TOKEN),
            uint64(block.timestamp)
        );

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapFromOutputWeth.selector;

        targetSelector(
            FuzzSelector({addr: address(handler), selectors: selectors})
        );
        targetContract(address(handler));
    }

    function statefulFuzz_ConstantProductFormulaStaysTheSameX() public {
        assertEq(
            handler.actualDeltaPoolTokenAmount(),
            handler.expectedDeltaPoolTokenAmount()
        );
    }

    function statefulFuzz_ConstantProductFormulaStaysTheSameY() public {
        assertEq(
            handler.actualDeltaWethAmount(),
            handler.expectedDeltaWethAmount()
        );
    }
}
