// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../tokenization/PToken.sol";

abstract contract PriceOracle {
    bool public constant isPriceOracle = true;

    function getUnderlyingPrice(PToken pToken) public view virtual returns (uint256, uint256);

    function updateAndGetUnderlyingPrice(PToken pToken) external payable virtual returns (uint256);

    function getPriceCost(PToken pToken) public view virtual returns (uint256);
}