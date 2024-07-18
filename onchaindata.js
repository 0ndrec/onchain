
const testnet_config_files = [
    'wardenprotocol.json',
    'crossfi.json',
    'allora.json',
];

const mainnet_config_files = [
    'cosmos.json',
    'osmosis.json',
    'nolus.json',
    'neutron.json',
];

const typeChains= ['testnet', 'mainnet'];
const chainsUrl = `https://raw.githubusercontent.com/0ndrec/explorer/master/chains/`;
const tendermintUrl = `/cosmos/base/tendermint/v1beta1/blocks/latest`;


async function fetchJSON(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
}
// Function who return dictionary values from json files for current network
async function getValues(chainsUrl, chainType, configFile) {
    const fileUrl = `${chainsUrl}${chainType}/${configFile}`;
    console.log(fileUrl)
    const jsonData = await fetchJSON(fileUrl);
    data = {
        name : jsonData.chain_name,
        rpc : jsonData.rpc[0],
        api : jsonData.api[0],
    }
    console.log(data)
    return data
}



async function generateDivs(configFiles, chainType, containerClassTarget) {
    for (config_f of configFiles) {
        const data = await getValues(chainsUrl, chainType, config_f);


        function selectEndpoint(endpoint) {
            if (typeof endpoint === 'string') {
                return endpoint
            } else {
                return endpoint.address;
            }
        }

        const ApiEndpoint = selectEndpoint(data.api);
        const RpcEndpoint = selectEndpoint(data.rpc);
        const ChainName = data.name;


        async function fetchBlockHeight() {
            try {
                const response = await fetch(`${ApiEndpoint}${tendermintUrl}`);
                const height_data = await response.json();
                return height_data.block.header.height;
            } catch (error) {
                return 'Loading...';
            }
        }

        blockHeight = await fetchBlockHeight();

        const div = document.createElement('div');

        if (chainType === 'testnet') {
            div.id = `${data.name}`;
            div.classList.add('testnet');
        }
        else {
            div.id = `${data.name}`;
            div.classList.add('mainnet');
        }

        // Convert ChainName to uppercase
        div.innerHTML = `
            <h3>${ChainName.toUpperCase()}</h3>
            <div class="block_height">
                <p class="title">Block Height</p>
                <p class="value">${blockHeight}</p>
            </div>
            <div class="endpoints">
                <div class="button" href="${ApiEndpoint}" target="_blank">
                    <a href="${ApiEndpoint}" target="_blank">API</a>
                </div>
                <div class="button" href="${RpcEndpoint}" target="_blank">
                    <a href="${RpcEndpoint}" target="_blank">RPC</a>
                </div>
            </div>
        `;

        document.querySelector(containerClassTarget).appendChild(div);
    }
}
