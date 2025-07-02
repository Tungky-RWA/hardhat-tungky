// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./BrandNFT.sol";
import "./Coupon.sol";
import "./BrandMetadata.sol";

import "../interfaces/IContractFactory.sol";

// Kontrak utama platform yang akan mendeploy kontrak NFT untuk setiap brand
contract ContractFactory is AccessControl, IContractFactory {
    address public immutable brandNFTImplementation;

    mapping(address => BrandInfo) public brands;

    constructor(address _implementationAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        brandNFTImplementation = _implementationAddress;
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
    function approveBrand(address _brandWallet, address _minterWallet, address couponContract) external onlyRole(DEFAULT_ADMIN_ROLE) returns (address) {
        require(brands[_brandWallet].nftContractAddress == address(0) || brands[_brandWallet].isLegalVerified == false, "No change in legal status or NFT contract already deployed.");

        brands[_brandWallet].isLegalVerified = true;

        // Deploy kontrak BrandNFT baru dan transfer ownership ke _brandWallet
        bytes memory initData = abi.encodeCall(
            BrandNFT.initialize,
            (brands[_brandWallet].name, brands[_brandWallet].nftSymbol, _brandWallet, _minterWallet, couponContract)
        );

        ERC1967Proxy newProxy = new ERC1967Proxy(
            brandNFTImplementation,
            initData
        );

        address newBrandNFTAddress = address(newProxy);
        // BrandNFT newBrandNFT = new BrandNFT(brands[_brandWallet].name, brands[_brandWallet].nftSymbol, _brandWallet, _minterWallet, couponContract);
        brands[_brandWallet].nftContractAddress = address(newBrandNFTAddress);
        brands[_brandWallet].isActive = true; // Aktifkan brand setelah kontrak NFT dideploy

        emit BrandRegistered(_brandWallet, address(newBrandNFTAddress), brands[_brandWallet].name, true); // Emit ulang dengan informasi lengkap
        return address(newBrandNFTAddress);
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