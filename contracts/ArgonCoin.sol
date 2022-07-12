// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract ArgonCoin {
    mapping(address => uint256) private _balances;

    constructor() {
        _balances[msg.sender] = 100;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external {
        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance >= amount, "Amount exceeds balance");

        _balances[msg.sender] = senderBalance - amount;
        _balances[to] += amount;
    }
}
