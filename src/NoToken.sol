// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@solmate/tokens/ERC20.sol";


contract NoToken is ERC20("No", "NO", 18) {
    constructor() { _mint(msg.sender, 100_000e18); }
}