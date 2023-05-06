// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { IAuction } from "@zoralabs/nouns-protocol/dist/src/auction/IAuction.sol";
import { IToken } from "@zoralabs/nouns-protocol/dist/src/token/IToken.sol";
import { console } from "hardhat/console.sol";

enum AuctionState {
    ONGOING,
    WON,
    LOST
}

// unable to use `Auction` in "@zoralabs/nouns-protocol/dist/src/auction/Auction.sol"
// because file imports `Token`, which exceeds contract size of 24KB and triggers compilation warning
interface Auction is IAuction {
    function token() external returns (IToken);
    function auction() external returns (uint256, uint256, address, uint40, uint40, bool);
}

interface IAuctionBidder {
    function createBid() external;
    function transferToken() external;
}

contract AuctionBidder is IAuctionBidder {
    error INSUFFICIENT_FUNDS();

    Auction auction;
    AuctionState public state;
    uint tokenID;
    address safe;

    constructor(address _auction, address _safe) {
        console.log(_auction);
        auction = Auction(_auction);
        // TODO @ygao: update auction state
        state = AuctionState.ONGOING;
        (tokenID, , , , , ) = auction.auction();
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
        (auction.token()).transferFrom(address(this), safe, tokenID);
    }

    // TODO @ygao: add receive or fallback to accept ETH
}