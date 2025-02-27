// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@solmate/tokens/ERC20.sol";


contract YesToken is ERC20("Yes", "YES", 18) {
    constructor() { _mint(msg.sender, 100_000e18); }
}