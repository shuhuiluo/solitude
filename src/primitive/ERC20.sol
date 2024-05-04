// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { AllowanceMap } from "./AllowanceMap.sol";
import { BalanceMap } from "./BalanceMap.sol";

using ERC20Lib for ERC20Storage global;

struct ERC20Storage {
    BalanceMap balances;
    AllowanceMap allowances;
    uint256 totalSupply;
}

library ERC20Lib {
    function balanceOf(
        ERC20Storage storage self,
        address account
    )
        internal
        view
        returns (uint256)
    {
        return self.balances.get(account);
    }

    function allowance(
        ERC20Storage storage self,
        address owner,
        address spender
    )
        internal
        view
        returns (uint256)
    {
        return self.allowances.get(owner, spender);
    }

    function approve(ERC20Storage storage self, address spender, uint256 value) internal {
        approve(self, msg.sender, spender, value);
    }

    function transfer(ERC20Storage storage self, address to, uint256 value) internal {
        _transfer(self, msg.sender, to, value);
    }

    function transferFrom(
        ERC20Storage storage self,
        address from,
        address to,
        uint256 value
    )
        internal
    {
        self.spendAllowance(from, msg.sender, value);
        _transfer(self, from, to, value);
    }

    function mint(ERC20Storage storage self, address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidReceiver(address(0));
        }
        // Overflow check required: The rest of the code assumes that totalSupply never overflows
        self.totalSupply += value;
        _increaseBalance(self, account, value);
    }

    function burn(ERC20Storage storage self, address account, uint256 value) internal {
        if (account == address(0)) {
            revert IERC20Errors.ERC20InvalidSender(address(0));
        }
        unchecked {
            // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
            self.totalSupply -= value;
        }
        _deductBalance(self, account, value);
    }

    function approve(
        ERC20Storage storage self,
        address owner,
        address spender,
        uint256 value
    )
        internal
    {
        self.allowances.set(owner, spender, value);
    }

    function spendAllowance(
        ERC20Storage storage self,
        address owner,
        address spender,
        uint256 value
    )
        internal
    {
        uint256 slot = self.allowances.slot(owner, spender);
        uint256 currentAllowance;
        assembly {
            currentAllowance := sload(slot)
        }
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert IERC20Errors.ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            assembly {
                sstore(slot, sub(currentAllowance, value))
            }
        }
    }

    function _transfer(
        ERC20Storage storage self,
        address from,
        address to,
        uint256 value
    )
        private
    {
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
            // Overflow not possible: balance + value is at most totalSupply, which we know fits
            // into a uint256.
            let toBalanceBefore := sload(toSlot)
            sstore(toSlot, add(toBalanceBefore, value))
        }
    }
}
