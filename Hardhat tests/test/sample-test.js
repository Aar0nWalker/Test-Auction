const { inputToConfig } = require("@ethereum-waffle/compiler");
const { getContractFactory } = require("@nomiclabs/hardhat-ethers/types");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe ("NFT", function(){
  let acc1
  let acc2
  let acc3
  let _NFT
  let _TestAuction
  beforeEach(async function(){
    [acc1, acc2, acc3] = await ethers.getSigners();
    const NFT = await ethers.getContractFactory("NFT", acc1);
    _NFT = await NFT.deploy("1", acc1.address)
    await _NFT.deployed()

    const TestAuction = await ethers.getContractFactory("TestAuction", acc1);
    _TestAuction = await TestAuction.deploy()
    await _TestAuction.deployed()
  })

  it("it should be deployed", async function(){
    expect(_NFT.address).to.be.properAddress;
    expect(_TestAuction.address).to.be.properAddress;
  })

  it("it should be added and removed", async function(){
    await _NFT.connect(acc1).setNFTHardcap(20)
    await _NFT.connect(acc1).setNFTLimits(10, 10)
    await _NFT.connect(acc1).setPrices(100, 100)
    await _NFT.connect(acc1).togglePresaleStarted()
    await _NFT.connect(acc1).togglePublicSaleStarted()
    const mint = await _NFT.connect(acc2).PublicMint(1, {value:100})
    await mint.wait()

    const balance = await _NFT.balanceOf(acc2.address)
    expect(balance).to.eq(1)

    await _NFT.connect(acc2).approve(_TestAuction.address, 0)

    await _TestAuction.connect(acc2).addAssert(_NFT.address, 0, "Lot1", 200)

    const balance2 = await _NFT.balanceOf(_TestAuction.address)
    expect(balance2).to.eq(1)

    await _TestAuction.connect(acc2).removeAssert(1)
    const balance3 = await _NFT.balanceOf(_TestAuction.address)
    expect(balance3).to.eq(0)
  })

  it("it should be bought with start price", async function(){
    await _NFT.connect(acc1).setNFTHardcap(20)
    await _NFT.connect(acc1).setNFTLimits(10, 10)
    await _NFT.connect(acc1).setPrices(100, 100)
    await _NFT.connect(acc1).togglePresaleStarted()
    await _NFT.connect(acc1).togglePublicSaleStarted()
    const mint = await _NFT.connect(acc2).PublicMint(1, {value:100})
    await mint.wait()

    const balance = await _NFT.balanceOf(acc2.address)
    expect(balance).to.eq(1)

    await _NFT.connect(acc2).approve(_TestAuction.address, 0)

    await _TestAuction.connect(acc2).addAssert(_NFT.address, 0, "Lot1", 200)

    const balance2 = await _NFT.balanceOf(_TestAuction.address)
    expect(balance2).to.eq(1)

    await _TestAuction.connect(acc3).buyAssert(1, {value: 200})
    const balance3 = await _NFT.balanceOf(acc3.address)
    expect(balance3).to.eq(1)
  })

  it("it should be bought with offered price", async function(){
    await _NFT.connect(acc1).setNFTHardcap(20)
    await _NFT.connect(acc1).setNFTLimits(10, 10)
    await _NFT.connect(acc1).setPrices(100, 100)
    await _NFT.connect(acc1).togglePresaleStarted()
    await _NFT.connect(acc1).togglePublicSaleStarted()
    const mint = await _NFT.connect(acc2).PublicMint(1, {value:100})
    await mint.wait()

    const balance = await _NFT.balanceOf(acc2.address)
    expect(balance).to.eq(1)

    await _NFT.connect(acc2).approve(_TestAuction.address, 0)

    await _TestAuction.connect(acc2).addAssert(_NFT.address, 0, "Lot1", 200)

    const balance2 = await _NFT.balanceOf(_TestAuction.address)
    expect(balance2).to.eq(1)

    await _TestAuction.connect(acc3).offerPrice(1, 150)
    await _TestAuction.connect(acc2).sellForTheOfferedPrice(1, acc3.address)
    const buyer = await _TestAuction.buyerData(1)
    expect(buyer).to.eq(acc3.address)

    await _TestAuction.connect(acc3).buyAssertForTheOfferedPrice(1, {value:150})
    const balance3 = await _NFT.balanceOf(acc3.address)
    expect(balance3).to.eq(1)
  })
})
