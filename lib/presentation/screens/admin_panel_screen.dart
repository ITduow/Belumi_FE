import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';
import 'admin_news_screen.dart';
import 'admin_ingredients_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _selectedViewIndex = 0;

  // Analytics tab state
  String _selectedPeriod = 'daily';
  Future<Map<String, dynamic>>? _analyticsFuture;
  bool _showRevenueChart = true;

  // Payments tab state
  List<Map<String, dynamic>>? _payments;
  bool _loadingPayments = false;
  String _paymentSearchQuery = '';

  // Users tab state
  List<Map<String, dynamic>>? _users;
  String _userSearchQuery = '';
  bool _loadingUsers = false;

  // AI Logs tab state
  List<Map<String, dynamic>>? _aiLogs;
  bool _loadingAiLogs = false;
  final Set<String> _expandedLogIds = {};

  // Contacts tab state
  List<Map<String, dynamic>>? _contacts;
  bool _loadingContacts = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _changeView(int index) {
    setState(() {
      _selectedViewIndex = index;
    });
    if (index == 0) {
      _loadAnalytics();
    } else if (index == 1) {
      _fetchPayments();
    } else if (index == 2) {
      _fetchUsers();
    } else if (index == 5) {
      _fetchAiLogs();
    } else if (index == 6) {
      _fetchContacts();
    }
  }

  Future<void> _fetchPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final data = await widget.repository.adminPayments();
      setState(() {
        _payments = data;
        _loadingPayments = false;
      });
    } catch (e) {
      setState(() => _loadingPayments = false);
      _showErrorSnackBar('Lỗi tải danh sách giao dịch: $e');
    }
  }

  void _loadAnalytics() {
    setState(() {
      _analyticsFuture = widget.repository.adminDashboardAnalytics(_selectedPeriod);
    });
  }

  Future<void> _fetchUsers() async {
    setState(() => _loadingUsers = true);
    try {
      final data = await widget.repository.adminUsers();
      setState(() {
        _users = data;
        _loadingUsers = false;
      });
    } catch (e) {
      setState(() => _loadingUsers = false);
      _showErrorSnackBar('Lỗi tải danh sách người dùng: $e');
    }
  }

  Future<void> _fetchAiLogs() async {
    setState(() => _loadingAiLogs = true);
    try {
      final data = await widget.repository.adminAiUsage();
      setState(() {
        _aiLogs = data;
        _loadingAiLogs = false;
      });
    } catch (e) {
      setState(() => _loadingAiLogs = false);
      _showErrorSnackBar('Lỗi tải logs AI: $e');
    }
  }

  Future<void> _fetchContacts() async {
    setState(() => _loadingContacts = true);
    try {
      final data = await widget.repository.adminContacts();
      setState(() {
        _contacts = data;
        _loadingContacts = false;
      });
    } catch (e) {
      setState(() => _loadingContacts = false);
      _showErrorSnackBar('Lỗi tải yêu cầu tư vấn: $e');
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final originalStatus = (user['isActive'] ?? user['IsActive']) as bool? ?? true;
    final newStatus = !originalStatus;
    try {
      final userId = user['id'] ?? user['Id'];
      await widget.repository.api.put('/admin/users/$userId/status', {
        'isActive': newStatus,
      });
      setState(() {
        if (user.containsKey('isActive')) {
          user['isActive'] = newStatus;
        }
        if (user.containsKey('IsActive')) {
          user['IsActive'] = newStatus;
        }
      });
      _showSuccessSnackBar(
        newStatus
            ? 'Đã mở khóa tài khoản thành công.'
            : 'Đã khóa tài khoản thành công.',
      );
    } catch (e) {
      _showErrorSnackBar('Không thể cập nhật trạng thái người dùng: $e');
    }
  }

  Future<void> _updateContactStatus(Map<String, dynamic> contact, String newStatus) async {
    try {
      int statusInt = 0;
      if (newStatus == 'InProgress') statusInt = 1;
      if (newStatus == 'Resolved') statusInt = 2;

      await widget.repository.api.patch(
        '/admin/contacts/${contact['id'] ?? contact['Id']}/status',
        statusInt,
      );
      setState(() {
        if (contact.containsKey('status')) {
          contact['status'] = newStatus;
        }
        if (contact.containsKey('Status')) {
          contact['Status'] = newStatus;
        }
      });
      _showSuccessSnackBar('Đã cập nhật trạng thái yêu cầu liên hệ.');
    } catch (e) {
      _showErrorSnackBar('Không thể cập nhật trạng thái liên hệ: $e');
    }
  }

  String _parseContactStatus(dynamic statusVal) {
    if (statusVal == null) return 'New';
    final strVal = statusVal.toString();
    if (strVal == '0' || strVal.toLowerCase() == 'new') return 'New';
    if (strVal == '1' || strVal.toLowerCase() == 'inprogress') return 'InProgress';
    if (strVal == '2' || strVal.toLowerCase() == 'resolved') return 'Resolved';
    return 'New';
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.teal.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCurrency(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}K';
    }
    return val.toStringAsFixed(0);
  }

  String _formatVND(double val) {
    return '${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
  }

  String _getRelativeTime(String timestampStr) {
    try {
      final parsed = DateTime.parse(timestampStr);
      final diff = DateTime.now().difference(parsed);
      if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} năm trước';
      if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} tháng trước';
      if (diff.inDays > 0) return '${diff.inDays} ngày trước';
      if (diff.inHours > 0) return '${diff.inHours} giờ trước';
      if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
      return 'Vừa xong';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 900;

    final List<Map<String, dynamic>> menuItems = [
      {'title': t('Thống kê', 'Statistics'), 'icon': Icons.analytics_outlined},
      {'title': t('Doanh thu', 'Revenue'), 'icon': Icons.monetization_on_outlined},
      {'title': t('Người dùng', 'Users'), 'icon': Icons.people_alt_outlined},
      {'title': t('Tin tức', 'News'), 'icon': Icons.article_outlined},
      {'title': t('Thành phần', 'Ingredients'), 'icon': Icons.science_outlined},
      {'title': t('Logs AI', 'AI Logs'), 'icon': Icons.auto_awesome},
      {'title': t('Liên hệ', 'Contacts'), 'icon': Icons.contact_mail_outlined},
    ];

    final List<Widget> views = [
      _buildAnalyticsTab(),
      _buildPaymentsTab(),
      _buildUsersTab(),
      AdminNewsScreen(repository: widget.repository, embedMode: true),
      AdminIngredientsScreen(repository: widget.repository, embedMode: true),
      _buildAiLogsTab(),
      _buildContactsTab(),
    ];

    final activeView = views[_selectedViewIndex];
    final activeTitle = menuItems[_selectedViewIndex]['title'] as String;

    Widget buildDrawerContent() {
      return Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [BelumiLuxury.ink, Color(0xFF2C3E50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.repository.currentUser?.fullName ?? 'Admin',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          widget.repository.currentUser?.email ?? 'admin@belumi.site',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isSelected = _selectedViewIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFFFE8E0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? BelumiLuxury.ink : BelumiLuxury.muted,
                      ),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: isSelected ? BelumiLuxury.ink : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () {
                        _changeView(index);
                        if (!isLargeScreen) {
                          Navigator.pop(context); // Close drawer on mobile
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            // Footer with logout/back
            const Divider(),
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.red),
              title: Text(t('Quay về trang chủ', 'Back to Home'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                context.go('/home');
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const BelumiLogo(height: 24),
            const SizedBox(width: 8),
            Text(
              activeTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        leading: isLargeScreen
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: BelumiLuxury.ink),
                onPressed: () => context.go('/home'),
              )
            : null, // Burger menu icon will be automatically shown on mobile
      ),
      drawer: isLargeScreen ? null : Drawer(child: buildDrawerContent()),
      body: Row(
        children: [
          if (isLargeScreen)
            SizedBox(
              width: 250,
              child: buildDrawerContent(),
            ),
          Expanded(child: activeView),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ANALYTICS TAB
  // ==========================================
  Widget _buildAnalyticsTab() {
    final t = belumiCopy(context).t;
    return LuxuryPage(
      children: [
        Builder(
          builder: (context) {
            final isMobile = MediaQuery.sizeOf(context).width < 600;
            final headerContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('Báo cáo phân tích', 'Analytics Reports'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: BelumiLuxury.black,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  t('Thống kê dữ liệu hoạt động & doanh thu', 'Operations & revenue insights'),
                  style: TextStyle(color: BelumiLuxury.muted, fontSize: 13),
                ),
              ],
            );
            final actionButtons = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                LuxuryButton(
                  label: t('Tin tức', 'News'),
                  icon: Icons.article_outlined,
                  outlined: true,
                  onPressed: () => _changeView(3),
                ),
                LuxuryButton(
                  label: t('Thành phần', 'Ingredients'),
                  icon: Icons.science_outlined,
                  outlined: true,
                  onPressed: () => _changeView(4),
                ),
              ],
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  headerContent,
                  const SizedBox(height: 12),
                  actionButtons,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                headerContent,
                actionButtons,
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        _buildPeriodSelector(),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, dynamic>>(
          future: _analyticsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(
                        t('Không thể kết nối máy chủ để tải dữ liệu thống kê.', 'Cannot fetch analytics data from server.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              );
            }

            try {
              final data = snapshot.data ?? const <String, dynamic>{};
              final overview = (data['overview'] ?? data['Overview']) as Map<String, dynamic>? ?? {};
              final distributions = (data['distributions'] ?? data['Distributions']) as Map<String, dynamic>? ?? {};
              final recentActivities = (data['recentActivities'] ?? data['RecentActivities']) as List<dynamic>? ?? [];
              final timeSeries = (data['timeSeries'] ?? data['TimeSeries']) as List<dynamic>? ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPIGrid(overview),
                  const SizedBox(height: 18),
                  _buildChartSection(timeSeries),
                  const SizedBox(height: 18),
                  _buildDistributionsSection(distributions),
                  const SizedBox(height: 18),
                  _buildRecentActivitiesSection(recentActivities),
                ],
              );
            } catch (e, st) {
              debugPrint("Lỗi vẽ thống kê: $e\n$st");
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning_amber_outlined, color: Colors.orange, size: 40),
                      const SizedBox(height: 12),
                      const Text(
                        'Lỗi xử lý dữ liệu thống kê.',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$e',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Builder(
      builder: (context) {
        final isMobile = MediaQuery.sizeOf(context).width < 600;
        final selector = Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF1DFD8)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption('daily', 'Ngày'),
              _buildPeriodOption('monthly', 'Tháng'),
              _buildPeriodOption('yearly', 'Năm'),
            ],
          ),
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Làm mới dữ liệu',
              icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
              onPressed: _loadAnalytics,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                _showSuccessSnackBar('Tính năng xuất báo cáo Excel đang được chuẩn bị.');
              },
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Xuất báo cáo', style: TextStyle(fontSize: 12)),
            )
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              selector,
              const SizedBox(height: 10),
              actions,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            selector,
            actions,
          ],
        );
      },
    );
  }

  Widget _buildPeriodOption(String key, String label) {
    final isSelected = _selectedPeriod == key;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod == key) return;
        setState(() {
          _selectedPeriod = key;
        });
        _loadAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BelumiLuxury.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : BelumiLuxury.muted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(Map<String, dynamic> overview) {
    final t = belumiCopy(context).t;
    final totalRev = (overview['totalRevenue'] ?? overview['TotalRevenue']) as num? ?? 0;
    final revGrowth = (overview['revenueGrowthPercent'] ?? overview['RevenueGrowthPercent']) as num? ?? 0;
    final newUsers = (overview['newUsers'] ?? overview['NewUsers']) as num? ?? 0;
    final userGrowth = (overview['userGrowthPercent'] ?? overview['UserGrowthPercent']) as num? ?? 0;
    final scans = (overview['totalScans'] ?? overview['TotalScans']) as num? ?? 0;
    final scanGrowth = (overview['scanGrowthPercent'] ?? overview['ScanGrowthPercent']) as num? ?? 0;
    final conversion = (overview['conversionRate'] ?? overview['ConversionRate']) as num? ?? 0;
    final premiumCount = (overview['premiumUsersCount'] ?? overview['PremiumUsersCount']) as num? ?? 0;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildKPICard(
          title: t('DOANH THU', 'REVENUE'),
          value: _formatVND(totalRev.toDouble()),
          subtitle: 'Kỳ này',
          growth: revGrowth.toDouble(),
          color1: const Color(0xFFF39C12),
          color2: const Color(0xFFE67E22),
          icon: Icons.monetization_on_outlined,
        ),
        _buildKPICard(
          title: t('THÀNH VIÊN MỚI', 'NEW MEMBERS'),
          value: newUsers.toString(),
          subtitle: 'Kỳ này',
          growth: userGrowth.toDouble(),
          color1: const Color(0xFF3498DB),
          color2: const Color(0xFF2980B9),
          icon: Icons.person_add_alt_1_outlined,
        ),
        _buildKPICard(
          title: t('QUÉT AI & TRA CỨU', 'AI SCANS & LOOKUPS'),
          value: scans.toString(),
          subtitle: 'Kỳ này',
          growth: scanGrowth.toDouble(),
          color1: const Color(0xFF9B59B6),
          color2: const Color(0xFF8E44AD),
          icon: Icons.auto_awesome_outlined,
        ),
        _buildKPICard(
          title: t('TỶ LỆ PREMIUM', 'PREMIUM CONVERSION'),
          value: '$conversion%',
          subtitle: 'Premium: $premiumCount',
          growth: 0.0,
          color1: const Color(0xFF1ABC9C),
          color2: const Color(0xFF16A085),
          icon: Icons.workspace_premium_outlined,
          showGrowth: false,
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required String subtitle,
    required double growth,
    required Color color1,
    required Color color2,
    required IconData icon,
    bool showGrowth = true,
  }) {
    final double cardWidth = (MediaQuery.sizeOf(context).width - 36 - 12) / 2;
    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    return Container(
      width: isDesktop ? (1040 - 36) / 4 : cardWidth.clamp(140.0, 500.0),
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color2.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 70,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    if (showGrowth) ...[
                      Icon(
                        growth >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: growth >= 0 ? Colors.greenAccent.shade100 : Colors.redAccent.shade100,
                        size: 11,
                      ),
                      Text(
                        '${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: growth >= 0 ? Colors.greenAccent.shade100 : Colors.redAccent.shade100,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    ]
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // CHARTS IMPLEMENTATION
  // ==========================================
  Widget _buildChartSection(List<dynamic> timeSeries) {
    if (timeSeries.isEmpty) {
      return const LuxuryPanel(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('Không có dữ liệu chu kỳ này.')),
        ),
      );
    }

    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.sizeOf(context).width < 500;
              final titleText = Text(
                _showRevenueChart ? 'Xu hướng Doanh thu' : 'Xu hướng Người dùng & Quét AI',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: BelumiLuxury.ink,
                ),
              );

              final toggleButton = TextButton.icon(
                icon: Icon(
                  _showRevenueChart ? Icons.people_outline : Icons.monetization_on_outlined,
                  size: 16,
                  color: BelumiLuxury.ink,
                ),
                label: Text(
                  _showRevenueChart ? 'Xem Lượt truy cập' : 'Xem Doanh thu',
                  style: const TextStyle(color: BelumiLuxury.ink, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                onPressed: () {
                  setState(() => _showRevenueChart = !_showRevenueChart);
                },
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleText,
                    toggleButton,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  titleText,
                  toggleButton,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 230,
            child: _showRevenueChart
                ? _buildRevenueBarChart(timeSeries)
                : _buildActivityLineChart(timeSeries),
          ),
          const SizedBox(height: 12),
          _buildChartLegend(),
        ],
      ),
    );
  }

  Widget _buildChartLegend() {
    if (_showRevenueChart) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 12, height: 12, decoration: const BoxDecoration(color: BelumiLuxury.ink, borderRadius: BorderRadius.all(Radius.circular(2)))),
          const SizedBox(width: 6),
          const Text('Doanh thu (VND)', style: TextStyle(fontSize: 12, color: BelumiLuxury.muted)),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF3498DB), borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 6),
        const Text('Thành viên mới', style: TextStyle(fontSize: 12, color: BelumiLuxury.muted)),
        const SizedBox(width: 20),
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF9B59B6), borderRadius: BorderRadius.all(Radius.circular(2)))),
        const SizedBox(width: 6),
        const Text('Lượt quét AI & Tra cứu', style: TextStyle(fontSize: 12, color: BelumiLuxury.muted)),
      ],
    );
  }

  Widget _buildRevenueBarChart(List<dynamic> timeSeries) {
    double maxVal = 0.0;
    for (var pt in timeSeries) {
      final rev = ((pt['revenue'] ?? pt['Revenue']) as num? ?? 0).toDouble();
      if (rev > maxVal) maxVal = rev;
    }
    if (maxVal == 0.0) maxVal = 1000.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: timeSeries.map((pt) {
            final label = (pt['label'] ?? pt['Label']) as String? ?? '';
            final rev = ((pt['revenue'] ?? pt['Revenue']) as num? ?? 0).toDouble();
            final height = (rev / maxVal) * 150; // max height 150

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    rev > 0 ? _formatCurrency(rev) : '0',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: BelumiLuxury.ink),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 16,
                    height: height.clamp(4.0, 150.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2C3E50), BelumiLuxury.ink],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: BelumiLuxury.muted),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivityLineChart(List<dynamic> timeSeries) {
    double maxVal = 0.0;
    for (var pt in timeSeries) {
      final u = ((pt['newUsers'] ?? pt['NewUsers']) as num? ?? 0).toDouble();
      final s = ((pt['scans'] ?? pt['Scans']) as num? ?? 0).toDouble();
      if (u > maxVal) maxVal = u;
      if (s > maxVal) maxVal = s;
    }
    if (maxVal == 0.0) maxVal = 10.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: timeSeries.map((pt) {
            final label = (pt['label'] ?? pt['Label']) as String? ?? '';
            final u = ((pt['newUsers'] ?? pt['NewUsers']) as num? ?? 0).toDouble();
            final s = ((pt['scans'] ?? pt['Scans']) as num? ?? 0).toDouble();

            final uHeight = (u / maxVal) * 150;
            final sHeight = (s / maxVal) * 150;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        u.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF2980B9)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 8,
                        height: uHeight.clamp(2.0, 150.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Container(
                        width: 8,
                        height: sHeight.clamp(2.0, 150.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: BelumiLuxury.muted),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ==========================================
  // DISTRIBUTIONS SECTION
  // ==========================================
  Widget _buildDistributionsSection(Map<String, dynamic> distributions) {
    final t = belumiCopy(context).t;
    final subscriptionPlans = (distributions['subscriptionPlans'] ?? distributions['SubscriptionPlans']) as List<dynamic>? ?? [];
    final skinTypes = (distributions['skinTypes'] ?? distributions['SkinTypes']) as List<dynamic>? ?? [];
    final topIngredients = (distributions['topIngredients'] ?? distributions['TopIngredients']) as List<dynamic>? ?? [];

    final isDesktop = MediaQuery.sizeOf(context).width >= 760;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildDistributionCard(t('Gói dịch vụ', 'Subscription Plans'), subscriptionPlans, _getPlanColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildDistributionCard(t('Phân bố loại da', 'Skin Types Distribution'), skinTypes, _getSkinColor)),
          const SizedBox(width: 12),
          Expanded(child: _buildTopIngredientsCard(topIngredients)),
        ],
      );
    }

    return Column(
      children: [
        _buildDistributionCard(t('Gói dịch vụ', 'Subscription Plans'), subscriptionPlans, _getPlanColor),
        const SizedBox(height: 14),
        _buildDistributionCard(t('Phân bố loại da', 'Skin Types Distribution'), skinTypes, _getSkinColor),
        const SizedBox(height: 14),
        _buildTopIngredientsCard(topIngredients),
      ],
    );
  }

  Color _getPlanColor(String name) {
    switch (name.toLowerCase()) {
      case 'yearly':
      case 'gói năm':
        return BelumiLuxury.ink;
      case 'monthly':
      case 'gói tháng':
        return BelumiLuxury.rose;
      default:
        return const Color(0xFFBDC3C7);
    }
  }

  Color _getSkinColor(String name) {
    switch (name.toLowerCase()) {
      case 'oily':
      case 'da dầu':
        return const Color(0xFFE67E22);
      case 'dry':
      case 'da khô':
        return const Color(0xFF3498DB);
      case 'sensitive':
      case 'da nhạy cảm':
        return const Color(0xFFE74C3C);
      case 'combination':
      case 'da hỗn hợp':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF2ECC71);
    }
  }

  Widget _buildDistributionCard(String title, List<dynamic> items, Color Function(String) colorSelector) {
    final double totalCount = items.fold<double>(
      0.0,
      (sum, x) => sum + ((x['count'] ?? x['Count']) as num? ?? 0).toDouble(),
    );

    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BelumiLuxury.ink),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty || totalCount == 0)
            const SizedBox(height: 120, child: Center(child: Text('Không có dữ liệu.')))
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    width: double.infinity,
                    child: Row(
                      children: items.where((x) {
                        final count = (x['count'] ?? x['Count']) as num? ?? 0;
                        return count > 0;
                      }).map((x) {
                        final name = (x['name'] ?? x['Name']) as String? ?? 'Chưa rõ';
                        final count = (x['count'] ?? x['Count']) as num? ?? 0;
                        final double pct = totalCount > 0 ? count.toDouble() / totalCount : 0.0;
                        return Expanded(
                          flex: (pct * 1000).toInt().clamp(1, 1000),
                          child: Container(
                            color: colorSelector(name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...items.map((x) {
                  final name = (x['name'] ?? x['Name']) as String? ?? 'Chưa rõ';
                  final percent = ((x['percentage'] ?? x['Percentage']) as num? ?? 0).toDouble();
                  final count = (x['count'] ?? x['Count']) as num? ?? 0;
                  final double pct = totalCount > 0 ? count.toDouble() / totalCount : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: colorSelector(name), shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${percent.toStringAsFixed(1)}% ($count)',
                              style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                            )
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: const Color(0xFFF9F9F9),
                            valueColor: AlwaysStoppedAnimation<Color>(colorSelector(name)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTopIngredientsCard(List<dynamic> ingredients) {
    final t = belumiCopy(context).t;
    int maxCount = 1;
    if (ingredients.isNotEmpty) {
      maxCount = ingredients.map((x) => (x['count'] as num? ?? 0).toInt()).reduce((a, b) => a > b ? a : b);
      if (maxCount == 0) maxCount = 1;
    }

    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Top tìm kiếm thành phần', 'Top Ingredients Searched'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: BelumiLuxury.ink),
          ),
          const SizedBox(height: 14),
          if (ingredients.isEmpty)
            const SizedBox(height: 120, child: Center(child: Text('Chưa có lượt tra cứu nào.')))
          else
            ...ingredients.map((x) {
              final name = (x['name'] ?? x['Name']) as String? ?? 'Chưa rõ';
              final count = (x['count'] ?? x['Count']) as num? ?? 0;
              final ratio = count / maxCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text('$count lượt', style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio.toDouble(),
                        backgroundColor: Colors.grey.shade100,
                        color: BelumiLuxury.rose,
                        minHeight: 6,
                      ),
                    )
                  ],
                ),
              );
            })
        ],
      ),
    );
  }

  // ==========================================
  // RECENT ACTIVITIES TIMELINE
  // ==========================================
  Widget _buildRecentActivitiesSection(List<dynamic> activities) {
    final t = belumiCopy(context).t;
    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Dòng hoạt động gần đây', 'Recent Activities'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: BelumiLuxury.ink),
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Không có hoạt động gần đây.')),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final act = activities[index] as Map<String, dynamic>;
                final type = (act['type'] ?? act['Type']) as String? ?? '';
                final title = (act['title'] ?? act['Title']) as String? ?? '';
                final subtitle = (act['subtitle'] ?? act['Subtitle']) as String? ?? '';
                final timestamp = (act['timestamp'] ?? act['Timestamp']) as String? ?? '';

                IconData icon = Icons.info_outline;
                Color color = Colors.grey;

                if (type == 'payment') {
                  icon = Icons.shopping_bag_outlined;
                  color = Colors.teal;
                } else if (type == 'signup') {
                  icon = Icons.person_add_outlined;
                  color = Colors.blue;
                } else if (type == 'scan') {
                  icon = Icons.auto_awesome;
                  color = Colors.purple;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getRelativeTime(timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      )
                    ],
                  ),
                );
              },
            )
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: USERS LIST & MANAGEMENT
  // ==========================================
  Widget _buildUsersTab() {
    final t = belumiCopy(context).t;
    if (_loadingUsers && _users == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final usersList = _users ?? [];
    final filtered = usersList.where((x) {
      final email = ((x['email'] ?? x['Email']) as String? ?? '').toLowerCase();
      final name = ((x['fullName'] ?? x['FullName']) as String? ?? '').toLowerCase();
      final q = _userSearchQuery.toLowerCase();
      return email.contains(q) || name.contains(q);
    }).toList();

    return LuxuryPage(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Quản lý người dùng', 'User Management'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BelumiLuxury.black,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
              onPressed: _fetchUsers,
            )
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: TextField(
            decoration: InputDecoration(
              hintText: t('Tìm kiếm theo Email, Tên...', 'Search email, name...'),
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
              ),
            ),
            onChanged: (val) => setState(() => _userSearchQuery = val),
          ),
        ),
        const SizedBox(height: 16),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingUsers) const LinearProgressIndicator(),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(t('Không tìm thấy người dùng nào.', 'No users match criteria.')),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final user = filtered[idx];
                    final isActive = (user['isActive'] ?? user['IsActive']) as bool? ?? true;
                    final email = (user['email'] ?? user['Email']) as String? ?? '';
                    final name = (user['fullName'] ?? user['FullName']) as String? ?? 'Chưa đặt tên';
                    final roleVal = user['role'] ?? user['Role'];
                    final role = roleVal is int
                        ? (roleVal == 1 ? 'Admin' : 'Customer')
                        : (roleVal?.toString() ?? 'Customer');
                    final plan = (user['subscriptionPlan'] ?? user['SubscriptionPlan']) as String? ?? 'Free';
                    final regDate = (user['createdAt'] ?? user['CreatedAt']) as String? ?? '';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1DFD8), width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (role == 'Admin')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade800,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 9)),
                                      ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: plan == 'Free' ? Colors.grey.shade400 : BelumiLuxury.ink,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        plan,
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Đăng ký: ${_formatDate(regDate)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.teal.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: (isActive ? Colors.teal.shade700 : Colors.red.shade700).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        isActive ? 'Đang hoạt động' : 'Đã khóa',
                                        style: TextStyle(
                                          color: isActive ? Colors.teal.shade700 : Colors.red.shade700,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (role != 'Admin')
                            Switch(
                              value: isActive,
                              activeThumbColor: Colors.teal.shade700,
                              inactiveTrackColor: Colors.red.shade100,
                              inactiveThumbColor: Colors.red.shade700,
                              onChanged: (_) => _toggleUserStatus(user),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: AI USAGE LOGS
  // ==========================================
  Widget _buildAiLogsTab() {
    final t = belumiCopy(context).t;
    if (_loadingAiLogs && _aiLogs == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final logs = _aiLogs ?? [];

    return LuxuryPage(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Lịch sử cuộc gọi AI', 'AI Usage Logs'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BelumiLuxury.black,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
              onPressed: _fetchAiLogs,
            )
          ],
        ),
        const SizedBox(height: 12),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingAiLogs) const LinearProgressIndicator(),
              if (logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có bản ghi hoạt động AI nào.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    final id = (log['id'] ?? log['Id'])?.toString() ?? idx.toString();
                    final feature = (log['featureName'] ?? log['FeatureName']) as String? ?? 'N/A';
                    final token = (log['tokenUsed'] ?? log['TokenUsed']) as num? ?? 0;
                    final date = (log['createdAt'] ?? log['CreatedAt']) as String? ?? '';
                    final userMap = (log['user'] ?? log['User']) as Map<String, dynamic>?;
                    final userEmail = userMap != null ? ((userMap['email'] ?? userMap['Email']) as String? ?? 'Ẩn danh') : 'Ẩn danh';
                    final isExpanded = _expandedLogIds.contains(id);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Text(feature, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.purple.shade200),
                                ),
                                child: Text(
                                  '$token tokens',
                                  style: TextStyle(color: Colors.purple.shade800, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                          subtitle: Text('User: $userEmail\nThời gian: ${_formatDate(date)}'),
                          trailing: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: BelumiLuxury.muted,
                          ),
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedLogIds.remove(id);
                              } else {
                                _expandedLogIds.add(id);
                              }
                            });
                          },
                        ),
                        if (isExpanded)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Dữ liệu gửi lên:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: BelumiLuxury.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  (log['requestData'] ?? log['RequestData'])?.toString() ?? 'Trống',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey.shade800),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Kết quả phản hồi:',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: BelumiLuxury.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  log['responseData'] as String? ?? 'Trống',
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          )
                      ],
                    );
                  },
                )
            ],
          ),
        )
      ],
    );
  }

  // ==========================================
  // TAB 4: CONTACT REQUESTS MANAGEMENT
  // ==========================================
  Widget _buildContactsTab() {
    final t = belumiCopy(context).t;
    if (_loadingContacts && _contacts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _contacts ?? [];

    return LuxuryPage(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Yêu cầu hỗ trợ', 'Contact Requests'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BelumiLuxury.black,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
              onPressed: _fetchContacts,
            )
          ],
        ),
        const SizedBox(height: 12),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingContacts) const LinearProgressIndicator(),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Chưa có yêu cầu hỗ trợ nào.')),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = list[idx];
                    final name = (item['fullName'] ?? item['FullName']) as String? ?? 'N/A';
                    final phone = (item['phone'] ?? item['Phone']) as String? ?? 'N/A';
                    final email = (item['email'] ?? item['Email']) as String? ?? 'N/A';
                    final msg = (item['message'] ?? item['Message']) as String? ?? 'Trống';
                    final status = _parseContactStatus(item['status'] ?? item['Status']);
                    final date = (item['createdAt'] ?? item['CreatedAt']) as String? ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              _buildStatusBadge(status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('SĐT: $phone | Email: $email', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 6),
                          Text(msg, style: const TextStyle(fontSize: 13, height: 1.3)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Gửi lúc: ${_formatDate(date)}',
                                style: const TextStyle(fontSize: 10, color: BelumiLuxury.muted),
                              ),
                              Row(
                                children: [
                                  const Text('Đổi trạng thái: ', style: TextStyle(fontSize: 11)),
                                  DropdownButton<String>(
                                    value: status,
                                    elevation: 2,
                                    underline: const SizedBox(),
                                    style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
                                    items: ['New', 'InProgress', 'Resolved'].map((s) {
                                      return DropdownMenuItem<String>(
                                        value: s,
                                        child: Text(_translateStatus(s)),
                                      );
                                    }).toList(),
                                    onChanged: (newVal) {
                                      if (newVal != null && newVal != status) {
                                        _updateContactStatus(item, newVal);
                                      }
                                    },
                                  )
                                ],
                              )
                            ],
                          )
                        ],
                      ),
                    );
                  },
                )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;
    if (status == 'New') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
    } else if (status == 'InProgress') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    } else if (status == 'Resolved') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Text(
        _translateStatus(status),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _translateStatus(String s) {
    if (s == 'New') return 'Chưa xử lý';
    if (s == 'InProgress') return 'Đang xử lý';
    if (s == 'Resolved') return 'Đã xong';
    return s;
  }

  String _formatDate(String isoString) {
    try {
      final parsed = DateTime.parse(isoString);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildPaymentsTab() {
    final t = belumiCopy(context).t;
    if (_loadingPayments && _payments == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final paymentsList = _payments ?? [];
    
    double totalRevenue = 0.0;
    int successfulCount = 0;
    int pendingCount = 0;
    double totalPendingAmount = 0.0;

    for (var payment in paymentsList) {
      final amount = ((payment['amount'] ?? payment['Amount']) as num? ?? 0).toDouble();
      final status = (payment['paymentStatus'] ?? payment['PaymentStatus']) as String? ?? 'Pending';
      final isPaid = status == 'Paid' || status == 'MockPaid';
      if (isPaid) {
        totalRevenue += amount;
        successfulCount++;
      } else {
        totalPendingAmount += amount;
        pendingCount++;
      }
    }

    final filtered = paymentsList.where((x) {
      final email = ((x['userEmail'] ?? x['UserEmail']) as String? ?? '').toLowerCase();
      final name = ((x['userFullName'] ?? x['UserFullName']) as String? ?? '').toLowerCase();
      final code = ((x['transactionCode'] ?? x['TransactionCode']) as String? ?? '').toLowerCase();
      final q = _paymentSearchQuery.toLowerCase();
      return email.contains(q) || name.contains(q) || code.contains(q);
    }).toList();

    return LuxuryPage(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('Quản lý doanh thu', 'Revenue Management'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: BelumiLuxury.black,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
              onPressed: _fetchPayments,
            )
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildKPICard(
              title: t('TỔNG DOANH THU', 'TOTAL REVENUE'),
              value: _formatVND(totalRevenue),
              subtitle: t('Đã thanh toán', 'Paid'),
              growth: 0.0,
              color1: const Color(0xFF2ECC71),
              color2: const Color(0xFF27AE60),
              icon: Icons.monetization_on_outlined,
              showGrowth: false,
            ),
            _buildKPICard(
              title: t('GIAO DỊCH THÀNH CÔNG', 'SUCCESSFUL TRANS.'),
              value: successfulCount.toString(),
              subtitle: t('Giao dịch thành công', 'Successful'),
              growth: 0.0,
              color1: const Color(0xFF3498DB),
              color2: const Color(0xFF2980B9),
              icon: Icons.check_circle_outline,
              showGrowth: false,
            ),
            _buildKPICard(
              title: t('GIAO DỊCH CHỜ', 'PENDING TRANS.'),
              value: pendingCount.toString(),
              subtitle: t('Đang chờ xử lý', 'Pending'),
              growth: 0.0,
              color1: const Color(0xFFF1C40F),
              color2: const Color(0xFFF39C12),
              icon: Icons.hourglass_empty_outlined,
              showGrowth: false,
            ),
            _buildKPICard(
              title: t('SỐ TIỀN CHỜ XỬ LÝ', 'PENDING AMOUNT'),
              value: _formatVND(totalPendingAmount),
              subtitle: t('Chưa thanh toán', 'Unpaid'),
              growth: 0.0,
              color1: const Color(0xFFE74C3C),
              color2: const Color(0xFFC0392B),
              icon: Icons.pending_actions_outlined,
              showGrowth: false,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: TextField(
            decoration: InputDecoration(
              hintText: t('Tìm kiếm theo Email, Tên, Mã giao dịch...', 'Search email, name, transaction code...'),
              prefixIcon: const Icon(Icons.search),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
              ),
            ),
            onChanged: (val) => setState(() => _paymentSearchQuery = val),
          ),
        ),
        const SizedBox(height: 16),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingPayments) const LinearProgressIndicator(),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(t('Không tìm thấy giao dịch nào.', 'No transactions found.')),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final payment = filtered[idx];
                    final amount = (payment['amount'] ?? payment['Amount']) as num? ?? 0;
                    final email = (payment['userEmail'] ?? payment['UserEmail']) as String? ?? 'Ẩn danh';
                    final name = (payment['userFullName'] ?? payment['UserFullName']) as String? ?? 'Ẩn danh';
                    final planName = (payment['planName'] ?? payment['PlanName']) as String? ?? 'Chưa rõ';
                    final status = (payment['paymentStatus'] ?? payment['PaymentStatus']) as String? ?? 'Pending';
                    final method = (payment['paymentMethod'] ?? payment['PaymentMethod']) as String? ?? 'Mock';
                    final code = (payment['transactionCode'] ?? payment['TransactionCode']) as String? ?? 'N/A';
                    final date = (payment['createdAt'] ?? payment['CreatedAt']) as String? ?? '';

                    final isPaid = status == 'Paid' || status == 'MockPaid';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF1DFD8), width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isPaid ? Colors.teal.shade800 : Colors.red.shade800,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        isPaid ? 'Thành công' : 'Chờ xử lý',
                                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        method,
                                        style: const TextStyle(color: Colors.white, fontSize: 9),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Gói: $planName | Mã GD: $code',
                                  style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Thời gian: ${_formatDate(date)}',
                                  style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatVND(amount.toDouble()),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isPaid ? Colors.teal.shade800 : Colors.red.shade800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
