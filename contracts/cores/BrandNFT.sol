// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./Coupon.sol";
import "../interfaces/IBrandNFT.sol";

contract BrandNFT is ERC721URIStorage, ERC1155Holder, AccessControl, IBrandNFT {
    using Strings for uint256;

    Coupon public immutable couponContract;

    mapping(uint256 => string) preMints;

    constructor(string memory _name, string memory _symbol, address _owner, address _couponContractAddress)
        ERC721(_name, _symbol)
    {
        // Transfer ownership ke alamat dompet Brand
        couponContract = Coupon(_couponContractAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function preMint(uint256 _tokenId, string memory _uri) external {
        require(couponContract.balanceOf(address(this), 1) > 0 && bytes(preMints[_tokenId]).length == 0, "insufficient coupon or Invalid");
        couponContract.burn(address(this), 1, 1);
        preMints[_tokenId] = _uri;
    }

    function updatePreMint(uint256 _tokenId, uint256 _newTokenId, string memory _uri) external {
        if (_newTokenId > 0) {
          preMints[_newTokenId] = _uri;
          delete preMints[_tokenId];
        } else {
          preMints[_tokenId] = _uri;
        }
    }

    /**
     * @dev Fungsi untuk mengklaim NFT menggunakan tanda tangan dari server.
     * @param _tokenId ID token yang akan dicetak.
     * @param _tokenURI Metadata URI untuk token tersebut.
     * @param _signature Tanda tangan digital yang didapat dari server.
     */
    function claimNFT(uint256 _tokenId, string memory _tokenURI, bytes memory _signature) external {
        if (!isValidSignature(msg.sender, _tokenId, _signature)) {
          revert("Signature Invalid!");
        }
        
        _safeMint(msg.sender, _tokenId);
        emit NFTClaimed(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function isValidSignature(
        address _recipient,
        uint256 _nonce,
        bytes memory _signature
    ) public view returns (bool) {
        // 1. Buat hash awal dari data mentah
        bytes32 messageHash = keccak256(abi.encodePacked(_recipient, _nonce));

        // 2. Tambahkan prefix Ethereum Signed Message (INI BAGIAN UTAMANYA)
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(messageHash);

        // 3. Pulihkan alamat penandatangan dari digest dan tanda tangan
        address signer = ECDSA.recover(digest, _signature);

        // 4. Periksa apakah penandatangan adalah admin
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