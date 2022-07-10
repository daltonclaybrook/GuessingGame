import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import { config as configureDotenv } from 'dotenv';

configureDotenv();

const config: HardhatUserConfig = {
  solidity: "0.8.15",
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY
  }
};

export default config;
