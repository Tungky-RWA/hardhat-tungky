// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LockModule = buildModule("Deploy", (m) => {
  const mCoupon = m.contract("Coupon");
  const mBrandMetadata = m.contract("BrandMetadata");
  const mFactory = m.contract("ContractFactory");
  const mMaster = m.contract("Master")
  return { contractFactory };
});

export default LockModule;