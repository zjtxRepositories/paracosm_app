import 'app_localizations.dart';

/// AppLocalizations 的快捷访问扩展
///
/// 将所有的翻译 Key 放在这里管理，实现配置与管理逻辑分离。
extension AppLocalizationsKeys on AppLocalizations {
  // --- 通用 ---
  String get commonConfirm => translate('common_confirm');
  String get commonContinue => translate('common_continue');
  String get commonNext => translate('common_next');
  String get commonCopy => translate('common_copy');
  String get commonCopied => translate('common_copied');
  String get commonRiskTips => translate('common_risk_tips');

  // --- 钱包启动页 ---
  String get walletStartWelcome => translate('wallet_start_welcome');
  String get walletStartTo => translate('wallet_start_to');
  String get walletStartWorld => translate('wallet_start_world');

  // --- 钱包设置页 ---
  String get walletSetupCreateTitle => translate('wallet_setup_create_title');
  String get walletSetupCreateSubtitle =>
      translate('wallet_setup_create_subtitle');
  String get walletSetupImportTitle => translate('wallet_setup_import_title');
  String get walletSetupImportSubtitle =>
      translate('wallet_setup_import_subtitle');
  String get walletSetupAgree => translate('wallet_setup_agree');
  String get walletSetupTerms => translate('wallet_setup_terms');
  String get walletSetupAnd => translate('wallet_setup_and');
  String get walletSetupPrivacy => translate('wallet_setup_privacy');

  // --- 钱包相关通用 ---
  String get walletCreateTitle => translate('wallet_create_title');
  String get walletCreateNew => translate('wallet_create_new');
  String get walletSetupTitle => translate('wallet_setup_title');
  String get walletStep1Title => translate('wallet_step_1_title');
  String get walletStep1Subtitle => translate('wallet_step_1_subtitle');
  String get walletStep1LabelPwd => translate('wallet_step_1_label_pwd');
  String get walletStep1HintPwd => translate('wallet_step_1_hint_pwd');
  String get walletStep1LabelConfirmPwd =>
      translate('wallet_step_1_label_confirm_pwd');
  String get walletStep1HintConfirmPwd =>
      translate('wallet_step_1_hint_confirm_pwd');
  String get walletStep2Title => translate('wallet_step_2_title');
  String get walletStep2Subtitle => translate('wallet_step_2_subtitle');
  String get walletStep2RiskDialog => translate('wallet_step_2_risk_dialog');
  String get walletStep2IHaveBackedUp =>
      translate('wallet_step_2_i_have_backed_up');
  String get walletStep3Title => translate('wallet_step_3_title');
  String get walletStep3Subtitle => translate('wallet_step_3_subtitle');
  String get walletStep3SelectHint => translate('wallet_step_3_select_hint');
  String get walletCreatingTitle => translate('wallet_creating_title');
  String get walletCreatingTip => translate('wallet_creating_tip');
  String get walletCreatingStarNetwork =>
      translate('wallet_creating_star_network');
  String get walletCreateSuccess => translate('wallet_create_success');

  // --- 钱包导入页 ---
  String get walletImportTitle => translate('wallet_import_title');
  String get walletImportSubtitle => translate('wallet_import_subtitle');
  String get walletImportMnemonic => translate('wallet_import_mnemonic');
  String get walletImportPrivateKey => translate('wallet_import_private_key');
  String get walletImportMnemonicHint =>
      translate('wallet_import_mnemonic_hint');
  String get walletImportPrivateKeyHint =>
      translate('wallet_import_private_key_hint');
  String get walletImportPaste => translate('wallet_import_paste');
  String get walletImportMnemonicTip => translate('wallet_import_mnemonic_tip');
  String get walletImportCloud => translate('wallet_import_cloud');
  String get walletImportAction => translate('wallet_import_action');
  String get walletImportMnemonicNotEnglish =>
      translate('wallet_import_mnemonic_not_english');
  String get walletImportMnemonicWordCountError =>
      translate('wallet_import_mnemonic_word_count_error');
  String get walletImportPrivateKeyInvalidError =>
      translate('wallet_import_private_key_invalid_error');
  String get walletImportHowToFind => translate('wallet_import_how_to_find');

  // --- 钱包备份相关 ---
  String get walletBackupTipsTitle => translate('wallet_backup_tips_title');
  String get walletBackupTipsMnemonicIdentity =>
      translate('wallet_backup_tips_mnemonic_identity');
  String get walletBackupTipsMnemonicRule1 =>
      translate('wallet_backup_tips_mnemonic_rule1');
  String get walletBackupTipsMnemonicRule2 =>
      translate('wallet_backup_tips_mnemonic_rule2');
  String get walletBackupTipsRisk1 => translate('wallet_backup_tips_risk1');
  String get walletBackupTipsRisk2 => translate('wallet_backup_tips_risk2');
  String get walletBackupTipsRisk3 => translate('wallet_backup_tips_risk3');
  String get walletBackupRiskTitle => translate('wallet_backup_risk_title');
  String get walletBackupPrivTitle => translate('wallet_backup_priv_title');
  String get walletBackupPrivSubtitle =>
      translate('wallet_backup_priv_subtitle');
  String get walletBackupPrivShareTip =>
      translate('wallet_backup_priv_share_tip');
  String get walletBackupPrivPart1 => translate('wallet_backup_priv_part1');
  String get walletBackupPrivPart2 => translate('wallet_backup_priv_part2');
  String get walletBackupRiskDialogTitle =>
      translate('wallet_backup_risk_dialog_title');
  String get walletBackupRiskDialogDesc =>
      translate('wallet_backup_risk_dialog_desc');
  String get walletBackupRiskDialogCancel =>
      translate('wallet_backup_risk_dialog_cancel');
  String get walletBackupRiskDialogConfirm =>
      translate('wallet_backup_risk_dialog_confirm');

  // --- 聊天相关 ---
  String get chatTitle => translate('chat_title');
  String get chatContacts => translate('chat_contacts');
  String get chatSearchHint => translate('chat_search_hint');
  String get chatFriendRequest => translate('chat_friend_request');
  String chatFriendRequestCount(int count) => translate(
    'chat_friend_request_count',
  ).replaceAll('{count}', count.toString());
  String get chatGroup => translate('chat_group');
  String chatGroupManageCount(int count) => translate(
    'chat_group_manage_count',
  ).replaceAll('{count}', count.toString());
  String get chatFilterAll => translate('chat_filter_all');
  String chatFilterAllCount(int count) => translate(
    'chat_filter_all_count',
  ).replaceAll('{count}', count.toString());
  String get chatFilterMessage => translate('chat_filter_message');
  String chatFilterMessageCount(int count) => translate(
    'chat_filter_message_count',
  ).replaceAll('{count}', count.toString());
  String get chatFilterDao => translate('chat_filter_dao');
  String chatFilterDaoCount(int count) => translate(
    'chat_filter_dao_count',
  ).replaceAll('{count}', count.toString());
  String get chatFilterClub => translate('chat_filter_club');
  String chatFilterClubCount(int count) => translate(
    'chat_filter_club_count',
  ).replaceAll('{count}', count.toString());
  String get chatFilterOthers => translate('chat_filter_others');
  String get chatYesterday => translate('chat_yesterday');
  String get chatStarFriend => translate('chat_star_friend');
  String get chatNotificationTitle => translate('chat_notification_title');
  String get chatImage => translate('chat_image');
  String get chatVoice => translate('chat_voice');
  String get chatRequestNew => translate('chat_request_new');
  String get chatRequestProcessed => translate('chat_request_processed');
  String get chatRequestAgree => translate('chat_request_agree');
  String get chatRequestReject => translate('chat_request_reject');
  String get chatRequestSure => translate('chat_request_sure');
  String get chatRequestCancel => translate('chat_request_cancel');
  String get chatRequestHint => translate('chat_request_hint');
  String get chatRequestRejectConfirm =>
      translate('chat_request_reject_confirm');
  String get chatRequestStatusAdded => translate('chat_request_status_added');
  String get chatRequestStatusExpired =>
      translate('chat_request_status_expired');
  String get chatRequestStatusRejected =>
      translate('chat_request_status_rejected');
  String get chatProfileMessage => translate('chat_profile_message');
  String get chatProfileCall => translate('chat_profile_call');
  String get chatProfileVideo => translate('chat_profile_video');
  String get chatProfileMoment => translate('chat_profile_moment');
  String get chatProfileSetNote => translate('chat_profile_set_note');
  String get chatProfileAddBlacklist => translate('chat_profile_add_blacklist');
  String get chatProfileAddFriend => translate('chat_profile_add_friend');
  String get chatProfileDelete => translate('chat_profile_delete');
  String get chatProfileSave => translate('chat_profile_save');
  String get chatProfileAddFriendPlaceholder =>
      translate('chat_profile_add_friend_placeholder');

  // --- 聊天设置 ---
  String get chatSettingTitle => translate('chat_setting_title');
  String get chatSettingClearHistory => translate('chat_setting_clear_history');
  String get chatSettingClearConfirm => translate('chat_setting_clear_confirm');
  String get chatSettingGroupInfo => translate('chat_setting_group_info');
  String get chatSettingIntroduction => translate('chat_setting_introduction');
  String get chatSettingIntroEmpty => translate('chat_setting_intro_empty');
  String get chatSettingNotice => translate('chat_setting_notice');
  String get chatSettingSearchHistory =>
      translate('chat_setting_search_history');
  String get chatSettingPin => translate('chat_setting_pin');
  String get chatSettingMuteAll => translate('chat_setting_mute_all');
  String get chatSettingDisband => translate('chat_setting_disband');
  String get chatSettingLeave => translate('chat_setting_leave');
  String chatSettingViewMore(int count) => translate(
    'chat_setting_view_more',
  ).replaceAll('{count}', count.toString());

  // --- 聊天详情 ---
  String get chatDetailAlbum => translate('chat_detail_album');
  String get chatDetailCamera => translate('chat_detail_camera');
  String get chatDetailVideoCall => translate('chat_detail_video_call');
  String get chatDetailAudioCall => translate('chat_detail_audio_call');
  String get chatDetailRedPacket => translate('chat_detail_red_packet');
  String get chatDetailFile => translate('chat_detail_file');
  String get chatDetailActive => translate('chat_detail_active');
  String get chatDetailCanceled => translate('chat_detail_canceled');
  String chatDetailCallDuration(String duration) =>
      translate('chat_detail_call_duration').replaceAll('{duration}', duration);
  String chatDetailReceivedRedPacket(String name) =>
      translate('chat_detail_received_red_packet').replaceAll('{name}', name);
  String get chatDetailWithdrewMessage =>
      translate('chat_detail_withdrew_message');
  String get chatDetailReleaseToCancel =>
      translate('chat_detail_release_to_cancel');
  String get chatDetailReleaseToEnd => translate('chat_detail_release_to_end');
  String get chatDetailHoldToTalk => translate('chat_detail_hold_to_talk');
  String get chatDetailRecordCanceled =>
      translate('chat_detail_record_canceled');
  String get chatDetailContactCard => translate('chat_detail_contact_card');

  // --- 聊天搜索 ---
  String get chatSearchCancel => translate('chat_search_cancel');
  String get chatSearchSpecific => translate('chat_search_specific');
  String get chatSearchUser => translate('chat_search_user');
  String get chatSearchGroup => translate('chat_search_group');
  String get chatSearchMessage => translate('chat_search_message');
  String get chatSearchBrowser => translate('chat_search_browser');
  String get chatSearchHistory => translate('chat_search_history');
  String get chatSearchNoRecent => translate('chat_search_no_recent');
  String get chatSearchNoData => translate('chat_search_no_data');

  // --- 聊天组信息 ---
  String get chatGroupInfoTitle => translate('chat_group_info_title');
  String get chatGroupInfoName => translate('chat_group_info_name');
  String get chatGroupInfoNote => translate('chat_group_info_note');
  String get chatGroupInfoHint => translate('chat_group_info_hint');

  // --- 会话详情 ---
  String get sessionDetailsTitle => translate('session_details_title');
  String get sessionDetailsReport => translate('session_details_report');
  String get sessionDetailsBurnTitle => translate('session_details_burn_title');
  String get sessionDetailsBurnClose => translate('session_details_burn_close');
  String get sessionDetailsBurn10s => translate('session_details_burn_10s');
  String get sessionDetailsBurn1m => translate('session_details_burn_1m');
  String get sessionDetailsBurn5m => translate('session_details_burn_5m');
  String get sessionDetailsBurn10m => translate('session_details_burn_10m');
  String get sessionDetailsBurn30m => translate('session_details_burn_30m');

  // --- 社区菜单 ---
  String get communityMenuCreateGroup =>
      translate('community_menu_create_group');
  String get communityMenuCreateDao => translate('community_menu_create_dao');
  String get communityMenuCreateClub => translate('community_menu_create_club');
  String get communityMenuScan => translate('community_menu_scan');

  // --- 社区创建 ---
  String get communityCreateDaoTitle => translate('community_create_dao_title');
  String get communityCreateClubTitle =>
      translate('community_create_club_title');
  String get communityCreateName => translate('community_create_name');
  String get communityCreateNameNft => translate('community_create_name_nft');
  String get communityCreateDaoDescription =>
      translate('community_create_dao_description');
  String get communityCreateClubDescription =>
      translate('community_create_club_description');
  String get communityCreateDaoDescHint =>
      translate('community_create_dao_desc_hint');
  String get communityCreateClubNameHint =>
      translate('community_create_club_name_hint');
  String get communityCreateClubDescHint =>
      translate('community_create_club_desc_hint');
  String get communityCreateClubStakeNft =>
      translate('community_create_club_stake_nft');
  String get communityCreateDaoIntro => translate('community_create_dao_intro');
  String get communityCreateClubIntro =>
      translate('community_create_club_intro');

  // --- 发现相关 ---
  String get discoverTitle => translate('discover_title');
  String get discoverTabPopular => translate('discover_tab_popular');
  String get discoverTabRecommend => translate('discover_tab_recommend');
  String get discoverTabRecent => translate('discover_tab_recent');
  String get discoverSectionNewArrivals =>
      translate('discover_section_new_arrivals');
  String get discoverSectionDefi => translate('discover_section_defi');
  String get discoverSectionAirdrop => translate('discover_section_airdrop');
  String get communityFilterTooltip => translate('community_filter_tooltip');
  String get communityMockBkokGroup => translate('community_mock_bkok_group');
  String get communityMockSalaryDesc => translate('community_mock_salary_desc');
  String get communityMockLazyMod => translate('community_mock_lazy_mod');
  String get communityMockSparkPlan => translate('community_mock_spark_plan');
  String get communityDetailTabDashboard =>
      translate('community_detail_tab_dashboard');
  String get communityDetailTabAsset => translate('community_detail_tab_asset');
  String get communityDetailTabPick => translate('community_detail_tab_pick');
  String get communityDetailBtnJoin => translate('community_detail_btn_join');
  String get communityDetailBtnChat => translate('community_detail_btn_chat');
  String get communityDetailLabelMembers =>
      translate('community_detail_label_members');
  String get communityDetailMockDesc => translate('community_detail_mock_desc');
  String get communityDetailYieldSinceAdded =>
      translate('community_detail_yield_since_added');
  String get communityDetailDaoAssets =>
      translate('community_detail_dao_assets');
  String get communityDetailDonorRanking =>
      translate('community_detail_donor_ranking');
  String get communityDetailActivity => translate('community_detail_activity');
  String get communityDetailBtnDonate =>
      translate('community_detail_btn_donate');
  String get communityDetailLabelViewMore =>
      translate('community_detail_label_view_more');
  String get communityDetailLabelMore =>
      translate('community_detail_label_more');
  String get communityDetailLabelOthers =>
      translate('community_detail_label_others');
  String get communityDetailActivityIncome =>
      translate('community_detail_activity_income');
  String get communityDetailActivityLabelDonor =>
      translate('community_detail_activity_label_donor');
  String get communityDetailActivityLabelFrom =>
      translate('community_detail_activity_label_from');
  String get communityDetailActivityLabelTime =>
      translate('community_detail_activity_label_time');
  String get communityDetailLabelShare =>
      translate('community_detail_label_share');
  String get communityDetailMockPostContent =>
      translate('community_detail_mock_post_content');
  String get communityDetailMockDonorName1 =>
      translate('community_detail_mock_donor_name_1');
  String get communityDetailMockDonorName2 =>
      translate('community_detail_mock_donor_name_2');
  String get communityDetailMockDonorName3 =>
      translate('community_detail_mock_donor_name_3');
  String get communityDetailActivityIncomeValue =>
      translate('community_detail_activity_income_value');
  String get communityDetailActivityMockTime =>
      translate('community_detail_activity_mock_time');
  String get communityDetailMockPostUser =>
      translate('community_detail_mock_post_user');
  String get communityDetailMockPostTime =>
      translate('community_detail_mock_post_time');
  String get communityDetailMockDonorAddress =>
      translate('community_detail_mock_donor_address');
  String get communityDetailMockActivityTitle1 =>
      translate('community_detail_mock_activity_title_1');
  String get communityDetailMockActivityTitle2 =>
      translate('community_detail_mock_activity_title_2');
  String get communityDetailMockActivityTitle3 =>
      translate('community_detail_mock_activity_title_3');
  String get communityDetailMockAssetEthName =>
      translate('community_detail_mock_asset_eth_name');
  String get communityDetailMockAssetEthFullName =>
      translate('community_detail_mock_asset_eth_full_name');
  String get communityDetailMockAssetUsdtName =>
      translate('community_detail_mock_asset_usdt_name');
  String get communityDetailMockAssetUsdtFullName =>
      translate('community_detail_mock_asset_usdt_full_name');
  String get communityDetailMockAssetVboxName =>
      translate('community_detail_mock_asset_vbox_name');

  // --- 社区弹窗 ---
  String get communityModalSelectDaoTypeTitle =>
      translate('community_modal_select_dao_type_title');
  String get communityModalTokenHoldingGroupTitle =>
      translate('community_modal_token_holding_group_title');
  String get communityModalTokenHoldingGroupDesc =>
      translate('community_modal_token_holding_group_desc');
  String get communityModalNftHoldingGroupTitle =>
      translate('community_modal_nft_holding_group_title');
  String get communityModalNftHoldingGroupDesc =>
      translate('community_modal_nft_holding_group_desc');
  String get communityModalSelectTokenTitle =>
      translate('community_modal_select_token_title');
  String get communityModalSearchTokenHint =>
      translate('community_modal_search_token_hint');

  // --- 网络 ---
  String get networkSolana => translate('network_solana');
  String get networkEthereum => translate('network_ethereum');
  String get networkTether => translate('network_tether');
  String get networkBnb => translate('network_bnb');
  String get networkBnbChain => translate('network_bnb_chain');
  String get networkBase => translate('network_base');
  String get networkPolygon => translate('network_polygon');
  String get networkOptimism => translate('network_optimism');
  String get networkArbitrum => translate('network_arbitrum');
  String get networkZksyncEra => translate('network_zksync_era');
  String get networkAvalanche => translate('network_avalanche');
  String get networkFantom => translate('network_fantom');
  String get networkBlast => translate('network_blast');
  String get networkMerlin => translate('network_merlin');
  String get networkLinea => translate('network_linea');
  String get networkScroll => translate('network_scroll');
  String get networkBitlayer => translate('network_bitlayer');
  String get networkMantle => translate('network_mantle');
  String get networkXLayer => translate('network_x_layer');
  String get networkBitcoin => translate('network_bitcoin');

  // --- 成员选择 ---
  String get communityTitle => translate('community_title');
  String get communityTabDao => translate('community_tab_dao');
  String get communityTabClub => translate('community_tab_club');
  String get communityTabKey => translate('community_tab_key');
  String get screening => translate('screening');
  String get byType => translate('by_type');
  String get blockchain => translate('blockchain');
  String get byTag => translate('by_tag');
  String get reset => translate('reset');
  String get confirm => translate('confirm');

  // --- 社区模拟数据 ---
  String get communityMockMemberCount2k =>
      translate('community_mock_member_count_2k');
  String get communityMockMemberCount2_5k =>
      translate('community_mock_member_count_2_5k');
  String get communityMockMemberCount1_2k =>
      translate('community_mock_member_count_1_2k');
  String get communityMockMemberCount8_9k =>
      translate('community_mock_member_count_8_9k');
  String get communityMockDaoAssetsValue =>
      translate('community_mock_dao_assets_value');
  String get communityMockYieldValue => translate('community_mock_yield_value');
  String get communityMockAssetEthPrice =>
      translate('community_mock_asset_eth_price');
  String get communityMockAssetEthTrend =>
      translate('community_mock_asset_eth_trend');
  String get communityMockAssetUsdtPrice =>
      translate('community_mock_asset_usdt_price');
  String get communityMockAssetUsdtTrend =>
      translate('community_mock_asset_usdt_trend');
  String get communityMockAssetUsdtValue =>
      translate('community_mock_asset_usdt_value');
  String get communityMockAssetVboxValue =>
      translate('community_mock_asset_vbox_value');
  String get communityMockAssetDefaultValue =>
      translate('community_mock_asset_default_value');
  String get communityMockAssetZeroValue =>
      translate('community_mock_asset_zero_value');
  String get communityMockDonorAmount1 =>
      translate('community_mock_donor_amount_1');
  String get communityMockDonorAmount2 =>
      translate('community_mock_donor_amount_2');
  String get communityMockDonorAmount3 =>
      translate('community_mock_donor_amount_3');
  String get communityMockAddressDetail =>
      translate('community_mock_address_detail');
  String get communityMockMemberCount5_0k =>
      translate('community_mock_member_count_5_0k');
  String get communityMockMemberCount3_4k =>
      translate('community_mock_member_count_3_4k');
  String get communityMockMemberCount1_1k =>
      translate('community_mock_member_count_1_1k');
  String get communityMockAddress1 => translate('community_mock_address_1');
  String get communityMockAddress2 => translate('community_mock_address_2');
  String get communityMockAddress3 => translate('community_mock_address_3');
  String get communityMockAddress4 => translate('community_mock_address_4');
  String get communityMockAddress5 => translate('community_mock_address_5');
  String get communityMockAddress6 => translate('community_mock_address_6');

  // --- 筛选选项 ---
  String get filterAll => translate('filter_all');
  String get filterTypeToken => translate('filter_type_token');
  String get filterTypeNft => translate('filter_type_nft');
  String get filterTagGame => translate('filter_tag_game');
  String get filterTagSocial => translate('filter_tag_social');
  String get filterTagMeme => translate('filter_tag_meme');
  String get filterTagStaking => translate('filter_tag_staking');
  String get filterTagAirdrop => translate('filter_tag_airdrop');
  String get filterTagNews => translate('filter_tag_news');
  String get filterTagAlpha => translate('filter_tag_alpha');
  String get filterTagFun => translate('filter_tag_fun');
  String get filterTagGiveaway => translate('filter_tag_giveaway');
  String get filterTagInscription => translate('filter_tag_inscription');
  String get filterTagLayer2 => translate('filter_tag_layer2');

  // --- 聊天菜单 ---
  String get chatMenuAddFriend => translate('chat_menu_add_friend');
  String get chatMenuCreateGroup => translate('chat_menu_create_group');
  String get chatMenuScan => translate('chat_menu_scan');

  // --- 成员选择 ---
  String get chatSelectMembersTitle => translate('chat_select_members_title');

  // --- 更多通用 ---
  String get commonDelete => translate('common_delete');
  String get commonSave => translate('common_save');
  String get commonSearch => translate('common_search');
  String get commonCancel => translate('common_cancel');
  String get commonLeave => translate('common_leave');
  String commonViewMore(int count) =>
      translate('common_view_more', {'count': count});
  String get commonDone => translate('common_done');
  String get commonEdit => translate('common_edit');

  // --- Profile Pages ---
  String get profileAboutAbout => translate('profile_about_about');
  String get profileAboutEmail => translate('profile_about_email');
  String get profileAboutLq84y0qf5woaskcom =>
      translate('profile_about_lq84y0qf5woaskcom');
  String get profileAboutVersionUpdate =>
      translate('profile_about_version_update');
  String get profileAbout309 => translate('profile_about_309');
  String get profileLanguageSettingsChangeLanguage =>
      translate('profile_language_settings_change_language');
  String get profileNodeSettingsNodeSettings =>
      translate('profile_node_settings_node_settings');
  String get profileProfileDetailsChooseNetwork =>
      translate('profile_profile_details_choose_network');
  String get profileProfileDetailsNewPassword =>
      translate('profile_profile_details_new_password');
  String get profileProfileDetailsWallet =>
      translate('profile_profile_details_wallet');
  String get profileProfileDetailsBackupWallet =>
      translate('profile_profile_details_backup_wallet');
  String get profileProfileDetailsInviteFriends =>
      translate('profile_profile_details_invite_friends');
  String get profileProfileDetailsConfirm =>
      translate('profile_profile_details_confirm');
  String get profileProfileChooseNetwork =>
      translate('profile_profile_choose_network');
  String get profileQrCodeQrCode => translate('profile_qr_code_qr_code');
  String get profileTokenDetailPaymentDetails =>
      translate('profile_token_detail_payment_details');
  String get profileTokenDetailRequestToSign =>
      translate('profile_token_detail_request_to_sign');
  String get profileTokenDetailTotalIssue =>
      translate('profile_token_detail_total_issue');
  String get profileTokenDetailContractAddress =>
      translate('profile_token_detail_contract_address');
  String get profileTokenDetailFrom => translate('profile_token_detail_from');
  String get profileTokenDetailTo => translate('profile_token_detail_to');
  String get profileTokenDetailNetworkFees =>
      translate('profile_token_detail_network_fees');
  String get profileTokenDetailSignatureWallet =>
      translate('profile_token_detail_signature_wallet');
  String get profileTokenDetailConfirm =>
      translate('profile_token_detail_confirm');
  String get profileTokenDetailRefused =>
      translate('profile_token_detail_refused');
  String get profileTokenMarketTotalIssue =>
      translate('profile_token_market_total_issue');
  String get profileTokenMarketContractAddress =>
      translate('profile_token_market_contract_address');
  String get profileTokenNetworkNoNft =>
      translate('profile_token_network_no_nft');
  String get profileTokenNetworkSend => translate('profile_token_network_send');
  String get profileTokenNetworkReceive =>
      translate('profile_token_network_receive');
  String get profileTokenNetworkTokens =>
      translate('profile_token_network_tokens');
  String get profileTokenNetworkNfts => translate('profile_token_network_nfts');
  String get profileTokenNetworkSwap => translate('profile_token_network_swap');
  String get profileTokenNetworkBridge =>
      translate('profile_token_network_bridge');
  String get profileTokenNetworkBuy => translate('profile_token_network_buy');
  String get profileTokenNetworkSell => translate('profile_token_network_sell');
  String get profileTokenNetworkMessage =>
      translate('profile_token_network_message');
  String get profileTokenNetworkSlow => translate('profile_token_network_slow');
  String get profileTokenNetworkFast => translate('profile_token_network_fast');
  String get profileTransferSlow => translate('profile_transfer_slow');
  String get profileTransferMiddle => translate('profile_transfer_middle');
  String get profileTransferFast => translate('profile_transfer_fast');
  String get profileTransferNetwork => translate('profile_transfer_network');
  String get profileTransferAsset => translate('profile_transfer_asset');
  String get profileTransferAmount => translate('profile_transfer_amount');
  String get profileTransferBalance => translate('profile_transfer_balance');
  String get profileTransferAddress => translate('profile_transfer_address');
  String get profileTransferNetworkFees =>
      translate('profile_transfer_network_fees');
  String get profileTransferFeeLevel => translate('profile_transfer_fee_level');
  String get profileTransferFeeEstimated =>
      translate('profile_transfer_fee_estimated');
  String get profileTransferEstimatedFee =>
      translate('profile_transfer_estimated_fee');
  String get profileTransferFeeRate => translate('profile_transfer_fee_rate');
  String get profileTransferEstimatedSize =>
      translate('profile_transfer_estimated_size');
  String get profileTransferGasLimit => translate('profile_transfer_gas_limit');
  String get profileTransferContractData =>
      translate('profile_transfer_contract_data');
  String get profileTransferMoreTransactionInfo =>
      translate('profile_transfer_more_transaction_info');
  String get profileTransferHideTransactionInfo =>
      translate('profile_transfer_hide_transaction_info');
  String get profileTokenNetworkHistory =>
      translate('profile_token_network_history');
  String get profileTokenReceive => translate('profile_token_receive_');
  String get profileTokenReceiveQrCodePayment =>
      translate('profile_token_receive_qr_code_payment');
  String get profileTokenReceiveScanQrToPay =>
      translate('profile_token_receive_scan_qr_to_pay');
  String get profileTokenReceiveWalletAddress =>
      translate('profile_token_receive_wallet_address');
  String get profileTokenReceiveCopiedToClipboard =>
      translate('profile_token_receive_copied_to_clipboard');
  String get profileTokenReceiveShare =>
      translate('profile_token_receive_share');
  String get profileTokenReceiveCopy => translate('profile_token_receive_copy');
  String get profileTokenReceiveSave => translate('profile_token_receive_save');
  String get profileTransferDetailsCopiedToClipboard =>
      translate('profile_transfer_details_copied_to_clipboard');
  String get profileTransferDetailsTransferDetails =>
      translate('profile_transfer_details_transfer_details');
  String get profileTransferDetailsContinueToTransfer =>
      translate('profile_transfer_details_continue_to_transfer');
  String get profileTransferDetailsSender =>
      translate('profile_transfer_details_sender');
  String get profileTransferDetailsRecipient =>
      translate('profile_transfer_details_recipient');
  String get profileTransferDetailsTransactionFee =>
      translate('profile_transfer_details_transaction_fee');
  String get profileTransferDetailsTransactionHash =>
      translate('profile_transfer_details_transaction_hash');
  String get profileTransferDetailsTransactionTime =>
      translate('profile_transfer_details_transaction_time');
  String get profileTransferDetailsTransferWaiting =>
      translate('profile_transfer_details_transfer_waiting');
  String get profileTransferDetailsTransferSuccess =>
      translate('profile_transfer_details_transfer_success');
  String get profileTransferDetailsTransferFail =>
      translate('profile_transfer_details_transfer_fail');
  String get profileTransferChooseNetwork =>
      translate('profile_transfer_choose_network');
  String get profileTransferPaymentDetails =>
      translate('profile_transfer_payment_details');
  String get profileTransferPassword => translate('profile_transfer_password');
  String get profileTransferTransfer => translate('profile_transfer_transfer');
  String get profileTransfer000 => translate('profile_transfer_000');
  String get profileTransferPleaseEnter =>
      translate('profile_transfer_please_enter');
  String get profileTransferConfirmPayment =>
      translate('profile_transfer_confirm_payment');
  String get profileTransferConfirm => translate('profile_transfer_confirm');
  String get profileWalletEditRenameThisWallet =>
      translate('profile_wallet_edit_rename_this_wallet');
  String get profileWalletEditManageWallet =>
      translate('profile_wallet_edit_manage_wallet');
  String get profileWalletEditBackupMnemonics =>
      translate('profile_wallet_edit_backup_mnemonics');
  String get profileWalletEditBackingUpPrivate =>
      translate('profile_wallet_edit_backing_up_private');
  String get profileWalletEditEnterWalletName =>
      translate('profile_wallet_edit_enter_wallet_name');
  String get profileWalletEditSave => translate('profile_wallet_edit_save');
  String get profileWalletEditYourWallets =>
      translate('profile_wallet_edit_your_wallets');
  String get profileWalletEditBackupWarning =>
      translate('profile_wallet_edit_backup_warning');
  String get profileWalletEditDelete => translate('profile_wallet_edit_delete');
  String get profilePcosmDetailTotalAssets =>
      translate('profile_pcosm_detail_total_assets');
  String get profilePcosmDetailAvailableAssets =>
      translate('profile_pcosm_detail_available_assets');
  String get profilePcosmDetailAll => translate('profile_pcosm_detail_all');
  String get profilePcosmDetailIncome =>
      translate('profile_pcosm_detail_income');
  String get profilePcosmDetailSpending =>
      translate('profile_pcosm_detail_spending');
  String get profileProfileParacosm => translate('profile_profile_paracosm');
  String get profileProfileWalletNo1 =>
      translate('profile_profile_wallet_no_1');
  String get profileProfileAll => translate('profile_profile_all');
  String get profileWalletManagerWallet =>
      translate('profile_wallet_manager_wallet');

  // --- Profile Pages ---
  String get profileNodeDetailNodeSpeed =>
      translate('profile_node_detail_node_speed');
  String get profileNodeDetailQuick => translate('profile_node_detail_quick');
  String get profileNodeDetailMiddle => translate('profile_node_detail_middle');
  String get profileNodeDetailSlow => translate('profile_node_detail_slow');
  String get profileNodeDetailNone => translate('profile_node_detail_none');
  String get profileNodeDetailBlockHeightDesc =>
      translate('profile_node_detail_block_height_desc');
  String get profileQrCodeScanToAdd => translate('profile_qr_code_scan_to_add');
  String get profileTokenMarketTransferHistory =>
      translate('profile_token_market_transfer_history');
  String get profileTokenMarketTokenOverview =>
      translate('profile_token_market_token_overview');
  String get profileTokenMarketTime => translate('profile_token_market_time');
  String get profileTokenMarketMore => translate('profile_token_market_more');
  String get profileTokenMarketShow => translate('profile_token_market_show');
  String get profileTokenMarketHide => translate('profile_token_market_hide');
  String get profileTokenMarketNone => translate('profile_token_market_none');
  String get profileTokenMarketUnknown =>
      translate('profile_token_market_unknown');
  String get profileProfileDetailsYourWallets =>
      translate('profile_profile_details_your_wallets');
  String get profileProfileDetailsWalletNo2 =>
      translate('profile_profile_details_wallet_no_2');
  String get profileProfileDetailsWalletNo3 =>
      translate('profile_profile_details_wallet_no_3');
  String get profileProfileDetailsWalletNo4 =>
      translate('profile_profile_details_wallet_no_4');
  String get profileProfileDetailsAddWallet =>
      translate('profile_profile_details_add_wallet');
  String get profileProfileDetailsWalletNo1 =>
      translate('profile_profile_details_wallet_no_1');
  String get profileProfileDetailsBackupDesc =>
      translate('profile_profile_details_backup_desc');
  String get profileProfileDetailsInviteDesc =>
      translate('profile_profile_details_invite_desc');
  String get profileProfileDetailsChangeAddWallet =>
      translate('profile_profile_details_change_add_wallet');
  String get profileProfileDetailsBackupPrivateKey =>
      translate('profile_profile_details_backup_private_key');
  String get profileProfileDetailsBackupMnemonic =>
      translate('profile_profile_details_backup_mnemonic');
  String get profileProfileDetailsChangeCurrency =>
      translate('profile_profile_details_change_currency');
  String get profileProfileDetailsPcosm =>
      translate('profile_profile_details_pcosm');
  String get profileProfileDetailsChangePassword =>
      translate('profile_profile_details_change_password');
  String get profileProfileDetailsMessagesNotifications =>
      translate('profile_profile_details_messages_notifications');
  String get profileProfileDetailsLogout =>
      translate('profile_profile_details_logout');

  // --- 发现列表数据 ---
  String get discoverMockArbitrumLabel =>
      translate('discover_mock_arbitrum_label');
  String get discoverMockArbitrumDesc =>
      translate('discover_mock_arbitrum_desc');
  String get discoverMockAelfLabel => translate('discover_mock_aelf_label');
  String get discoverMockAelfDesc => translate('discover_mock_aelf_desc');
  String get discoverMockStarknetLabel =>
      translate('discover_mock_starknet_label');
  String get discoverMockStarknetDesc =>
      translate('discover_mock_starknet_desc');
  String get discoverMockAstarLabel => translate('discover_mock_astar_label');
  String get discoverMockAstarDesc => translate('discover_mock_astar_desc');
  String get discoverMockMagicEdenLabel =>
      translate('discover_mock_magic_eden_label');
  String get discoverMockFluxLabel => translate('discover_mock_flux_label');
  String get discoverMockIagonLabel => translate('discover_mock_iagon_label');
  String get discoverMockCartesiLabel =>
      translate('discover_mock_cartesi_label');
}
