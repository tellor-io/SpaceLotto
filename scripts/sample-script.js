// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const superagent = require('superagent');
const url = "http://api.open-notify.org/iss-now.json"

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');
  let res =  await superagent.get(url)
  
  let timestamp = res.body.timestamp;
  let longitude = parseFloat(res.body.iss_position.longitude) * 10000
  let latitude = parseFloat(res.body.iss_position.latitude) * 10000

  console.log(longitude, latitude)
  console.log(hre.ethers.FixedNumber.from(longitude, "ufixed64x0").toString(), hre.ethers.FixedNumber.fromString(longitude, "ufixed64x0").toString())

  //115792089237316195423570985008687907853269984665640564039457584007913129639935
  //000000000000000000000000000000000000000000000000000000000000000000000000397664
  //

  //Combining all values in a single uint256
  // let value = hre.ethers.utils.AbiCoder.encode(["uin128", ["uint64"], ["uin64"]])

  // We get the contract to deploy
  const Greeter = await hre.ethers.getContractFactory("Greeter");
  const greeter = await Greeter.deploy("Hello, Hardhat!");

  await greeter.deployed();

  console.log("Greeter deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
