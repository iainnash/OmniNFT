// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console2} from "forge-std/console2.sol";

import {OmniNFT} from "../src/OmniNFT.sol";

import {ScriptBase} from "./ScriptBase.sol";

contract DeployRegistry is ScriptBase {
    /// @notice gets the chains to do fork tests on, by reading environment var FORK_TEST_CHAINS.
    /// Chains are by name, and must match whats under `rpc_endpoints` in the foundry.toml
    function getDeployChains() private view returns (string[] memory result) {
        try vm.envString("DEPLOY_CHAINS", ",") returns (
            string[] memory deployChains
        ) {
            result = deployChains;
        } catch {
            console2.log(
                "could not get fork test chains - make sure the environment variable DEPLOY_CHAINS is set"
            );
            result = new string[](0);
        }
    }

    function run() public {
        setUp();

        string[] memory commands = new string[](4);
        commands[0] = "openssl";
        commands[1] = "rand";
        commands[2] = "-hex";
        commands[3] = "32";
        uint256 accountBase = uint256(keccak256(vm.ffi(commands)));
        console2.log(vm.toString(bytes32(accountBase)));
        address accountBaseAddress = vm.addr(accountBase);

        string[] memory deployChains = getDeployChains();
        uint256[] memory deployCost = vm.envUint("COST", ",");
        // require(deployChains.length == deployCost.length, "cost not match chains");
        for (uint256 i = 0; i < deployChains.length; i++) {
            vm.createSelectFork(vm.rpcUrl(deployChains[i]));
            vm.broadcast(deployer);
            // fund wallet
            accountBaseAddress.call{value: deployCost[i]}("");
            deploy(accountBase);
        }
    }

    function deploy(uint256 accountBase) internal {
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
        // bytes memory constructorArgs = abi.encode(
        //     80001,
        //     "Polygon",
        //     ["linea", "base"],
        //     address(0x9444390c01Dd5b7249E53FAc31290F7dFF53450D),
        //     "omni test 1",
        //     "OMNI_TEST1"
        // );

        string[] memory chains = new string[](3);
        chains[0] = "Polygon";
        chains[1] = "linea";
        chains[2] = "mantle";

        vm.startBroadcast(accountBase);
        OmniNFT meh = new OmniNFT(
            84531,
            "base",
            chains,
            address(0x9444390c01Dd5b7249E53FAc31290F7dFF53450D),
            "omni test 3",
            "OMNI_TEST3"
        );

        vm.stopBroadcast();
    }
}
