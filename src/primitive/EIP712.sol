// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

using EIP712Lib for EIP712Storage global;

/**
 * @dev EIP712 storage.
 *
 * The meaning of `name` and `version` is specified in
 * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
 *
 * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
 * - `version`: the current major version of the signing domain.
 *
 */
struct EIP712Storage {
    address cachedThis;
    uint64 cachedChainId;
    bytes32 cachedDomainSeparator;
    ShortString name;
    ShortString version;
}

/// @dev EIP712 library.
/// @notice Modified from OpenZeppelin Contracts v5.0.0 [utils/cryptography/EIP712.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52c36d412e8681053975396223d0ea39687fe33b/contracts/utils/cryptography/EIP712.sol)
library EIP712Lib {
    using ShortStrings for ShortString;

    bytes32 private constant TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @dev Cache the domain separator, but also store the chain id that it corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    function cacheDomainSeparator(EIP712Storage storage self) internal {
        self.cachedThis = address(this);
        self.cachedChainId = uint64(block.chainid);
        self.cachedDomainSeparator = _buildDomainSeparator(self);
    }

    /// @dev Returns the domain separator for the current chain.
    function domainSeparatorV4(EIP712Storage storage self) internal view returns (bytes32) {
        if (address(this) == self.cachedThis && block.chainid == self.cachedChainId) {
            return self.cachedDomainSeparator;
        } else {
            return _buildDomainSeparator(self);
        }
    }

    /// @dev Returns the domain separator for the current chain.
    function _buildDomainSeparator(EIP712Storage storage self) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                TYPE_HASH,
                keccak256(bytes(self.name.toString())),
                keccak256(bytes(self.version.toString())),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @dev Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).
     *
     * The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
     * `\x19\x01` and hashing the result. It corresponds to the hash signed by the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.
     *
     * See {ECDSA-recover}.
     */
    function toTypedDataHash(
        bytes32 domainSeparator,
        bytes32 structHash
    )
        internal
        pure
        returns (bytes32 digest)
    {
        assembly ("memory-safe") {
            mstore(0, hex"1901")
            mstore(0x02, domainSeparator)
            mstore(0x22, structHash)
            digest := keccak256(0, 0x42)
            mstore(0x22, 0)
        }
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function hashTypedDataV4(
        EIP712Storage storage self,
        bytes32 structHash
    )
        internal
        view
        returns (bytes32)
    {
        return toTypedDataHash(self.domainSeparatorV4(), structHash);
    }

    /// @dev See {IERC-5267}.
    function eip712Domain(EIP712Storage storage self)
        internal
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            self.name.toString(),
            self.version.toString(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}
