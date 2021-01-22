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
    Nest3VoteFactory public immutable voteFactory;
    address public immutable nestToken;
    uint256 public DESTRUCTION_AMOUNT = 0 ether; // from nest oracle


    constructor (address _voteFactory, address _nestToken) public {
        voteFactory = Nest3VoteFactory(address(_voteFactory));
        nestToken = _nestToken;
    }

    function updateAndGetUnderlyingPrice(PToken pToken) external payable override returns (uint256) {
        uint256 priceCost = getPriceCost(pToken);
        require(msg.value >= priceCost, "No enough balance to pay oracle price.");

        if (msg.value > priceCost) {
            msg.sender.transfer(msg.value.sub(priceCost));
        }

        if (pToken.isNativeToken()) {
            return 1e18;
        }

        uint256 currentBlock = block.number;
        address underlyingToken = address(PErc20(address(pToken)).underlying());

        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        (uint256 ethAmount, uint256 tokenAmount,) = _offerPrice.updateAndCheckPriceNow{value: priceCost}(underlyingToken);
        uint256 ethForToken = ethAmount.mul(1e18).div(tokenAmount);
        prices[underlyingToken] = ethForToken;
        lastUpdateBlocks[underlyingToken] = currentBlock;

        return ethForToken;
    }

    function getPriceCost(PToken pToken) public view override returns (uint256) {
        // No need to call oracle to get ETH price
        if (pToken.isNativeToken()) return 0;
        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        uint256 priceCost = _offerPrice.checkPriceCost();
        return priceCost;
    }

    function getUnderlyingPrice(PToken pToken) public view override returns (uint256, uint256) {
        if (pToken.isNativeToken()) {
            return (1e18, block.number);
        }
        address underlyingToken = address(PErc20(address(pToken)).underlying());
        return (prices[underlyingToken], lastUpdateBlocks[underlyingToken]);
    }

    function activation() public {
        Nest3OfferPrice _offerPrice = getNestOfferPrice();
        require(!_offerPrice.checkUseNestPrice(address(this)), "Already activated.");

        if (nestToken == address(0x0)) {
            _offerPrice.activation();
            return;
        }
        IERC20(nestToken).safeTransferFrom(msg.sender, address(this), DESTRUCTION_AMOUNT);
        IERC20(nestToken).safeApprove(address(_offerPrice), DESTRUCTION_AMOUNT);
        _offerPrice.activation();
        IERC20(nestToken).safeApprove(address(_offerPrice), 0);
    }

    function getNestOfferPrice() internal view returns (Nest3OfferPrice) {
        return Nest3OfferPrice(address(voteFactory.checkAddress("nest.v3.offerPrice")));
    }

    receive() external payable {}
}


interface Nest3VoteFactory {
    function checkAddress(string calldata name) external view returns (address contractAddress);
}

// Price contract
interface Nest3OfferPrice {
    // Activate the price checking function
    function activation() external;
    // Update and check the latest price
    function updateAndCheckPriceNow(address tokenAddress) external payable returns(uint256 ethAmount, uint256 erc20Amount, uint256 blockNum);
    // Check call price fee
    function checkPriceCost() external view returns (uint256);
    // Check whether the price-checking functions can be called
    function checkUseNestPrice(address target) external view returns (bool);
}