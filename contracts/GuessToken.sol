// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GuessingGame.sol";

contract GuessToken is IERC20 {
    /// @notice The total supply of the token currently in circulation
    uint256 public totalSupply;

    /// @notice The name of the token
    string public constant name = "GuessToken";

    /// @notice The token's symbol
    string public constant symbol = "GUESS";
    
    /// @notice The number of decimal places used to get the token's user representation.
    /// @dev e.g. If `decimals` is 4, and a user's balance in `_balances` is "123456",
    /// then the balance the user sees in any user-facing UI is "12.3456"
    uint8 public constant decimals = 18;

    /// @notice The address of the associated game contract that has special
    /// privileges when accessing this contract.
    GuessingGame public immutable gameContract;

    /// @notice A mapping of addresses to their balance of tokens
    mapping(address => uint256) private _balances;

    /// @notice A mapping of tokens an address is allowed to spend on behalf of
    /// a different owner.
    /// @dev owner => spender => allowance
    mapping(address => mapping(address => uint256)) private _allowances;

    // MARK: - ERC-20 requirements

    constructor(GuessingGame _gameContract) {
        gameContract = _gameContract;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = allowance(from, spender);
        require(_allowance >= amount, "insufficient allowance");
        
        _approve(from, spender, _allowance - amount);
        _transfer(from, to, amount);
        return true;
    }

    // MARK: - Game contract functions

    /// @notice The game contract can mint tokens for various reasons like the winner's
    /// prize, or incentives for adding clues.
    function mint(address account, uint256 amount) external onlyGameContract {
        totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // MARK: - Private helpers

    function _transfer(address from, address to, uint256 amount) private {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");
        _balances[msg.sender] = fromBalance - amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Modifiers

    modifier onlyGameContract {
        require(msg.sender == address(gameContract), "This function can only be called by the game contract");
        _;
    }
}
