import 'package:flutter/material.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return FutureBuilder<List<Product>>(
      future: widget.repository.products(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? sampleProducts;
        return LuxuryPage(
          children: [
            LuxuryHero(
              title: t('Danh mục làm đẹp', 'Beauty Catalogue'),
              subtitle: t(
                'Sản phẩm skincare và makeup được Belumi gợi ý theo nhu cầu làm đẹp của bạn.',
                'Skincare and makeup products suggested by Belumi for your beauty needs.',
              ),
              imageUrl:
                  'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=1200&q=80',
            ),
            const SizedBox(height: 16),
            ...products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: LuxuryPanel(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 86,
                          height: 86,
                          child: Image.network(
                            product.thumbnailUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                ColoredBox(color: Colors.grey.shade100),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.categoryName ?? 'Belumi',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${product.price.toStringAsFixed(0)} VND',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await widget.repository.addWishlist(
                                      product,
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Da them ${product.name} vao Wishlist',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.favorite_border),
                                  label: Text(t('Yêu thích', 'Favorite')),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
