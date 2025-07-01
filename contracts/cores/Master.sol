// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./ContractFactory.sol";
import "./Coupon.sol";
import "./BrandMetadata.sol";

import "../interfaces/IMaster.sol";

// Kontrak utama platform yang akan mendeploy kontrak NFT untuk setiap brand
contract Master is Ownable, AccessControl, IMaster {
    Coupon private coupon;
    BrandMetadata private brandMetadata;
    ContractFactory private contractFactory;

    address private couponAddress;

    constructor(address _couponAddress, address _brandMetadataAddress, address _contractFactoryAddress) Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        coupon = Coupon(_couponAddress);
        brandMetadata = BrandMetadata(_brandMetadataAddress);
        contractFactory = ContractFactory(_contractFactoryAddress);
        couponAddress = _couponAddress;
    }

    function registerBrand(string memory _brandName, string memory _nftSymbol, address _brandWallet, string memory _uri) external {
        contractFactory.registerBrand(_brandName, _nftSymbol, _brandWallet);
        brandMetadata.mint(_brandWallet, _uri);
    }
    
    function approveBrand(address _brandWallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
         // Menjalankan token factory untuk membuat NFT yang baru dari kode ini.
        address brandSC = contractFactory.approveBrand(_brandWallet, couponAddress);
        coupon.mintCoupon(brandSC, 30);
        coupon.grantRole(DEFAULT_ADMIN_ROLE, brandSC);
    }

    function mintCoupon(address _to, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        coupon.mintCoupon(_to, amount);
    }
}