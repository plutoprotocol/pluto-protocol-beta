// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.9;

import "../oracle/INestQuery.sol";

contract MockNestQuery is INestQuery {
    mapping(address => bool) public activated;
    uint256 singleFee = 0.01 ether;

    function activate(address defi) external override {
        require(address(msg.sender) == address(tx.origin), "Contract is not allowed!");

        activated[defi] = true;
    }

    function params() external override view returns(uint256 single, uint64 leadTime, uint256 nestAmount) {
        single = singleFee;
        leadTime;
        nestAmount;
    }

    /// @notice The main function called by DeFi clients, compatible to Nest Protocol v3.0
    /// @dev  The payback address is ZERO, so the changes are kept in this contract
    ///         The ABI keeps consist with Nest v3.0
    /// @param tokenAddress The address of token contract address
    /// @return ethAmount The amount of ETH in price pair (ETH, ERC20)
    /// @return erc20Amount The amount of ERC20 in price pair (ETH, ERC20)
    /// @return blockNum The block.number where the price is being in effect
    function updateAndCheckPriceNow(address tokenAddress) external payable override returns (uint256, uint256, uint256) {
        require(msg.value >= singleFee, "No enough oracle cost paid.");
        require(activated[msg.sender], "Need to activate it before using.");

        tokenAddress;
        return (10e18, 8000 * 1e6, block.number);
    }

    /// @notice A view function returning the latestPrice
    /// @param token  The address of the token contract
    function latestPrice(address token) external override view returns (uint256 ethAmount, uint256 tokenAmount, uint128 avgPrice, int128 vola, uint256 bn) {
        require(address(msg.sender) == address(tx.origin), "Contract is not allowed!");

        token;
        return (10e18, 9000 * 1e6, 0, 0, block.number);
    }
}