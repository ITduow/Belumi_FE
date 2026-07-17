import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../widgets/belumi_luxury.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({
    super.key,
    required this.repository,
    required this.planId,
  });

  final BelumiRepository repository;
  final String planId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PayOsPaymentLinkResponse? _paymentLink;
  Plan? _selectedPlan;
  bool _paymentSuccess = false;

  final TextEditingController _voucherController = TextEditingController();
  final FocusNode _voucherFocusNode = FocusNode();
  bool _isValidatingVoucher = false;
  String? _voucherError;
  String? _appliedVoucherCode;
  num _discountAmount = 0;

  @override
  void initState() {
    super.initState();
    _voucherFocusNode.addListener(_onVoucherFocusChange);
    _initPayment();
  }

  @override
  void dispose() {
    _voucherFocusNode.removeListener(_onVoucherFocusChange);
    _voucherFocusNode.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  void _onVoucherFocusChange() {
    if (!_voucherFocusNode.hasFocus) {
      _applyVoucher();
    }
  }

  Future<void> _initPayment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final plans = await widget.repository.plans();
      _selectedPlan = plans.firstWhere(
        (p) => p.id == widget.planId,
        orElse: () => throw ArgumentError('Không tìm thấy gói cước phù hợp.'),
      );

      final payOsResponse = await widget.repository.createPayOsLink(
        widget.planId,
        'https://belumi.vn/payment-cancel',
        'https://belumi.vn/payment-success',
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('pending_payment_order_code', payOsResponse.orderCode);
        await prefs.setString('pending_payment_plan_code', _selectedPlan!.code);
      } catch (_) {}

      setState(() {
        _paymentLink = payOsResponse;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPayOs() async {
    if (_paymentLink == null) return;
    
    final typedCode = _voucherController.text.trim().toUpperCase();
    if (typedCode != (_appliedVoucherCode ?? '')) {
      await _applyVoucher();
      if (_voucherError != null) return;
    }

    if (_paymentLink == null) return;
    final uri = Uri.parse(_paymentLink!.checkoutUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể mở liên kết thanh toán: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      if (_appliedVoucherCode != null) {
        setState(() {
          _isValidatingVoucher = true;
          _voucherError = null;
        });
        try {
          final payOsResponse = await widget.repository.createPayOsLink(
            widget.planId,
            'https://belumi.vn/payment-cancel',
            'https://belumi.vn/payment-success',
          );
          setState(() {
            _appliedVoucherCode = null;
            _discountAmount = 0;
            _paymentLink = payOsResponse;
            _isValidatingVoucher = false;
          });
        } catch (e) {
          setState(() {
            _voucherError = e.toString().replaceAll('Exception: ', '');
            _isValidatingVoucher = false;
          });
        }
      }
      return;
    }

    if (code == _appliedVoucherCode) return;

    setState(() {
      _isValidatingVoucher = true;
      _voucherError = null;
    });

    try {
      final result = await widget.repository.validateVoucher(code, widget.planId);
      if (!mounted) return;

      if (result.isValid) {
        final payOsResponse = await widget.repository.createPayOsLink(
          widget.planId,
          'https://belumi.vn/payment-cancel',
          'https://belumi.vn/payment-success',
          voucherCode: code,
        );

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('pending_payment_order_code', payOsResponse.orderCode);
        } catch (_) {}

        setState(() {
          _appliedVoucherCode = code;
          _discountAmount = result.discountAmount;
          _paymentLink = payOsResponse;
          _voucherError = null;
          _isValidatingVoucher = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã áp dụng mã giảm giá thành công!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      } else {
        setState(() {
          _voucherError = result.message;
          _isValidatingVoucher = false;
        });
      }
    } catch (e) {
      setState(() {
        _voucherError = e.toString().replaceAll('Exception: ', '');
        _isValidatingVoucher = false;
      });
    }
  }

  Future<void> _checkStatus() async {
    if (_paymentLink == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await widget.repository.checkPaymentStatus(_paymentLink!.orderCode);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (status == 'Paid') {
        if (_selectedPlan != null) {
          widget.repository.activatePlan(_selectedPlan!.code);
        }
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('pending_payment_order_code');
          await prefs.remove('pending_payment_plan_code');
        } catch (_) {}
        
        // Cập nhật lại session trong AuthController để đồng bộ gói mới toàn bộ app
        ref.read(authControllerProvider.notifier).restoreSession();

        setState(() {
          _paymentSuccess = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trạng thái thanh toán: $status. Vui lòng hoàn thành giao dịch.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kiểm tra trạng thái: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;

    if (_paymentSuccess) {
      return _buildSuccessScreen(context);
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const BelumiLogo(height: 28)),
        body: const DecoratedBox(
          decoration: BelumiLuxury.background,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const BelumiLogo(height: 28)),
        body: DecoratedBox(
          decoration: BelumiLuxury.background,
          child: Center(
            child: LuxuryPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    t('Đã xảy ra lỗi', 'An error occurred'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  LuxuryButton(
                    label: t('Thử lại', 'Retry'),
                    icon: Icons.refresh,
                    onPressed: _initPayment,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final plan = _selectedPlan!;
    final link = _paymentLink!;

    return Scaffold(
      appBar: AppBar(title: const BelumiLogo(height: 28)),
      body: LuxuryPage(
        children: [
          LuxuryPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxuryHeader(
                  eyebrow: 'PayOS Gateway',
                  title: t('Thanh toán nâng cấp', 'Secure Premium Checkout'),
                  subtitle: t(
                    'Đăng ký gói dịch vụ Belumi chất lượng cao',
                    'Subscribe to the high-quality Belumi plan',
                  ),
                ),
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('Gói dịch vụ', 'Service Plan'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            plan.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('Chu kỳ thanh toán', 'Billing Cycle'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            plan.billingCycle == 'yearly'
                                ? t('Mỗi Năm', 'Yearly')
                                : t('Mỗi Tháng', 'Monthly'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('Mã đơn hàng', 'Order Code'),
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            '#${link.orderCode}',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildVoucherInput(context, t),
                      if (_discountAmount > 0) ...[
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              t('Giảm giá', 'Discount'),
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            Text(
                              '-${_formatPrice(_discountAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t('Tổng thanh toán', 'Total Amount'),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                          Text(
                            '${link.amount.toStringAsFixed(0)} VND',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: BelumiLuxury.ink,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                LuxuryButton(
                  label: t('Thanh toán với PayOS', 'Pay with PayOS'),
                  icon: Icons.payment,
                  onPressed: _launchPayOs,
                ),
                const SizedBox(height: 12),
                
                LuxuryButton(
                  label: t('Kiểm tra trạng thái thanh toán', 'Check Payment Status'),
                  icon: Icons.refresh,
                  outlined: true,
                  onPressed: _checkStatus,
                ),
                const SizedBox(height: 16),
                
                Center(
                  child: Text(
                    t(
                      '* Sau khi chuyển khoản trên trang PayOS, bấm "Kiểm tra trạng thái" để kích hoạt gói ngay.',
                      '* After completing transfer on PayOS, click "Check Status" to activate immediately.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context) {
    final t = belumiCopy(context).t;
    final planName = _selectedPlan?.name ?? t('Gói Premium', 'Premium Plan');
    
    return Scaffold(
      body: DecoratedBox(
        decoration: BelumiLuxury.background,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Glowing Checkmark Animation-like Circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F5E9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E7D32).withValues(alpha: 0.15),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 64,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Congratulation Headers
                    Text(
                      t('NÂNG CẤP THÀNH CÔNG!', 'UPGRADE SUCCESSFUL!'),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t('Chào mừng bạn đến với Belumi Premium', 'Welcome to Belumi Premium'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: BelumiLuxury.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                        ),
                        children: [
                          TextSpan(text: t('Tài khoản của bạn đã được nâng cấp lên ', 'Your account has been upgraded to ')),
                          TextSpan(
                            text: planName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF193447),
                            ),
                          ),
                          TextSpan(text: t('. Hãy bắt đầu tận hưởng toàn bộ các đặc quyền của hội viên cao cấp.', '. Start enjoying all the exclusive privileges of premium membership.')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Unlocked Features section
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        t('Các tính năng bạn có thể sử dụng:', 'Features you can use now:'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF193447),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 4 Feature Cards
                    _buildFeatureTile(
                      icon: Icons.auto_awesome_rounded,
                      title: t('AI Chăm Sóc Da (Skin AI)', 'AI Skin Care (Skin AI)'),
                      subtitle: t(
                        'Phân tích da sâu, phát hiện mụn, nếp nhăn và đề xuất routine chăm sóc cá nhân hóa hoàn toàn miễn phí.',
                        'Deep skin analysis, acne/wrinkle detection, and custom skin routine suggestions.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureTile(
                      icon: Icons.search_rounded,
                      title: t('Tra cứu không giới hạn', 'Unlimited Ingredient Lookup'),
                      subtitle: t(
                        'Tra cứu nhanh chóng độ an toàn, kích ứng, công dụng và độ tương thích của mọi thành phần mỹ phẩm.',
                        'Quickly look up safety, irritation rate, effects, and compatibility of any cosmetic ingredient.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureTile(
                      icon: Icons.face_retouching_natural_rounded,
                      title: t('Trang điểm ảo AR', 'AR Virtual Try-On'),
                      subtitle: t(
                        'Thử trực tiếp các màu son môi, màu má, kẻ mắt chân thực qua camera trước khi quyết định mua.',
                        'Try lipstick shades, blush, eyeliner in real-time through AR camera before buying.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureTile(
                      icon: Icons.support_agent_rounded,
                      title: t('Hỗ trợ Chuyên gia AI 24/7', '24/7 AI Expert Chat'),
                      subtitle: t(
                        'Trò chuyện không giới hạn với chatbot chuyên sâu về da liễu để trả lời mọi băn khoăn về routine.',
                        'Unlimited chat with chatbot specialized in dermatology for any questions on routines.',
                      ),
                    ),
                    const SizedBox(height: 36),
                    
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193447),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          // Clear payment screen and go home
                          context.go('/home');
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t('Bắt Đầu Khám Phá Ngay', 'Start Exploring Now'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1DFD8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF193447).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF193447),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF193447),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherInput(BuildContext context, String Function(String, String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _voucherController,
                  focusNode: _voucherFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: t('Nhập mã voucher (nếu có)', 'Enter voucher code'),
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: BelumiLuxury.ink),
                    ),
                  ),
                  onSubmitted: (_) => _applyVoucher(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BelumiLuxury.ink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: _isValidatingVoucher ? null : _applyVoucher,
                child: _isValidatingVoucher
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(t('Áp dụng', 'Apply'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (_voucherError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _voucherError!,
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        if (_appliedVoucherCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              t('Đã áp dụng mã: $_appliedVoucherCode', 'Applied code: $_appliedVoucherCode'),
              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  String _formatPrice(num val) {
    return '${val.toStringAsFixed(0)} VND';
  }
}
