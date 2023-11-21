# suave-template

### **A template for writing SUAVE contracts with Foundry**

[`Use this template`](https://github.com/mehranhydary/suave-template/generate)

1. This template it built using Foundry
2. The template has `suave-geth` already installed and a few example SUAVE applications

### **Setting up the repository**

1. Create a template from this repository
2. Run `forge-install`
3. Review or remove the examples in this repository and start coding!

### **Deploying your contract to local Rigil Testnet**

You can use Anvil to setup a local SUAVE testnet

1. Create a `.env` file in the root of this folder as follows.

```
RPC_URL=https://rpc.rigil.suave.flashbots.net
PK=ADD_YOUR_PRIVATE_KEY_HERE
PK_LOCAL=ADD_YOUR_LOCAL_PRIVATE_KEY_HERE
```

2. Return to your terminal, run `source .env` and then run `anvil --fork-url $RPC_URL` to create a local SUAVE testnet.
3. At this point, you have a local SUAVE testnet running that has been forked from the public SUAVE testnet (Rigil).
4. In a new terminal, you can now deploy contracts to your local testnet with the following command. The `$PK_LOCAL`variable referenced below should be one of the private keys that are spun up by `anvil` (or you'll have to fund your own private key after spinning up the local SUAVE testnet).

```
forge create --rpc-url http://localhost:8545 --legacy --private-key $PK_LOCAL src/examples/basic/OnlyConfidential.sol:OnlyConfidential
```

5. You should see the deployment in both terminals

```
# Terminal with local SUAVE testnet
Transaction: 0x8d67f37ae32ae295e2a8e6ac0db655c8b4da7a3962e0c997a0764524d08ad5fa
Contract created: 0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0
Gas used: 334876

Block Number: 254191
Block Hash: 0x3ce42ea3a493d9ec73d2d18f3ad8a9152763579c053387d317f2830321ecb0b5
Block Time: "Tue, 21 Nov 2023 16:07:32 +0000"
```

```
# Terminal where you ran the `forge create` command
[⠰] Compiling...
No files changed, compilation skipped
Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Deployed to: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
Transaction hash: 0x8d67f37ae32ae295e2a8e6ac0db655c8b4da7a3962e0c997a0764524d08ad5fa

```

### **Deploying your contract to Rigil Testnet**

You can use Forge to deploy contracts to SUAVE.

1. Replace all `SuaveForge.sol` imports with `Suave.sol`.
2. Get Rigil ETH from the [faucet](https://faucet.rigil.suave.flashbots.net/). Only use the faucet for your `$PK` address since the `$PK_LOCAL` address will be usable by people who use Foundry (the same local private keys are spun up for all Foundry users).
3. Create a `.env` file in the root of this folder as follows (you can also use the same `.env` file you created for the previous step).

```
RPC_URL=https://rpc.rigil.suave.flashbots.net
PK=ADD_YOUR_PRIVATE_KEY_HERE
PK_LOCAL=ADD_YOUR_LOCAL_PRIVATE_KEY_HERE
```

4. Upon saving it, return to your terminal and run `source .env`. There's an example (`.env.example`) that you can copy and use in the root folder of this repository.
5. Now you can use your `.env` variables in your terminal. Run the following command to deploy your contracts (don't forget to change the `SuaveForge.sol` imports to `Suave.sol`).

```
  forge create --rpc-url $RPC_URL --legacy --private-key $PK src/examples/basic/OnlyConfidential.sol:OnlyConfidential
```

6. A Rigil block-explorer can be found [here](https://explorer.rigil.suave.flashbots.net/)

### **Examples in the repository**

#### **OnlyConfidential**

This is a basic contract that showcases some of the new precompiles available in SUAVE (`isConfidental`, `confidentialInputs`, and `simulateBundle`).

#### **OnlyConfidentialWithLogs**

Extended version of `OnlyConfidential` so that it emits the results of the simulation performed by the MEVM allowed to decrypt the confidential inputs.

#### **Bundle Bids**

`Bundle Bids`, `Eth Block Bids`, and `MEV Share Bids` are examples of orderflow auctions (OFAs) on SUAVE. The flow for all are outlined in thie section.

1. A user sends their L1 transaction, EIP-712 message, UserOp, or Intent to a SUAVE Kettle.
2. The MEVM inside that Kettle processes the L1 transaction, extracts a hint, and emits it onchain.
3. Searchers listening to the chain see the hint, craft backrun transactions, and send them to a SUAVE Kettle.
4. SUAVE Kettles will process the backrun, combine it into a bundle with the original transaction, include the bundle in a block, and then emit the block to an offchain relay.

Optionally, bundles can also be sent to a centralized block builder.

The `Bundle Bids` bidder and sender contracts are the simplest version of an OFA.

#### **Eth Block and MEV Share Bids**

The `Eth Block Bids` and `MEV Share Bids` use Confidential Data Store to hide the data that is relevant to the transaction. The contracts use `confidentialStore` to store the confidential data along with specific conditions. Searchers can look for the specific conditions and try to match and add backrun transactions.

When the searcher is ready, they can call a `newMatch` or an equivalent function to merge their transaction with the initial transaction(s).

If all is well, the transaction will be submitted to whatever chain the initial user intended. The examples in this repository submit to an L1 via an RPC url.

### **Glossary**

-   SUAVE - Single Unifying Auction for Value Expression - is a platform for building MEV applications such as OFAs and block builders in a decentralized and private way [more info](https://suave.flashbots.net/what-is-suave)

-   SUAPPs - MEV applications

-   Confidential Data Store - A privacy-centric networked storage system specifically tailored to enable programmable privacy in SUAPPs [more info](https://suave.flashbots.net/technical/specs/rigil/confidential-data-store)

-   MEVM - Modified version of the EVM [more info](https://suave.flashbots.net/technical/specs/rigil/mevm)
-   SUAVE Kettle - contains all necessary components to accept, process, and route confidential compute requests and results [more info](https://suave.flashbots.net/technical/specs/rigil/kettle)
