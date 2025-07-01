// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../interfaces/IBrandMetadata.sol";

contract BrandMetadata is ERC721Holder, ERC721URIStorage, AccessControl, IBrandMetadata {
    uint256 private BRAND_ID = 1;
    mapping(address => uint256) public brandIds;

    constructor()
        ERC721("Brand Info", "Info")
    {
        // Transfer ownership ke alamat dompet Brand
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address brandWallet, string memory uri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only Admin can mint");
        _safeMint(address(this), BRAND_ID);
        _setTokenURI(BRAND_ID, uri);
        brandIds[brandWallet];
        BRAND_ID++;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}