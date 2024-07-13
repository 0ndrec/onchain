// Function to fetch JSON data from a remote storage
async function fetchJSON(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.json();
}

// Function to retrieve the API endpoint from JSON files
async function getApiEndpoint(repoUrl, files) {
    for (const file of files) {
        try {
            const jsonData = await fetchJSON(repoUrl + file);
            if (jsonData && jsonData.api && jsonData.api.length > 0) {
                return jsonData.api[0];
            }
        } catch (error) {
            console.error('Error fetching JSON:', error);
            continue;
        }
    }
    throw new Error('API endpoint not found in any file.');
}

// Function to display information about the latest block
async function displayLatestBlock(networkType, networkName) {
    try {
        const repoUrl = `https://raw.githubusercontent.com/0ndrec/explorer/master/chains/${networkType}/`;
        const files = [`${networkName}.json`];
        const apiEndpoint = await getApiEndpoint(repoUrl, files);
        const url = `${apiEndpoint}/cosmos/base/tendermint/v1beta1/blocks/latest`;
        return await fetchJSON(url);
    } catch (error) {
        console.error('Error fetching JSON:', error);
    }
}

// Main execution
(async () => {
    try {
        const blockData = await displayLatestBlock('testnet', 'wardenprotocol');
        if (blockData) {
            document.getElementById('chain_id').textContent = blockData.block.header.chain_id;
            document.getElementById('block_height').textContent = blockData.block.header.height;
        }
    } catch (error) {
        console.error('Error displaying block data:', error);
    }
})();
