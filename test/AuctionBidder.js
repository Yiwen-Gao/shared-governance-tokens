const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { smock } = require("@defi-wonderland/smock");
const AuctionABI = require("@zoralabs/nouns-protocol/dist/artifacts/Auction.sol/Auction.json");

describe("AuctionBidder contract", function() {
    async function deploy() {
        const [treasury, governor, user] = await ethers.getSigners();
        const auctionFake = await smock.fake(AuctionABI);
        const AuctionBidder = await ethers.getContractFactory("AuctionBidder");
        const bidder = await AuctionBidder.deploy(auctionFake.address, treasury.address, governor.address);

        return { bidder, auctionFake, treasury, governor, user };
    }

    it("should create bid", async function() {
        const { bidder, auctionFake, user } = await loadFixture(deploy);
        auctionFake.auction.returns([0, 0, ethers.constants.AddressZero, 0, 0, false]);
        auctionFake.minBidIncrement.returns(10);
        auctionFake.reservePrice.returns(ethers.utils.parseEther(".1"));

        const amt = ethers.utils.parseEther("1");
        await user.sendTransaction({
            from: user.address,
            to: bidder.address,
            value: amt,
        });
        expect(await ethers.provider.getBalance(bidder.address)).to.be.equal(amt);

        // successful bid
        await bidder.createBid();
        expect(await ethers.provider.getBalance(bidder.address)).to.be.equal(0);
        // failed bid
        await expect(bidder.createBid()).to.be.reverted;
    });

    it("should refund contribution to treasury", async function() {
        const { bidder, user } = await loadFixture(deploy);

        const balance = ethers.utils.parseEther("10");
        await user.sendTransaction({
            from: user.address,
            to: bidder.address,
            value: balance,
        });        
        expect(await ethers.provider.getBalance(bidder.address)).to.be.equal(balance);

        // sufficient funds
        let amt = ethers.utils.parseEther("5");
        await bidder.refundContribution(amt);
        expect(await ethers.provider.getBalance(bidder.address)).to.be.equal(amt);

        // insufficient funds
        amt = ethers.utils.parseEther("15");
        await expect(bidder.refundContribution(amt)).to.be.reverted;
    });
});