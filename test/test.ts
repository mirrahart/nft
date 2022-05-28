const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"

import { 
  MirrahArt,
  MockERC20,
} from "../types"

use(solidity)

describe("NFT", function() {

  // Factories
  let ERC20Factory: any
  let MirrahArtFactory: any

  const artist = "0x709Ba910aF125285BC99d4D49e4381D49b3A4874"
  const developer = "0x3eb6Bf5B7AC2B683c787f7aac59683A8d05d885d"

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
    usdc = await ERC20Factory.deploy("USDC", "USDC")
    await usdc.deployed()
    await usdc.mint(wallet.address, "1000000000000000000000000")
    dai = await ERC20Factory.deploy("DAI", "DAI")
    await dai.deployed()
    await dai.mint(wallet.address, "1000000000000000000000000")
    mirrah = await MirrahArtFactory.deploy(
      artist,
      developer,
      usdc.address,
      dai.address
    )
    await mirrah.deployed()
  }

  it("Fetch number of minted tokens", async function() {
    const count = await mirrah.balanceOf(mirrah.address)
    console.log("Token count: " + count)
  })
})
