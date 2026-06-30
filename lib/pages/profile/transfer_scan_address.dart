import 'package:paracosm/modules/scan/scan_result_parser.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';

class TransferScanPrefill {
  final String address;
  final String? amount;
  final String? tokenSymbol;
  final String? chain;

  const TransferScanPrefill({
    required this.address,
    this.amount,
    this.tokenSymbol,
    this.chain,
  });
}

class TransferScanAssetMatch {
  final ChainAccount? chain;
  final TokenModel? token;

  const TransferScanAssetMatch({this.chain, this.token});
}

String? extractTransferAddressFromScan(String raw) {
  return extractTransferPrefillFromScan(raw)?.address;
}

TransferScanPrefill? extractTransferPrefillFromScan(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }

  final result = ScanResultParser.parse(text);
  switch (result.type) {
    case ScanResultType.walletPayment:
      final address = result.address?.trim();
      if (address == null || address.isEmpty) {
        return null;
      }
      return TransferScanPrefill(
        address: address,
        amount: _blankToNull(result.amount),
        tokenSymbol: _blankToNull(result.tokenSymbol),
        chain: _blankToNull(result.chain),
      );
    case ScanResultType.unknown:
      return TransferScanPrefill(address: text);
    case ScanResultType.invite:
    case ScanResultType.webUrl:
    case ScanResultType.friend:
    case ScanResultType.group:
      return null;
  }
}

TransferScanAssetMatch matchTransferScanAsset(
  WalletModel wallet,
  TransferScanPrefill prefill,
) {
  final chain =
      findTransferScanChain(wallet, prefill.chain) ??
      _currentWalletChain(wallet) ??
      (wallet.chains.isNotEmpty ? wallet.chains.first : null);
  final token = chain == null
      ? null
      : findTransferScanToken(chain, prefill.tokenSymbol) ??
            _nativeTokenOfChain(chain);
  return TransferScanAssetMatch(chain: chain, token: token);
}

ChainAccount? findTransferScanChain(WalletModel wallet, String? chainValue) {
  final normalized = _normalize(chainValue);
  if (normalized.isEmpty) {
    return null;
  }

  final chainId = int.tryParse(normalized);
  for (final chain in wallet.chains) {
    if (chainId != null && chain.chainId == chainId) {
      return chain;
    }
    if (_normalize(chain.name) == normalized ||
        _normalize(chain.symbol) == normalized) {
      return chain;
    }
  }
  return null;
}

TokenModel? findTransferScanToken(ChainAccount chain, String? tokenSymbol) {
  final normalized = _normalize(tokenSymbol);
  if (normalized.isEmpty) {
    return null;
  }

  for (final token in chain.tokens) {
    if (_normalize(token.symbol) == normalized) {
      return token;
    }
  }
  return null;
}

ChainAccount? _currentWalletChain(WalletModel wallet) {
  for (final chain in wallet.chains) {
    if (chain.chainId == wallet.currentChainId) {
      return chain;
    }
  }
  return null;
}

TokenModel? _nativeTokenOfChain(ChainAccount chain) {
  for (final token in chain.tokens) {
    if (token.address.isEmpty) {
      return token;
    }
  }
  return null;
}

String? _blankToNull(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}

String _normalize(String? value) {
  final text = value?.trim().toLowerCase();
  if (text == null || text.isEmpty) {
    return '';
  }
  return text;
}
