// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../oracle/NestPriceOracle.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockNest3OfferPrice is Nest3OfferPrice {
    using SafeMath for uint256;

    uint256 effectTime = 0 days;
    mapping(address => uint256) _addressEffect;

    constructor() public {
    }

    // Activate the price checking function
    function activation() external override {
        _addressEffect[address(msg.sender)] = now.add(effectTime);
    }

    // Update and check the latest price
    function updateAndCheckPriceNow(address tokenAddress) external payable override returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum) {
        tokenAddress;
        uint256 priceCost = checkPriceCost();
        require(checkUseNestPrice(address(msg.sender)), "Activation required.");
        require(msg.value >= priceCost, "No enough oracle cost paid.");
        if (msg.value > priceCost) msg.sender.transfer(msg.value.sub(priceCost));
        // 10 ETH ~ 4000 USDT
        return (10e18, 4000 * 1e6, block.number);
    }

    // Check call price fee
    function checkPriceCost() public view override returns(uint256) {
        // 0.01 ETH
        return 1e9;
        //return 0;
    }

    // Check whether the price-checking functions can be called
    function checkUseNestPrice(address target) public view override returns (bool) {
        if (_addressEffect[target] <= now && _addressEffect[target] != 0) {
            return true;
        } else {
            return false;
        }
    }
}
