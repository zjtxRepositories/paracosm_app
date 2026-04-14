var config = {
    ethereum: {
        chainId: ${chainId},
        rpcUrl: `${rpcUrl}`
    },
    solana: {},
    aptos: {}
};

trustwallet.ethereum = new trustwallet.Provider(config);
trustwallet.solana = new trustwallet.SolanaProvider(config);
trustwallet.cosmos = new trustwallet.CosmosProvider(config);
trustwallet.aptos = new trustwallet.AptosProvider(config);

trustwallet.postMessage = (jsonString) => {
    if (window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('trust', jsonString);
    } else {
        window.flutter_inappwebview._callHandler(
            'trust',
            setTimeout(function () {
                // nothing to do
            }),
            JSON.stringify([
                jsonString,
            ]),
        );
    }
};

window.ethereum = trustwallet.ethereum;
window.keplr = trustwallet.cosmos;
window.aptos = trustwallet.aptos;

const getDefaultCosmosProvider = (chainId) => {
    return trustwallet.cosmos.getOfflineSigner(chainId);
}

window.getOfflineSigner = getDefaultCosmosProvider;
window.getOfflineSignerOnlyAmino = getDefaultCosmosProvider;
window.getOfflineSignerAuto = getDefaultCosmosProvider;

/// Camouflage Metamask
window.ethereum.isMetaMask = true;