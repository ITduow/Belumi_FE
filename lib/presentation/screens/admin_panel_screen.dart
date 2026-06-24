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

  String _formatVND(double val) {
    return '${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} đ';
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

    Widget buildActiveView() {
      switch (_selectedViewIndex) {
        case 0:
          return _buildAnalyticsTab();
        case 1:
          return _buildPaymentsTab();
        case 2:
          return _buildUsersTab();
        case 3:
          return AdminNewsScreen(repository: widget.repository, embedMode: true);
        case 4:
          return AdminIngredientsScreen(repository: widget.repository, embedMode: true);
        case 5:
          return _buildAiLogsTab();
        case 6:
          return _buildContactsTab();
        default:
          return const SizedBox();
      }
    }

    final activeView = buildActiveView();
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
        Text(
          t('Báo cáo thống kê', 'Statistics Report'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: BelumiLuxury.black,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          t('Tổng quan hoạt động & doanh thu',
              'Overview of operations & revenue'),
          style: const TextStyle(color: BelumiLuxury.muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        _buildPeriodSelector(),
        const SizedBox(height: 18),
        FutureBuilder<Map<String, dynamic>>(
          future: _analyticsFuture,
          builder: (ctx, snapshot) {
            debugPrint(
                "Thong ke FutureBuilder: state=${snapshot.connectionState}, "
                "hasData=${snapshot.hasData}, hasError=${snapshot.hasError}");
            if (snapshot.hasData) {
              debugPrint("Thong ke du lieu: ${snapshot.data}");
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      t('Không thể tải dữ liệu thống kê.',
                          'Cannot load statistics.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 6),
                    Text('${snapshot.error}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            try {
              final data = snapshot.data ?? {};
              final overview = (data['overview'] ?? data['Overview'])
                      as Map<String, dynamic>? ??
                  {};
              final timeSeries =
                  (data['timeSeries'] ?? data['TimeSeries'])
                          as List<dynamic>? ??
                      [];
              final distributions =
                  (data['distributions'] ?? data['Distributions'])
                          as Map<String, dynamic>? ??
                      {};

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewCards(t, overview),
                  const SizedBox(height: 24),
                  _buildTimeSeriesTable(t, timeSeries),
                  const SizedBox(height: 24),
                  _buildPlanDistribution(t, distributions),
                ],
              );
            } catch (e, st) {
              debugPrint("Lỗi vẽ thống kê: $e\n$st");
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_outlined,
                        color: Colors.orange, size: 36),
                    const SizedBox(height: 10),
                    const Text('Lỗi xử lý dữ liệu thống kê.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(height: 6),
                    Text('$e',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF1DFD8)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _periodChip('daily', 'Ngày'),
              _periodChip('monthly', 'Tháng'),
              _periodChip('yearly', 'Năm'),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Làm mới dữ liệu',
          icon: const Icon(Icons.refresh, color: BelumiLuxury.ink),
          onPressed: _loadAnalytics,
        ),
      ],
    );
  }

  Widget _periodChip(String key, String label) {
    final active = _selectedPeriod == key;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod == key) return;
        setState(() => _selectedPeriod = key);
        _loadAnalytics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? BelumiLuxury.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : BelumiLuxury.muted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // -- KPI Overview Cards --
  Widget _buildOverviewCards(
      String Function(String, String) t, Map<String, dynamic> o) {
    num v(String c, String p) => (o[c] ?? o[p]) as num? ?? 0;

    final totalRev = v('totalRevenue', 'TotalRevenue').toDouble();
    final revGrowth =
        v('revenueGrowthPercent', 'RevenueGrowthPercent').toDouble();
    final newUsers = v('newUsers', 'NewUsers').toInt();
    final userGrowth =
        v('userGrowthPercent', 'UserGrowthPercent').toDouble();
    final totalUsers = v('totalUsers', 'TotalUsers').toInt();
    final premiumCount =
        v('premiumUsersCount', 'PremiumUsersCount').toInt();
    final premiumPurchases =
        v('premiumPurchases', 'PremiumPurchases').toInt();
    final totalArticles = v('totalArticles', 'TotalArticles').toInt();
    final newArticles = v('newArticles', 'NewArticles').toInt();
    final conversion = v('conversionRate', 'ConversionRate').toDouble();

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final cols = w >= 900 ? 5 : (w >= 500 ? 3 : 2);
        final gap = 12.0;
        final cw = (w - gap * (cols - 1)) / cols;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _statCard(cw, t('DOANH THU', 'REVENUE'),
                _formatVND(totalRev), Icons.monetization_on_outlined,
                const Color(0xFF1B76FF),
                growth: revGrowth,
                sub: t('so với kỳ trước', 'vs prev')),
            _statCard(cw, t('NGƯỜI DÙNG MỚI', 'NEW USERS'),
                '$newUsers', Icons.person_add_alt_1_outlined,
                const Color(0xFF1F1F2C),
                growth: userGrowth,
                sub: t('so với kỳ trước', 'vs prev')),
            _statCard(cw, t('MUA GÓI PREMIUM', 'PREMIUM'),
                '$premiumPurchases', Icons.workspace_premium_outlined,
                const Color(0xFF1B76FF),
                sub: '${t("Tổng", "Total")}: $premiumCount'),
            _statCard(cw, t('BÀI VIẾT MỚI', 'NEW ARTICLES'),
                '$newArticles', Icons.article_outlined,
                const Color(0xFF1F1F2C),
                sub: '${t("Tổng", "Total")}: $totalArticles'),
            _statCard(cw, t('TỔNG NGƯỜI DÙNG', 'TOTAL USERS'),
                '$totalUsers', Icons.people_outline,
                const Color(0xFF1B76FF),
                sub: 'Premium: ${conversion.toStringAsFixed(1)}%'),
          ],
        );
      },
    );
  }

  Widget _statCard(double width, String title, String value,
      IconData icon, Color bg,
      {double? growth, String sub = ''}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: bg.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5)),
              ),
              Icon(icon,
                  size: 16, color: Colors.white.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (growth != null) ...[
                Icon(
                    growth >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 12,
                    color: growth >= 0
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE74C3C)),
                const SizedBox(width: 3),
                Text(
                    '${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: growth >= 0
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE74C3C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- Time Series Table --
  Widget _buildTimeSeriesTable(
      String Function(String, String) t, List<dynamic> series) {
    if (series.isEmpty) {
      return LuxuryPanel(
        child: SizedBox(
          height: 100,
          child: Center(
              child: Text(
                  t('Không có dữ liệu xu hướng.', 'No trend data.'),
                  style: const TextStyle(color: BelumiLuxury.muted))),
        ),
      );
    }

    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('Biến động theo thời gian', 'Trends over Time'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1F1F2C))),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FixedColumnWidth(140),
                2: FixedColumnWidth(100),
                3: FixedColumnWidth(100),
                4: FixedColumnWidth(80),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                    color: Colors.grey.shade200, width: 0.5),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade300))),
                  children: [
                    _tHead(t('Thời gian', 'Period')),
                    _tHead(t('Doanh thu', 'Revenue')),
                    _tHead(t('TV mới', 'New Users')),
                    _tHead(t('Premium', 'Premium')),
                    _tHead(t('Bài viết', 'Articles')),
                  ],
                ),
                ...series.map((pt) {
                  final label =
                      (pt['label'] ?? pt['Label']) as String? ?? '';
                  final rev =
                      ((pt['revenue'] ?? pt['Revenue']) as num? ?? 0)
                          .toDouble();
                  final u =
                      (pt['newUsers'] ?? pt['NewUsers']) as num? ?? 0;
                  final p = (pt['premiumPurchases'] ??
                          pt['PremiumPurchases']) as num? ??
                      0;
                  final art = (pt['newArticles'] ??
                          pt['NewArticles']) as num? ??
                      0;
                  return TableRow(children: [
                    _tCell(label, bold: true),
                    _tCell(_formatVND(rev),
                        color: const Color(0xFF1B76FF)),
                    _tCell('$u'),
                    _tCell('$p'),
                    _tCell('$art'),
                  ]);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Padding _tHead(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(s,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1F1F2C))),
      );

  Padding _tCell(String s, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(s,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: color ?? const Color(0xFF1F1F2C))),
      );

  // -- Subscription Plan Distribution --
  Widget _buildPlanDistribution(
      String Function(String, String) t, Map<String, dynamic> dist) {
    final plans = (dist['subscriptionPlans'] ??
            dist['SubscriptionPlans']) as List<dynamic>? ??
        [];
    if (plans.isEmpty) {
      return LuxuryPanel(
        child: SizedBox(
          height: 100,
          child: Center(
              child: Text(
                  t('Không có dữ liệu gói.', 'No plan data.'),
                  style: const TextStyle(color: BelumiLuxury.muted))),
        ),
      );
    }

    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('Phân bố gói dịch vụ', 'Plan Distribution'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1F1F2C))),
          const SizedBox(height: 16),
          ...plans.map((item) {
            final m = item is Map
                ? Map<String, dynamic>.from(item)
                : <String, dynamic>{};
            final name = (m['name'] ?? m['Name']) as String? ?? '?';
            final count =
                ((m['count'] ?? m['Count']) as num? ?? 0).toInt();
            final pct =
                ((m['percentage'] ?? m['Percentage']) as num? ?? 0)
                    .toDouble();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      Text('$count (${pct.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              color: Color(0xFF8A94A6), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE8EAF0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B76FF)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // -- KPI Card (used by Payments tab) --
  Widget _buildKPICard({
    required String title,
    required String value,
    required double growth,
    required IconData icon,
    required String subtitle,
    Color? color1,
    Color? color2,
    bool? isBlue,
    bool showGrowth = true,
  }) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 760;
    final double cardW = isDesktop ? 230.0 : 155.0;
    final bool hasGradient = color1 != null && color2 != null;
    final Color bg = hasGradient
        ? color1
        : ((isBlue ?? true)
            ? const Color(0xFF1B76FF)
            : const Color(0xFF1F1F2C));

    return Container(
      width: cardW,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: (color1 != null && color2 != null)
            ? LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: hasGradient ? null : bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: bg.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (showGrowth) ...[
                Icon(
                    growth >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 12,
                    color: growth >= 0
                        ? const Color(0xFF2ECC71)
                        : const Color(0xFFE74C3C)),
                const SizedBox(width: 2),
                Text(
                    '${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: growth >= 0
                            ? const Color(0xFF2ECC71)
                            : const Color(0xFFE74C3C),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10)),
              ),
            ],
          ),
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


