import { ethers } from "ethers"
import HundredFinanceHackReplicator from "../../hack-replication/artifacts/HundredFinance_Original.t.sol/HundredFinanceHackReplicator.json"

function main() {
  console.log("Start listening...")

  const url = "http://127.0.0.1:8545"
  const target = "0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84"

  const provider = new ethers.JsonRpcProvider(url)
  provider.on("block", (blockNumber) => {
    console.log("blockNumber", blockNumber)
  })

  // const contract = new ethers.Contract(target, HundredFinanceHackReplicator.abi)

  // const filter = {
  //   address: target,
  //   topics: [
  //     // the name of the event, parnetheses containing the data type of each event, no spaces
  //     "*",
  //   ],
  // }

  // contract.on(filter, (event) => {
  //   console.log("event", event)
  // })
}

main()
