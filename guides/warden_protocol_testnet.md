
**Step-by-Step Tutorial for Setting Up a Validator on Warden Protocol's Alfama Testnet**

**Part 1. Preparing an Environment: Update Packages**

Before diving into the specifics of joining the Alfama testnet or creating a validator, it's crucial to prepare your environment, particularly if you are using a remote Ubuntu server. The first step is to update the package lists for upgrades for packages that need upgrading, as well as new package versions.

- Open your terminal and connect to your remote Ubuntu server.
- Run the following commands:
  ```bash
  sudo apt update       # Fetches the list of available updates
  sudo apt upgrade -y   # Installs some updates; -y flag means "yes" to prompts
  ```

**Part 2. Joining the Alfama Testnet**

1. **Hardware Recommendations**: Ensure your machine has at least 8 cores, 32GB of RAM, and 300GB of disk space for running public testnet nodes efficiently.

2. **Build Tools Installation**:
   - Install Go by following the instructions on the [official Go website](https://golang.org/doc/install).

3. **Installation & Configuration**:
   - Install and configure the Warden binary. Start by cloning the Warden Protocol repository and building the `wardend` binary. Initialize the chain home folder with your custom moniker and prepare the genesis file.
   ```bash
   git clone --depth 1 --branch v0.1.0 https://github.com/warden-protocol/wardenprotocol/
   cd wardenprotocol/warden/cmd/wardend
   go build
   sudo mv wardend /usr/local/bin/
   wardend init <custom_moniker>
   ```
   Prepare the genesis file by downloading it to the correct directory and setting up the minimum gas prices and peers.

4. **(Optional) Setup State Sync**:
   - To speed up the initial sync, consider using the state sync feature by setting up a list of trusted RPC endpoints, a trusted block height, and its corresponding block hash.

5. **Start the Node**:
   - Start your node with the `wardend start` command, connecting to the persistent peers and beginning to download blocks.

**Part 3. Creating a Validator**

1. **Prerequisites**: Ensure you have set up a full node and synchronized it to the latest block height following the instructions in Part 2.

2. **Create or Restore a Local Wallet Key Pair**:
   - Generate a new key pair for your validator or restore an existing wallet. Securely store the seed phrase provided.

3. **Get Testnet WARD**:
   - Obtain testnet WARD tokens from the faucet to fund your new address. This is necessary for submitting transactions, including the one to create your validator.

4. **Create a New Validator**:
   - Create a validator by submitting a `create-validator` transaction. This requires setting up a `validator.json` file with your validator's public key, moniker, and other details. Finally, submit the transaction with the `wardend tx staking create-validator` command.

5. **Backup Critical Files**:
   - It's crucial to backup certain files like `priv_validator_key.json` and `node_key.json` to ensure you can restore your validator if needed.

6. **Confirm Your Validator is in the Active Set**:
   - Verify if your validator has been successfully added to the active set by checking the validator set for your validator's address.
