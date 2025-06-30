// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./BrandNFT.sol"; // Import BrandNFT kontrak yang akan dideploy

// Kontrak utama platform yang akan mendeploy kontrak NFT untuk setiap brand
contract ContractFactory is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    modifier onlyAdminRole {
      require(hasRole(ADMIN_ROLE, msg.sender), "Only Admin role can call this function");
      _;
    }

    // Struktur untuk menyimpan informasi setiap brand yang terdaftar
    struct BrandInfo {
        address brandWallet;
        address nftContractAddress;
        string name;
        string nftSymbol;
        bool isActive;
        bool isLegalVerified; // <-- Tambahan: Status verifikasi legalitas
        uint256 registrationTimestamp; // <-- Tambahan: Waktu pendaftaran
    }

    mapping(address => BrandInfo) public brands;
    address[] public registeredBrands; // Array untuk menyimpan semua alamat dompet Brand yang terdaftar

    event BrandRegistered(address indexed brandWallet, address indexed nftContractAddress, string name, bool isLegalVerified); // Update event
    event BrandStatusUpdated(address indexed brandWallet, bool newStatus);
    event BrandLegalStatusUpdated(address indexed brandWallet, bool newLegalStatus); // <-- Tambahan: Event untuk update status legal

    constructor() Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Fungsi untuk mendaftarkan Brand baru
    // Hanya admin platform yang bisa memanggil fungsi ini
    function registerBrand(string memory _brandName, string memory _nftSymbol, address _brandWallet) public {
        require(_brandWallet != address(0), "Invalid brand wallet address");
        require(brands[_brandWallet].nftContractAddress == address(0), "Brand already registered");

        // Pada tahap pendaftaran awal, asumsikan belum terverifikasi secara legal.
        // Verifikasi legalitas akan dilakukan secara off-chain dan diupdate kemudian.
        brands[_brandWallet] = BrandInfo({
            brandWallet: _brandWallet,
            nftContractAddress: address(0), // Belum ada kontrak NFT yang dideploy sampai legalitas terverifikasi
            name: _brandName,
            isActive: false, // Belum aktif sampai legalitas terverifikasi
            isLegalVerified: false, // Awalnya false
            registrationTimestamp: block.timestamp, // Catat waktu pendaftaran
            nftSymbol: _nftSymbol
        });

        registeredBrands.push(_brandWallet);
        emit BrandRegistered(_brandWallet, address(0), _brandName, false); // Emit dengan status awal
    }

    // Fungsi baru untuk memperbarui status verifikasi legalitas Brand
    // Hanya admin platform yang bisa memanggil fungsi ini
    function updateBrandLegalStatus(address _brandWallet, bool _isLegalVerified) public onlyAdminRole {
        require(brands[_brandWallet].nftContractAddress == address(0) || brands[_brandWallet].isLegalVerified != _isLegalVerified, "No change in legal status or NFT contract already deployed.");
        require(brands[_brandWallet].brandWallet != address(0), "Brand not registered."); // Pastikan brand terdaftar

        brands[_brandWallet].isLegalVerified = _isLegalVerified;
        emit BrandLegalStatusUpdated(_brandWallet, _isLegalVerified);

        // Jika legalitas sudah terverifikasi dan kontrak NFT belum dideploy, deploy sekarang
        if (_isLegalVerified && brands[_brandWallet].nftContractAddress == address(0)) {
            // Dapatkan nama dan simbol dari data brand yang sudah tersimpan
            string memory brandName = brands[_brandWallet].name;
            string memory nftSymbol = brands[_brandWallet].nftSymbol; // Kamu mungkin perlu menyimpan simbol ini juga saat registerBrand

            // Deploy kontrak BrandNFT baru dan transfer ownership ke _brandWallet
            BrandNFT newBrandNFT = new BrandNFT(brandName, nftSymbol, _brandWallet);
            brands[_brandWallet].nftContractAddress = address(newBrandNFT);
            brands[_brandWallet].isActive = true; // Aktifkan brand setelah kontrak NFT dideploy

            emit BrandRegistered(_brandWallet, address(newBrandNFT), brandName, true); // Emit ulang dengan informasi lengkap
        }
    }


    // Fungsi untuk mendapatkan alamat kontrak NFT dari Brand tertentu
    // Tambahkan require untuk memastikan legalitas sudah terverifikasi
    function getBrandNFTContractAddress(address _brandWallet) public view returns (address) {
        require(brands[_brandWallet].brandWallet != address(0), "Brand not registered.");
        require(brands[_brandWallet].isLegalVerified, "Brand not legally verified yet."); // <-- Pastikan sudah terverifikasi
        return brands[_brandWallet].nftContractAddress;
    }

    // Fungsi untuk mengupdate status aktif Brand (misalnya, menonaktifkan jika ada masalah)
    // Hanya admin platform yang bisa memanggil fungsi ini
    function updateBrandStatus(address _brandWallet, bool _isActive) public onlyAdminRole {
        require(brands[_brandWallet].brandWallet != address(0), "Brand not registered");
        require(brands[_brandWallet].isLegalVerified, "Cannot change status of unverified brand."); // <-- Tambahan: hanya brand terverifikasi yang bisa diubah statusnya
        brands[_brandWallet].isActive = _isActive;
        emit BrandStatusUpdated(_brandWallet, _isActive);
    }

    function getTotalRegisteredBrands() public view returns (uint256) {
        return registeredBrands.length;
    }

    // Fungsi tambahan untuk mendapatkan detail Brand (bisa tambahkan lebih banyak info jika perlu)
    function getBrandInfo(address _brandWallet) public view returns (BrandInfo memory) {
        return brands[_brandWallet];
    }
}