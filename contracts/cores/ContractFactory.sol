// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./BrandNFT.sol";
import "./Coupon.sol";
import "./BrandMetadata.sol";

import "../interfaces/IContractFactory.sol";

// Kontrak utama platform yang akan mendeploy kontrak NFT untuk setiap brand
contract ContractFactory is AccessControl, IContractFactory {

    mapping(address => BrandInfo) public brands;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Fungsi untuk mendaftarkan Brand baru
    // Hanya admin platform yang bisa memanggil fungsi ini
    function registerBrand(string memory _brandName, string memory _nftSymbol, address _brandWallet) external {
        require(brands[_brandWallet].nftContractAddress == address(0), "Brand already registered");

        brands[_brandWallet] = BrandInfo({
            brandWallet: _brandWallet,
            nftContractAddress: address(0),
            name: _brandName,
            isActive: false,
            isLegalVerified: false,
            registrationTimestamp: block.timestamp,
            nftSymbol: _nftSymbol
        });

        emit BrandRegistered(_brandWallet, address(0), _brandName, false);
    }

    // Fungsi baru untuk memperbarui status verifikasi legalitas Brand
    // Hanya admin platform yang bisa memanggil fungsi ini
    function approveBrand(address _brandWallet, address couponContract) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        require(brands[_brandWallet].nftContractAddress == address(0) || brands[_brandWallet].isLegalVerified == false, "No change in legal status or NFT contract already deployed.");

        brands[_brandWallet].isLegalVerified = true;
        // emit BrandLegalStatusUpdated(_brandWallet, true);

        // Jika legalitas sudah terverifikasi dan kontrak NFT belum dideploy, deploy sekarang
        string memory brandName = brands[_brandWallet].name;
        string memory nftSymbol = brands[_brandWallet].nftSymbol; // Kamu mungkin perlu menyimpan simbol ini juga saat registerBrand

        // Deploy kontrak BrandNFT baru dan transfer ownership ke _brandWallet
        BrandNFT newBrandNFT = new BrandNFT(brandName, nftSymbol, _brandWallet, couponContract);
        brands[_brandWallet].nftContractAddress = address(newBrandNFT);
        brands[_brandWallet].isActive = true; // Aktifkan brand setelah kontrak NFT dideploy

        emit BrandRegistered(_brandWallet, address(newBrandNFT), brandName, true); // Emit ulang dengan informasi lengkap
        return address(newBrandNFT);
    }

    // Fungsi untuk mendapatkan alamat kontrak NFT dari Brand tertentu
    // Tambahkan require untuk memastikan legalitas sudah terverifikasi
    function getBrandNFTContractAddress(address _brandWallet) external view returns (address) {
        return brands[_brandWallet].nftContractAddress;
    }

    // Fungsi tambahan untuk mendapatkan detail Brand (bisa tambahkan lebih banyak info jika perlu)
    function getBrandInfo(address _brandWallet) external view returns (BrandInfo memory) {
        return brands[_brandWallet];
    }
}