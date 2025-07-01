// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IContractFactory {
    event BrandRegistered(
        address indexed brandWallet,
        address indexed nftContractAddress,
        string name,
        bool isLegalVerified
    ); // brand approved
    
    event BrandStatusUpdated(address indexed brandWallet, bool newStatus);

    struct BrandInfo {
        address brandWallet;
        address nftContractAddress;
        string name;
        string nftSymbol;
        bool isActive;
        bool isLegalVerified;
        uint256 registrationTimestamp;
    }

    function registerBrand(string memory _brandName, string memory _nftSymbol, address _brandWallet) external;

    function approveBrand(address _brandWallet, address couponContract) external returns (address);

    function getBrandNFTContractAddress(address _brandWallet) external view returns (address);

    function getBrandInfo(address _brandWallet) external view returns (BrandInfo memory); 

}