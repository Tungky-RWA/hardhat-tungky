// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol"; // Tetap sama, tidak ada versi upgradeable
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Coupon.sol";

contract BrandNFT is Initializable, ERC721URIStorageUpgradeable, ERC1155HolderUpgradeable, AccessControlUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    Coupon public couponContract;

    mapping(uint256 => string) public preMints;

    event BrandNFTInitialized(address indexed owner, address contractAddress);
    event PreMintedNFT(address indexed smartContractWallet, uint256 indexed tokenId, string uri);
    event PreMintNFTUpdated(
        uint256 indexed oldTokenId,
        uint256 indexed newTokenId,
        string newUri
    );

    constructor() {
        // 3. Constructor HARUS dikosongkan untuk pola proxy/clone
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _owner,
        address _minter,
        address _couponContractAddress
    ) public initializer {
        __ERC721_init_unchained(_name, _symbol);
        __AccessControl_init_unchained();
        __ERC721URIStorage_init_unchained();

        // Pindahkan sisa logika dari constructor lama ke sini
        couponContract = Coupon(_couponContractAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _minter);

        emit BrandNFTInitialized(_owner, address(this));
    }

    function preMint(uint256 _tokenId, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(couponContract.balanceOf(address(this), 1) > 0 && bytes(preMints[_tokenId]).length == 0, "insufficient coupon or Invalid");
        require(_ownerOf(_tokenId) == address(0), "NFT is already exist!");
        couponContract.burn(address(this), 1, 1);
        preMints[_tokenId] = _uri;

        emit PreMintedNFT(address(this), _tokenId, _uri);
    }

    function updatePreMint(uint256 _tokenId, uint256 _newTokenId, string memory _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        string memory uri = preMints[_tokenId];
        require(bytes(uri).length > 0, "NFT not preminted or already claimed");
        if (_newTokenId > 0 && _newTokenId != _tokenId) {
          preMints[_newTokenId] = _uri;
          delete preMints[_tokenId];
          emit PreMintNFTUpdated(_tokenId, _newTokenId, _uri);
        } else {
          preMints[_tokenId] = _uri;
          emit PreMintNFTUpdated(_tokenId, _tokenId, _uri);
        }
    }

    function claimNFT(address _to, uint256 _tokenId) onlyRole(MINTER_ROLE) external {
        string memory uri = preMints[_tokenId];
        require(bytes(uri).length > 0, "NFT not preminted or already claimed");

        delete preMints[_tokenId];
        
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorageUpgradeable, ERC1155HolderUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}