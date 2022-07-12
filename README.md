# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a script that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## Deployment

```shell
yarn deploy-game
```

## Verify

```shell
# Verify game and token contracts
npx hardhat verify-game --network rinkeby --contract <game address>
```
