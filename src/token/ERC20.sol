// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AllowanceMap} from "../primitive/AllowanceMap.sol";
import {BalanceMap} from "../primitive/BalanceMap.sol";

using ERC20Lib for ERC20Storage global;

struct ERC20Storage {
    BalanceMap balances;
    AllowanceMap allowances;
    uint256 totalSupply;
}

library ERC20Lib {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    function balanceOf(ERC20Storage storage self, address account) internal view returns (uint256) {
        return self.balances.get(account);
    }

    function allowance(ERC20Storage storage self, address owner, address spender) internal view returns (uint256) {
        return self.allowances.get(owner, spender);
    }

    function transfer(ERC20Storage storage self, address to, uint256 value) internal returns (bool) {
        _transfer(self, msg.sender, to, value);
        return true;
    }

    function _transfer(ERC20Storage storage self, address from, address to, uint256 value) private {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(self, from, to, value);
    }

    function _update(ERC20Storage storage self, address from, address to, uint256 value) private {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            self.totalSupply += value;
        } else {
            uint256 fromBalance = self.balances.get(from);
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                self.balances.set(from, fromBalance - value);
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                self.totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                // TODO: optimize this
                self.balances.set(to, self.balances.get(to) + value);
            }
        }

        emit Transfer(from, to, value);
    }
}
