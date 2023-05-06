const { ethers } = require("hardhat");

async function main(auctionAddress, safeAddress) {
    const [deployer] = await ethers.getSigners();
    console.log("Deployer address:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
    
    const AuctionBidder = await ethers.getContractFactory("AuctionBidder", wallet);
    const bidder = await AuctionBidder.deploy(auctionAddress, safeAddress);
    console.log("Contract address:", bidder.address);
}

main(
    // auction house on Goerli: https://testnet.nouns.build/dao/0xe7ff4134De785E00305EC62D9dD52bc8b41b14e8/1?tab=smart-contracts
    "0xc557AFAec24dE1c2533a7D2C5ae355bd6Bf9505D",
    // NOTE replace
    "0x730D1e9eD4f6acf98701781d97Efa710602F505F",
)
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

exports.deploy = main;