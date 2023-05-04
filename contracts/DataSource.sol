// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { IJBFundingCycleDataSource } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol";
import { IJBPayDelegate } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol";
import { IJBRedemptionDelegate } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol";
import { JBDidPayData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBDidPayData.sol";
import { JBPayParamsData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayParamsData.sol";
import { JBPayDelegateAllocation } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBPayDelegateAllocation.sol";
import { JBRedemptionDelegateAllocation } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedemptionDelegateAllocation.sol";
import { JBRedeemParamsData } from "@jbx-protocol/juice-contracts-v3/contracts/structs/JBRedeemParamsData.sol";
import { AuctionState } from "./AuctionBidder.sol";

contract DataSource is IJBFundingCycleDataSource, IJBPayDelegate {
    error NO_REDEMPTIONS_FOR_ONGOING_AUCTION();
    error NO_PAYMENTS_FOR_SETTLED_AUCTION();
    error INVALID_PAYMENT_EVENT();

    AuctionState state;
    address payable bidder;
    uint projectID;

    constructor(uint _projectID, address payable _bidder) {
        state = AuctionState.ONGOING;
        projectID = _projectID;
        bidder = _bidder;
    }

    function payParams(JBPayParamsData calldata _data) external view override returns (
        uint256 weight,
        string memory memo,
        JBPayDelegateAllocation[] memory delegateAllocations
    ) {
        if (state != AuctionState.ONGOING) {
            revert NO_PAYMENTS_FOR_SETTLED_AUCTION();
        }
        weight = _data.weight;
        memo = _data.memo;
        IJBPayDelegate delegate = IJBPayDelegate(address(this));
        delegateAllocations[0] = JBPayDelegateAllocation({delegate: delegate, amount: _data.amount.value});
    }

    function redeemParams(JBRedeemParamsData calldata _data) external pure override returns (
        uint256 reclaimAmount,
        string memory memo,
        JBRedemptionDelegateAllocation[] memory delegateAllocations
    ) {
        if (state == AuctionState.ONGOING) {
            revert NO_REDEMPTIONS_FOR_ONGOING_AUCTION();
        }
        reclaimAmount = _data.reclaimAmount.value;
        memo = _data.memo;
        IJBRedemptionDelegate delegate = IJBRedemptionDelegate(0x0000000000000000000000000000000000000000);
        delegateAllocations[0] = JBRedemptionDelegateAllocation({delegate: delegate, amount: _data.reclaimAmount.value});
    }

    function didPay(JBDidPayData calldata _data) external payable override {
        if (projectID != _data.projectId) {
            revert INVALID_PAYMENT_EVENT();
        }
        
        bidder.transfer(msg.value);
    }

    // TODO @ygao: remove if unneeded
    function supportsInterface(bytes4 interfaceId) external view override(IJBFundingCycleDataSource, IJBPayDelegate) returns (bool) {
        super.supportsInterface(interfaceId);
    }
}