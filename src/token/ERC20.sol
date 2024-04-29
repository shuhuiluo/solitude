// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

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
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    function balanceOf(ERC20Storage storage self, address account) internal view returns (uint256) {
        return self.balances.get(account);
    }

    function allowance(ERC20Storage storage self, address owner, address spender) internal view returns (uint256) {
        return self.allowances.get(owner, spender);
    }

    function transfer(ERC20Storage storage self, address to, uint256 value) internal {
        _transfer(self, msg.sender, to, value);
    }

    function _transfer(ERC20Storage storage self, address from, address to, uint256 value) private {
        _update(self, from, to, value);
    }

    function _update(ERC20Storage storage self, address from, address to, uint256 value) private {
        _deductBalance(self, from, value);
        _increaseBalance(self, to, value);
    }

    function _deductBalance(ERC20Storage storage self, address from, uint256 value) private {
        uint256 fromSlot = self.balances.slot(from);
        uint256 fromBalance;
        assembly {
            fromBalance := sload(fromSlot)
        }
        if (fromBalance < value) {
            revert IERC20Errors.ERC20InsufficientBalance(from, fromBalance, value);
        }
        assembly {
            // Overflow not possible: value <= fromBalance <= totalSupply.
            sstore(fromSlot, sub(fromBalance, value))
        }
    }

    function _increaseBalance(ERC20Storage storage self, address to, uint256 value) private {
        uint256 toSlot = self.balances.slot(to);
        assembly {
            // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
            let toBalanceBefore := sload(toSlot)
            sstore(toSlot, add(toBalanceBefore, value))
        }
    }

    function _mint(ERC20Storage storage self, address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        // Overflow check required: The rest of the code assumes that totalSupply never overflows
        self.totalSupply += value;
        _increaseBalance(self, account, value);
    }

    function _burn(ERC20Storage storage self, address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        unchecked {
            // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
            self.totalSupply -= value;
        }
        _deductBalance(self, account, value);
    }
}
