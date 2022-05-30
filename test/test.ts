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

  const initialTokens = Big(10_000)
  const usdcDecimals = 6
  const daiDecimals = 18

  var mirrah: MirrahArt;
  var usdc: MockERC20;
  var dai: MockERC20;

  const usdcIndex = 0;
  const daiIndex = 1;

  const [wallet, denice] = waffle.provider.getWallets()

  before(async () => {
    ERC20Factory = await ethers.getContractFactory("MockERC20")
    MirrahArtFactory = await ethers.getContractFactory("MirrahArt")
    await deployTokens()
})

  beforeEach(async () => {
  });

  async function deployTokens() {
    
    usdc = await ERC20Factory.deploy("USDC", "USDC", usdcDecimals)
    dai = await ERC20Factory.deploy("DAI", "DAI", daiDecimals)

    mirrah = await MirrahArtFactory.deploy(
      artist,
      developer,
      usdc.address,
      dai.address
    )
    console.log("Deployer address: " + wallet.address)
    console.log("Denice address: " + denice.address)
    console.log("Mirrah address: " + mirrah.address)
  }

  async function topUpDenice() {
    let usdcAmount = initialTokens.mul(Math.pow(10, usdcDecimals)).toFixed()
    let daiAmount = initialTokens.mul(Math.pow(10, daiDecimals)).toFixed()

    await usdc.mint(denice.address, usdcAmount)
    await dai.mint(denice.address, daiAmount)

    await usdc.connect(denice).approve(mirrah.address, usdcAmount)
    await dai.connect(denice).approve(mirrah.address, daiAmount)
  }

  it("Correct number of initial tokens is minted", async function() {
    const count = await mirrah.balanceOf(mirrah.address)
    expect(count).to.eq(30)
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
  })

  it("Token buy works with both currencies", async function() {
    await topUpDenice()
    const buyWithUsdc = await mirrah.connect(denice).buyFromContract(usdcIndex, 0)
    const buyWithDai = await mirrah.connect(denice).buyFromContract(daiIndex, 1)

    expect(await mirrah.ownerOf(0)).to.eq(denice.address)
    expect(await mirrah.ownerOf(1)).to.eq(denice.address)
    await checkBalances()
  })

  it("Token buy fails when DAI allowance is insufficient", async function() {
    const buyTransaction = mirrah.connect(denice).buyFromContract(5, 0)
    expect(buyTransaction).to.be.revertedWith('Not enough allowance')
  })
})
