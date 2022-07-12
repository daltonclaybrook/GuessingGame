# Guessing Game

This project demonstrates an implementation of a guessing game on the Ethereum blockchain. It contains a `GuessingGame` contract with the core functionality of the game, and a `GuessToken` ERC-20 token, which serves as the prize token for the game.

## Deployment

Run the following script to deploy the contracts to the Rinkeby test network.

```shell
yarn deploy-game
```

## Verify

```shell
# Verify source code on Etherscan for the game and token contracts
npx hardhat verify-game --network rinkeby --contract <game address>
```
