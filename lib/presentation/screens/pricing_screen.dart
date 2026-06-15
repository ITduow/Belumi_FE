import 'package:flutter/material.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return FutureBuilder<List<Plan>>(
      future: repository.plans(),
      builder: (context, snapshot) {
        final plans =
            snapshot.data ??
            [
              Plan(code: 'free', name: 'Free', price: 0, features: const []),
              Plan(
                code: 'plus',
                name: 'Plus',
                price: 99000,
                features: const [],
              ),
              Plan(code: 'pro', name: 'Pro', price: 199000, features: const []),
            ];
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
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;
                final cards = plans
                    .map(
                      (plan) => _PlanCard(repository: repository, plan: plan),
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
            Text(
              plan.price == 0
                  ? '0 VND'
                  : t(
                      '${plan.price.toStringAsFixed(0)} VND/tháng',
                      '${plan.price.toStringAsFixed(0)} VND/month',
                    ),
              style: const TextStyle(
                color: BelumiLuxury.ink,
                fontWeight: FontWeight.w900,
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
                      children: [
                        const Icon(Icons.check_circle, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            if (plan.code == 'free')
              LuxuryButton(
                label: t('Dùng Free', 'Use Free'),
                icon: Icons.spa_outlined,
                outlined: true,
                onPressed: () {
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
                label: t('Đăng ký thử nghiệm', 'Subscribe (Demo)'),
                icon: Icons.offline_pin_outlined,
                onPressed: () {
                  repository.activatePlan(plan.code);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t(
                          'Đã kích hoạt gói ${plan.name} thử nghiệm!',
                          '${plan.name} plan activated (Demo)!',
                        ),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
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
      'pro' => [
        t('200 lượt Skincare AI/tháng', '200 Skincare AI uses/month'),
        t(
          '300 lượt Tra cứu thành phần/tháng',
          '300 Ingredient Lookup uses/month',
        ),
        t('Virtual Makeup nâng cao', 'Advanced Virtual Makeup'),
        t(
          'Full history và ưu tiên tính năng mới',
          'Full history and early access',
        ),
      ],
      'plus' => [
        t('50 lượt Skincare AI/tháng', '50 Skincare AI uses/month'),
        t(
          '100 lượt Tra cứu thành phần/tháng',
          '100 Ingredient Lookup uses/month',
        ),
        t('Wishlist không giới hạn', 'Unlimited wishlist'),
        t('Phân tích nâng cao', 'Advanced analysis'),
      ],
      _ => [
        t('3 lượt Skincare AI/tháng', '3 Skincare AI uses/month'),
        t('5 lượt Tra cứu thành phần/tháng', '5 Ingredient Lookup uses/month'),
        t('2 lượt Tư vấn makeup/tháng', '2 Makeup consultations/month'),
        t('Wishlist tối đa 10 sản phẩm', 'Wishlist up to 10 products'),
      ],
    };
  }
}
