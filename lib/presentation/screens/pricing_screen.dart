import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return FutureBuilder<List<Plan>>(
      future: widget.repository.plans(),
      builder: (context, snapshot) {
        final allPlans = snapshot.data ?? [];
        
        final plans = allPlans.where((plan) {
          if (plan.code == 'free') return true;
          if (_isYearly) {
            return plan.billingCycle == 'yearly';
          } else {
            return plan.billingCycle == 'monthly';
          }
        }).toList();

        final displayPlans = plans.isNotEmpty ? plans : _getFallbackPlans(_isYearly);

        return LuxuryPage(
          children: [
            LuxuryHero(
              title: t('Chọn gói Belumi', 'Choose Your Glow Plan'),
              subtitle: t(
                'Mở khóa Skincare AI, tra cứu thành phần, trang điểm ảo và lịch sử nâng cao theo nhu cầu của bạn.',
                'Unlock Skincare AI, ingredient lookup, virtual makeup and advanced history for your needs.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1200&q=80',
            ),
            const SizedBox(height: 18),
            
            // Premium Selector Toggle
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isYearly = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: !_isYearly ? BelumiLuxury.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          t('Hàng Tháng', 'Monthly'),
                          style: TextStyle(
                            color: !_isYearly ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isYearly = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isYearly ? BelumiLuxury.ink : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              t('Hàng Năm', 'Yearly'),
                              style: TextStyle(
                                color: _isYearly ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                t('-15%', '-15%'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;
                final cards = displayPlans
                    .map(
                      (plan) => _PlanCard(repository: widget.repository, plan: plan),
                    )
                    .toList();
                if (!isWide) return Column(children: cards);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cards
                      .map(
                        (card) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: card,
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Plan> _getFallbackPlans(bool isYearly) {
    return [
      Plan(
        id: 'free-plan-id',
        code: 'free',
        name: 'Gói Miễn Phí',
        price: 0,
        billingCycle: 'monthly',
        features: [
          'Kết quả tra cứu thành phần mỹ phẩm và phân tích da bị hạn chế',
          'Giới hạn lượt giải thích với AI về tình trạng da hiện tại',
          'Quy trình chăm sóc da cá nhân hóa theo loại da bị hạn chế',
        ],
      ),
      if (isYearly)
        Plan(
          id: 'yearly-plan-id',
          code: 'yearly',
          name: 'Gói Mỗi Năm',
          price: 599000,
          billingCycle: 'yearly',
          features: [
            'Chi phí mỗi tháng rẻ hơn',
            'Trải nghiệm miễn phí tính năng mới trang điểm ảo khi được ra mắt chính thức',
            'Kết quả tra cứu thành phần mỹ phẩm và phân tích da đầy đủ',
            'Không giới hạn lượt giải thích với AI về tình trạng da hiện tại và so sánh các mỹ phẩm phù hợp với loại da',
            'Quy trình chăm sóc da cá nhân hóa theo loại da đầy đủ',
          ],
        )
      else
        Plan(
          id: 'monthly-plan-id',
          code: 'monthly',
          name: 'Gói Mỗi Tháng',
          price: 59000,
          billingCycle: 'monthly',
          features: [
            'Kết quả tra cứu thành phần mỹ phẩm và phân tích da đầy đủ',
            'Không giới hạn lượt giải thích với AI về tình trạng da hiện tại và so sánh các mỹ phẩm phù hợp với loại da',
            'Quy trình chăm sóc da cá nhân hóa theo loại da đầy đủ',
          ],
        ),
    ];
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.repository, required this.plan});

  final BelumiRepository repository;
  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final isCurrent = repository.currentPlan == plan.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LuxuryPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: BelumiLuxury.black,
                    ),
                  ),
                ),
                if (isCurrent) Chip(label: Text(t('Đang dùng', 'Current'))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              plan.price == 0
                  ? '0 VND'
                  : plan.billingCycle == 'yearly'
                      ? '${plan.price.toStringAsFixed(0)} VND/năm'
                      : '${plan.price.toStringAsFixed(0)} VND/tháng',
              style: const TextStyle(
                color: BelumiLuxury.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...(plan.features.isEmpty
                    ? _fallbackFeatures(context, plan.code)
                    : plan.features)
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: BelumiLuxury.ink),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            if (plan.code == 'free')
              LuxuryButton(
                label: t('Dùng Free', 'Use Free'),
                icon: Icons.spa_outlined,
                outlined: true,
                onPressed: isCurrent
                    ? null
                    : () {
                        repository.activatePlan('free');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              t('Đã chọn gói Free', 'Free plan selected'),
                            ),
                          ),
                        );
                      },
              )
            else
              LuxuryButton(
                label: isCurrent
                    ? t('Đang sử dụng', 'Active')
                    : t('Đăng ký ngay', 'Subscribe Now'),
                icon: Icons.arrow_forward,
                onPressed: isCurrent
                    ? null
                    : () {
                        context.go('/payment/${plan.id ?? plan.code}');
                      },
              ),
          ],
        ),
      ),
    );
  }

  List<String> _fallbackFeatures(BuildContext context, String code) {
    final t = belumiCopy(context).t;
    return switch (code) {
      'yearly' => [
        t('Chi phí mỗi tháng rẻ hơn', 'Cheaper monthly cost'),
        t('Trải nghiệm miễn phí tính năng trang điểm ảo', 'Free virtual try-on access'),
        t('Tra cứu thành phần mỹ phẩm đầy đủ', 'Full cosmetic lookup'),
        t('Không giới hạn giải thích AI', 'Unlimited AI explanations'),
        t('Quy trình skincare cá nhân hóa đầy đủ', 'Full personalized skincare routine'),
      ],
      'monthly' => [
        t('Tra cứu thành phần mỹ phẩm đầy đủ', 'Full cosmetic lookup'),
        t('Không giới hạn giải thích AI', 'Unlimited AI explanations'),
        t('Quy trình skincare cá nhân hóa đầy đủ', 'Full personalized skincare routine'),
      ],
      _ => [
        t('Tra cứu thành phần bị hạn chế', 'Limited cosmetic lookup'),
        t('Giới hạn giải thích AI', 'Limited AI explanations'),
        t('Quy trình skincare bị hạn chế', 'Limited skincare routine'),
      ],
    };
  }
}
