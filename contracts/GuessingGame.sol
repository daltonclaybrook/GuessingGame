// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./GuessToken.sol";

contract GuessingGame {
    GuessToken public immutable token;

    constructor() {
        token = new GuessToken(this);
    }
}
