// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

contract OmniNFT is ERC721Upgradeable, AxelarExecutable {
    uint256 public immutable baseChainId;
    IAxelarGasService public immutable gasService;
    mapping(uint256 => string) public uris;
    uint256 public nextTokenId = 1;
    string[] public _chains;
    string public baseChainName;

    constructor(
        uint256 baseChainId_,
        string calldata baseChainName_,
        address gateway_,
        address gasService_
    ) AxelarExecutable(gateway_) {
        baseChainId = baseChainId_;
        gasService = IAxelarGasService(gasService_);
        baseChainName = baseChainName_;
    }

    function initialize(
        string[] calldata chains,
        string name,
        string description
    ) public initializer {
        __ERC721_init(name, description);
        _chains = chains;
    }

    function _broadcastMessage(bytes memory message) internal {
        for (uint256 i = 0; i < chains.length; i++) {
            if (address(this).value > 0) {
                gasService.payNativeGasForContractCall{
                    value: address(this).value
                }(address(this), chains[i], address(this), message, msg.sender);
            }
            gateway.callContract(chains[i], address(this), message);
        }
    }

    function _sendMessage(bytes memory message) internal {
        if (chainid() == baseChainId) {
            _broadcastMessage(message);
        } else {
            if (address(this).value > 0) {
                gasService.payNativeGasForContractCall{
                    value: address(this).value
                }(
                    address(this),
                    baseChainName,
                    address(this),
                    message,
                    msg.sender
                );
            }
            gateway.callContract(baseChainName, address(this), message);
        }
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata _sourceChain_,
        string calldata _sourceAddress_,
        bytes calldata payload_
    ) internal override {
        bytes4 message = payload_[0:4];
        if (message == transferFrom.selector) {
            (address from, address to, uint256 tokenId) = abi.decode(
                (address, address, uint256)
            );
            _transferFrom(from, to, tokenId);
        } else if (message == mint.selector) {
            (address dest, string uri) = abi.decode((address, string));
            uris[nextTokenId] = uri;
            _mint(nextTokenId, dest);
            nextTokenId++;
        }
        // sourceChain = sourceChain_;
        // sourceAddress = sourceAddress_;
    }

    function mint(address dest, string memory uri) {
        _sendMessage(abi.encodeWithSelector(mint.selector, dest, uri));
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        if (chainid() == baseChainId) {
            super.transferFrom(from, to, tokenId);
        }
        _sendMessage(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                from,
                to,
                tokenId
            )
        );
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        revert("NOT_SUPPORTED");
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert("NOT_SUPPORTED");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        _transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    event HasValue(address indexed sender, uint256 value);

    receive() external {
        emit HasValue(msg.sender, msg.value);
    }
}
