// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMaster {
    
    function registerBrand(
        string memory _brandName,
        string memory _nftSymbol,
        address _brandWallet,
        string memory _uri
    ) external;
    
    function approveBrand(address _brandWallet) external;

    function mintCoupon(address _to, uint amount) external;
}