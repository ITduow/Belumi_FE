import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return Scaffold(
      appBar: AppBar(title: const BelumiLogo(height: 28)),
      body: LuxuryPage(
        children: [
          LuxuryHero(
            title: t('Bảng quản trị', 'Admin Panel'),
            subtitle: t(
              'Quản lý user, AI usage, subscription, payment mock và contact requests.',
              'Manage users, AI usage, subscriptions, mock payments and contact requests.',
            ),
            imageUrl:
                'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1200&q=80',
            actions: [
              LuxuryButton(
                label: repository.currentUser?.email ?? 'Admin',
                icon: Icons.admin_panel_settings,
                onPressed: () {},
              ),
              LuxuryButton(
                label: t('Quản lý tin tức', 'Manage news'),
                icon: Icons.article_outlined,
                outlined: true,
                onPressed: () => context.go('/admin/news'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _DashboardSection(future: repository.adminDashboard()),
          const SizedBox(height: 14),
          _AdminSection(
            title: 'Users',
            icon: Icons.people_alt_outlined,
            future: repository.adminUsers(),
            emptyText: t('Chưa có user.', 'No users yet.'),
          ),
          const SizedBox(height: 14),
          _AdminSection(
            title: 'AI usage logs',
            icon: Icons.analytics_outlined,
            future: repository.adminAiUsage(),
            emptyText: t('Chưa có usage log.', 'No usage logs yet.'),
          ),
          const SizedBox(height: 14),
          _AdminSection(
            title: t('Yêu cầu tư vấn', 'Contact requests'),
            icon: Icons.contact_mail,
            future: repository.adminContacts(),
            emptyText: t(
              'Chưa có contact request.',
              'No contact requests yet.',
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.future});

  final Future<Map<String, dynamic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final stats = [
          ('Users', data['totalUsers'] ?? 0, Icons.people_alt_outlined),
          ('AI', data['aiUsageThisMonth'] ?? 0, Icons.auto_awesome),
          ('Subs', data['totalSubscriptions'] ?? 0, Icons.workspace_premium),
          ('Payments', data['totalPayments'] ?? 0, Icons.payments_outlined),
          ('News', data['totalNews'] ?? 0, Icons.article_outlined),
        ];
        return LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: stats
                    .map(
                      (item) => SizedBox(
                        width: 132,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.$3, color: BelumiLuxury.ink),
                                const SizedBox(height: 8),
                                Text(
                                  item.$2.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(item.$1),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({
    required this.title,
    required this.icon,
    required this.future,
    required this.emptyText,
  });

  final String title;
  final IconData icon;
  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return LuxuryPanel(
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(),
              if (snapshot.hasError)
                Text(
                  belumiCopy(context).t(
                    'Không tải được dữ liệu. Hãy kiểm tra token admin và backend.',
                    'Could not load data. Check admin token and backend.',
                  ),
                  style: TextStyle(color: Colors.red),
                ),
              if (!snapshot.hasError && rows.isEmpty) Text(emptyText),
              ...rows
                  .take(6)
                  .map(
                    (row) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        row['fullName']?.toString() ??
                            row['status']?.toString() ??
                            row['id']?.toString() ??
                            'Item',
                      ),
                      subtitle: Text(
                        row.entries
                            .take(3)
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
