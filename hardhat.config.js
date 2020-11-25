require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("deploy", "Deploy and verify the contracts on rinkeby")
  .setAction(async taskArgs => {
    const playgroundAddress = "0x20374E579832859f180536A69093A126Db1c8aE9"
    const SpaceLotto = await hre.ethers.getContractFactory("contracts/SpaceLotto.sol:SpaceLotto");
    const contract = await SpaceLotto.deploy(playgroundAddress);
    await contract.deployed();
    console.log("contract deployed to:", contract.address);

    // Wait for 2 confirmed transactions.
    // Otherwise the etherscan api doesn't find the deployed contract.
    await contract.deployTransaction.wait(2)

    await hre.run(
      "verify", {
      address: contract.address,
      constructorArguments: [playgroundAddress],
    },
    )
  });


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_RINKEBY}`,
      accounts: [process.env.PRIVATE_KEY]
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_MAINNET}`,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.ETHERSCAN
  },
  // solidity: "0.7.3",
  // solidity: "0.5.16",
  solidity: "0.7.0",
};

