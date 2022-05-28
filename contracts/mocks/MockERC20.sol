//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

    uint8 decimalsOverride;

    constructor(
        string memory name_, 
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        decimalsOverride = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimalsOverride;
    }

    function mint(address to, uint amount) public {
        _mint(to, amount);
    }
}
