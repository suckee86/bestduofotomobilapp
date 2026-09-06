import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/announcement.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('announcements')
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(50)
        .snapshots();

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: ScreenHeader(
                eyebrow: 'ÉRTESÍTÉSEK',
                title: 'Hírek és ajánlatok',
                subtitle:
                    'Akciók, újdonságok és hasznos információk egy helyen.',
                trailing: _BellBadge(),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.orange),
                    );
                  }
                  if (snapshot.hasError) {
                    return const _NewsState(
                      icon: Icons.cloud_off_outlined,
                      title: 'A hírek most nem elérhetők',
                      message:
                          'Ellenőrizd a kapcsolatot, vagy próbáld újra később.',
                    );
                  }

                  final items = (snapshot.data?.docs ?? const [])
                      .map(Announcement.fromDocument)
                      .toList();
                  if (items.isEmpty) {
                    return const _NewsState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Még nincs új hír',
                      message:
                          'Itt jelennek majd meg a Best Duo friss ajánlatai.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 13),
                    itemBuilder: (context, index) =>
                        _NewsCard(item: items[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BellBadge extends StatelessWidget {
  const _BellBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE9D5),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.notifications_active_outlined,
        color: AppColors.orange,
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item});

  final Announcement item;

  Future<void> _openLink() async {
    final uri = Uri.tryParse(item.targetUrl ?? '');
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = item.targetUrl?.trim().isNotEmpty ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasLink ? _openLink : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'BEST DUO',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(item.publishedAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (item.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ],
                  if (hasLink) ...[
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Text(
                          'Részletek',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.orange,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'jan.',
      'febr.',
      'márc.',
      'ápr.',
      'máj.',
      'jún.',
      'júl.',
      'aug.',
      'szept.',
      'okt.',
      'nov.',
      'dec.',
    ];
    return '${date.year}. ${months[date.month - 1]} ${date.day}.';
  }
}

class _NewsState extends StatelessWidget {
  const _NewsState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9D5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.orange, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
