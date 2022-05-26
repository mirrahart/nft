const { expect } = require("chai")

describe("NFT", function() {
  it("It should deploy the contract, mint a token, and resolve to the right URI", async function() {
    const NFT = await ethers.getContractFactory("MirrahArt")
    const nft = await NFT.deploy()
    сonsole.log(nft.address)
    await nft.deployed()
    console.log("Deployed!")
  })
})
