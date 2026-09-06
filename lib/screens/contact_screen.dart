import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_details.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.paper,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appConfig')
            .doc('contact')
            .snapshots(),
        builder: (context, snapshot) {
          final details = snapshot.hasData
              ? ContactDetails.fromDocument(snapshot.data!)
              : ContactDetails.defaults;
          return _ContactContent(details: details);
        },
      ),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({required this.details});

  final ContactDetails details;

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A hivatkozás nem nyitható meg.')),
      );
    }
  }

  Uri get _phoneUri {
    var number = details.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.startsWith('06')) number = '+36${number.substring(2)}';
    return Uri(scheme: 'tel', path: number);
  }

  Uri get _emailUri => Uri(scheme: 'mailto', path: details.email.trim());

  Uri get _directionsUri => Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': details.mapDestination,
  });

  @override
  Widget build(BuildContext context) {
    final location = LatLng(details.latitude, details.longitude);
    final facebookUri = Uri.tryParse(details.facebookUrl);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 30),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ScreenHeader(
              eyebrow: 'KAPCSOLAT',
              title: details.headline,
              subtitle: details.subtitle,
            ),
          ),
          const SizedBox(height: 22),
          _MapCard(
            key: ValueKey('${details.latitude},${details.longitude}'),
            location: location,
            onOpenMap: () => _open(context, _directionsUri),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ContactRow(
                    icon: Icons.location_on_outlined,
                    label: 'Címünk',
                    value: details.address,
                  ),
                  const Divider(height: 30),
                  _ContactRow(
                    icon: Icons.phone_outlined,
                    label: 'Telefon',
                    value: details.phone,
                    onTap: () => _open(context, _phoneUri),
                  ),
                  const Divider(height: 30),
                  _ContactRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'E-mail',
                    value: details.email,
                    onTap: () => _open(context, _emailUri),
                  ),
                  const Divider(height: 30),
                  _ContactRow(
                    icon: Icons.schedule_rounded,
                    label: 'Nyitvatartás',
                    value: details.openingHours,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _open(context, _phoneUri),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Hívás'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _open(context, _directionsUri),
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Útvonal'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed:
                facebookUri != null && facebookUri.scheme.startsWith('http')
                ? () => _open(context, facebookUri)
                : null,
            icon: const Icon(Icons.public_rounded),
            label: const Text('Best Duo a Facebookon'),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({super.key, required this.location, required this.onOpenMap});

  final LatLng location;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 245,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: location,
              initialZoom: 16.5,
              keepAlive: true,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'hu.bestduo.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 54,
                    height: 54,
                    alignment: Alignment.bottomCenter,
                    child: const _MapPin(),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap közreműködők',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FilledButton.icon(
              onPressed: onOpenMap,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Google Térkép'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.orange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
