import '../../modules/wallet/chains/model/gas_fee.dart';

class DAppConnectDecision {
  final bool approved;
  final bool remember;

  const DAppConnectDecision({required this.approved, required this.remember});
}

class DappTransactionDecision {
  final bool approved;
  final GasFee? gasFee;

  const DappTransactionDecision({required this.approved, this.gasFee});
}
