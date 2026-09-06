import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  bool _motionPreferenceApplied = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionPreferenceApplied) return;
    _motionPreferenceApplied = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.value = 1;
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.displayName?.trim();
    final firstName = displayName == null || displayName.isEmpty
        ? null
        : displayName.split(RegExp(r'\s+')).first;

    return ColoredBox(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: SliverToBoxAdapter(
                child: _EntranceTransition(
                  animation: _entranceController,
                  begin: 0,
                  end: 0.42,
                  child: Row(
                    children: [
                      const BrandLogo(width: 98, padding: 5),
                      const Spacer(),
                      Text(
                        'A TE PILLANATAID',
                        style: TextStyle(
                          color: AppColors.muted.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          letterSpacing: 1.35,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ProfileButton(
                        user: widget.user,
                        onTap: widget.onOpenProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              sliver: SliverList.list(
                children: [
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.06,
                    end: 0.68,
                    distance: 34,
                    child: _WelcomeCard(
                      firstName: firstName,
                      animation: _entranceController,
                      onPressed: widget.onOpenPhotos,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.3,
                    end: 0.76,
                    child: const _SectionTitle(
                      eyebrow: 'INNEN MÁR CSAK EGY KOPPINTÁS',
                      title: 'Merre tovább?',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.4,
                    end: 0.84,
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_photo_alternate_outlined,
                            title: 'Fotókidolgozás',
                            subtitle: 'Képfeltöltés és rendelés',
                            color: AppColors.orange,
                            onTap: widget.onOpenPhotos,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.location_on_outlined,
                            title: 'Üzletünk',
                            subtitle: 'Cím, hívás és útvonal',
                            color: AppColors.ink,
                            onTap: widget.onOpenContact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.5,
                    end: 0.9,
                    child: _NewsAction(onTap: widget.onOpenNews),
                  ),
                  const SizedBox(height: 28),
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.58,
                    end: 0.96,
                    child: const _PhotoTipCard(),
                  ),
                  const SizedBox(height: 18),
                  _EntranceTransition(
                    animation: _entranceController,
                    begin: 0.64,
                    end: 1,
                    child: const _StoreStrip(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntranceTransition extends StatelessWidget {
  const _EntranceTransition({
    required this.animation,
    required this.begin,
    required this.end,
    required this.child,
    this.distance = 20,
  });

  final Animation<double> animation;
  final double begin;
  final double end;
  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final rawProgress = ((animation.value - begin) / (end - begin)).clamp(
          0.0,
          1.0,
        );
        final progress = Curves.easeOutCubic.transform(rawProgress);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, distance * (1 - progress)),
            child: child,
          ),
        );
      },
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.firstName,
    required this.animation,
    required this.onPressed,
  });

  final String? firstName;
  final Animation<double> animation;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141210), Color(0xFF2B2119)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -86,
            top: -92,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            left: -74,
            bottom: -112,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orange.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 30,
            child: _MemoryStack(animation: animation),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.orange,
                        size: 13,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'JÓ, HOGY ITT VAGY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: 1.25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 285),
                  child: Text(
                    firstName == null ? 'Üdvözlünk!' : 'Szia, $firstName!',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 42,
                      height: 0.98,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 275),
                  child: const Text(
                    'Legyen ma is helye egy pillanatnak, amit jó lesz újra kézbe venni.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 19),
                  label: const Text('Fotót választok'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
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

class _MemoryStack extends StatelessWidget {
  const _MemoryStack({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = Curves.easeOutBack.transform(
            ((animation.value - 0.08) / 0.68).clamp(0.0, 1.0),
          );

          return Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(26 * (1 - progress), -10 * (1 - progress)),
              child: Transform.scale(
                scale: 0.82 + (0.18 * progress),
                child: const SizedBox(
                  width: 108,
                  height: 122,
                  child: Stack(
                    children: [
                      Positioned(
                        right: 3,
                        top: 2,
                        child: _MemoryTile(
                          angle: 0.14,
                          color: Color(0xFFFFA12B),
                          icon: Icons.wb_sunny_outlined,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: _MemoryTile(
                          angle: -0.11,
                          color: Color(0xFFFF7900),
                          icon: Icons.favorite_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({
    required this.angle,
    required this.color,
    required this.icon,
  });

  final double angle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 70,
        height: 86,
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.6), color],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, color: Colors.white, size: 25),
        ),
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
