import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.repository,
    required this.planId,
  });

  final BelumiRepository repository;
  final String planId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  PayOsPaymentLinkResponse? _paymentLink;
  Plan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _initPayment();
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thanh toán thành công! Gói cước của bạn đã được nâng cấp.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
}
