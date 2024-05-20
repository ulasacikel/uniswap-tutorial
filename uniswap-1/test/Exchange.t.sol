// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Exchange} from "../src/Exchange.sol";
import {Token} from "../src/Token.sol";

contract ExchangeTest is Test {
    Exchange public exchange;
    Token public token;
    address user = vm.addr(0x1337);

    function setUp() public {
        token = new Token("Test Token", "TST", 1_000_000 * 1e18);
        exchange = new Exchange(address(token));
    }

    function test_addLiquidity() public {
        token.approve(address(exchange), 200 * 1e18);
        exchange.addLiquidity{value:100e18}(200 * 1e18);
        assertEq(exchange.getReserve(), 200 * 1e18);
        assertEq(address(exchange).balance, 100 * 1e18);
    }

    function test_allowsZeroAmounts() public {
        token.approve(address(exchange), 0);
        exchange.addLiquidity{value:0}(0);

        assertEq(exchange.getReserve(), 0);
        assertEq(address(exchange).balance, 0);
    }

    function test_getsTokenAmount() public {
        token.approve(address(exchange), 2000 * 1e18);
        exchange.addLiquidity{value:1000e18}(2000 * 1e18);

        uint256 tokensOut = exchange.getTokenAmount(1 * 1e18);
        assertEq(tokensOut, 1_998001998001998001);
    }

    function test_getsEthAmount() public {
        token.approve(address(exchange), 2000 * 1e18);
        exchange.addLiquidity{value:1000e18}(2000 * 1e18);

        uint256 tokensOut = exchange.getEthAmount(2 * 1e18);
        assertEq(tokensOut, 999000999000999000);
    }

    function test_ethToTokenSwap() public {
        token.approve(address(exchange), 2000 * 1e18);
        exchange.addLiquidity{value:1000e18}(2000 * 1e18);
        (bool success, ) = payable(user).call{value:100 * 1e18}("");
        require(success, "Low-level call failed.");

        // BEGIN: USER REALM
        vm.startPrank(user);
        uint256 userEthBalanceBefore = address(user).balance;
        exchange.ethToTokenSwap{value:1e18}(1_99 * 1e16);
        vm.stopPrank();

        uint256 userEthBalanceAfter = address(user).balance;
        assertEq(userEthBalanceBefore - userEthBalanceAfter, 1e18);

        uint256 userTokenBalance = token.balanceOf(user);
        assertEq(userTokenBalance, 1_998001998001998001);

        uint256 exchangeEthBalance = address(exchange).balance;
        assertEq(exchangeEthBalance, 1001e18);

        uint256 exchangeTokenBalance = token.balanceOf(address(exchange));
        assertEq(exchangeTokenBalance, 1998_001998001998001999);
    }

    function test_tokenToEthSwap() public {
        token.approve(address(exchange), 2000 * 1e18);
        exchange.addLiquidity{value:1000e18}(2000 * 1e18);
        token.transfer(address(user), 2e18);

        // BEGIN: USER REALM
        vm.startPrank(user);
        token.approve(address(exchange), 2e18);
        uint256 userTokenBalanceBefore = token.balanceOf(user);
        exchange.tokenToEthSwap(2e18, 9e17);
        vm.stopPrank();

        uint256 userTokenBalanceAfter = token.balanceOf(user);
        assertEq(userTokenBalanceBefore - userTokenBalanceAfter, 2e18);

        uint256 userEthBalance = address(user).balance;
        assertEq(userEthBalance, 999000999000999000);

        uint256 exchangeEthBalance = address(exchange).balance;
        assertEq(exchangeEthBalance, 1000e18-999000999000999000);

        uint256 exchangeTokenBalance = token.balanceOf(address(exchange));
        assertEq(exchangeTokenBalance, 2002 * 1e18);
       
    }

}

