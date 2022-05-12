const fantomAddress = ""
const rinkebyAddress = ""
const ropstenAddress = ""
const deployAddress = ropstenAddress

async function main() {
  const NFT = await hre.ethers.getContractFactory("MirrahArt")
  const nft = await NFT.deploy()
  await nft.deployed()
  console.log("NFT deployed to: ", nft.address)

  await delay(20000)
  await verify(nft.address)
}

async function verify(address) {
  await hre.run("verify:verify", {
    address: address,
    network: hre.network,
  })
}

async function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error)
  process.exit(1)
})
