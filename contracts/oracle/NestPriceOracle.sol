// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../tokenization/PToken.sol";
import "../tokenization/PErc20.sol";
import "./PriceOracle.sol";
import "./INestQuery.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract NestPriceOracle is PriceOracle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    INestQuery nestQuery;
    uint256 singleFee;
    mapping(address => uint256) prices;
    mapping(address => uint256) lastUpdateBlocks;

    constructor (address _nestQuery) public {
        nestQuery = INestQuery(_nestQuery);
        (singleFee,,) = nestQuery.params();
    }

    function updateAndGetUnderlyingPrice(PToken pToken) external payable override returns (uint256) {
        uint256 priceCost = getPriceCost(pToken);
        require(msg.value == priceCost, "No enough balance to pay oracle price.");

        if (pToken.isNativeToken()) {
            return 1e18;
        }

        uint256 currentBlock = block.number;
        address underlyingToken = address(PErc20(address(pToken)).underlying());

        (uint256 ethAmount, uint256 tokenAmount,) = nestQuery.updateAndCheckPriceNow{value: priceCost}(underlyingToken);
        uint256 ethForToken = ethAmount.mul(1e18).div(tokenAmount);
        prices[underlyingToken] = ethForToken;
        lastUpdateBlocks[underlyingToken] = currentBlock;

        return ethForToken;
    }

    function getPriceCost(PToken pToken) public view override returns (uint256) {
        if (pToken.isNativeToken()) return 0;
        return singleFee;
    }

    function getSinglePriceFee() public view override returns (uint256) {
        return singleFee;
    }

    function getUnderlyingPrice(PToken pToken) public view override returns (uint256, uint256) {
        if (pToken.isNativeToken()) {
            return (1e18, block.number);
        }
        address underlyingToken = address(PErc20(address(pToken)).underlying());
        return (prices[underlyingToken], lastUpdateBlocks[underlyingToken]);
    }
}