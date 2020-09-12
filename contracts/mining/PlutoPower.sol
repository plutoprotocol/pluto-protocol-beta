// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlutoPower is ERC20 {
    constructor(address initialOwner, uint256 initialSupply) public ERC20("Pluto Power", "PP") {
        _mint(initialOwner, initialSupply);
    }
}
