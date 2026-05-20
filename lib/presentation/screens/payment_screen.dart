import 'package:flutter/material.dart';

import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.repository,
    required this.planCode,
  });

  final BelumiRepository repository;
  final String planCode;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return Scaffold(
      appBar: AppBar(title: const BelumiLogo(height: 28)),
      body: FutureBuilder(
        future: repository.createPaymentQr(planCode, 'customer@belumi.com'),
        builder: (context, snapshot) {
          final qr = snapshot.data;
          if (qr == null) {
            return const DecoratedBox(
              decoration: BelumiLuxury.background,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return LuxuryPage(
            children: [
              LuxuryPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LuxuryHeader(
                      eyebrow: 'BIDV VietQR',
                      title: t('Thanh toán an toàn', 'Secure Beauty Checkout'),
                      subtitle: t(
                        'Gói ${qr.planCode.toUpperCase()} - ${qr.amount.toStringAsFixed(0)} VND',
                        '${qr.planCode.toUpperCase()} plan - ${qr.amount.toStringAsFixed(0)} VND',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          qr.vietQrUrl,
                          height: 320,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LuxuryInfoTile(
                      icon: Icons.account_balance,
                      title: 'BIDV - 1234567890',
                      subtitle: t(
                        'Nội dung: BELUMI ${qr.planCode.toUpperCase()}',
                        'Transfer note: BELUMI ${qr.planCode.toUpperCase()}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    LuxuryButton(
                      label: t('Tôi đã thanh toán', 'I have paid'),
                      icon: Icons.verified,
                      onPressed: () {
                        repository.activatePlan(planCode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t(
                                'Đã kích hoạt gói ${planCode.toUpperCase()} trong demo',
                                '${planCode.toUpperCase()} plan activated in demo',
                              ),
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
