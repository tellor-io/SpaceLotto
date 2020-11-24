// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const hre = require("hardhat");
const superagent = require('superagent');
const url = "http://api.open-notify.org/iss-now.json"
const apiKey = require("../infura.json")
const privateKey = require("../pKey.json")

async function submit() {
  const abi = [
    // Authenticated Functions
    "function submitValue(uint256 _requestId,uint256 _value) external",
  ] ;

  let res =  await superagent.get(url)
    
  let timestamp = res.body.timestamp;
  let longitude = Math.floor(Math.abs(parseFloat(res.body.iss_position.longitude) * 10000))
  let latitude = Math.floor(Math.abs(parseFloat(res.body.iss_position.latitude) * 10000))

  let time = hre.ethers.FixedNumber.from(timestamp.toString(), "ufixed128x0").toHexString() 
  let lon = hre.ethers.FixedNumber.from(longitude.toString(), "ufixed64x0").toHexString().slice(2)
  let lat = hre.ethers.FixedNumber.from(latitude.toString(), "ufixed64x0").toHexString().slice(2)
  
  let value = hre.ethers.BigNumber.from(time + lon + lat)

  const provider = new hre.ethers.providers.InfuraProvider("rinkeby", apiKey)
  const address = "0x20374E579832859f180536A69093A126Db1c8aE9"
  let wallet = new hre.ethers.Wallet(privateKey.key, provider);

  const tellorPlayground = new hre.ethers.Contract(address, abi, wallet)

  await tellorPlayground.submitValue(75, value)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
submit()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
