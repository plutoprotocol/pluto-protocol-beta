// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "../tokenization/PToken.sol";

contract PEther is PToken {
    uint private msgValue;
    /**
     * @notice Construct a new PEther money market
     * @param riskManager_ The address of the RiskManager
     * @param interestRateModel_ The address of the interest rate model
     * @param initialExchangeRateMantissa_ The initial exchange rate, scaled by 1e18
     * @param admin_ Address of the administrator of this token
     */
    constructor(IRiskManager riskManager_,
                InterestRateModel interestRateModel_,
                uint initialExchangeRateMantissa_,
                string memory name_,
                address payable admin_) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;

        initialize(riskManager_, interestRateModel_, initialExchangeRateMantissa_, name_);

        // Set the proper admin now that initialization is done
        admin = admin_;
    }


    /*** User Interface ***/

    /**
     * @notice Sender supplies assets into the market and receives PTokens in exchange
     * @dev Reverts upon any failure
     */
    function mint() external payable {
        updateMsgValue(msg.value);
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /**
     * @notice Sender redeems PTokens in exchange for the underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemTokens The number of PTokens to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint redeemTokens) external payable returns (uint) {
        updateMsgValue(0);
        updateTokenPrice(address(this));
        return redeemInternal(redeemTokens);
    }

    /**
     * @notice Sender redeems PTokens in exchange for a specified amount of underlying asset
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param redeemAmount The amount of underlying to redeem
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint redeemAmount) external payable returns (uint) {
        updateMsgValue(0);
        updateTokenPrice(address(this));
        return redeemUnderlyingInternal(redeemAmount);
    }

    /**
      * @notice Sender borrows assets from the protocol to their own address
      * @param borrowAmount The amount of the underlying asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint borrowAmount) external payable returns (uint) {
        updateMsgValue(0);
        updateTokenPrice(address(this));
        return borrowInternal(borrowAmount);
    }

    /**
     * @notice Sender repays their own borrow
     * @dev Reverts upon any failure
     */
    function repayBorrow() external payable {
        updateMsgValue(msg.value);
        (uint err,) = repayBorrowInternal(msg.value);
        requireNoError(err, "repayBorrow failed");
    }

    /**
     * @notice Sender repays a borrow belonging to borrower
     * @dev Reverts upon any failure
     * @param borrower the account with the debt being payed off
     */
    function repayBorrowBehalf(address borrower) external payable {
        updateMsgValue(msg.value);
        (uint err,) = repayBorrowBehalfInternal(borrower, msg.value);
        requireNoError(err, "repayBorrowBehalf failed");
    }

    /**
     * @notice The sender liquidates the borrowers collateral.
     *  The collateral seized is transferred to the liquidator.
     * @dev Reverts upon any failure
     * @param borrower The borrower of this PToken to be liquidated
     * @param pTokenCollateral The market in which to seize collateral from the borrower
     */
    function liquidateBorrow(address borrower, PToken pTokenCollateral) external payable {
        uint256 priceCost = riskManager.getPriceCost(address(this), msg.sender);
        require(msg.value >= priceCost, "No enough value to pay price oracle.");
        (MathError mathErr, uint256 repayAmount) = subUInt(msg.value, priceCost);
        require(mathErr == MathError.NO_ERROR, "liquidateBorrow failed to subtract price cost.");
        riskManager.updateTokenPrice{value: priceCost}(address(this), msg.sender);
        updateMsgValue(repayAmount);
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, pTokenCollateral);
        requireNoError(err, "liquidateBorrow failed");
    }

    /**
     * @notice Send Ether to PEther to mint
     */
    receive() external payable {
        updateMsgValue(msg.value);
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of Ether, before this message
     * @dev This excludes the value of the current message, if any
     * @return The quantity of Ether owned by this contract
     */
    function getCashPrior() internal override view returns (uint) {
        uint localMsgValue = 0;
        if (msg.value > 0) localMsgValue = msgValue;
        (MathError err, uint startingBalance) = subUInt(address(this).balance, localMsgValue);
        require(err == MathError.NO_ERROR);
        return startingBalance;
    }

    function _addReserves(uint addAmount) external payable returns (uint) {
        updateMsgValue(msg.value);
        return _addReservesInternal(addAmount);
    }

    function isNativeToken() public pure override returns (bool) {
        return true;
    }

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the Ether
     * @param amount Amount of Ether being sent
     * @return The actual amount of Ether transferred
     */
    function doTransferIn(address from, uint amount) internal override returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value >= amount, "value mismatch");
        return amount;
    }

    function doTransferOut(address payable to, uint amount) internal override {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }

    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }

        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;

        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }

        fullMessage[i+0] = byte(uint8(32));
        fullMessage[i+1] = byte(uint8(40));
        fullMessage[i+2] = byte(uint8(48 + ( errCode / 10 )));
        fullMessage[i+3] = byte(uint8(48 + ( errCode % 10 )));
        fullMessage[i+4] = byte(uint8(41));

        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }

    function updateMsgValue(uint value) internal {
        msgValue = value;
    }
}
