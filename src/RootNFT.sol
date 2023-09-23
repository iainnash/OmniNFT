// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "solmate/src/tokens/ERC721.sol";


contract RootNFT is ERC721 {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
