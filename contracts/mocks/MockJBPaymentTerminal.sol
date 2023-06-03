// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";

import { IJBPaymentTerminal } from "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol";
import { console } from "hardhat/console.sol";

contract MockJBPaymentTerminal is IJBPaymentTerminal {

    function acceptsToken(address /*_token*/, uint256 /*_projectId*/) external pure returns (bool) {
        return false;
    }

    function currencyForToken(address /*_token*/) external pure returns (uint256) {
        return 0;
    }

    function decimalsForToken(address /*_token*/) external pure returns (uint256) {
        return 0;
    }

    function currentEthOverflowOf(uint256 /*_projectId*/) external pure returns (uint256) {
        return 0;
    }

    function pay(
        uint256 /*_projectId*/,
        uint256 /*_amount*/,
        address /*_token*/,
        address /*_beneficiary*/,
        uint256 /*_minReturnedTokens*/,
        bool /*_preferClaimedTokens*/,
        string calldata /*_memo*/,
        bytes calldata /*_metadata*/
    ) external payable returns (uint256 beneficiaryTokenCount) {
        beneficiaryTokenCount = 0;
    }

    function addToBalanceOf(
        uint256 /*_projectId*/,
        uint256 /*_amount*/,
        address /*_token*/,
        string calldata /*_memo*/,
        bytes calldata /*_metadata*/
    ) external payable {}

    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return (
            interfaceId == type(IJBPaymentTerminal).interfaceId ||
            interfaceId == type(IERC165).interfaceId
        );
    }
}