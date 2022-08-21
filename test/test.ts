const { 
  ethers,
  waffle
} = require("hardhat");
const { 
  chai,
  expect
} = require('chai');

import { 
  MirrahArt,
  MockERC20,
} from "../types"

describe("MirrahNFT", function() {

  // Factories
  let ERC20Factory: any
  let MirrahArtFactory: any

  const artist = "0x709Ba910aF125285BC99d4D49e4381D49b3A4874"

  const initialTokens = ethers.BigNumber.from(100_000)
 
  const usdcDecimalsRaw = 6
  const daiDecimalsRaw = 18
  const usdtDecimalsRaw = 6

  const usdcDecimals = ethers.BigNumber.from(10).pow(usdcDecimalsRaw)
  const daiDecimals = ethers.BigNumber.from(10).pow(daiDecimalsRaw)
  const usdtDecimals = ethers.BigNumber.from(10).pow(usdtDecimalsRaw)

  var mirrah: MirrahArt;
  var usdc: MockERC20;
  var dai: MockERC20;
  var usdt: MockERC20;

  const usdcIndex = 0;
  const daiIndex = 1;
  const usdtIndex = 2;

  const [deployer, denice, third] = waffle.provider.getWallets()

  const stageByIndex: Map<number, string> = new Map([
    [0, "NEW"],
    [1, "MODELING"],
    [2, "FIRING"],
    [3, "COLORING"],
    [4, "PREFINAL"],
    [5, "FINISHED"]
  ])

  const indexByStageName: Map<string, number> = new Map([
    ["NEW", 0],
    ["MODELING", 1],
    ["FIRING", 2],
    ["COLORING", 3],
    ["PREFINAL", 4],
    ["FINISHED", 5]
])

  before(async () => {
    await deployTokens()
  })

  beforeEach(async () => {
  });

  async function deployTokens() {

    ERC20Factory = await ethers.getContractFactory("MockERC20")
    MirrahArtFactory = await ethers.getContractFactory("MirrahArt")

    usdc = await ERC20Factory.deploy("USDC", "USDC", usdcDecimalsRaw)
    dai = await ERC20Factory.deploy("DAI", "DAI", daiDecimalsRaw)
    usdt = await ERC20Factory.deploy("USDT", "USDT", usdtDecimalsRaw)

    mirrah = await MirrahArtFactory.deploy(
      artist,
      deployer.address,
      usdc.address,
      dai.address,
      usdt.address
    )
    console.log("Deployer address: " + deployer.address)
    console.log("Denice address: " + denice.address)
    console.log("Mirrah address: " + mirrah.address)
  }

  async function topUpDenice() {
    let usdcAmount = initialTokens.mul(usdcDecimals)
    let daiAmount = initialTokens.mul(daiDecimals)
    let usdtAmount = initialTokens.mul(usdtDecimals)

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
    const usdtBalance = await usdt.balanceOf(mirrah.address)
    console.log("Mirrah USDT balance: " + usdtBalance)
    return [ daiBalance, usdcBalance, usdtBalance ]
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

  async function mirrahBalance(token: MockERC20) {
    return await token.balanceOf(mirrah.address)
  }

  it.only("Token buy works with all currencies and payments received correctly", async function() {
    await topUpDenice()
    const pricesObject = await mirrah.prices()
    const initialPrice = ethers.BigNumber.from(pricesObject[0])
    const priceIncrement = ethers.BigNumber.from(pricesObject[1])
    const initialBalances = await checkBalances()
    // Dai - Initial price, no increments
    const buyWithDai = await mirrah.connect(denice).buyFromContract(0, daiIndex)
    expect((await mirrahBalance(dai)))
      .to.eq(initialBalances[0].add(initialPrice.mul(daiDecimals)))
    // USDC - One price increment
    const buyWithUsdc = await mirrah.connect(denice).buyFromContract(1, usdcIndex)
    expect((await mirrahBalance(usdc)))
      .to.eq(initialBalances[1].add((initialPrice.add(priceIncrement)).mul(usdcDecimals)))
    // USDT - Two price increments
    const buyWithUsdt = await mirrah.connect(denice).buyFromContract(2, usdtIndex)
    expect((await mirrahBalance(usdt)))
      .to.eq(initialBalances[2].add((initialPrice.add(priceIncrement.mul(2))).mul(usdtDecimals)))

    expect(await mirrah.ownerOf(0)).to.eq(denice.address)
    expect(await mirrah.ownerOf(1)).to.eq(denice.address)
    expect(await mirrah.ownerOf(2)).to.eq(denice.address)
  })

  async function getStage(id: number): Promise<string> {
    const details = await mirrah.nftDetails(0)
    return stageByIndex.get(details[0] as number)!
  }

  async function getNextStage(id: number): Promise<string> {
    const details = await mirrah.nftDetails(0)
    const stageIndex = details[0] as number
    const stage = stageByIndex.get(stageIndex)!
    const nextStageIndex = await mirrah.nextStage(stageIndex)
    return stageByIndex.get(nextStageIndex)!
  }

  async function checkCurrentStageAndRequestNext(
    id: number, 
    user: any,
    currentStage: string, 
    nextStage: string) {
      console.log("Expected current stage: " + currentStage)
      console.log("Expected next stage: " + nextStage)
      expect(await getStage(id)).to.eq(currentStage)
      expect(await getNextStage(id)).to.eq(nextStage)
      await mirrah.connect(user).requestStateUpdate(id, daiIndex)
      await expect(mirrah.connect(user).requestStateUpdate(id, daiIndex)).to.be.revertedWith("WorkInProgress")
      await mirrah.connect(deployer).setNftStage(id, indexByStageName.get(nextStage)!)
      expect(await getStage(0)).to.eq(nextStage)
  }

  it.only("Token stages can be updated - optimistic", async function() {
    const id = 0
    const denisMirrah = mirrah.connect(denice)
    await checkCurrentStageAndRequestNext(id, denice, "NEW", "MODELING")
    await checkCurrentStageAndRequestNext(id, denice, "MODELING", "FIRING")
    await checkCurrentStageAndRequestNext(id, denice, "FIRING", "COLORING")
    await denisMirrah.requestFinalStage(0, daiIndex, true, "No details")
  })

  it("Token buy fails for indices higher than max sale", async function() {
    await topUpDenice()
    await expect(mirrah.connect(denice).buyFromContract(5, usdtIndex)).to.be.revertedWith('Token not for sale')

    await mirrah.setMaxSaleIndex(18)

    const buy18 = await mirrah.connect(denice).buyFromContract(18, usdtIndex)
    expect(await mirrah.ownerOf(18)).to.eq(denice.address)

    await expect(mirrah.connect(denice).buyFromContract(19, usdtIndex)).to.be.revertedWith('Token not for sale')
  })

  it("Token fails if user didn't give enough allowance", async function() {
    await usdc.connect(denice).approve(mirrah.address, 0)
    expect(await usdc.allowance(denice.address, mirrah.address)).to.eq(0)
    await expect(mirrah.connect(denice).buyFromContract(11, 0)).to.be.revertedWith('ERC20: insufficient allowance')
  })

  it("Protected calls fail when called by non-admin", async function() {
    await expect(mirrah.connect(denice).setMaxSaleIndex(11)).to.be.revertedWith('Not admin or owner')
    await expect(mirrah.connect(denice).setNftStage(1, 2)).to.be.revertedWith('Not admin or owner')
    await expect(mirrah.connect(denice).setArtistAddress(third.address)).to.be.revertedWith('Not owner')
    await expect(mirrah.connect(denice).setDeveloperAddress(third.address)).to.be.revertedWith('Not owner')
    await expect(mirrah.connect(denice).setStablesAddress([third.address, third.address, third.address])).to.be.revertedWith('Not owner')
    await expect(mirrah.connect(denice).withdrawAllOfToken(dai.address)).to.be.revertedWith('Not admin or owner')
  })

  it("Withdraw increases artist and developer token balances correctly", async function() {
    await checkIfWithdrawalGivesCorrectAmount(dai)
    await checkIfWithdrawalGivesCorrectAmount(usdc)
    await checkIfWithdrawalGivesCorrectAmount(usdt)
  })

  // Recheck
  async function checkIfWithdrawalGivesCorrectAmount(token: MockERC20) {
    console.log(await token.name() + ":")
    const contractBalance = await token.balanceOf(mirrah.address)
    console.log("Mirrah token balance: " + contractBalance)
    const dev0 = await token.balanceOf(deployer.address)
    const art0 = await token.balanceOf(artist)
    console.log("Dev initital: " + dev0.toString() + "\nArtist initital: " + art0.toString())
    await mirrah.connect(deployer).withdrawAllOfToken(token.address)
    const dev1 = await token.balanceOf(deployer.address)
    const art1 = await token.balanceOf(artist)
    console.log("Dev after: " + dev1.toString() + "\nArtist after: " + art1.toString())
    expect(dev1.add(art1).sub(dev0).sub(art0)).to.eq(contractBalance)
  }
})
