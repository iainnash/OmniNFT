// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AxelarExecutableStatic} from "./AxelarExecutableStatic.sol";

contract OmniNFT is ERC721, AxelarExecutableStatic, Ownable {
    uint256 public immutable baseChainId;
    IAxelarGasService public gasService;
    mapping(uint256 => string) public uris;
    uint256 public nextTokenId = 1;
    string[] public chains;
    string public baseChainName;

    constructor(
        uint256 baseChainId_,
        string memory baseChainName_,
        string[] memory chains_,
        address owner,
        string memory name,
        string memory description
    ) ERC721(name, description) {
        _transferOwnership(owner);
        chains = chains_;
        baseChainId = baseChainId_;
        baseChainName = baseChainName_;
        uint256 currentChainId = chainid();
        // base
        if (currentChainId == 84531) {
            _setupAxelar(
                0xe432150cce91c13a887f7D836923d5597adD8E31,
                0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
            );
        }
        // polygon mumbai
        if (currentChainId == 80001) {
            _setupAxelar(
                0xBF62ef1486468a6bd26Dd669C06db43dEd5B849B,
                0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
            );
        }
        // linea
        if (currentChainId == 59140) {
            _setupAxelar(
                0xe432150cce91c13a887f7D836923d5597adD8E31,
                0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
            );
        }
        // filecoin calibration
        if (currentChainId == 314159) {
            _setupAxelar(
                0x999117D44220F33e0441fbAb2A5aDB8FF485c54D,
                0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6
            );
        }
        // mantle
        if (currentChainId == 5001) {
            _setupAxelar(0xe432150cce91c13a887f7D836923d5597adD8E31, 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6);
        }
    }

    function _setupAxelar(address gateway_, address gasService_) internal {
        _setGateway(gateway_);
        gasService = IAxelarGasService(gasService_);
    }

    function _broadcastMessage(bytes memory message) internal {
        uint256 actionBalance = address(this).balance / chains.length;
        for (uint256 i = 0; i < chains.length; i++) {
            if (actionBalance > 0) {
                gasService.payNativeGasForContractCall{value: actionBalance}(
                    address(this),
                    chains[i],
                    Strings.toHexString(address(this)),
                    message,
                    address(this)
                );
            }
            gateway.callContract(
                chains[i],
                Strings.toHexString(address(this)),
                message
            );
        }
    }

    function _sendMessage(bytes memory message) internal {
        if (chainid() == baseChainId) {
            _broadcastMessage(message);
        } else {
            if (address(this).balance > 0) {
                gasService.payNativeGasForContractCall{
                    value: address(this).balance
                }(
                    address(this),
                    baseChainName,
                    Strings.toHexString(address(this)),
                    message,
                    address(this)
                );
            }
            gateway.callContract(
                baseChainName,
                Strings.toHexString(address(this)),
                message
            );
        }
    }

    function _executeMessage(bytes calldata payload_) internal {
        if (bytes4(payload_[0:4]) == this.transferFrom.selector) {
            (address from, address to, uint256 tokenId) = abi.decode(
                payload_[4:],
                (address, address, uint256)
            );
            _transfer(from, to, tokenId);
        } else if (bytes4(payload_[0:4]) == this.mint.selector) {
            (address dest, string memory uri) = abi.decode(
                payload_[4:],
                (address, string)
            );
            uris[nextTokenId] = uri;
            _mint(dest, nextTokenId);
            nextTokenId++;
        }
    }

    // Handles calls created by setAndSend. Updates this contract's value
    function _execute(
        string calldata _sourceChain_,
        string calldata _sourceAddress_,
        bytes calldata payload_
    ) internal override {
        _executeMessage(payload_);
        // sourceChain = sourceChain_;
        // sourceAddress = sourceAddress_;
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        if (bytes(uris[id]).length == 0) {
            revert("NO TOKEN");
        }
        return uris[id];
    }

    function mint(address dest, string memory uri) public {
        _sendMessage(abi.encodeWithSelector(this.mint.selector, dest, uri));
        if (chainid() == baseChainId) {
            uris[nextTokenId] = uri;
            _mint(dest, nextTokenId);
            nextTokenId++;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transferFrom(from, to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved or owner"
        );
        _sendMessage(
            abi.encodeWithSelector(
                this.transferFrom.selector,
                from,
                to,
                tokenId
            )
        );
        if (chainid() == baseChainId) {
            _transfer(from, to, tokenId);
        }
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
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        _transferFrom(from, to, tokenId);
        // todo
        // _checkOnERC721Received(from, to, tokenId, data);
    }

    event HasValue(address indexed sender, uint256 value);

    receive() external payable {
        emit HasValue(msg.sender, msg.value);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = address(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send value");
    }

    function chainid() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }
}
