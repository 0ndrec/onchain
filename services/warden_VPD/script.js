
const API_BASE_URL = "https://api.chiado.wardenprotocol.org";
const validatorsContainer = document.getElementById('validators-container');
const blockHeightDisplay = document.getElementById('current-block-height');
const qValidatorsDisplay = document.getElementById('current-q-validators');

async function fetchBlockHeight() {
    const response = await fetch(`${API_BASE_URL}/cosmos/base/node/v1beta1/status`);
    const data = await response.json();
    return data.height;
}

async function fetchValidators() {
    const blockHeight = await fetchBlockHeight();
    blockHeightDisplay.textContent = blockHeight;

    const response = await fetch(`${API_BASE_URL}/cosmos/staking/v1beta1/validators?pagination.limit=900&status=BOND_STATUS_BONDED`);
    const data = await response.json();
    qValidatorsDisplay.textContent = data.validators.length;
    return data.validators;
}

async function fetchVotingPower(blockHeight) {
    const response = await fetch(`${API_BASE_URL}/cosmos/base/tendermint/v1beta1/validatorsets/${blockHeight}?pagination.limit=900`);
    const data = await response.json();
    return data.validators;
}


async function fetchBondedTokensValue() {
    const response = await fetch(`${API_BASE_URL}/cosmos/staking/v1beta1/pool`);
    const data = await response.json();
    return data.pool.bonded_tokens;
}


// Preloader text
function displayLoadingPopup(isShow) {

    const loadingPopup = document.createElement('div');
    loadingPopup.id = 'loading-popup';
    loadingPopup.textContent = 'LOADING';
    loadingPopup.style.position = 'fixed';
    loadingPopup.style.top = '50%';
    loadingPopup.style.left = '50%';
    loadingPopup.style.transform = 'translate(-50%, -50%)';
    loadingPopup.style.opacity = '0.3';
    loadingPopup.style.fontSize = '7vw';
    loadingPopup.style.color = 'white';

    if (isShow) {
        document.body.appendChild(loadingPopup);
    } else {
        const loadingPopupElement = document.getElementById('loading-popup');
        if (loadingPopupElement) {
            document.body.removeChild(loadingPopupElement);
        }
    }
}

/**
 * Display the list of validators on the page.
 * Fetches the validators, block height, and voting powers,
 * then creates and appends div elements to display the information.
 */
async function displayValidators() {
    // Fetch the validators, block height, and voting powers
    displayLoadingPopup(true);
    const validators = await fetchValidators();
    const blockHeight = await fetchBlockHeight();
    const votingPowers = await fetchVotingPower(blockHeight);

    displayLoadingPopup(false);


    // Sort the validators by voting power in descending order
    const sortedValidators = validators.slice().sort((a, b) => {
        const ap = votingPowers.find(vp => vp.pub_key.key === a.consensus_pubkey.key)?.voting_power || 0;
        const bp = votingPowers.find(vp => vp.pub_key.key === b.consensus_pubkey.key)?.voting_power || 0;
        return bp - ap;
    });

    // Calculate the width of each validator block
    const gapBetweenBlocks = 10;

    // Set 100 percent value bonded tokens for next calculation.
    const totalBondedTokens = await fetchBondedTokensValue();

    // Loop through each validator and create a div element
    sortedValidators.forEach((validator, index) => {
        // Find the voting power for this validator
        const power = votingPowers.find(vp => vp.pub_key.key === validator.consensus_pubkey.key);

        // Create div elements for the validator and voting power
        const validatorDiv = document.createElement('a');
        validatorDiv.className = 'validator-block';
        validatorDiv.href = validator.description.website;
        validatorDiv.target = '_blank';

        const validatorText = document.createElement('div');
        validatorText.className = 'validator-text';
        validatorText.textContent = validator.description.moniker;

        const validatorPercent = document.createElement('div');
        validatorPercent.className = 'validator-percent';

        // Calculate the percentage of bonded tokens that this validator has.
        const bondedTokensPercentage = (validator.tokens / totalBondedTokens) * 100;
        const bondedTokensPercentageRounded = bondedTokensPercentage.toFixed(2);
        validatorPercent.textContent = `${bondedTokensPercentageRounded}%`;

        // Append the validator percent to the validator text
        validatorDiv.appendChild(validatorPercent);

        // Append the validator text to the validator div
        validatorDiv.appendChild(validatorText);

        // Append the validator div to the container
        validatorsContainer.appendChild(validatorDiv);
    });

    displayLoadingPopup(false);
}

document.addEventListener('DOMContentLoaded', displayValidators);

