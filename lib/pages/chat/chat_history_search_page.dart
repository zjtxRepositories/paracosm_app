import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:paracosm/modules/im/manager/im_message_manager.dart';
import 'package:paracosm/pages/chat/chat_detail_message.dart';
import 'package:paracosm/pages/chat/chat_detail_message_mapper.dart';
import 'package:paracosm/pages/chat/chat_session_args.dart';
import 'package:paracosm/theme/app_colors.dart';
import 'package:paracosm/theme/app_text_styles.dart';
import 'package:paracosm/util/string_util.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:paracosm/widgets/base/app_page.dart';
import 'package:paracosm/widgets/chat/user_avatar_widget.dart';
import 'package:paracosm/widgets/common/app_empty_view.dart';
import 'package:paracosm/widgets/common/app_search_input.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

class ChatHistorySearchPage extends StatefulWidget {
  const ChatHistorySearchPage({super.key, required this.sessionArgs});

  final ChatSessionArgs sessionArgs;

  @override
  State<ChatHistorySearchPage> createState() => _ChatHistorySearchPageState();
}

class _ChatHistorySearchPageState extends State<ChatHistorySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _keyword = '';
  DateTime? _selectedDate;
  bool _isLoading = false;
  List<_ChatHistorySearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleSearch(String keyword) async {
    final query = keyword.trim();
    if (query.isEmpty) {
      setState(() {
        _keyword = '';
        _selectedDate = null;
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _keyword = query;
      _selectedDate = null;
      _isLoading = true;
    });

    final result = await ImMessageManager().searchMessages(
      type: widget.sessionArgs.conversationType,
      targetId: widget.sessionArgs.targetId,
      channelId: widget.sessionArgs.channelId,
      keyword: query,
      startTime: 0,
      count: 50,
    );

    if (!mounted || query != _keyword) return;

    final messages = result.data ?? [];
    final mapped = await Future.wait(
      messages.map((message) async {
        final detail = await ChatDetailMessageMapper.mapMessage(message);
        return _ChatHistorySearchResult(message: message, detail: detail);
      }),
    );

    if (!mounted || query != _keyword) return;

    setState(() {
      _results = result.success ? mapped : [];
      _isLoading = false;
    });
  }

  Future<void> _handleDateSearch(DateTime date) async {
    _debounce?.cancel();
    _searchController.clear();

    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    setState(() {
      _keyword = '';
      _selectedDate = dayStart;
      _results = [];
      _isLoading = true;
    });

    final messages = <RCIMIWMessage>[];
    var sentTime = dayEnd.millisecondsSinceEpoch;
    var hasMore = true;

    while (hasMore) {
      final batch = await ImMessageManager().getMessages(
        type: widget.sessionArgs.conversationType,
        targetId: widget.sessionArgs.targetId,
        channelId: widget.sessionArgs.channelId,
        sentTime: sentTime,
        order: RCIMIWTimeOrder.before,
        policy: RCIMIWMessageOperationPolicy.localRemote,
        count: 20,
      );

      if (batch.isEmpty) {
        break;
      }

      var reachedPreviousDay = false;
      for (final message in batch) {
        final timestamp = message.sentTime ?? message.receivedTime;
        if (timestamp == null) continue;

        if (timestamp >= dayStart.millisecondsSinceEpoch &&
            timestamp < dayEnd.millisecondsSinceEpoch) {
          messages.add(message);
        }

        if (timestamp < dayStart.millisecondsSinceEpoch) {
          reachedPreviousDay = true;
        }
      }

      final oldestTime = batch
          .map((message) => message.sentTime ?? message.receivedTime)
          .whereType<int>()
          .fold<int?>(null, (oldest, time) {
            if (oldest == null || time < oldest) return time;
            return oldest;
          });

      if (oldestTime == null || reachedPreviousDay || batch.length < 20) {
        hasMore = false;
      } else {
        sentTime = oldestTime;
      }
    }

    final uniqueMessages = <String, RCIMIWMessage>{};
    for (final message in messages) {
      uniqueMessages[_messageKey(message)] = message;
    }

    final sorted = uniqueMessages.values.toList()
      ..sort((a, b) {
        final aTime = a.sentTime ?? a.receivedTime ?? 0;
        final bTime = b.sentTime ?? b.receivedTime ?? 0;
        return aTime.compareTo(bTime);
      });

    final mapped = await Future.wait(
      sorted.map((message) async {
        final detail = await ChatDetailMessageMapper.mapMessage(message);
        return _ChatHistorySearchResult(message: message, detail: detail);
      }),
    );

    if (!mounted || _selectedDate != dayStart) return;

    setState(() {
      _results = mapped;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      showNav: true,
      isCustomHeader: true,
      renderCustomHeader: _buildHeader(),
      child: _buildBody(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSearchInput(
              controller: _searchController,
              autofocus: true,
              hintText: AppLocalizations.of(context)!.chatSettingSearchHistory,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => _handleSearch(value),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.grey900,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: '日期',
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.chatSearchCancel,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_keyword.isEmpty && _selectedDate == null) {
      return _buildInitialView();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return AppEmptyView(text: AppLocalizations.of(context)!.chatSearchNoData);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _results.length + (_selectedDate == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (_selectedDate != null && index == 0) {
          return _buildDateHeader();
        }

        final resultIndex = _selectedDate == null ? index : index - 1;
        return _buildResultItem(_results[resultIndex]);
      },
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: GestureDetector(
        onTap: _pickDate,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 32,
                color: AppColors.grey400,
              ),
              const SizedBox(height: 8),
              Text(
                '按日期查看',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.grey400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        _formatDate(_selectedDate!),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.grey400,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildResultItem(_ChatHistorySearchResult result) {
    final message = result.message;
    final detail = result.detail;
    final sentTime =
        detail.sentTime ?? message.sentTime ?? message.receivedTime;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: sentTime == null ? null : () => _openMessage(result, sentTime),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: UserAvatarWidget(
                userId: message.senderUserId,
                avatarUrl: message.userInfo?.portrait,
                size: 44,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey100, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _senderName(message),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.grey900,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sentTime != null)
                          Text(
                            formatIMTime(sentTime),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildHighlightText(
                      _messageSummary(detail),
                      _keyword,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMessage(_ChatHistorySearchResult result, int sentTime) {
    final encoded = Uri.encodeComponent(widget.sessionArgs.name);
    context.push(
      '/chat-detail/$encoded',
      extra: widget.sessionArgs.copyWith(
        anchorSentTime: sentTime,
        anchorMessageId: result.detail.messageId,
        searchKeyword: _keyword.isEmpty ? null : _keyword,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (date == null) return;
    await _handleDateSearch(date);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}/$month/$day';
  }

  String _messageKey(RCIMIWMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId > 0) return 'id:$messageId';

    final messageUId = message.messageUId;
    if (messageUId != null && messageUId.isNotEmpty) return 'uid:$messageUId';

    return [
      message.conversationType?.index,
      message.targetId,
      message.channelId,
      message.senderUserId,
      message.sentTime ?? message.receivedTime,
      message.messageType?.index,
    ].join(':');
  }

  String _senderName(RCIMIWMessage message) {
    final name = message.userInfo?.name;
    if (name != null && name.isNotEmpty) return name;
    if (!widget.sessionArgs.isGroup) return widget.sessionArgs.name;
    return message.senderUserId ?? '';
  }

  String _messageSummary(ChatDetailMessage message) {
    switch (message.kind) {
      case ChatDetailMessageKind.text:
      case ChatDetailMessageKind.fm:
      case ChatDetailMessageKind.call:
        return message.text ?? '';
      case ChatDetailMessageKind.image:
        return AppLocalizations.of(context)!.chatImage;
      case ChatDetailMessageKind.voice:
        return AppLocalizations.of(context)!.chatVoice;
      case ChatDetailMessageKind.video:
        return AppLocalizations.of(context)!.chatDetailVideoCall;
      case ChatDetailMessageKind.file:
        return message.fileName ?? AppLocalizations.of(context)!.chatDetailFile;
      case ChatDetailMessageKind.withdrawnNotice:
        return AppLocalizations.of(context)!.chatDetailWithdrewMessage;
      default:
        return '';
    }
  }

  Widget _buildHighlightText(
    String text,
    String highlight, {
    required TextStyle style,
  }) {
    if (highlight.isEmpty ||
        !text.toLowerCase().contains(highlight.toLowerCase())) {
      return Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    var start = 0;
    var indexOfHighlight = lowerText.indexOf(lowerHighlight, start);

    while (indexOfHighlight != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(
        TextSpan(
          text: text.substring(
            indexOfHighlight,
            indexOfHighlight + highlight.length,
          ),
          style: const TextStyle(color: AppColors.primaryLight),
        ),
      );
      start = indexOfHighlight + highlight.length;
      indexOfHighlight = lowerText.indexOf(lowerHighlight, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ChatHistorySearchResult {
  const _ChatHistorySearchResult({required this.message, required this.detail});

  final RCIMIWMessage message;
  final ChatDetailMessage detail;
}
