// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../tokenization/PToken.sol";
import "../tokenization/PErc20.sol";
import "./PriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract NestPriceOracle is PriceOracle {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) prices;
    mapping(address => uint256) lastUpdateBlocks;
    Nest3VoteFactory _voteFactory;

    constructor (address voteFactory) public {
        _voteFactory = Nest3VoteFactory(address(voteFactory));
    }

    function updateAndGetUnderlyingPrice(PToken pToken) external payable override returns (uint256) {
        (uint256 tokenPrice, uint256 priceUpdateBlock) = getUnderlyingPrice(pToken);
        uint256 currentBlock = block.number;
        if (pToken.isForETH() || currentBlock == priceUpdateBlock) {
            tx.origin.transfer(msg.value);
            return tokenPrice;
        }

        address underlyingToken = address(PErc20(address(pToken)).underlying());
        uint256 priceCost = getPriceCost(pToken);

        require(msg.value >= priceCost, "No enough balance to pay oracle price.");

        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        (uint256 ethAmount, uint256 tokenAmount,) = _offerPrice.updateAndCheckPriceNow{value: msg.value}(underlyingToken);
        uint256 ethForToken = ethAmount.mul(1e18).div(tokenAmount);
        prices[underlyingToken] = ethForToken;
        lastUpdateBlocks[underlyingToken] = currentBlock;

        return ethForToken;
    }

    function getPriceCost(PToken pToken) public view override returns (uint256) {
        address underlyingToken = address(PErc20(address(pToken)).underlying());
        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        uint256 priceCost = _offerPrice.checkPriceCostSingle(underlyingToken);
        return priceCost;
    }

    function getUnderlyingPrice(PToken pToken) public view override returns (uint256, uint256) {
        if (pToken.isForETH()) {
            return (1e18, block.number);
        }
        address underlyingToken = address(PErc20(address(pToken)).underlying());
        return (prices[underlyingToken], lastUpdateBlocks[underlyingToken]);
    }

    function activation(address nestAddress, uint256 nestAmount) public {
        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        // 向价格合约授权 Nest，暂定数量为10万
        IERC20(nestAddress).safeApprove(address(_offerPrice), nestAmount);
        // 激活
        _offerPrice.activation();
    }

    receive() external payable {
        tx.origin.transfer(msg.value);
    }

    function getNestOfferPrice() internal view returns (Nest3OfferPrice) {
        return Nest3OfferPrice(address(_voteFactory.checkAddress("nest.v3.offerPrice")));
    }
}


interface Nest3VoteFactory {
    // 查询地址
    function checkAddress(string calldata name) external view returns (address contractAddress);
}

// 价格合约
interface Nest3OfferPrice {
    // 激活使用价格合约
    function activation() external;
    // 更新并查看最新价格
    function updateAndCheckPriceNow(address tokenAddress) external payable returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum);
    // 查看价格eth单条数据费用
    function checkPriceCostSingle(address tokenAddress) external view returns(uint256);
}