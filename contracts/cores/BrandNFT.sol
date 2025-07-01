// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "./Coupon.sol";
import "../interfaces/IBrandNFT.sol";

contract BrandNFT is ERC721URIStorage, ERC1155Holder, AccessControl, IBrandNFT {
    using Strings for uint256;
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    Coupon public immutable couponContract;

    address public signerAddress; // Alamat dompet server verifikasi Anda
    mapping(bytes32 => bool) public usedHashes; // Untuk mencegah penggunaan ulang tanda tangan

    constructor(string memory _name, string memory _symbol, address _owner, address _couponContractAddress)
        ERC721(_name, _symbol)
    {
        // Transfer ownership ke alamat dompet Brand
        couponContract = Coupon(_couponContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @dev Fungsi untuk mengklaim NFT menggunakan tanda tangan dari server.
     * @param _tokenId ID token yang akan dicetak.
     * @param _tokenURI Metadata URI untuk token tersebut.
     * @param _signature Tanda tangan digital yang didapat dari server.
     */
    function claimNFT(uint256 _tokenId, string memory _tokenURI, bytes memory _signature) external {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _tokenId));

        require(!usedHashes[messageHash], "Signature has already been used");
        
        if(!validateSignature(msg.sender, _signature)) {
            revert("invalid signature");
        }
        _safeMint(msg.sender, _tokenId);
        emit NFTClaimed(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function validateSignature(address _recipient, bytes memory _signature) public view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_recipient));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address signer = ethSignedMessageHash.recover(_signature);

        return hasRole(DEFAULT_ADMIN_ROLE, signer);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage, ERC1155Holder, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}