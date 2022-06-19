const { 
  ethers,
  waffle
} = require("hardhat");
const { 
  chai,
  expect
} = require('chai');
import Big from "big.js";

import { 
  MirrahArt,
  MockERC20,
} from "../types"

describe("MirrahNFT", function() {

  // Factories
  let ERC20Factory: any
  let MirrahArtFactory: any

  const artist = "0x709Ba910aF125285BC99d4D49e4381D49b3A4874"
  const developer = "0x3eb6Bf5B7AC2B683c787f7aac59683A8d05d885d"

  const initialTokens = Big(100_000)
 
  const usdcDecimals = 6
  const daiDecimals = 18
  const usdtDecimals = 6

  var mirrah: MirrahArt;
  var usdc: MockERC20;
  var dai: MockERC20;
  var usdt: MockERC20;

  const usdcIndex = 0;
  const daiIndex = 1;
  const usdtIndex = 2;

  const [wallet, denice] = waffle.provider.getWallets()

  before(async () => {
    await deployTokens()
})

  beforeEach(async () => {
  });

  async function deployTokens() {

    ERC20Factory = await ethers.getContractFactory("MockERC20")
    MirrahArtFactory = await ethers.getContractFactory("MirrahArt")

    usdc = await ERC20Factory.deploy("USDC", "USDC", usdcDecimals)
    dai = await ERC20Factory.deploy("DAI", "DAI", daiDecimals)
    usdt = await ERC20Factory.deploy("USDT", "USDT", usdtDecimals)

    mirrah = await MirrahArtFactory.deploy(
      artist,
      developer,
      usdc.address,
      dai.address,
      usdt.address
    )
    console.log("Deployer address: " + wallet.address)
    console.log("Denice address: " + denice.address)
    console.log("Mirrah address: " + mirrah.address)
  }

  async function topUpDenice() {
    let usdcAmount = initialTokens.mul(Math.pow(10, usdcDecimals)).toFixed()
    let daiAmount = initialTokens.mul(Math.pow(10, daiDecimals)).toFixed()
    let usdtAmount = initialTokens.mul(Math.pow(10, usdtDecimals)).toFixed()

    await usdc.mint(denice.address, usdcAmount)
    await dai.mint(denice.address, daiAmount)
    await usdt.mint(denice.address, usdtAmount)

    await usdc.connect(denice).approve(mirrah.address, usdcAmount)
    await dai.connect(denice).approve(mirrah.address, daiAmount)
    await usdt.connect(denice).approve(mirrah.address, usdtAmount)
  }

  it("Correct number of initial tokens is minted", async function() {
    const count = await mirrah.balanceOf(mirrah.address)
    expect(count).to.eq(30)
    expect(await mirrah.ownerOf(29)).to.eq(mirrah.address)
    await expect(mirrah.ownerOf(30)).to.be.revertedWith('OwnerQueryForNonexistentToken')
  })

  async function checkBalances() {
    const daiBalance = await dai.balanceOf(mirrah.address)
    console.log("Mirrah Dai balance: " + daiBalance)
    const usdcBalance = await usdc.balanceOf(mirrah.address)
    console.log("Mirrah USDC balance: " + usdcBalance)
  }

  it("Token indices are correct", async function() {
    expect(await mirrah.tokenForCurrency(usdcIndex)).to.eq(usdc.address)
    expect(await mirrah.tokenForCurrency(daiIndex)).to.eq(dai.address)
    expect(await mirrah.tokenForCurrency(usdtIndex)).to.eq(usdt.address)
  })

  it("Metadata URLs are correct", async function() {
    const uri = await mirrah.tokenURI(0)
    console.log(uri)
    expect(uri).to.eq("https://s.nft.mirrah.art/one/metadata/0")
  })

  it("Token buy works with all currencies", async function() {
    await topUpDenice()
    const buyWithUsdc = await mirrah.connect(denice).buyFromContract(2, usdcIndex)
    const buyWithDai = await mirrah.connect(denice).buyFromContract(0, daiIndex)
    const buyWithUsdt = await mirrah.connect(denice).buyFromContract(1, usdtIndex)

    expect(await mirrah.ownerOf(0)).to.eq(denice.address)
    expect(await mirrah.ownerOf(1)).to.eq(denice.address)
    expect(await mirrah.ownerOf(2)).to.eq(denice.address)
    await checkBalances()
  })

  it("Token buy fails for indices higher than max sale", async function() {
    await topUpDenice()
    await expect(mirrah.connect(denice).buyFromContract(5, usdtIndex)).to.be.revertedWith('Token not for sale')

    await mirrah.setMaxSaleIndex(18)

    const buy17 = await mirrah.connect(denice).buyFromContract(18, usdtIndex)
    expect(await mirrah.ownerOf(18)).to.eq(denice.address)

    await expect(mirrah.connect(denice).buyFromContract(19, usdtIndex)).to.be.revertedWith('Token not for sale')
  })

  it("Token buy fails when DAI allowance is insufficient", async function() {
    const buyTransaction = mirrah.connect(denice).buyFromContract(5, 0)
    expect(buyTransaction).to.be.revertedWith('Not enough allowance')
  })
})
