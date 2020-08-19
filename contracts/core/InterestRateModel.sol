// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;


abstract contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    /**
     * @notice 计算区块借款利率
     * @param cash 该市场的现金量
     * @param borrows 该市场已出借金额
     * @param reserves 该市场备付金
     * @return 借款利率
     */
    function getBorrowRate(uint cash, uint borrows, uint reserves) external virtual view returns (uint);

    /**
     * @notice 计算当前区块出借利率 = utilizationRate * BorrowRate * （1 - reserveFactor）
     * @param cash 该市场现金量
     * @param borrows 该市场出借量
     * @param reserves 市场备付金
     * @param reserveFactorMantissa 备付金比例
     * @return 当前区块出借利率
     */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) external virtual view returns (uint);

}
