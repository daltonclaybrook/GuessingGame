import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
import { config as configureDotenv } from "dotenv";

configureDotenv();

const config: HardhatUserConfig = {
  solidity: "0.8.15",

  networks: {
    rinkeby: {
      chainId: 4,
      url: process.env.RINKEBY_URL,
      accounts: [process.env.RINKEBY_PRIVATE_KEY as string],
    },
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
