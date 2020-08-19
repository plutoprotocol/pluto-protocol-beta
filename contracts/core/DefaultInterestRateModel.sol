// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;

import "./InterestRateModel.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract DefaultInterestRateModel is InterestRateModel {
    using SafeMath for uint256;

    event NewInterestParams(uint256 baseRatePerBlock, uint256 multiplierPerBlock);

    /**
     * @notice 该利率模型所使用的每年区块数，按 每 15 秒出一个块，每年 365 天来计算
     * blocksPerYear = (60/15) * 60 * 24 * 365
     */
    uint256 public constant blocksPerYear = 2102400;

    /**
     * @notice 资金利用率乘数因子，基于此可以得到利率曲线
     */
    uint256 public multiplierPerBlock;

    /**
     * @notice 基础年化利率，可看作利率函数在 y 轴的截距
     */
    uint256 public baseRatePerBlock;

    /**
     * @notice 构造一个利率模型
     * @param baseRatePerYear 年化基础利率
     * @param multiplierPerYear 加给利率
     */
    constructor(uint256 baseRatePerYear, uint256 multiplierPerYear) public {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }

    /**
     * @notice 计算当前市场的资金使用率: `borrows / (cash + borrows - reserves)`
     * @param cash 当前市场中的现金
     * @param borrows 当前市场已借出总金额
     * @param reserves 市场中未使用储备金
     * @return 资金使用率，范围在 [0, 1e18]
     */
    function utilizationRate(uint256 cash, uint256 borrows, uint256 reserves) public pure returns (uint256) {
        // 无借款时资金使用率为 0
        if (borrows == 0) {
            return 0;
        }

        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }

    /**
     * @notice 计算区块借款利率 = baseRatePerBlock + utilizationRate * multiplierPerBlock
     * @param cash 该市场的现金量
     * @param borrows 该市场已出借金额
     * @param reserves 该市场备付金
     * @return 借款利率
     */
    function getBorrowRate(uint256 cash, uint256 borrows, uint256 reserves) public view override returns (uint256) {
        uint256 ur = utilizationRate(cash, borrows, reserves);
        return ur.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
    }

    /**
     * @notice 计算当前区块出借利率 = utilizationRate * BorrowRate * （1 - reserveFactor）
     * @param cash 该市场现金量
     * @param borrows 该市场出借量
     * @param reserves 市场备付金
     * @param reserveFactorMantissa 备付金比例
     * @return 当前区块出借利率
     */
    function getSupplyRate(uint256 cash, uint256 borrows, uint256 reserves, uint256 reserveFactorMantissa) public view override returns (uint256) {
        uint256 oneMinusReserveFactor = uint256(1e18).sub(reserveFactorMantissa);
        uint256 borrowRate = getBorrowRate(cash, borrows, reserves);
        uint256 rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}
