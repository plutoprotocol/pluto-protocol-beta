// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.9;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PlutoToken is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Pluto Finance Token", "PLUF") {
        _mint(msg.sender, initialSupply);
    }
}
