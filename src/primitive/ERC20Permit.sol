// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

import { EIP712Storage } from "./EIP712.sol";
import { NonceMap } from "./Nonces.sol";

using ERC20Permit for ERC20PermitStorage global;

/// @dev ERC20 Permit storage.
struct ERC20PermitStorage {
    NonceMap nonceMap;
    EIP712Storage eip712;
}

/// @dev ERC20 Permit library.
/// @notice Modified from OpenZeppelin Contracts v5.0.0
/// [token/ERC20/extensions/ERC20Permit.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52c36d412e8681053975396223d0ea39687fe33b/contracts/token/ERC20/extensions/ERC20Permit.sol)
library ERC20Permit {
    using ShortStrings for string;

    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    );

    /// @dev Permit deadline has expired.
    error ERC2612ExpiredSignature(uint256 deadline);

    /// @dev Mismatched signature.
    error ERC2612InvalidSigner(address signer, address owner);

    /// @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting
    /// `version` to `"1"`.
    ///
    /// It's a good idea to use the same `name` that is defined as the ERC20 token name.
    function initialize(
        ERC20PermitStorage storage self,
        string memory name,
        string memory version
    )
        internal
    {
        EIP712Storage storage eip712 = self.eip712;
        eip712.name = name.toShortString();
        eip712.version = version.toShortString();
        eip712.cacheDomainSeparator();
    }

    /// @dev Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s
    /// signed approval.
    function permit(
        ERC20PermitStorage storage self,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        internal
    {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH, owner, spender, value, self.nonceMap.useNonce(owner), deadline
            )
        );

        bytes32 hash = self.eip712.hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }
    }

    /// @dev Returns the current nonce for `owner`.
    function nonces(
        ERC20PermitStorage storage self,
        address owner
    )
        internal
        view
        returns (uint256)
    {
        return self.nonceMap.nonces(owner);
    }

    /// @dev Returns the domain separator used in the encoding of the signature for {permit}, as
    /// defined by {EIP712}.
    function DOMAIN_SEPARATOR(ERC20PermitStorage storage self) internal view returns (bytes32) {
        return self.eip712.domainSeparatorV4();
    }
}
