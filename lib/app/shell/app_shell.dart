import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/i18n/app_strings.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../presentation/widgets/belumi_luxury.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.repository, required this.child});

  final BelumiRepository repository;
  final Widget child;

  static const _routes = [
    '/home',
    '/skincare-ai',
    '/ingredient-lookup',
    '/news',
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
              onSelected: (value) {
                if (value == 'logout') {
                  ref.read(authControllerProvider.notifier).logout();
                  context.go('/login');
                } else if (value == 'admin') {
                  context.go('/admin');
                } else if (value == 'profile') {
                  context.go('/profile');
                } else if (value == 'pricing') {
                  context.push('/pricing');
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(enabled: false, child: Text(user.email)),
                const PopupMenuItem(value: 'profile', child: Text('Profile')),
                PopupMenuItem(
                  value: 'pricing',
                  child: Text(strings.t('pricing')),
                ),
                if (user.role.toLowerCase() == 'admin')
                  PopupMenuItem(
                    value: 'admin',
                    child: Text(strings.t('admin')),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text(strings.t('logout')),
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
            label: strings.t('home'),
          ),
          _BottomNavItem(
            icon: Icons.auto_awesome_outlined,
            selectedIcon: Icons.auto_awesome,
            label: locale == 'vi' ? 'AI da' : 'Skin AI',
          ),
          _BottomNavItem(
            icon: Icons.document_scanner_outlined,
            selectedIcon: Icons.document_scanner,
            label: locale == 'vi' ? 'Thành phần' : 'Ingredients',
          ),
          _BottomNavItem(
            icon: Icons.article_outlined,
            selectedIcon: Icons.article,
            label: strings.t('news'),
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
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFFFFF9F5)),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _BottomNavTile(
                    item: items[index],
                    selected: selectedIndex == index,
                    onTap: () => onSelected(index),
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
        ? Theme.of(context).colorScheme.primary
        : BelumiLuxury.muted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 44,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFFFE8E0) : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                size: 20,
                color: color,
              ),
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
