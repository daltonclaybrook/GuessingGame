// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Counter {
    uint256 public currentCount;

    function increment() external returns (uint256) {
        return currentCount++;
    }

    function decrement() external returns (uint256) {
        require(currentCount > 0, "Cannot decrement any lower");
        return currentCount--;
    }
}
