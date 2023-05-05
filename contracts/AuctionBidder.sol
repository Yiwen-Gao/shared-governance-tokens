// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { Auction, AuctionStorageV1, IAuction, Token } from "@zoralabs/nouns-protocol/dist/src/auction/Auction.sol";
import { console } from "hardhat/console.sol";

enum AuctionState {
    ONGOING,
    WON,
    LOST
}

interface IAuctionBidder {
    function createBid() external;
    function transferToken() external;
}

contract AuctionBidder is IAuctionBidder {
    error INSUFFICIENT_FUNDS();

    Auction auction;
    AuctionState public state;
    Token token;
    uint tokenID;
    address safe;

    constructor(address _auction, address _safe) {
        auction = Auction(_auction);
        // TODO @ygao: update auction state
        state = AuctionState.ONGOING;
        token = auction.token();
        (tokenID, , , , ,) = auction.auction();
        safe = _safe;
    }

    function createBid() external override {
        ( , uint highestBid, , , , ) = auction.auction();
        if (highestBid > address(this).balance) {
            revert INSUFFICIENT_FUNDS();
        }

        auction.createBid{value: address(this).balance}(tokenID);
    }

    function transferToken() external override {
        token.transferFrom(address(this), safe, tokenID);
    }

    // TODO @ygao: add receive or fallback to accept ETH
}