// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract TrustGemsToken is ERC20 {
    constructor() ERC20("TrustGems Token", "TGT") {
        _mint(msg.sender, 300000000 * 10**18);
    }
}