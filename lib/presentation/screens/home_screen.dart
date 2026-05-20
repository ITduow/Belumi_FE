import 'package:flutter/material.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/image_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([repository.products(), repository.blogs()]),
      builder: (context, snapshot) {
        final products = snapshot.hasData
            ? snapshot.data![0] as List<Product>
            : sampleProducts;
        final blogs = snapshot.hasData
            ? snapshot.data![1] as List<BlogPost>
            : sampleBlogs;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Belumi Beauty',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'My pham, cham soc da va tu van ca nhan hoa.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ImageCard(
              imageUrl:
                  'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908',
              height: 190,
              child: Text(
                'Glow Week\nRoutine moi cho lan da sang hon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _SectionTitle(title: 'San pham noi bat'),
            const SizedBox(height: 12),
            ...products
                .take(2)
                .map(
                  (item) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: item.thumbnailUrl == null
                            ? null
                            : NetworkImage(item.thumbnailUrl!),
                      ),
                      title: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${item.price.toStringAsFixed(0)} VND'),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Blog lam dep'),
            const SizedBox(height: 12),
            ...blogs
                .take(2)
                .map(
                  (post) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ImageCard(
                      imageUrl: post.coverImageUrl,
                      height: 130,
                      child: Text(
                        post.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  );
}
