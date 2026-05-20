import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/belumi_luxury.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return LuxuryPage(
      children: [
        LuxuryHero(
          eyebrow: t(
            'Nền tảng AI làm đẹp thông minh',
            'AI Beauty Intelligence Platform',
          ),
          title: t('Về Belumi', 'About Belumi'),
          subtitle: t(
            'Hiểu làn da, giải mã thành phần và chọn sản phẩm làm đẹp tự tin hơn với AI cá nhân hóa.',
            'Understand your skin, decode ingredients and choose beauty products confidently with personalized AI guidance.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1616683693504-3ea7e9ad6fec?auto=format&fit=crop&w=1200&q=80',
          actions: [
            LuxuryButton(
              label: t('Khám phá Belumi', 'Explore Belumi'),
              icon: Icons.auto_awesome,
              onPressed: () => context.go('/skincare-ai'),
            ),
            LuxuryButton(
              label: t('Giải mã thành phần', 'Decode ingredients'),
              icon: Icons.document_scanner_outlined,
              outlined: true,
              onPressed: () => context.go('/ingredient-lookup'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _InfoCard(
          icon: Icons.science_outlined,
          title: t('Giải mã thành phần', 'Decode Ingredients'),
          body: t(
            'Biến bảng INCI khó hiểu thành công dụng, cảnh báo, độ phù hợp và ghi chú dễ đọc.',
            'Turn confusing INCI labels into simple benefits, warnings, suitability and evidence notes.',
          ),
        ),
        _InfoCard(
          icon: Icons.face_retouching_natural,
          title: t('Hiểu làn da của bạn', 'Understand Your Skin'),
          body: t(
            'AI phân tích da và hồ sơ nhanh giúp xây routine phù hợp với vấn đề da.',
            'AI skin analysis and quick profile questions help users build routines that match their concerns.',
          ),
        ),
        _InfoCard(
          icon: Icons.auto_awesome,
          title: t('Chọn tự tin hơn', 'Choose Confidently'),
          body: t(
            'Tư vấn makeup, thử ảo, wishlist và gói nâng cấp giúp bạn so sánh trước khi mua.',
            'Makeup recommendations, virtual try-on, wishlist and plan gating help users compare before buying.',
          ),
        ),
        const SizedBox(height: 10),
        LuxuryPanel(
          child: LuxuryHeader(
            eyebrow: t('Sứ mệnh', 'Mission'),
            title: t('Decode your glow', 'Decode your glow'),
            subtitle: t(
              'Giúp người dùng Việt đưa ra quyết định làm đẹp an toàn, rõ ràng và tự tin hơn.',
              'Empower Vietnamese users to make safer, informed and confident beauty decisions with clear, personalized and science-backed guidance.',
            ),
          ),
        ),
        const SizedBox(height: 18),
        LuxuryPanel(
          child: LuxuryHeader(
            eyebrow: t('Tầm nhìn', 'Vision'),
            title: t(
              'Nền tảng beauty intelligence',
              'Beauty intelligence platform',
            ),
            subtitle: t(
              'Xây dựng Belumi thành nền tảng AI đáng tin cậy cho skincare, hair, nails và makeup.',
              'Build Belumi into a trusted AI-powered beauty intelligence platform across skincare, hair, nails and makeup.',
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LuxuryPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: BelumiLuxury.peach,
              child: Icon(icon, color: BelumiLuxury.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
