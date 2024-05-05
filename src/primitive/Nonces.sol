/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

using Nonces for NonceMap global;

/// @dev A map of nonces for each account.
struct NonceMap {
    mapping(address account => uint256) inner;
}

/// @dev Provides tracking nonces for addresses. Nonces will only increment.
/// @notice Modified from OpenZeppelin Contracts v5.0.0
/// [utils/Nonces.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/52c36d412e8681053975396223d0ea39687fe33b/contracts/utils/Nonces.sol).
library Nonces {
    /// @dev The nonce used for an `account` is not the expected current nonce.
    error InvalidAccountNonce(address account, uint256 currentNonce);

    function slot(NonceMap storage self, address owner) private pure returns (uint256 _slot) {
        assembly ("memory-safe") {
            mstore(0, owner)
            mstore(0x20, self.slot)
            _slot := keccak256(0, 0x40)
        }
    }

    /// @dev Returns the next unused nonce for an address.
    function nonces(NonceMap storage self, address owner) internal view returns (uint256 nonce) {
        uint256 _slot = slot(self, owner);
        assembly ("memory-safe") {
            nonce := sload(_slot)
        }
    }

    /// @dev Consumes a nonce.
    function useNonce(NonceMap storage self, address owner) internal returns (uint256 nonce) {
        uint256 _slot = slot(self, owner);
        // For each account, the nonce has an initial value of 0, can only be incremented by one,
        // and cannot be decremented or reset. This guarantees that the nonce never overflows.
        assembly ("memory-safe") {
            nonce := sload(_slot)
            sstore(_slot, add(nonce, 1))
        }
    }

    /// @dev Same as {useNonce} but checking that `nonce` is the next valid for `owner`.
    function useCheckedNonce(NonceMap storage self, address owner, uint256 nonce) internal {
        uint256 current = self.useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}
