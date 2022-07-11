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
npx hardhat run --network <network> scripts/deploy.ts
```

## Verify

```shell
npx hardhat verify --network <network> --constructor-args scripts/deploy-args.ts <contract address>
```
