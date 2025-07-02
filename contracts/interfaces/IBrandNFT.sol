// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IBrandNFT {

    event NFTClaimed(address indexed claimer, uint256 indexed tokenId);
    
    function claimNFT(uint256 _tokenId, string memory _tokenURI, bytes memory _signature) external;
}