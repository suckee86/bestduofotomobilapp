import 'package:cloud_firestore/cloud_firestore.dart';

class ContactDetails {
  const ContactDetails({
    required this.headline,
    required this.subtitle,
    required this.address,
    required this.mapDestination,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.email,
    required this.openingHours,
    required this.facebookUrl,
  });

  static const defaults = ContactDetails(
    headline: 'Találkozzunk személyesen',
    subtitle: 'A nagypostával szemben várunk Békéscsaba belvárosában.',
    address: '5600 Békéscsaba,\nMunkácsy u. 13/1.',
    mapDestination: '5600 Békéscsaba, Munkácsy utca 13/1.',
    latitude: 46.6779,
    longitude: 21.0973,
    phone: '(06 66) 746 990',
    email: 'foto@bestduo.hu',
    openingHours: 'Hétfő–Péntek: 09:00–18:00\nSzombat–Vasárnap: zárva',
    facebookUrl: 'https://facebook.com/bestduofoto',
  );

  factory ContactDetails.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) return defaults;
    return ContactDetails.fromMap(data);
  }

  factory ContactDetails.fromMap(Map<String, dynamic> data) {
    String text(String key, String fallback) {
      final value = data[key];
      return value is String && value.trim().isNotEmpty ? value : fallback;
    }

    double number(String key, double fallback) {
      final value = data[key];
      return value is num ? value.toDouble() : fallback;
    }

    return ContactDetails(
      headline: text('headline', defaults.headline),
      subtitle: text('subtitle', defaults.subtitle),
      address: text('address', defaults.address),
      mapDestination: text('mapDestination', defaults.mapDestination),
      latitude: number('latitude', defaults.latitude),
      longitude: number('longitude', defaults.longitude),
      phone: text('phone', defaults.phone),
      email: text('email', defaults.email),
      openingHours: text('openingHours', defaults.openingHours),
      facebookUrl: text('facebookUrl', defaults.facebookUrl),
    );
  }

  Map<String, Object> toMap() => {
    'headline': headline.trim(),
    'subtitle': subtitle.trim(),
    'address': address.trim(),
    'mapDestination': mapDestination.trim(),
    'latitude': latitude,
    'longitude': longitude,
    'phone': phone.trim(),
    'email': email.trim(),
    'openingHours': openingHours.trim(),
    'facebookUrl': facebookUrl.trim(),
  };

  final String headline;
  final String subtitle;
  final String address;
  final String mapDestination;
  final double latitude;
  final double longitude;
  final String phone;
  final String email;
  final String openingHours;
  final String facebookUrl;
}
