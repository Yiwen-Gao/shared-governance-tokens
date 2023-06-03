// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IAuction } from "@zoralabs/nouns-protocol/dist/src/auction/IAuction.sol";
import { IToken } from "@zoralabs/nouns-protocol/dist/src/token/IToken.sol";
import { console } from "hardhat/console.sol";

// unable to use `Auction` in "@zoralabs/nouns-protocol/dist/src/auction/Auction.sol"
// because file imports `Token`, which exceeds contract size of 24KB and triggers compilation warning
interface ICustomAuction is IAuction {
    function token() external returns (IToken);
    function auction() external returns (
        uint256 tokenId, 
        uint256 highestBid, 
        address highestBidder, 
        uint40 startTime, 
        uint40 endTime, 
        bool settled
    );
}

interface IAuctionBidder {
    function createBid() external;
    function transferToken() external;
    function refundContribution(uint) external;
    function hasHighestBid() external returns (bool);
}

contract AuctionBidder is IAuctionBidder {
    error INSUFFICIENT_FUNDS();

    ICustomAuction auction;
    address treasury;
    address governor;
    uint tokenId;

    constructor(address _auction, address _treasury, address _governor) {
        auction = ICustomAuction(_auction);
        treasury = _treasury;
        governor = _governor;
        (tokenId, , , , , ) = auction.auction();
    }

    function _getMinNextBid() private returns(uint) {
        ( , uint highestBid, , , , ) = auction.auction();
        uint minBidIncrement = auction.minBidIncrement();
        uint reservePrice = auction.reservePrice();
        uint bidPrice = highestBid + (highestBid * minBidIncrement / 100);
        return Math.max(reservePrice, bidPrice);
    }

    function createBid() external override {
        uint min = _getMinNextBid();
        uint balance = address(this).balance;
        if (min > balance) {
            revert INSUFFICIENT_FUNDS();
        }

        auction.createBid{value: balance}(tokenId);
    }

    // function createBid() external override {
    //     uint min = _getMinNextBid();
    //     uint balance = address(this).balance;
    //     if (min > balance) {
    //         revert INSUFFICIENT_FUNDS();
    //     }

    //     auction.createBid{value: min}(tokenId);
    // }

    // function createBid(uint amt) external override {
    //     uint min = _getMinNextBid();
    //     if (amt < min || amt > address(this).balance) {
    //         revert INSUFFICIENT_FUNDS();
    //     }

    //     auction.createBid{value: amt}(tokenId);
    // }

    function transferToken() external override {
        (auction.token()).transferFrom(address(this), governor, tokenId);
    }

    function refundContribution(uint amt) external override {
        if (amt > address(this).balance) {
            revert INSUFFICIENT_FUNDS();
        }

        payable(treasury).transfer(amt);
    }

    function hasHighestBid() external override returns(bool) {
        ( , , address highestBidder, , , ) = auction.auction();
        return (highestBidder == address(this));
    }

    receive() external payable {}
}