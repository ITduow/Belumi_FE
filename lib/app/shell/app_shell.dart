import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/i18n/app_strings.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../presentation/widgets/belumi_luxury.dart';
import '../../presentation/screens/skin_analysis_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.repository, required this.child});

  final BelumiRepository repository;
  final Widget child;

  static const _routes = [
    '/home',
    '/skincare-ai',
    '/ingredient-lookup',
    '/news',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final selectedIndex = _routes.indexWhere(
      (route) => location.startsWith(route),
    );
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;
    final locale = ref.watch(appLocaleProvider);
    final strings = AppStrings(locale);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: const BelumiLogo(height: 30),
        actions: [
          IconButton(
            tooltip: strings.t('about'),
            onPressed: () => context.go('/about'),
            icon: const Icon(Icons.info_outline),
          ),
          if (authState.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (user == null)
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(strings.t('login')),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              offset: const Offset(0, 48),
              elevation: 4,
              color: const Color(0xFFFFF9F5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFF1DFD8)),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  ref.read(authControllerProvider.notifier).logout();
                  context.go('/login');
                } else if (value == 'admin') {
                  context.go('/admin');
                } else if (value == 'profile') {
                  context.go('/profile');
                } else if (value == 'history') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => SkinAnalysisHistoryScreen(repository: repository),
                    ),
                  );
                } else if (value == 'pricing') {
                  context.push('/pricing');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    user.email,
                    style: const TextStyle(
                      color: BelumiLuxury.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 18, color: BelumiLuxury.ink),
                      const SizedBox(width: 10),
                      const Text('Hồ sơ'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history_toggle_off, size: 18, color: BelumiLuxury.ink),
                      const SizedBox(width: 10),
                      Text(locale == 'vi' ? 'Lịch sử da' : 'Skin History'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pricing',
                  child: Row(
                    children: [
                      Icon(Icons.card_membership_outlined, size: 18, color: BelumiLuxury.ink),
                      const SizedBox(width: 10),
                      Text(strings.t('pricing')),
                    ],
                  ),
                ),
                if (user.role.toLowerCase() == 'admin')
                  PopupMenuItem(
                    value: 'admin',
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings_outlined, size: 18, color: BelumiLuxury.ink),
                        const SizedBox(width: 10),
                        Text(strings.t('admin')),
                      ],
                    ),
                  ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFB85C5C)),
                      const SizedBox(width: 10),
                      Text(
                        strings.t('logout'),
                        style: const TextStyle(color: Color(0xFFB85C5C), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BelumiLuxury.background,
          child: KeyedSubtree(key: ValueKey(locale), child: child),
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        onSelected: (index) => context.go(_routes[index]),
        items: [
          _BottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: locale == 'vi' ? 'Trang chủ' : 'Home',
          ),
          _BottomNavItem(
            icon: Icons.auto_awesome_outlined,
            selectedIcon: Icons.auto_awesome,
            label: locale == 'vi' ? 'Phân tích' : 'Analysis',
          ),
          _BottomNavItem(
            icon: Icons.center_focus_weak,
            selectedIcon: Icons.center_focus_weak,
            label: locale == 'vi' ? 'Tra cứu' : 'Lookup',
          ),
          _BottomNavItem(
            icon: Icons.article_outlined,
            selectedIcon: Icons.article,
            label: locale == 'vi' ? 'Bảng tin' : 'News',
          ),
          _BottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: locale == 'vi' ? 'Hồ sơ' : 'Profile',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Belumi chat',
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _ChatbotSheet(repository: repository),
        ),
        child: const Icon(Icons.message_outlined),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_BottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF9F5),
          border: Border(
            top: BorderSide(color: Color(0xFFE6E1DC), width: 1),
          ),
        ),
        child: SizedBox(
          height: 76,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _BottomNavTile(
                      item: items[0],
                      selected: selectedIndex == 0,
                      onTap: () => onSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavTile(
                      item: items[1],
                      selected: selectedIndex == 1,
                      onTap: () => onSelected(1),
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ),
                  Expanded(
                    child: _BottomNavTile(
                      item: items[3],
                      selected: selectedIndex == 3,
                      onTap: () => onSelected(3),
                    ),
                  ),
                  Expanded(
                    child: _BottomNavTile(
                      item: items[4],
                      selected: selectedIndex == 4,
                      onTap: () => onSelected(4),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -16,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => onSelected(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF9F5),
                            border: Border.all(
                              color: const Color(0xFFD3C5B7),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFF976D48),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.center_focus_weak,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[2].label,
                          style: TextStyle(
                            color: selectedIndex == 2
                                ? const Color(0xFF976D48)
                                : const Color(0xFF816A5C),
                            fontSize: 11,
                            fontWeight: selectedIndex == 2
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavTile extends StatelessWidget {
  const _BottomNavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? const Color(0xFF976D48)
        : const Color(0xFF816A5C);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatbotSheet extends StatefulWidget {
  const _ChatbotSheet({required this.repository});

  final BelumiRepository repository;

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubbleData> _messages = [
    const _ChatBubbleData(
      text:
          'Chào bạn, mình là Belumi Assistant. Bạn có thể hỏi về routine, loại da, ingredient hoặc sản phẩm skincare.',
      fromUser: false,
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final allowed = await widget.repository.checkAndIncrementLimit('chatbot');
    if (!allowed) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _ChatBubbleData(
            text: '🔒 Bạn đã dùng hết lượt trò chuyện miễn phí hôm nay (1 lần/ngày). Vui lòng nâng cấp tài khoản lên gói Paid để trò chuyện không giới hạn với Chuyên gia AI!',
            fromUser: false,
            isError: true,
          ),
        );
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add(_ChatBubbleData(text: text, fromUser: true));
      _controller.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final response = await widget.repository.sendChatbotMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleData(
            text: response.answer,
            fromUser: false,
            sources: response.sources,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleData(
            text:
                'Mình chưa trả lời được lúc này. Hãy kiểm tra backend hoặc OpenAI API key rồi thử lại nhé.\n$error',
            fromUser: false,
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF9F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.auto_awesome_outlined),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Belumi Chatbot',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(14),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) =>
                          _ChatBubble(data: _messages[index]),
                    ),
                  ),
                  if (_sending) const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText: 'Hỏi về skincare, ingredient...',
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Send',
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatBubbleData {
  const _ChatBubbleData({
    required this.text,
    required this.fromUser,
    this.sources = const [],
    this.isError = false,
  });

  final String text;
  final bool fromUser;
  final List<ChatbotSource> sources;
  final bool isError;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.data});

  final _ChatBubbleData data;

  @override
  Widget build(BuildContext context) {
    final alignment = data.fromUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final background = data.fromUser
        ? Theme.of(context).colorScheme.primary
        : data.isError
        ? const Color(0xFFFFE1E1)
        : Colors.white;
    final foreground = data.fromUser ? Colors.white : BelumiLuxury.ink;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16),
              border: data.fromUser
                  ? null
                  : Border.all(color: const Color(0xFFFFE8E0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.text, style: TextStyle(color: foreground)),
                  if (data.sources.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: data.sources
                          .map(
                            (source) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                source.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
