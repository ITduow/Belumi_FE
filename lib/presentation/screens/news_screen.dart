import 'package:flutter/material.dart';

import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return FutureBuilder(
      future: repository.blogs(),
      builder: (context, snapshot) {
        final posts = snapshot.data ?? sampleBlogs;
        return LuxuryPage(
          children: [
            LuxuryHero(
              title: t('Câu chuyện làm đẹp', 'Beauty Stories'),
              subtitle: t(
                'Tin làm đẹp, routine skincare và phân tích thành phần được chọn lọc cho cộng đồng Belumi.',
                'Beauty news, skincare routines and ingredient insights curated for the Belumi community.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=1200&q=80',
              actions: [
                LuxuryButton(
                  label: 'Skin AI',
                  icon: Icons.auto_awesome,
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LuxuryPanel(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 92,
                          height: 92,
                          child: Image.network(
                            post.coverImageUrl ??
                                'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=600&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Image.asset(
                              'assets/images/belumi_home_hero.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author ??
                                  t('Belumi Beauty', 'Belumi Beauty'),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: BelumiLuxury.muted,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_outward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
