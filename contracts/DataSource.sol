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
import { IAuctionBidder } from "./AuctionBidder.sol";
import { console } from "hardhat/console.sol";

contract DataSource is IJBFundingCycleDataSource, IJBPayDelegate {
    error NO_REDEMPTIONS_FOR_ACTIVE_BID();
    error INVALID_PAYMENT_EVENT();
    error UNAUTHORIZED();

    address owner;
    IAuctionBidder bidder;
    uint projectId;

    constructor(uint _projectId, address _bidder) {
        owner = msg.sender;
        projectId = _projectId;
        bidder = IAuctionBidder(_bidder);
    }

    function updateOwner(address _owner) external {
        owner = _owner;
    }

    function payParams(JBPayParamsData calldata _data) external view override returns (
        uint256 weight, 
        string memory memo, 
        JBPayDelegateAllocation[] memory allocations
    ) {
        if (msg.sender != owner) {
            revert UNAUTHORIZED();
        }
        weight = _data.weight;
        memo = _data.memo;
        allocations = new JBPayDelegateAllocation[](1);
        allocations[0] = JBPayDelegateAllocation({delegate: IJBPayDelegate(address(this)), amount: _data.amount.value});
    }

    // call refund in `redeemParams()` instead of `didRedeem()` 
    // so that redemption request will fail if the bid is currently active
    function redeemParams(JBRedeemParamsData calldata _data) external override returns (
        uint256 reclaimAmount, 
        string memory memo, 
        JBRedemptionDelegateAllocation[] memory allocations
    ) {
        if (msg.sender != owner) {
            revert UNAUTHORIZED();
        }
        if (bidder.hasHighestBid()) {
            revert NO_REDEMPTIONS_FOR_ACTIVE_BID();
        }
        // move the requested amount from the bidder back to the project treasury
        bidder.refundContribution(_data.reclaimAmount.value);

        reclaimAmount = _data.reclaimAmount.value;
        memo = _data.memo;
        allocations = new JBRedemptionDelegateAllocation[](1);
        allocations[0] = JBRedemptionDelegateAllocation({
            delegate: IJBRedemptionDelegate(0x0000000000000000000000000000000000000000), 
            amount: _data.reclaimAmount.value
        });
    }

    function didPay(JBDidPayData calldata _data) external payable override {
        if (msg.sender != owner) {
            revert UNAUTHORIZED();
        }
        if (projectId != _data.projectId) {
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