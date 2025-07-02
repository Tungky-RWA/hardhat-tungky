// contracts/SimpleVerifier.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SimpleSignatureVerifier {
    address private _admin;

    constructor(address adminAddress) {
        _admin = adminAddress;
    }

    /**
     * @dev Memverifikasi tanda tangan sederhana.
     * @param _recipient Alamat yang dimaksud dalam pesan.
     * @param _nonce Angka unik untuk pesan ini.
     * @param _signature Tanda tangan yang dibuat oleh admin.
     * @return boolean True jika tanda tangan valid dan dibuat oleh admin.
     */
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
        return signer == _admin;
    }
}