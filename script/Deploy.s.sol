// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console2} from "forge-std/console2.sol";

import {OmniNFT} from "../src/OmniNFT.sol";

import {ScriptBase} from "./ScriptBase.sol";

contract DeployRegistry is ScriptBase {
    function run() public {
        setUp();
        bytes memory creationCode = type(OmniNFT).creationCode;
        console2.logBytes32(keccak256(creationCode));
        bytes32 salt = bytes32(
            0x0000000000000000000000000000000000000000dcfbbaa66376ca0378b91b7c
        );

        /*
        uint256 baseChainId_,
        string memory baseChainName_,
        string[] memory chains_,
        address owner,
        string memory name,
        string memory description
        */
        // testnet!
        bytes memory constructorArgs = abi.encode(
            80001,
            "Polygon",
            ["linea", "filecoin-2"],
            address(0x9444390c01Dd5b7249E53FAc31290F7dFF53450D),
            "omni test 1",
            "OMNI_TEST1"
        );

        vm.broadcast(deployer);
        IMMUTABLE_CREATE2_FACTORY.safeCreate2(
            salt,
            abi.encodePacked(creationCode, constructorArgs)
        );
    }
}
