import { ethers } from "ethers"
import HundredFinanceHackReplicator from "../../hack-replication/artifacts/HundredFinance_Original.t.sol/HundredFinanceHackReplicator.json"

function main() {
  console.log("Start listening...")

  const url = "http://127.0.0.1:8545"
  const wsUrl = "ws://127.0.0.1:8545"

  const target = "0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84"

  const provider = new ethers.providers.JsonRpcProvider(url)
  provider.on("block", async (blockNumber) => {
    console.log("blockNumber", blockNumber)
    console.log(`New block: #${blockNumber}`)

    const block = await provider.getBlockWithTransactions(blockNumber)

    for (const transaction of block.transactions) {
      console.log("From:", transaction.from)
      console.log("To:", transaction.to)
      console.log("Value:", ethers.utils.formatEther(transaction.value))
      console.log("---------------------------------")
    }
  })

  // const init = function () {
  //   var customWsProvider = new ethers.WebSocketProvider(wsUrl)

  //   customWsProvider.on("pending", (tx) => {
  //     customWsProvider.getTransaction(tx).then(function (transaction) {
  //       console.log(transaction)
  //     })
  //   })
  // }

  // init()

  // customWsProvider.websocket.on("error", async () => {
  //   console.log(`Unable to connect to ${ep.subdomain} retrying in 3s...`);
  //   setTimeout(init, 3000);
  // });
  // customWsProvider.websocket.on("close", async (code) => {
  //   console.log(
  //   }

  // )
  // }

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
