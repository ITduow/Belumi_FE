import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../widgets/belumi_luxury.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  bool _isYearly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(authControllerProvider.notifier).restoreSession();
      }
    });
  }

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

        // Đưa gói Premium lên trước để người dùng thấy ngay lập tức, gói Free xuống dưới
        displayPlans.sort((a, b) {
          if (a.code == 'free' && b.code != 'free') return 1;
          if (a.code != 'free' && b.code == 'free') return -1;
          return 0;
        });

        return LuxuryPage(
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF193447).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 6),
                        Text(
                          t('BẬT TÍNH NĂNG CAO CẤP', 'ACTIVATE PREMIUM'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF193447),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t('Nâng Tầm Làn Da Cùng Belumi', 'Elevate Your Skin With Belumi'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: BelumiLuxury.black,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      t(
                        'Mở khóa toàn bộ sức mạnh của Skincare AI, phân tích da sâu, trang điểm ảo AR và trò chuyện không giới hạn với chuyên gia ảo.',
                        'Unlock the full power of Skincare AI, deep skin analysis, AR virtual try-on, and unlimited chat with virtual assistant.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            
            // Premium Selector Toggle
            Center(
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1DFD8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      label: t('Hàng Tháng', 'Monthly'),
                      isSelected: !_isYearly,
                      onTap: () => setState(() => _isYearly = false),
                    ),
                    _buildToggleButton(
                      label: t('Hàng Năm', 'Yearly'),
                      isSelected: _isYearly,
                      badge: t('Tiết kiệm 15%', 'Save 15%'),
                      onTap: () => setState(() => _isYearly = true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            
            Builder(
              builder: (context) {
                final isWide = MediaQuery.sizeOf(context).width >= 780;
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

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? BelumiLuxury.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF7E6E68),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE7B5AA), Color(0xFFD4AF37)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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
    final currentPlan = repository.currentPlan;
    final isCurrent = currentPlan == plan.code;
    final isPremium = plan.code != 'free';
    final isFreeDisabled = plan.code == 'free' && currentPlan != 'free';
    final isMonthlyDisabled = plan.code == 'monthly' && currentPlan == 'yearly';

    final cardBg = isPremium
        ? const Color(0xFF193447)
        : Colors.white;
    final textColor = isPremium ? Colors.white : const Color(0xFF15110F);
    final subtitleColor = isPremium ? const Color(0xFFB0C4DE) : const Color(0xFF7E6E68);
    final borderColor = isPremium ? const Color(0xFFE7B5AA) : const Color(0xFFF1DFD8);

    final features = plan.features.isEmpty
        ? _fallbackFeatures(context, plan.code)
        : plan.features;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: isPremium ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isPremium)
            BoxShadow(
              color: const Color(0xFF193447).withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          else
            BoxShadow(
              color: const Color(0xFFE7B5AA).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (isPremium)
              Positioned(
                top: -60,
                right: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE8E0).withValues(alpha: 0.05),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPremium
                              ? const Color(0xFFFFE8E0).withValues(alpha: 0.12)
                              : const Color(0xFF193447).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.name.toUpperCase(),
                          style: TextStyle(
                            color: isPremium ? const Color(0xFFFFE8E0) : const Color(0xFF193447),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFE7B5AA)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            t('PHỔ BIẾN', 'POPULAR'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 9,
                            ),
                          ),
                        )
                      else if (isCurrent)
                        Text(
                          t('ĐANG DÙNG', 'ACTIVE'),
                          style: const TextStyle(
                            color: Color(0xFF7E6E68),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Price section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        plan.price == 0
                            ? '0'
                            : plan.price == 59000
                                ? '59.000'
                                : plan.price == 599000
                                    ? '599.000'
                                    : plan.price.toStringAsFixed(0),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'VND',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        plan.price == 0
                            ? ''
                            : plan.billingCycle == 'yearly'
                                ? t(' / năm', ' / year')
                                : t(' / tháng', ' / month'),
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (plan.price > 0 && plan.billingCycle == 'yearly') ...[
                    const SizedBox(height: 4),
                    Text(
                      t('~ 49.900 VND / tháng (Tiết kiệm 15%)', '~ 49,900 VND / month (Save 15%)'),
                      style: const TextStyle(
                        color: Color(0xFFFFE8E0),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Divider(color: borderColor.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 24),
                  
                  // Features List
                  ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPremium
                                ? const Color(0xFFFFE8E0).withValues(alpha: 0.15)
                                : const Color(0xFF193447).withValues(alpha: 0.08),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 13,
                            color: isPremium ? const Color(0xFFFFE8E0) : const Color(0xFF193447),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: textColor.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 28),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: plan.code == 'free'
                        ? OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: (isCurrent || isFreeDisabled)
                                    ? Colors.grey.shade300
                                    : const Color(0xFF193447),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              foregroundColor: (isCurrent || isFreeDisabled)
                                  ? Colors.grey.shade400
                                  : const Color(0xFF193447),
                            ),
                            onPressed: (isCurrent || isFreeDisabled)
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
                            child: Text(
                              isCurrent
                                  ? t('Đang Sử Dụng', 'Active')
                                  : isFreeDisabled
                                      ? t('Không Thể Chọn', 'Unavailable')
                                      : t('Chọn Gói Miễn Phí', 'Select Free Plan'),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          )
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (isCurrent || isMonthlyDisabled) ? Colors.grey.shade700 : const Color(0xFFFFE8E0),
                              foregroundColor: const Color(0xFF193447),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: (isCurrent || isMonthlyDisabled)
                                ? null
                                : () {
                                    context.push('/payment/${plan.id ?? plan.code}');
                                  },
                            child: Text(
                              isCurrent
                                  ? t('Đang Sử Dụng', 'Active')
                                  : isMonthlyDisabled
                                      ? t('Không Thể Chọn', 'Unavailable')
                                      : t('Nâng Cấp Ngay', 'Upgrade Now'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
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
