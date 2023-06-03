const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { smock } = require("@defi-wonderland/smock");
const JBPaymentTerminalABI = require("@jbx-protocol/juice-contracts-v3/deployments/goerli/JBETHPaymentTerminal3_1.json");

describe("DataSource contract", function() {
    async function deploy() {
        const [deployer, temp] = await ethers.getSigners();
        const bidderFake = await smock.fake("AuctionBidder");
        const DataSource = await ethers.getContractFactory("DataSource");
        const source = await DataSource.deploy(123, bidderFake.address);

        return { source, bidderFake, deployer, temp };
    }

    it("should redeem based on bidder state", async function() {
        const { source, bidderFake, deployer, temp } = await loadFixture(deploy);
        const PaymentTerminal = await ethers.getContractFactory("MockJBPaymentTerminal");
        const terminal = await PaymentTerminal.deploy();
          
        const data = {
            terminal: terminal.address,
            holder: temp.address,
            projectId: 0,
            currentFundingCycleConfiguration: 0,
            tokenCount: 0,
            totalSupply: 0,
            overflow: 0,
            reclaimAmount: {
                token: temp.address,
                value: 123,
                decimals: 18,
                currency: 0,
            },
            useTotalOverflow: false,
            redemptionRate: 0,
            memo: "hi",
            metadata: "0x1234",
        };

        bidderFake.hasHighestBid.returns(true);
        await expect(source.connect(deployer).redeemParams(data)).to.be.reverted;
        bidderFake.hasHighestBid.returns(false);

        bidderFake.refundContribution.reverts();
        await expect(source.connect(deployer).redeemParams(data)).to.be.reverted;
        bidderFake.refundContribution.reset();

        const { reclaimAmount, memo, allocations } = await source.connect(deployer).callStatic.redeemParams(data);
        expect(reclaimAmount).to.be.equal(123);
        expect(memo).to.be.equal("hi");
        expect(allocations).to.have.length(1);
        const { delegate, amount } = allocations[0];
        expect(delegate).to.be.equal(ethers.constants.AddressZero);
        expect(amount).to.be.equal(123);
    });
});