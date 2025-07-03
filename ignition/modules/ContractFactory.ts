// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LockModule = buildModule("Deploy", (m) => {
  const brandNFT = m.contract("BrandNFT");
  const coupon = m.contract("Coupon");
  const brandMetadata = m.contract("BrandMetadata");
  const contractFactory = m.contract("ContractFactory", [brandNFT]);
  const master = m.contract("Master", [coupon, brandMetadata, contractFactory]);
  
  const DEFAUlT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";

  m.call(coupon, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);
  m.call(brandMetadata, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);
  m.call(contractFactory, "grantRole", [DEFAUlT_ADMIN_ROLE, master]);


  //testing only
  // m.call(master, "registerBrand", ["TEST", "TST", "0xC6E18dc61ce1B6C90c7315036E1fD43725F4484d", "anjay"])
  // m.call(master, "approveBrand", ["0xC6E18dc61ce1B6C90c7315036E1fD43725F4484d","0x5CbDc82605906d2fC422991310890B1bEcC8DC3D"]);

  return { coupon, brandMetadata, contractFactory, master };
});

export default LockModule;