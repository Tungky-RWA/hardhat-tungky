
import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("All Contract", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployAll() {

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount, minterAccount] = await hre.viem.getWalletClients();

    const InitialBrandNFT = await hre.viem.deployContract("BrandNFT");
    const Coupon = await hre.viem.deployContract("Coupon");
    const BrandMetadata = await hre.viem.deployContract("BrandMetadata");
    const ContractFactory = await hre.viem.deployContract("ContractFactory", [InitialBrandNFT.address]);
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
      minterAccount
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
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner, minterAccount } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      expect(await Master.write.approveBrand([otherAccount.account.address, minterAccount.account.address], { account: owner.account })).to.be.ok;
      expect((await ContractFactory.read.getBrandInfo([otherAccount.account.address])).isLegalVerified).to.be.eq(true);
    })

    it("Should have 30 Coupons after approved by admin", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner, minterAccount } = await loadFixture(deployAll);
      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address, minterAccount.account.address], { account: owner.account });

      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const couponId = await Coupon.read.MINTING_COUPON_ID()

      expect(await Coupon.read.balanceOf([nftContractAddress, couponId])).to.be.eq(30n);
    })
  })

  describe("BrandNFT Deployed", () => {
    it("BrandNFT Should have correct name", async () => {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner, minterAccount } = await loadFixture(deployAll);

      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address, minterAccount.account.address], { account: owner.account });
    
      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const deployedBrandNFT = await hre.viem.getContractAt("contracts/cores/BrandNFT.sol:BrandNFT", nftContractAddress);
      expect(await deployedBrandNFT.read.name()).to.be.eq("Harkon")
    })
    
    it('Should claim NFT', async function () {
      const { Master, Coupon, ContractFactory, BrandMetadata, otherAccount, owner, minterAccount } = await loadFixture(deployAll);

      const DEFAULT_ADMIN_ROLE = await Coupon.read.DEFAULT_ADMIN_ROLE();
      
      await Coupon.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await ContractFactory.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      await BrandMetadata.write.grantRole([DEFAULT_ADMIN_ROLE, Master.address]);
      
      await Master.write.registerBrand(["Harkon", "HKN", otherAccount.account.address, "anjay"]);
      await Master.write.approveBrand([otherAccount.account.address, minterAccount.account.address], { account: owner.account });
    
      const { nftContractAddress } = (await ContractFactory.read.getBrandInfo([otherAccount.account.address]))
      const deployedBrandNFT = await hre.viem.getContractAt("contracts/cores/BrandNFT.sol:BrandNFT", nftContractAddress);

      expect(await Coupon.read.balanceOf([deployedBrandNFT.address, 1n])).to.be.eq(30n);
      
      await deployedBrandNFT.write.preMint([1n, "anjay"], { account: otherAccount.account });
      expect(await Coupon.read.balanceOf([deployedBrandNFT.address, 1n])).to.be.eq(29n);

      await deployedBrandNFT.write.claimNFT([owner.account.address, 1n], { account: minterAccount.account });
      expect(await deployedBrandNFT.read.balanceOf([owner.account.address])).to.be.eq(1n);
    });
  });
});
