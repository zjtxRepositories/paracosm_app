
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/account/manager/account_manager.dart';
import 'package:paracosm/modules/wallet/chains/btc/bitcoin_search_token_info.dart';
import 'package:paracosm/modules/wallet/chains/evm/evm_facade.dart';
import 'package:paracosm/modules/wallet/manager/wallet_manager.dart';
import 'package:paracosm/modules/wallet/model/chain_account.dart';
import 'package:paracosm/modules/wallet/model/token_model.dart';
import 'package:paracosm/modules/wallet/model/wallet_model.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/base/app_localizations.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_network_image.dart';
import '../../widgets/modals/wallet_modals.dart';
import '../../widgets/modals/wallet_protocol_modal.dart';

class AddTokenManagerPage extends StatefulWidget {
  const AddTokenManagerPage(
      {super.key});

  @override
  State<AddTokenManagerPage> createState() => _AddTokenManagerPageState();

  void clear() {}
}

class _AddTokenManagerPageState extends State<AddTokenManagerPage> {
  WalletModel? wallet = AccountManager().currentWallet;
  late ChainAccount chain;
  bool _isEnabled = false;
  final TextEditingController addressTextEditingController = TextEditingController();
  final TextEditingController symbolTextEditingController = TextEditingController();
  final TextEditingController decimalsTextEditingController = TextEditingController();
  ProtocolType? _protocolType;
  TokenModel? _token;
  String _address = '';
  String _keyword = '';
  List<TokenModel>? _btcTokens;
  bool _searchError = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    chain = wallet!.currentChain!;
    _focusNode.addListener(() {
      setState(() {});
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).unfocus();
        loadingToken();
      }
    });

  }

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
  }

  void clear() {
    addressTextEditingController.text = "";
    symbolTextEditingController.text = "";
    decimalsTextEditingController.text = "";
    _isEnabled = false;
    _protocolType = null;
    _token = null;
    _address = '';
    _keyword = '';
    _btcTokens = null;
  }

  void loadingToken(){
    if (chain.chainType == ChainType.bitcoin){
      searchBTCAsset();
    }else{
      getToken();
    }
  }

  Future<void> getToken() async {
    EasyLoading.show();
    final address = addressTextEditingController.text;
    final isAddress = await EvmFacade.isContractAddress(chain,address);
    if (!isAddress){
      _searchError = true;
      _token = null;
      EasyLoading.dismiss();
      setState(() {});
      return;
    }
    final result = await EvmFacade.getTokenInfo(chain, address);
    if (result == null){
      _searchError = true;
      EasyLoading.dismiss();
      setState(() {});
      return;
    }
    EasyLoading.dismiss();
    _searchError = false;
    symbolTextEditingController.text = result.symbol;
    decimalsTextEditingController.text = result.decimals.toString();
    setState(() {
      _token = result;
      _isEnabled = true;
    });
  }

  Future<void> addToken() async {
    if (_token == null) return;
    EasyLoading.show();
    await WalletManager.addToken(wallet!.id,_token!);
    EasyLoading.dismiss();
    EasyLoading.showToast('添加成功');
    context.pop();
  }

  void searchBTCAsset() async {
    if (_protocolType == null || _keyword.isEmpty) return;
    final result = await BitcoinSearchTokenInfo.searchBTCAsset(_protocolType!,_keyword);
    setState(() {
      _btcTokens = result;
      _isEnabled = _protocolType != null
          && (_btcTokens ?? []).isNotEmpty
          && symbolTextEditingController.text.isNotEmpty;
    });
  }

  void addBTCAsset() async {
    if ((_btcTokens ?? []).isEmpty)return;
    for (final token in _btcTokens!) {
      await WalletManager.addToken(wallet!.id,token);
    }
    EasyLoading.showToast('添加成功');
    context.pop();

  }
  /// 显示网络选择弹窗
  void _showNetworkSelector() {
    if (wallet == null) return;
    WalletModals.showNetworkSelector(
        context: context,
        wallet: wallet!,
        onSelected: (network) {
          setState(() {
            chain = network;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: AppPage(
        title: '自定义币种',
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 16.h),
                      _buildChooseChain(),
                      SizedBox(height: 24.h),
                      ...(chain.chainType == ChainType.bitcoin
                          ? _buildBTC()
                          : _buildOther()),
                    ],
                  ),
                ),
              ),
              AppButton(
                text: AppLocalizations.of(context)!.commonConfirm,
                onPressed: _isEnabled ? () {
                  if (chain.chainType == ChainType.bitcoin){
                    addBTCAsset();
                    return;
                  }
                  addToken();
                } : null,
                backgroundColor: _isEnabled ? AppColors.grey900 : AppColors.grey900,
                textColor: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
  List<Widget> _buildBTC() {
    return [
      _buildProtocol(),
      SizedBox(height: 24.h),
      _buildInput('币种名称', symbolTextEditingController),
      SizedBox(height: 24.h),
    ];
  }

  List<Widget> _buildOther() {
    return [
      _buildInput('请输入正确的合约地址', addressTextEditingController),
      SizedBox(height: 24.h),
      _buildInput('符号', symbolTextEditingController),
      SizedBox(height: 24.h),
      _buildInput('小数位', decimalsTextEditingController,keyboardType: TextInputType.number),
    ];
  }

  Widget _buildChooseChain() {
    return  GestureDetector(
      onTap: _showNetworkSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            AppNetworkImage(
              url: chain.logo,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 4),
            Text(
              chain.name,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocol() {
    return GestureDetector(
      onTap: (){
        WalletProtocolModal.show(
          context: context,
          onConfirm: (protocolType) {
            setState(() {
              _protocolType = protocolType;
            });
            loadingToken();
          },
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('协议',style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey900,
          )),
          SizedBox(height: 12.h),
          Container(
              height: 52.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color:AppColors.grey200,
                  width: 1,
                ),
              ),
              child:Padding(padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _protocolType == null ?
                      Text('请选择协议',style:AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      ))
                          :Text(_protocolType!.text,style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey900,
                      )),
                      const Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.grey400),
                    ],
                  )

              )
          )
        ],
      )
    );
  }

  Widget _buildInput(String title,TextEditingController? textEditingController,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.grey900,
        )),
        SizedBox(height: 12.h),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
    focusNode: textEditingController == addressTextEditingController ? _focusNode : null,
    controller: textEditingController,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '请输入$title'
            ),
            style: AppTextStyles.body.copyWith(
              color: AppColors.grey900,
              fontWeight: FontWeight.w500,
            ),
            readOnly: _token != null,
            keyboardType: keyboardType ?? TextInputType.text,
            maxLines: 2,
            onChanged: (String text) {
              if (chain.chainType == ChainType.bitcoin){
                _isEnabled = _protocolType != null
                    && (_btcTokens ?? []).isNotEmpty
                    && symbolTextEditingController.text.isNotEmpty;
                if (_keyword != symbolTextEditingController.text){
                  _keyword = symbolTextEditingController.text;
                }
                return;
              }else {
                _isEnabled = addressTextEditingController.text.isNotEmpty
                    && symbolTextEditingController.text.isNotEmpty
                    && decimalsTextEditingController.text.isNotEmpty;
                _searchError = false;
                if(textEditingController == addressTextEditingController){
                  if (addressTextEditingController.text != _address){
                    _address = addressTextEditingController.text;
                  }
                }
              }
              setState(() {});
            },
          ),
        ),
        ... chain.chainType == ChainType.bitcoin ? _buildError('未找到该币种',!_isEnabled && textEditingController == symbolTextEditingController && symbolTextEditingController.text.isNotEmpty)
            : _buildError('请输入正确的合约地址',
            _searchError == true && textEditingController == addressTextEditingController && addressTextEditingController.text.isNotEmpty)
      ],
    );
  }

  List<Widget> _buildError(String text,bool show) {
    if (!show){
      return [];
    }
    return [
      SizedBox(height: 12.h),
      Text(text,style: AppTextStyles.body.copyWith(
        fontSize: 14,
        color: AppColors.error,
        fontWeight: FontWeight.w600,
      )),
    ];
  }
}

