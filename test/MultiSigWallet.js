const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MultiSigWallet", function () {
  async function deploy() {
    const [ownerA, ownerB, ownerC, outsider, recipient] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("MultiSigWallet");
    const wallet = await Factory.deploy(
      [ownerA.address, ownerB.address, ownerC.address],
      2
    );
    await wallet.waitForDeployment();
    return { wallet, ownerA, ownerB, ownerC, outsider, recipient };
  }

  it("pays out only after the threshold is met", async function () {
    const { wallet, ownerA, ownerB, recipient } = await deploy();
    const address = await wallet.getAddress();
    const amount = ethers.parseEther("0.4");

    await ownerA.sendTransaction({ to: address, value: ethers.parseEther("1") });
    await wallet.connect(ownerA).submit(recipient.address, amount, "0x");

    await expect(wallet.connect(ownerA).execute(0)).to.be.revertedWith(
      "need more confirmations"
    );

    await wallet.connect(ownerB).confirm(0);
    await expect(wallet.connect(ownerB).execute(0)).to.changeEtherBalance(
      recipient,
      amount
    );
    expect(await wallet.approvalCount(0)).to.equal(2);
  });

  it("rejects outsiders and duplicate confirms", async function () {
    const { wallet, ownerA, outsider, recipient } = await deploy();
    await expect(
      wallet.connect(outsider).submit(recipient.address, 0, "0x")
    ).to.be.revertedWith("not owner");

    await wallet.connect(ownerA).submit(recipient.address, 0, "0x");
    await expect(wallet.connect(ownerA).confirm(0)).to.be.revertedWith(
      "already confirmed"
    );
  });

  it("lets an owner revoke before execution", async function () {
    const { wallet, ownerA, ownerB, recipient } = await deploy();
    await wallet.connect(ownerA).submit(recipient.address, 0, "0x");
    await wallet.connect(ownerB).confirm(0);
    await wallet.connect(ownerB).revoke(0);

    await expect(wallet.connect(ownerA).execute(0)).to.be.revertedWith(
      "need more confirmations"
    );
    expect(await wallet.approvalCount(0)).to.equal(1);
  });
});
