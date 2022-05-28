const ethereumAddress = ""
const rinkebyAddress = ""
const deployAddress = rinkebyAddress

const artist = "0x709Ba910aF125285BC99d4D49e4381D49b3A4874"
const developer = "0x3eb6Bf5B7AC2B683c787f7aac59683A8d05d885d"

const usdcEthereum = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
const usdcRinkeby = "0x7f3a66bd60ec7a0fdb95fadbaa6648f512ce2f26"
const daiEthereum = "0x6b175474e89094c44da98b954eedeac495271d0f"
const daiRinkeby = "0x01d07d78cdb9535948eaef2fd1093be0e5f07186"

const usdc = usdcRinkeby
const dai = daiRinkeby

async function main() {
  const NFT = await hre.ethers.getContractFactory("MirrahArt")
  const nft = await NFT.deploy(
    artist, // Artist - metamask
    developer,
    usdc,
    dai,
  )
  await nft.deployed()
  console.log("NFT deployed to: ", nft.address)

  await delay(20000)
  await hre.run("verify:verify", {
    address: nft.address,
    network: hre.network,
    constructorArguments: [
      artist, 
      developer,
      usdc,
      dai,
  ]
  })
}

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
})
