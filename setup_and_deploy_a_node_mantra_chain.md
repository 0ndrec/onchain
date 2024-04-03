
# Setup and Deploy a Node | MANTRA Chain

## Setting up a generic node

### Update system & install prerequisites

```bash
sudo apt update
sudo apt upgrade
sudo apt install -y curl git jq lz4 build-essential unzip
bash <(curl -s "https://raw.githubusercontent.com/MANTRA-Finance/public/main/go_install.sh")
source .bash_profile
```

### Install binary

```bash
mkdir bin
cd bin
source ~/.profile
wget https://<Location to be provided>/mantrachaind-linux-amd64.zip
unzip mantrachaind-linux-amd64.zip
rm -rf mantrachaind-linux-amd64.zip
```

### Install cosmwasm library

More information can be found [here](https://github.com/CosmWasm/wasmvm).

```bash
sudo wget -P /usr/lib https://github.com/CosmWasm/wasmvm/releases/download/v1.3.0/libwasmvm.x86_64.so
```

### Initialise node

```bash
mantrachaind init <your-moniker> --chain-id mantrachain-testnet-1
```

where `<your-moniker>` is the moniker and can be any valid string name (e.g. val-01), and `mantrachain-testnet-1` is the Chain ID and must be exactly as specified.

### Download "genesis.json" - TESTNET

Obtain the MANTRA Chain `genesis.json` for the MANTRA Chain TESTNET.

```bash
curl -Ls https://<Location to be provided>/genesis.json > $HOME/.mantrachain/config/genesis.json
```

### Update the config.toml with the seed node and the peers for the MANTRA Chain TESTNET

```bash
CONFIG_TOML="$HOME/.mantrachain/config/config.toml"
SEEDS="69fa5f7927f2b013f152b6dfc56324156feb1973@34.172.80.207:26656"
PEERS="182a37a556ff0b6733fe58020e7746de3292492d@35.222.198.102:26656,64691a4202c1ad29a416b21ce21bfc9659783406@34.136.169.18:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $CONFIG_TOML
sed -i.bak -e "s/^seeds =.*/seeds = \"$SEEDS\"/" $CONFIG_TOML
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $CONFIG_TOML
sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0002uaum"|g' $CONFIG_TOML
sed -i 's|^prometheus *=.*|prometheus = true|' $CONFIG_TOML
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $CONFIG_TOML
```

### Install Cosmovisor

cosmovisor is a process manager for Cosmos SDK application binaries that automates application binary switch at chain upgrades.

```bash
go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@v1.4.0
mkdir -p ~/.mantrachain/cosmovisor/genesis/bin
mkdir -p ~/.mantrachain/cosmovisor/upgrades
cp ~/bin/mantrachaind ~/.mantrachain/cosmovisor/genesis/bin
```

### Configure "mantrachaind" as a Service

The systemd service manager allows the mantrachaind binary to run as a service, instead of as a command-line application. (See [systemd.io](https://systemd.io) for more information.)

```bash
sudo tee /etc/systemd/system/mantrachaind.service > /dev/null << EOF
[Unit]
Description=Mantra Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which cosmovisor) run start
Restart=on-failure
RestartSec=3
LimitNOFILE=10000
Environment="DAEMON_NAME=mantrachaind"
Environment="DAEMON_HOME=$HOME/.mantrachain"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
[Install]
WantedBy=multi-user.target
EOF
```

### Starting, stopping, and restarting service

```bash
#reload, enable and start
sudo systemctl daemon-reload
sudo systemctl enable mantrachaind
sudo systemctl start mantrachaind
#stop
sudo systemctl stop mantrachaind

#restart
sudo systemctl restart mantrachaind
#logs
sudo journalctl -xefu mantrachaind

#logs - filtered on block height lines
sudo journalctl -xefu mantrachaind -g ".*txindex"
```

Once started, the node will take some time to sync with the blockchain. 

Visit [explorer.testnet.mantrachain.io/mantrachain](https://explorer.testnet.mantrachain.io/mantrachain) to see the current height of the blockchain. Use the `journalctl` command to check on the node's progress.
