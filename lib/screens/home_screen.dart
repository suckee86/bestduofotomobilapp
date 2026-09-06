import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onOpenPhotos,
    required this.onOpenNews,
    required this.onOpenContact,
    required this.onOpenProfile,
  });

  final User user;
  final VoidCallback onOpenPhotos;
  final VoidCallback onOpenNews;
  final VoidCallback onOpenContact;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final firstName = user.displayName?.trim().split(' ').first;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const BrandLogo(width: 98, padding: 5),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          firstName == null
                              ? 'Üdvözlünk!'
                              : 'Szia, $firstName!',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Jó újra látni',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    _ProfileButton(user: user, onTap: onOpenProfile),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.list(
                children: [
                  _HeroCard(onPressed: onOpenPhotos),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    eyebrow: 'MINDEN EGY HELYEN',
                    title: 'Miben segíthetünk?',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_photo_alternate_outlined,
                          title: 'Fotókidolgozás',
                          subtitle: 'Képfeltöltés és rendelés',
                          color: AppColors.orange,
                          onTap: onOpenPhotos,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Üzletünk',
                          subtitle: 'Cím, hívás és útvonal',
                          color: AppColors.ink,
                          onTap: onOpenContact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NewsAction(onTap: onOpenNews),
                  const SizedBox(height: 28),
                  const _PhotoTipCard(),
                  const SizedBox(height: 18),
                  const _StoreStrip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton({required this.user, required this.onTap});

  final User user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Saját fiók',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 21,
          backgroundColor: AppColors.orange,
          foregroundImage: user.photoURL == null
              ? null
              : NetworkImage(user.photoURL!),
          child: Text(
            (user.displayName?.trim().isNotEmpty ?? false)
                ? user.displayName!.trim()[0].toUpperCase()
                : 'B',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 390,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x32000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/photo_lab_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x18000000), Color(0xEE0B0908)],
                stops: [0.15, 0.95],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.orange,
                        size: 14,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'PRÉMIUM MINŐSÉG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'A kedvenc pillanataid\nmegérdemlik a papírt.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Válaszd ki a fotóidat, a méretet és a darabszámot — a többit bízd ránk.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Fotók feltöltése'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppColors.orange,
            fontWeight: FontWeight.w900,
            fontSize: 10,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 170,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewsAction extends StatelessWidget {
  const _NewsAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            children: [
              _RoundIcon(icon: Icons.notifications_active_outlined),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Akciók és újdonságok',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Nézd meg a Best Duo legfrissebb híreit',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0E3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.orange),
    );
  }
}

class _PhotoTipCard extends StatelessWidget {
  const _PhotoTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppColors.orange),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipp a szebb papírképhez',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Az eredeti, teljes felbontású fotót töltsd fel — ne képernyőképet vagy üzenetküldőből mentett változatot.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
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

class _StoreStrip extends StatelessWidget {
  const _StoreStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.storefront_outlined, size: 17, color: AppColors.muted),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            '5600 Békéscsaba, Munkácsy u. 13/1.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
