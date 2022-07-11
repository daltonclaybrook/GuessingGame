import { ethers, network } from "hardhat";
import gameArgs from "./deploy-args";

async function deployLock() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  const lockedAmount = ethers.utils.parseEther("1");

  const Lock = await ethers.getContractFactory("Lock");
  const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  await lock.deployed();

  console.log("Lock with 1 ETH deployed to:", lock.address);
}

const deployGame = async () => {
  const GuessingGame = await ethers.getContractFactory("GuessingGame");
  const guessingGame = await GuessingGame.deploy(...gameArgs);

  await guessingGame.deployed();
  console.log(
    `GuessingGame contract deployed to network ${network.name} at ${guessingGame.address}`
  );
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployGame().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
