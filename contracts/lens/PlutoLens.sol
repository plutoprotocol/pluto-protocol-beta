// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
pragma experimental ABIEncoderV2;

import "../tokenization/PErc20.sol";
import "../tokenization/PToken.sol";
import "../oracle/PriceOracle.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface PlutoLensInterface {
    function markets(address) external view returns (bool, uint);
    function oracle() external view returns (PriceOracle);
    function getAccountLiquidity(address) external view returns (uint, uint, uint);
    function getAssetsIn(address) external view returns (PToken[] memory);
}

contract PlutoLens {
    struct PTokenMetadata {
        address pToken;
        uint exchangeRateCurrent;
        uint supplyRatePerBlock;
        uint borrowRatePerBlock;
        uint reserveFactorMantissa;
        uint totalBorrows;
        uint totalReserves;
        uint totalSupply;
        uint totalCash;
        bool isListed;
        uint collateralFactorMantissa;
        address underlyingAssetAddress;
        uint pTokenDecimals;
        uint underlyingDecimals;
    }

    function pTokenMetadata(PToken pToken) public returns (PTokenMetadata memory) {
        uint exchangeRateCurrent = pToken.exchangeRateCurrent();
        PlutoLensInterface plutoLens = PlutoLensInterface(address(pToken.riskManager()));
        (bool isListed, uint collateralFactorMantissa) = plutoLens.markets(address(pToken));
        address underlyingAssetAddress;
        uint underlyingDecimals;

        if (compareStrings(pToken.symbol(), "cETH")) {
            underlyingAssetAddress = address(0);
            underlyingDecimals = 18;
        } else {
            PErc20 pErc20 = PErc20(address(pToken));
            underlyingAssetAddress = pErc20.underlying();
            underlyingDecimals = ERC20(pErc20.underlying()).decimals();
        }

        return PTokenMetadata({
        pToken: address(pToken),
        exchangeRateCurrent: exchangeRateCurrent,
        supplyRatePerBlock: pToken.supplyRatePerBlock(),
        borrowRatePerBlock: pToken.borrowRatePerBlock(),
        reserveFactorMantissa: pToken.reserveFactorMantissa(),
        totalBorrows: pToken.totalBorrows(),
        totalReserves: pToken.totalReserves(),
        totalSupply: pToken.totalSupply(),
        totalCash: pToken.getCash(),
        isListed: isListed,
        collateralFactorMantissa: collateralFactorMantissa,
        underlyingAssetAddress: underlyingAssetAddress,
        pTokenDecimals: pToken.decimals(),
        underlyingDecimals: underlyingDecimals
        });
    }

    function pTokenMetadataAll(PToken[] calldata pTokens) external returns (PTokenMetadata[] memory) {
        uint pTokenCount = pTokens.length;
        PTokenMetadata[] memory res = new PTokenMetadata[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = pTokenMetadata(pTokens[i]);
        }
        return res;
    }

    struct PTokenBalances {
        address pToken;
        uint balanceOf;
        uint borrowBalanceCurrent;
        uint balanceOfUnderlying;
        uint tokenBalance;
        uint tokenAllowance;
    }

    function pTokenBalances(PToken pToken, address payable account) public returns (PTokenBalances memory) {
        uint balanceOf = pToken.balanceOf(account);
        uint borrowBalanceCurrent = pToken.borrowBalanceCurrent(account);
        uint balanceOfUnderlying = pToken.balanceOfUnderlying(account);
        uint tokenBalance;
        uint tokenAllowance;

        if (compareStrings(pToken.symbol(), "cETH")) {
            tokenBalance = account.balance;
            tokenAllowance = account.balance;
        } else {
            PErc20 pErc20 = PErc20(address(pToken));
            IERC20 underlying = IERC20(pErc20.underlying());
            tokenBalance = underlying.balanceOf(account);
            tokenAllowance = underlying.allowance(account, address(pToken));
        }

        return PTokenBalances({
        pToken: address(pToken),
        balanceOf: balanceOf,
        borrowBalanceCurrent: borrowBalanceCurrent,
        balanceOfUnderlying: balanceOfUnderlying,
        tokenBalance: tokenBalance,
        tokenAllowance: tokenAllowance
        });
    }

    function pTokenBalancesAll(PToken[] calldata pTokens, address payable account) external returns (PTokenBalances[] memory) {
        uint pTokenCount = pTokens.length;
        PTokenBalances[] memory res = new PTokenBalances[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = pTokenBalances(pTokens[i], account);
        }
        return res;
    }

    struct PTokenUnderlyingPrice {
        address pToken;
        uint underlyingPrice;
    }

    function pTokenUnderlyingPrice(PToken pToken) public view returns (PTokenUnderlyingPrice memory) {
        PlutoLensInterface plutoLens = PlutoLensInterface(address(pToken.riskManager()));
        PriceOracle priceOracle = plutoLens.oracle();

        return PTokenUnderlyingPrice({
        pToken: address(pToken),
        underlyingPrice: getUnderlyingPrice(priceOracle, pToken)
        });
    }

    function getUnderlyingPrice(PriceOracle priceOracle, PToken pToken) private view returns (uint256) {
        (uint256 price, ) = priceOracle.getUnderlyingPrice(pToken);
        return price;
    }

    function pTokenUnderlyingPriceAll(PToken[] calldata pTokens) external view returns (PTokenUnderlyingPrice[] memory) {
        uint pTokenCount = pTokens.length;
        PTokenUnderlyingPrice[] memory res = new PTokenUnderlyingPrice[](pTokenCount);
        for (uint i = 0; i < pTokenCount; i++) {
            res[i] = pTokenUnderlyingPrice(pTokens[i]);
        }
        return res;
    }

    struct AccountLimits {
        PToken[] markets;
        uint liquidity;
        uint shortfall;
    }

    function getAccountLimits(PlutoLensInterface plutoLens, address account) public view returns (AccountLimits memory) {
        (uint errorCode, uint liquidity, uint shortfall) = plutoLens.getAccountLiquidity(account);
        require(errorCode == 0);

        return AccountLimits({
        markets: plutoLens.getAssetsIn(account),
        liquidity: liquidity,
        shortfall: shortfall
        });
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;
        return c;
    }
}
