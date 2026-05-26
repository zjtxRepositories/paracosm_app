import 'package:flutter/material.dart';
import 'package:paracosm/modules/im/message/custom_face_message.dart';
import 'package:paracosm/theme/app_colors.dart';

class ChatEmojiPanel extends StatefulWidget {
  const ChatEmojiPanel({
    super.key,
    required this.onEmojiTap,
    required this.onDeleteTap,
    required this.onCustomFaceTap,
  });

  final ValueChanged<String> onEmojiTap;
  final VoidCallback onDeleteTap;
  final ValueChanged<ChatCustomFace> onCustomFaceTap;

  @override
  State<ChatEmojiPanel> createState() => _ChatEmojiPanelState();
}

class _ChatEmojiPanelState extends State<ChatEmojiPanel> {
  static const List<String> _emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '🙃',
    '😉',
    '😍',
    '😘',
    '😗',
    '😚',
    '😋',
    '😛',
    '😝',
    '😜',
    '🤪',
    '🤨',
    '🧐',
    '🤓',
    '😎',
    '🥳',
    '😏',
    '😒',
    '😞',
    '😔',
    '😟',
    '😕',
    '🙁',
    '☹️',
    '😣',
    '😖',
    '😫',
    '😩',
    '🥺',
    '😢',
    '😭',
    '😤',
    '😠',
    '😡',
    '🤬',
    '🤯',
    '😳',
    '🥵',
    '🥶',
    '😱',
    '😨',
    '😰',
    '😥',
    '😓',
    '🤗',
    '🤔',
    '🤭',
    '🤫',
    '🤥',
    '😶',
    '😐',
    '😑',
    '😬',
    '🙄',
    '😯',
    '😦',
    '😧',
    '😮',
    '😲',
    '🥱',
    '😴',
    '🤤',
    '😪',
    '😵',
    '🤐',
    '🥴',
    '🤢',
    '🤮',
    '🤧',
    '😷',
    '🤒',
    '🤕',
    '🤑',
    '🤠',
    '👍',
    '👎',
    '👌',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '👏',
    '🙌',
    '🙏',
    '💪',
    '🔥',
    '✨',
    '🎉',
    '❤️',
    '💔',
    '💕',
    '💯',
  ];

  final List<ChatCustomFacePack> _packs = ChatCustomFaceCatalog.packs();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Column(
        children: [
          Expanded(child: _buildGrid()),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_selectedIndex == 0) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _emojis.length,
        itemBuilder: (context, index) {
          final emoji = _emojis[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => widget.onEmojiTap(emoji),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          );
        },
      );
    }

    final pack = _packs[_selectedIndex - 1];
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: pack.faces.length,
      itemBuilder: (context, index) {
        final face = pack.faces[index];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => widget.onCustomFaceTap(face),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Image.asset(face.assetPath, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    final tabs = <Widget>[
      _buildTab(
        selected: _selectedIndex == 0,
        onTap: () => _select(0),
        child: const Text('😀', style: TextStyle(fontSize: 24)),
      ),
      ...List<Widget>.generate(_packs.length, (index) {
        final tabIndex = index + 1;
        return _buildTab(
          selected: _selectedIndex == tabIndex,
          onTap: () => _select(tabIndex),
          child: Image.asset(
            _packs[index].menuAssetPath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        );
      }),
    ];

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.topBg,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: tabs,
            ),
          ),
          InkWell(
            onTap: widget.onDeleteTap,
            child: const SizedBox(
              width: 58,
              height: 48,
              child: Icon(
                Icons.backspace_outlined,
                size: 22,
                color: AppColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
  }

  void _select(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }
}
