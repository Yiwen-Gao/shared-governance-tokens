// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { 
    IJBFundingCycleDataSource, 
    IJBPayDelegate,
    IJBRedemptionDelegate,
    JBDidPayData,
    JBPayDelegateAllocation, 
    JBPayParamsData, 
    JBRedeemParamsData, 
    JBRedemptionDelegateAllocation
} from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol";
import { AuctionBidder, AuctionState } from "./AuctionBidder.sol";

contract DataSource is IJBFundingCycleDataSource, IJBPayDelegate {
    error NO_REDEMPTIONS_FOR_ONGOING_AUCTION();
    error NO_PAYMENTS_FOR_SETTLED_AUCTION();
    error INVALID_PAYMENT_EVENT();

    AuctionBidder bidder;
    uint projectID;

    constructor(uint _projectID, address payable _bidder) {
        projectID = _projectID;
        bidder = AuctionBidder(_bidder);
    }

    function payParams(JBPayParamsData calldata _data) external view override returns (uint256, string memory, JBPayDelegateAllocation[] memory) {
        if (bidder.state() != AuctionState.ONGOING) {
            revert NO_PAYMENTS_FOR_SETTLED_AUCTION();
        }
        JBPayDelegateAllocation[] memory allocations = new JBPayDelegateAllocation[](1);
        allocations[0] = JBPayDelegateAllocation({delegate: IJBPayDelegate(address(this)), amount: _data.amount.value});
        return (_data.weight, _data.memo, allocations);
    }

    // TODO @ygao: get funds back from bidder
    function redeemParams(JBRedeemParamsData calldata _data) external view override returns (uint256, string memory, JBRedemptionDelegateAllocation[] memory) {
        if (bidder.state() == AuctionState.ONGOING) {
            revert NO_REDEMPTIONS_FOR_ONGOING_AUCTION();
        }
        JBRedemptionDelegateAllocation[] memory allocations = new JBRedemptionDelegateAllocation[](1); 
        allocations[0] = JBRedemptionDelegateAllocation({
            delegate: IJBRedemptionDelegate(0x0000000000000000000000000000000000000000), 
            amount: _data.reclaimAmount.value
        });
        return (_data.reclaimAmount.value, _data.memo, allocations);
    }

    function didPay(JBDidPayData calldata _data) external payable override {
        if (projectID != _data.projectId) {
            revert INVALID_PAYMENT_EVENT();
        }
        
        payable(address(bidder)).transfer(msg.value);
    }

    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return (
            interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
            interfaceId == type(IJBPayDelegate).interfaceId ||
            interfaceId == type(IERC165).interfaceId
        );
    }
}