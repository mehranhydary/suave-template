# suave-template

### **A template for writing SUAVE contracts with Foundry**

[`Use this template`](https://github.com/mehranhydary/suave-template/generate)

1. This template it built using Foundry
2. The template has `suave-geth` already installed and a few example SUAVE applications

### **Setting up the repository**

1. Create a template from this repository
2. Run `forge-install`
3. Review or remove the examples in this repository and start coding!

### **Deploying your contract to Rigil Testnet**

You can use Forge to deploy contracts to SUAVE.

1. Replace all `SuaveForge.sol` imports with `Suave.sol`.
2. Get Rigil ETH from the [faucet](https://faucet.rigil.suave.flashbots.net/).
3. Create a `.env` file in the root of this folder as follows.

```
RPC_URL=https://rpc.rigil.suave.flashbots.net
PK=ADD_YOUR_PRIVATE_KEY_HERE
```

4. Upon saving it, return to your terminal and run `source .env`. There's an example (`.env.example`) that you can copy and use in the root folder of this repository.
5. Now you can use your `.env` variables in your terminal. Run the following command to deploy your contracts

```
  forge create --rpc-url $RPC_URL --legacy --private-key $PK src/examples/basic/OnlyConfidential.sol:OnlyConfidential
```

# Todo:

1. Add instructions on running a local testnet
2. Add more examples
3. Anvil x Rigil Testnet - does it work!?
4. Multi-chain communications
