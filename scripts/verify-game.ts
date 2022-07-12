import { HardhatRuntimeEnvironment } from "hardhat/types";
import gameArgs from "./deploy-args";

interface Args {
  contract: string;
}

export const verifyGameAndToken = async (
  taskArgs: Args,
  env: HardhatRuntimeEnvironment
): Promise<void> => {
  const gameAddress = taskArgs.contract;

  console.log(`Verifying game contract at ${gameAddress}`);
  await env.run("verify:verify", {
    address: gameAddress,
    constructorArguments: gameArgs,
  });

  const GuessingGame = await env.ethers.getContractFactory("GuessingGame");
  const guessingGame = GuessingGame.attach(gameAddress);
  const tokenAddress = await guessingGame.token();

  console.log(`Verifying token contract...`);
  await env.run("verify:verify", {
    address: tokenAddress,
    constructorArguments: [gameAddress],
  });
};
