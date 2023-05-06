const { ethers } = require("hardhat");

async function main(juiceboxProjectID, auctionBidderAddress) {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
    
    const DataSource = await ethers.getContractFactory("DataSource", wallet);
    const source = await DataSource.deploy(juiceboxProjectID, auctionBidderAddress);
    console.log("Contract address:", source.address);
}

// NOTE replace the addresses.
main(
    "0x730D1e9eD4f6acf98701781d97Efa710602F505F", 
    "0x730D1e9eD4f6acf98701781d97Efa710602F505F",
)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error.reason);
        process.exit(1);
    });

exports.deploy = main;