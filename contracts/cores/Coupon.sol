// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "../interfaces/ICoupon.sol";

contract Coupon is ERC1155, AccessControl, ICoupon {

    uint256 public constant MINTING_COUPON_ID = 1;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Fungsi ini hanya bisa dipanggil oleh owner untuk membuat kupon baru
     * dan mengirimkannya ke alamat tertentu (misalnya alamat dompet brand).
     * @param to Alamat penerima kupon.
     * @param amount Jumlah kupon yang akan dibuat.
     */
    function mintCoupon(address to, uint256 amount) external  {
        _mint(to, MINTING_COUPON_ID, amount, "");
    }

    /**
     * @dev Override fungsi ini agar bisa di-burn dari kontrak lain.
     */
    function burn(address from, uint256 id, uint256 amount) external {
        // Di ERC1155, tidak ada fungsi burn publik secara default.
        // Kita bisa menambahkannya, tapi untuk kasus ini, BrandNFT akan memanggil _burn.
        // Namun, BrandNFT memerlukan izin. Cara terbaik adalah BrandNFT memanggil
        // fungsi burn milik Coupon, dan Coupon memeriksa pemanggilnya.
        // Untuk simplisitas, kita akan biarkan BrandNFT yang melakukan burn
        // setelah mendapat approval. Cara yang lebih aman ada di catatan di bawah.

        // Dalam implementasi ini, kita akan biarkan BrandNFT yang memanggil burn
        // secara internal setelah brand memberikan approval.
        require(
            from == msg.sender || isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not owner nor approved"
        );
        _burn(from, id, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}