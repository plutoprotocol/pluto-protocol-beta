// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../NestPriceOracle.sol";

contract MockNest3OfferPrice is Nest3OfferPrice {
    bool public activated = false;

    constructor() public {
    }

    // 激活使用价格合约
    function activation() external override {
        activated = true;
    }
    // 更新并查看最新价格
    function updateAndCheckPriceNow(address tokenAddress) external payable override returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum) {
        tokenAddress;
        // 10 ETH ~ 4000 USDT
        return (10e18, 4000 * 1e6, block.number);
    }

    // 查看价格eth单条数据费用
    function checkPriceCostSingle(address tokenAddress) external view override returns(uint256) {
        tokenAddress;
        // 0.01 ETH
        return 1e16;
    }
}
