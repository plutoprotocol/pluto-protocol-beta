// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../tokenization/PToken.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PErc20 is PToken, IPErc20 {
    using SafeERC20 for IERC20;
    /**
     * @notice Initialize the new money market
     * @param underlying_ The address of the underlying asset
     * @param riskManager_ The address of the RiskManager
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     */
    constructor(address underlying_,
                        IRiskManager riskManager_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        address payable admin_) public {
        admin = msg.sender;

        // pToken initialize does the bulk of the work
        super.initialize(riskManager_, interestRateModel_, initialExchangeRateMantissa_);

        // Set underlying and sanity check it
        underlying = underlying_;
        IERC20(underlying).totalSupply();

        admin = admin_;
    }

    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives pTokens in exchange
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount The amount of the underlying asset to supply
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function mint(uint mintAmount) external override returns (uint) {
        (uint err,) = mintInternal(mintAmount);
        return err;
    }

    /**
     * @notice Sender redeems pTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of pTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external payable override returns (uint) {
        updateTokenPrice();
        return redeemInternal(redeemTokens);
    }

    /**
     * @notice Sender redeems pTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external payable override returns (uint) {
        updateTokenPrice();
        return redeemUnderlyingInternal(redeemAmount);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external payable override returns (uint) {
        updateTokenPrice();
        return borrowInternal(borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrow(uint repayAmount) external override returns (uint) {
        (uint err,) = repayBorrowInternal(repayAmount);
        return err;
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @param borrower the account with the debt being payed off
     * @param repayAmount The amount to repay
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function repayBorrowBehalf(address borrower, uint repayAmount) external override returns (uint) {
        (uint err,) = repayBorrowBehalfInternal(borrower, repayAmount);
            return err;
        }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @param borrower The borrower of this pToken to be liquidated
     * @param repayAmount The amount of the underlying borrowed asset to repay
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function liquidateBorrow(address borrower, uint repayAmount, IPToken pTokenCollateral) external payable override returns (uint) {
        updateTokenPrice();
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, pTokenCollateral);
        return err;
    }

    /**
     * @notice The sender adds to reserves.
     * @param addAmount The amount fo underlying token to add as reserves
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _addReserves(uint addAmount) external override returns (uint) {
        return _addReservesInternal(addAmount);
    }

    function isNativeToken() public pure override returns (bool) {
        return false;
    }
    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of the underlying
     * @dev This excludes the value of the current message, if any
     * @return The quantity of underlying tokens owned by this contract
     */
    function getCashPrior() internal view override returns (uint) {
        IERC20 token = IERC20(underlying);
        return token.balanceOf(address(this));
    }

    function doTransferIn(address from, uint amount) internal override returns (uint) {
        IERC20 token = IERC20(underlying);
        uint balanceBefore = IERC20(underlying).balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = IERC20(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }

    function doTransferOut(address payable to, uint amount) internal override {
        IERC20 token = IERC20(underlying);
        token.safeTransfer(to, amount);
    }
}
