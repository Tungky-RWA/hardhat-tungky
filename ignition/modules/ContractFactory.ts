// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LockModule = buildModule("Deploy", (m) => {
  const coupon = m.contract("Coupon");
  const brandMetadata = m.contract("BrandMetadata");
  const contractFactory = m.contract("ContractFactory");
  const master = m.contract("Master", [coupon, brandMetadata, contractFactory]) //cara mengambil address gimana?
  
  const DEFAUlT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";

  m.call(coupon, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);
  m.call(brandMetadata, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);
  m.call(contractFactory, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);
  
  return { coupon, brandMetadata, contractFactory, master };
});

export default LockModule;