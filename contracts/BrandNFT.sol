// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract BrandNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    event NFTMinted(address indexed owner, uint256 indexed tokenId, string tokenURI);

    constructor(string memory _name, string memory _symbol, address _owner)
        ERC721(_name, _symbol)
        Ownable(msg.sender)
    {
        // Transfer ownership ke alamat dompet Brand
        transferOwnership(_owner);
    }

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _safeMint(_to, _tokenId);
        emit NFTMinted(_to, _tokenId, _tokenURI);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}