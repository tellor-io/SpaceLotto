// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const superagent = require('superagent');
const url = "http://api.open-notify.org/iss-now.json"
const apiKey = require("../infura.json")
const privateKey = require("../pKey.json")

async function submit() {
  
  // let res =  await superagent.get(url)
  
  // let timestamp = res.body.timestamp;
  // let longitude = Math.floor(Math.abs(parseFloat(res.body.iss_position.longitude) * 10000))
  // let latitude = Math.floor(Math.abs(parseFloat(res.body.iss_position.latitude) * 10000))
  
  // let time = hre.ethers.FixedNumber.from(timestamp.toString(), "ufixed128x0").toHexString() 
  // let lon = hre.ethers.FixedNumber.from(longitude.toString(), "ufixed64x0").toHexString().slice(2)
  // let lat = hre.ethers.FixedNumber.from(latitude.toString(), "ufixed64x0").toHexString().slice(2)
  
  // let value = hre.ethers.BigNumber.from(time + lon + lat)
  
  const provider = new hre.ethers.providers.InfuraProvider("rinkeby", apiKey)
  let wallet = new hre.ethers.Wallet(privateKey.key, provider);
  
  //Submit Value to Tellor Playground
  const abi = [
      // Authenticated Functions
      "function submitValue(uint256 _requestId,uint256 _value) external",
  ] ;
  const address = "0x20374E579832859f180536A69093A126Db1c8aE9"
  // const tellorPlayground = new hre.ethers.Contract(address, abi, wallet)
  // await tellorPlayground.submitValue(75, value)

  //Draw Result from previous slots
  const drawAbi = [
    "function drawResult(uint256 slot) external",
    "function getCurrentSlot() public view returns(uint)"
  ]

  const spaceAddress = "0x62dA812723dfB6b7036ceFf63c717900b5386A32"
  const spaceLotto = new hre.ethers.Contract(spaceAddress, drawAbi, wallet)
  let slot = Math.floor(Math.floor(Date.now() / 1000) / 600) - 3
  console.log(slot);
  let cur = await spaceLotto.getCurrentSlot()
  console.log(cur.toString());
  await spaceLotto.drawResult(cur - 5)
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
submit()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
