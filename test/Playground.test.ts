// test/SimpleVerifier.test.js
import hre from "hardhat";
import { expect } from "chai";
import { keccak256, encodePacked, getAddress } from "viem";

describe("SimpleSignatureVerifier", function () {
  it("Should verify a valid simple signature", async function () {
    // Dapatkan akun admin dan pengguna
    const [admin, user] = await hre.viem.getWalletClients();

    // Deploy kontrak dengan alamat admin
    const verifier = await hre.viem.deployContract("contracts/playgrounds/SimpleSignatureVerifier.sol:SimpleSignatureVerifier", [admin.account.address]);
    const publicClient = await hre.viem.getPublicClient();

    // Data yang akan ditandatangani
    const recipientAddress = user.account.address;
    const nonce = 123n;

    // 1. Buat hash mentah, sama persis seperti di kontrak
    const messageHash = keccak256(encodePacked(
        ["address", "uint256"],
        [recipientAddress, nonce]
    ));

    // 2. Admin menandatangani HASH.
    // `signMessage` secara otomatis menambahkan prefix "\x19Ethereum Signed Message:\n32"
    const signature = await admin.signMessage({
        account: admin.account,
        message: { raw: messageHash }
    });

    // 3. Panggil fungsi di kontrak untuk verifikasi
    const isValid = await publicClient.readContract({
        address: verifier.address,
        abi: verifier.abi,
        functionName: "isValidSignature",
        args: [recipientAddress, nonce, signature],
    });

    // 4. Tes harus berhasil
    expect(isValid).to.be.true;
  });
});