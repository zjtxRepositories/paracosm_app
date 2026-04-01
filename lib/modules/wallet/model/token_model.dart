import 'package:get/get_navigation/src/root/parse_route.dart';
import 'package:paracosm/core/util/string_util.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/chains/model/coin_market_model.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';

class TokenModel {

  String symbol;        // ETH / USDT
  String name;          // Ethereum
  String address;       // 合约地址（主链为空）
  BigInt balance;       // 余额（字符串防精度丢失）
  int decimals;         // 精度
  String logo;
  String coinId;
  int chainId;
  bool? isAdded;
  CoinMarketModel? market;
  double price;


  TokenModel({
    required this.symbol,
    required this.name,
    required this.address,
    required this.balance,
    required this.decimals,
    required this.logo,
    required this.coinId,
    required this.chainId,
    this.isAdded,
    this.market,
    this.price = 0,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      symbol: json["symbol"] ?? "",
      name: json["name"] ?? "",
      address: json["address"] ?? "",
        balance: json["balance"] != null
            ? BigInt.parse(json["balance"].toString())
            : BigInt.zero,
      decimals: json["decimals"] ?? 18,
      logo: json["logo"] ?? "",
      coinId: json["coinId"] ?? "",
      chainId: json["chainId"] ?? 1,
      isAdded: json["isAdded"],
      market:json["market"] != null ? CoinMarketModel.fromJson(json["market"]) : null,
      price:json["price"],

    );
  }

  Map<String, dynamic> toJson() {
    return {
      "symbol": symbol,
      "name": name,
      "address": address,
      "balance": balance.toString(),
      "decimals": decimals,
      "logo": logo,
      "coinId": coinId,
      "chainId": chainId,
      "isAdded": isAdded,
      "market": market?.toJson(),
      "price": price,
    };
  }

  ChainAccount? getChain(){
    final chains = AccountManager().currentWallet?.chains ?? [];
    if (chains.isEmpty) return null;
    final chain = chains.firstWhereOrNull(
          (c) => c.chainId == chainId,
    );
    return chain;
  }


  String get showBalance => displayBalance;
  String get showUsdValue => truncateDouble(usdValue);

  double formatBalance() {
    final divisor = BigInt.from(10).pow(decimals);
    return balance / divisor;
  }

  String get displayBalance {
    final divisor = BigInt.from(10).pow(decimals);

    final integer = balance ~/ divisor;
    final decimal = balance % divisor;

    String decimalStr = decimal.toString().padLeft(decimals, '0');
    decimalStr = decimalStr.replaceFirst(RegExp(r'0+$'), '');

    if (decimalStr.isEmpty) return integer.toString();

    return "$integer.$decimalStr";
  }

  double get usdValue {
    final divisor = BigInt.from(10).pow(decimals);
    final amount = balance / divisor;
    return amount * price;
  }
}