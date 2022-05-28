const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
import { expect, use } from "chai"
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

  const initialTokens = Big(10_000)
  const usdcDecimals = 6
  const daiDecimals = 18

  var mirrah: MirrahArt;
  var usdc: MockERC20;
  var dai: MockERC20;

  const [wallet] = waffle.provider.getWallets()

  before(async () => {
    ERC20Factory = await ethers.getContractFactory("MockERC20")
    MirrahArtFactory = await ethers.getContractFactory("MirrahArt")
})

  beforeEach(async () => {
    await deployTokens()
  });

  async function deployTokens() {
    usdc = await ERC20Factory.deploy("USDC", "USDC", usdcDecimals)
    await usdc.mint(wallet.address, initialTokens.mul(Math.pow(10, usdcDecimals)).toFixed())
    dai = await ERC20Factory.deploy("DAI", "DAI", daiDecimals)
    await dai.mint(wallet.address, initialTokens.mul(Math.pow(10, daiDecimals)).toFixed())
    mirrah = await MirrahArtFactory.deploy(
      artist,
      developer,
      usdc.address,
      dai.address
    )
    console.log("Mirrah address: " + mirrah.address)
  }

  it("Correct number of initial tokens is minted", async function() {
    const count = await mirrah.balanceOf(mirrah.address)
    expect(count).to.eq(30)
  })

  async function checkBalances() {
    const daiBalance = await dai.balanceOf(wallet.address)
    console.log("Dai balance: " + daiBalance)
    const usdcBalance = await usdc.balanceOf(wallet.address)
    console.log("USDC balance: " + usdcBalance)
  }

  it("Correct number of initial tokens is minted", async function() {
    await mirrah.attach(wallet.address).buyFromContract(0, 0)
    await checkBalances()
    // expect(await mirrah.ownerOf(0)).to.eq(wallet.address)
  })
})
