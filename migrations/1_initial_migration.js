// First we import the contracts from the contracts folder
const TrustGemsToken = artifacts.require("./TrustGemsToken");
const PrivateSale = artifacts.require("./PrivateSale");

// The we have to declare export functions to the deployer
module.exports = async function (deployer) {
  // We deploy the first contrat
  await deployer.deploy(TrustGemsToken);
  // We store the information of the recently deployed token
  const token = await TrustGemsToken.deployed();
  // We deploy the sale contract passing the address of the token we are selling
  await deployer.deploy(PrivateSale, token.address);
  // We store the information of the recently deployed sale
  const ico = await PrivateSale.deployed();
  // We passs some tokens to the sale conract to have something to sell
  await token.transfer(ico.address, web3.utils.toBN("15000000000000000000000000"));
  // We add users to the Sale Whitelist
  await ico.addManyUsers(["0xC02D73E1dacA1e4a84e9CDD6d7CCACBBF1da3435","0x0582fB623317d4B711Da3D7658cd6f834b508417","0xe69C8358DfeA73492103eD34B8382f145aa0bAca", "0x640b0a091dE01eb67697A2116a3549E925DEC217", "0x02D9f1C0FF83c8848AD119A1FC41435F57b14A74", "0xFB756D65C2E74281ACc6D05F13D249b4D9432063" ]);
  
  // You can also directly start the sale by calling:
  // await ico.start();
};