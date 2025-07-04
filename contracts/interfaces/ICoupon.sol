// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICoupon {
    
    function mintCoupon(address to, uint256 amount) external;

    /**
     * @dev Override fungsi ini agar bisa di-burn dari kontrak lain.
     */
    function burn(address from, uint256 id, uint256 amount) external;
}