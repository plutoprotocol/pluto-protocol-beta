// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

interface IERC20Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}