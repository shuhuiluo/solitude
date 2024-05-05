// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

import { ERC20Storage } from "../primitive/ERC20.sol";
import { ERC20PermitStorage } from "../primitive/ERC20Permit.sol";

contract ERC20 is IERC20, IERC20Metadata, IERC20Permit {
    ERC20Storage internal _storage;
    ERC20PermitStorage internal _permitStorage;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _permitStorage.initialize(name_, "1");
    }

    /// @inheritdoc IERC20Metadata
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC20Metadata
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC20Metadata
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @inheritdoc IERC20
    function totalSupply() public view virtual returns (uint256) {
        return _storage.totalSupply;
    }

    /// @inheritdoc IERC20
    function balanceOf(address account) public view virtual returns (uint256) {
        return _storage.balanceOf(account);
    }

    /// @inheritdoc IERC20
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _storage.allowance(owner, spender);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) public virtual returns (bool) {
        _storage.approve(spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) public virtual returns (bool) {
        _storage.transfer(to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        _storage.transferFrom(from, to, value);
        return true;
    }

    /// @inheritdoc IERC20Permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        public
        virtual
    {
        _permitStorage.permit(owner, spender, value, deadline, v, r, s);
        _storage.approve(owner, spender, value);
    }

    /// @inheritdoc IERC20Permit
    function nonces(address owner) public view virtual override returns (uint256) {
        return _permitStorage.nonces(owner);
    }

    /// @inheritdoc IERC20Permit
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return _permitStorage.DOMAIN_SEPARATOR();
    }
}
