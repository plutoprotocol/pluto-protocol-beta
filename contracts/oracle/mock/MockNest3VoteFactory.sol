// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../NestPriceOracle.sol";
import "../PriceOracle.sol";
import "./MockNest3OfferPrice.sol";

contract MockNest3VoteFactory is Nest3VoteFactory {
    Nest3OfferPrice public priceOracle;

    constructor() public {
        priceOracle = new MockNest3OfferPrice();
    }

    function checkAddress(string calldata name) external view override returns (address contractAddress) {
        name;
        return address(priceOracle);
    }
}
