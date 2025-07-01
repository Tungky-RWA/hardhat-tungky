// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBrandMetadata {
    function mint(address brandWallet, string memory uri) external;
}