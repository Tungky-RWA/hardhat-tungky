
import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import { keccak256, encodePacked, toBytes } from "viem";

describe("All Contract", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployAll() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const Coupon = await hre.viem.deployContract("Coupon");
    const BrandMetadata = await hre.viem.deployContract("BrandMetadata");
    const ContractFactory = await hre.viem.deployContract("ContractFactory");
    const Master = await hre.viem.deployContract("Master", [Coupon.address, BrandMetadata.address, ContractFactory.address]);
    const publicClient = await hre.viem.getPublicClient();

    return {
      Coupon,
      BrandMetadata,
      ContractFactory,
      Master,
      owner,
      otherAccount,
      publicClient,
    };
  }

  describe("Deployment", () => {
    it("Should set Master address as DEFAULT_ADMIN_ROLE in every smart contract except BrandNFT", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      expect(await Coupon.read.hasRole([DEFAULT_ADMIN_ROLE, Master.address])).to.equal(true);
      expect(await ContractFactory.read.hasRole([DEFAULT_ADMIN_ROLE, Master.address])).to.equal(true);
      expect(await BrandMetadata.read.hasRole([DEFAULT_ADMIN_ROLE, Master.address])).to.equal(true);
    })
  })

  describe("Register Brand", () => {
    it("Should otherAccount Register his Brand", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();

      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);

      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      expect((await ContractFactory.read.getBrandInfo([otherAccount.account.address])).name).to.be.eq("Harkon");
    })
    
    it("Admin Should approve pending register brand", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      expect(await Master.write.approveBrand([otherAccount.account.address], { account: owner.account })).to.be.ok;
      expect((await ContractFactory.read.getBrandInfo([otherAccount.account.address])).isLegalVerified).to.be.eq(true);
    })

    it("Should have 30 Coupons after approved by admin", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address], { account: owner.account });

      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const couponId = await Coupon.read.MINTING_COUPON_ID()

      expect(await Coupon.read.balanceOf([nftContractAddress, couponId])).to.be.eq(30n);
    })
  })

  describe("BrandNFT Deployed", () => {
    it("BrandNFT Should have correct name", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner } = await loadFixture(deployAll);

      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address], { account: owner.account });
    
      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const deployedBrandNFT = await hre.viem.getContractAt("contracts/cores/BrandNFT.sol:BrandNFT", nftContractAddress);
      expect(await deployedBrandNFT.read.name()).to.be.eq("Harkon")
    })
    
    it('Should validate the signed message', async function () {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner } = await loadFixture(deployAll);

      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address], { account: owner.account });
    
      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const deployedBrandNFT = await hre.viem.getContractAt("contracts/cores/BrandNFT.sol:BrandNFT", nftContractAddress);

      // TODO...
      const BrandNFTOwnerAddress = otherAccount.account.address; //other akun adalah brand jadinya dibalik
      const recipientAddress = owner.account.address;
      const nonce = 1n;

      console.log(recipientAddress)
      console.log(BrandNFTOwnerAddress)

      const messageHash = keccak256(encodePacked(
          ["address", "uint256"],
          [recipientAddress, nonce]
      ));
      const signature = await otherAccount.signMessage({
        account: otherAccount.account,
        message: { raw: messageHash }
      });

      // Signer 1 calls the claimMint function with the signature
      expect(await deployedBrandNFT.read.isValidSignature([recipientAddress, nonce, signature])).to.be.true;
      expect(await deployedBrandNFT.write.claimNFT([nonce, "anjay", signature], { account: owner.account })).to.be.ok;
      expect(await deployedBrandNFT.read.balanceOf([recipientAddress], { account: owner.account })).to.be.equal(1n);
      expect(await deployedBrandNFT.read.balanceOf([recipientAddress], { account: owner.account })).to.be.equal(1n);
      expect(await deployedBrandNFT.read.tokenURI([nonce], { account: owner.account })).to.be.equal("anjay");
    });
  })

  // describe("Deployment", function () {
  //   it("Should set the right unlockTime", async function () {
  //     const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

  //     expect(await lock.read.unlockTime()).to.equal(unlockTime);
  //   });

  //   it("Should set the right owner", async function () {
  //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);

  //     expect(await lock.read.owner()).to.equal(
  //       getAddress(owner.account.address)
  //     );
  //   });

  //   it("Should receive and store the funds to lock", async function () {
  //     const { lock, lockedAmount, publicClient } = await loadFixture(
  //       deployOneYearLockFixture
  //     );

  //     expect(
  //       await publicClient.getBalance({
  //         address: lock.address,
  //       })
  //     ).to.equal(lockedAmount);
  //   });

  //   it("Should fail if the unlockTime is not in the future", async function () {
  //     // We don't use the fixture here because we want a different deployment
  //     const latestTime = BigInt(await time.latest());
  //     await expect(
  //       hre.viem.deployContract("Lock", [latestTime], {
  //         value: 1n,
  //       })
  //     ).to.be.rejectedWith("Unlock time should be in the future");
  //   });
  // });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.write.withdraw()).to.be.rejectedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We retrieve the contract with a different account to send a transaction
  //       const lockAsOtherAccount = await hre.viem.getContractAt(
  //         "Lock",
  //         lock.address,
  //         { client: { wallet: otherAccount } }
  //       );
  //       await expect(lockAsOtherAccount.write.withdraw()).to.be.rejectedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.write.withdraw()).to.be.fulfilled;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount, publicClient } =
  //         await loadFixture(deployOneYearLockFixture);

  //       await time.increaseTo(unlockTime);

  //       const hash = await lock.write.withdraw();
  //       await publicClient.waitForTransactionReceipt({ hash });

  //       // get the withdrawal events in the latest block
  //       const withdrawalEvents = await lock.getEvents.Withdrawal();
  //       expect(withdrawalEvents).to.have.lengthOf(1);
  //       // expect(withdrawalEvents[0].args.amount).to.equal(lockedAmount);
  //     });
  //   });
  // });
});
