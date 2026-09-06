import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/admin_access.dart';
import '../models/announcement.dart';
import '../models/contact_details.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    if (!isContentAdmin(user)) {
      return const ColoredBox(
        color: AppColors.paper,
        child: Center(child: Text('Ehhez az oldalhoz nincs jogosultságod.')),
      );
    }

    return DefaultTabController(
      length: 2,
      child: ColoredBox(
        color: AppColors.paper,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: ScreenHeader(
                  eyebrow: 'ADMINISZTRÁCIÓ',
                  title: 'Tartalomkezelés',
                  subtitle: 'Hírek és üzleti adatok biztonságos szerkesztése.',
                  trailing: _AdminBadge(),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Újdonságok'),
                  Tab(text: 'Elérhetőségek'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const _AnnouncementsAdminTab(),
                    _ContactAdminTab(user: user),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE9D5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.admin_panel_settings, color: AppColors.orange),
    );
  }
}

class _AnnouncementsAdminTab extends StatelessWidget {
  const _AnnouncementsAdminTab();

  Future<void> _openEditor(
    BuildContext context, [
    Announcement? announcement,
  ]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AnnouncementEditorScreen(announcement: announcement),
      ),
    );
  }

  Future<void> _setPublished(
    BuildContext context,
    Announcement announcement,
    bool value,
  ) async {
    final action = value ? 'megjeleníted' : 'elrejted';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(value ? 'Hír közzététele' : 'Hír elrejtése'),
        content: Text(
          value && announcement.notificationWasSent
              ? 'A hír újra megjelenik az alkalmazásban, de új push értesítés már nem megy ki.'
              : 'Biztosan $action ezt a hírt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Mégsem'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(value ? 'Közzététel' : 'Elrejtés'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcement.id)
          .update({
            'isPublished': value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'A hír megjelent.' : 'A hír el lett rejtve.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _delete(BuildContext context, Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hír törlése'),
        content: Text(
          'Biztosan végleg törlöd ezt a hírt?\n\n„${announcement.title}”',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Mégsem'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('announcements')
          .doc(announcement.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('A hír törölve lett.')));
      }
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('publishedAt', descending: true)
        .snapshots();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Új hír létrehozása'),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const _AdminEmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: 'A hírek most nem tölthetők be.',
                );
              }

              final items = (snapshot.data?.docs ?? const [])
                  .map(Announcement.fromDocument)
                  .toList();
              if (items.isEmpty) {
                return const _AdminEmptyState(
                  icon: Icons.campaign_outlined,
                  message: 'Még nincs hír. Hozd létre az elsőt!',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _AnnouncementAdminCard(
                    item: item,
                    onEdit: () => _openEditor(context, item),
                    onPublishChanged: (value) =>
                        _setPublished(context, item, value),
                    onDelete: () => _delete(context, item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AnnouncementAdminCard extends StatelessWidget {
  const _AnnouncementAdminCard({
    required this.item,
    required this.onEdit,
    required this.onPublishChanged,
    required this.onDelete,
  });

  final Announcement item;
  final VoidCallback onEdit;
  final ValueChanged<bool> onPublishChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = item.isPublished
        ? 'Közzétéve'
        : item.notificationWasSent
        ? 'Elrejtve'
        : 'Piszkozat';
    final statusColor = item.isPublished
        ? AppColors.success
        : item.notificationWasSent
        ? Colors.red.shade600
        : AppColors.muted;

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.campaign_outlined, color: statusColor),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Műveletek',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'visibility':
                      onPublishChanged(!item.isPublished);
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Szerkesztés'),
                  ),
                  PopupMenuItem(
                    value: 'visibility',
                    child: Text(item.isPublished ? 'Elrejtés' : 'Közzététel'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Törlés')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementEditorScreen extends StatefulWidget {
  const _AnnouncementEditorScreen({this.announcement});

  final Announcement? announcement;

  @override
  State<_AnnouncementEditorScreen> createState() =>
      _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState extends State<_AnnouncementEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _targetUrlController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final item = widget.announcement;
    _titleController = TextEditingController(text: item?.title ?? '');
    _bodyController = TextEditingController(text: item?.body ?? '');
    _targetUrlController = TextEditingController(text: item?.targetUrl ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _targetUrlController.dispose();
    super.dispose();
  }

  Future<bool> _confirmPublishing() async {
    if (widget.announcement?.isPublished == true) return true;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Közzéteszed a hírt?'),
            content: const Text('A hír megjelenik az alkalmazásban.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Mégsem'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Közzététel'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _save({required bool publish}) async {
    if (_busy || !_formKey.currentState!.validate()) return;
    if (publish && !await _confirmPublishing()) return;
    if (!mounted) return;
    setState(() => _busy = true);

    final collection = FirebaseFirestore.instance.collection('announcements');
    final reference = widget.announcement == null
        ? collection.doc()
        : collection.doc(widget.announcement!.id);

    try {
      final targetUrl = _targetUrlController.text.trim();
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'isPublished': publish,
        'updatedAt': FieldValue.serverTimestamp(),
        'targetUrl': targetUrl.isEmpty ? FieldValue.delete() : targetUrl,
      };
      if (widget.announcement == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['publishedAt'] = FieldValue.serverTimestamp();
      }

      await reference.set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish ? 'A hír mentve és közzétéve.' : 'A piszkozat mentve.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublished = widget.announcement?.isPublished ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.announcement == null ? 'Új hír' : 'Hír szerkesztése',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_busy,
              maxLength: 160,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Cím',
                hintText: 'Például: Őszi fotóakció',
                border: OutlineInputBorder(),
              ),
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyController,
              enabled: !_busy,
              minLines: 5,
              maxLines: 10,
              maxLength: 3000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Szöveg',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: _requiredText,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetUrlController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Részletek webcíme (nem kötelező)',
                hintText: 'https://bestduo.hu/...',
                prefixIcon: Icon(Icons.link_rounded),
                border: OutlineInputBorder(),
              ),
              validator: _optionalWebAddress,
            ),
            const SizedBox(height: 22),
            if (_busy) const LinearProgressIndicator(),
            if (_busy) const SizedBox(height: 12),
            if (!isPublished) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _save(publish: true),
                  icon: const Icon(Icons.campaign_rounded),
                  label: const Text('Közzététel'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _save(publish: isPublished),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  isPublished ? 'Módosítások mentése' : 'Piszkozat mentése',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactAdminTab extends StatelessWidget {
  const _ContactAdminTab({required this.user});

  final User user;

  Future<void> _openEditor(BuildContext context, ContactDetails details) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ContactEditorScreen(details: details, user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('appConfig')
          .doc('contact')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const _AdminEmptyState(
            icon: Icons.cloud_off_outlined,
            message: 'Az elérhetőségek most nem tölthetők be.',
          );
        }

        final details = snapshot.hasData
            ? ContactDetails.fromDocument(snapshot.data!)
            : ContactDetails.defaults;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openEditor(context, details),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Elérhetőségek szerkesztése'),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AdminContactValue(label: 'Cím', value: details.address),
                    _AdminContactValue(label: 'Telefon', value: details.phone),
                    _AdminContactValue(label: 'E-mail', value: details.email),
                    _AdminContactValue(
                      label: 'Nyitvatartás',
                      value: details.openingHours,
                    ),
                    _AdminContactValue(
                      label: 'Facebook',
                      value: details.facebookUrl,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminContactValue extends StatelessWidget {
  const _AdminContactValue({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.orange,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ContactEditorScreen extends StatefulWidget {
  const _ContactEditorScreen({required this.details, required this.user});

  final ContactDetails details;
  final User user;

  @override
  State<_ContactEditorScreen> createState() => _ContactEditorScreenState();
}

class _ContactEditorScreenState extends State<_ContactEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _headline;
  late final TextEditingController _subtitle;
  late final TextEditingController _address;
  late final TextEditingController _mapDestination;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _openingHours;
  late final TextEditingController _facebookUrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final details = widget.details;
    _headline = TextEditingController(text: details.headline);
    _subtitle = TextEditingController(text: details.subtitle);
    _address = TextEditingController(text: details.address);
    _mapDestination = TextEditingController(text: details.mapDestination);
    _latitude = TextEditingController(text: details.latitude.toString());
    _longitude = TextEditingController(text: details.longitude.toString());
    _phone = TextEditingController(text: details.phone);
    _email = TextEditingController(text: details.email);
    _openingHours = TextEditingController(text: details.openingHours);
    _facebookUrl = TextEditingController(text: details.facebookUrl);
  }

  @override
  void dispose() {
    for (final controller in [
      _headline,
      _subtitle,
      _address,
      _mapDestination,
      _latitude,
      _longitude,
      _phone,
      _email,
      _openingHours,
      _facebookUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _coordinate(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final details = ContactDetails(
      headline: _headline.text,
      subtitle: _subtitle.text,
      address: _address.text,
      mapDestination: _mapDestination.text,
      latitude: _coordinate(_latitude)!,
      longitude: _coordinate(_longitude)!,
      phone: _phone.text,
      email: _email.text,
      openingHours: _openingHours.text,
      facebookUrl: _facebookUrl.text,
    );

    try {
      await FirebaseFirestore.instance
          .collection('appConfig')
          .doc('contact')
          .set({
            ...details.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': widget.user.uid,
          });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Az elérhetőségek frissültek.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        _showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elérhetőségek szerkesztése')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _EditorField(
              controller: _headline,
              label: 'Kapcsolatoldal címsora',
              enabled: !_busy,
            ),
            _EditorField(
              controller: _subtitle,
              label: 'Rövid leírás',
              enabled: !_busy,
              maxLines: 3,
            ),
            _EditorField(
              controller: _address,
              label: 'Üzlet címe',
              enabled: !_busy,
              maxLines: 3,
            ),
            _EditorField(
              controller: _phone,
              label: 'Telefonszám',
              enabled: !_busy,
              keyboardType: TextInputType.phone,
            ),
            _EditorField(
              controller: _email,
              label: 'Kapcsolati e-mail',
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              validator: _emailAddress,
            ),
            _EditorField(
              controller: _openingHours,
              label: 'Nyitvatartás',
              enabled: !_busy,
              maxLines: 4,
            ),
            _EditorField(
              controller: _facebookUrl,
              label: 'Facebook webcím',
              enabled: !_busy,
              keyboardType: TextInputType.url,
              validator: _requiredWebAddress,
            ),
            const SizedBox(height: 4),
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Térkép beállításai'),
                subtitle: const Text(
                  'Címváltozáskor a térképpontot is frissíteni kell.',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _EditorField(
                    controller: _mapDestination,
                    label: 'Google Térképen keresett cím',
                    enabled: !_busy,
                    maxLines: 2,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _EditorField(
                          controller: _latitude,
                          label: 'Szélesség',
                          enabled: !_busy,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (value) =>
                              _coordinateValue(value, -90, 90),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EditorField(
                          controller: _longitude,
                          label: 'Hosszúság',
                          enabled: !_busy,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          validator: (value) =>
                              _coordinateValue(value, -180, 180),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_busy) const LinearProgressIndicator(),
            if (_busy) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Módosítások mentése'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  const _EditorField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textCapitalization:
            keyboardType == TextInputType.emailAddress ||
                keyboardType == TextInputType.url
            ? TextCapitalization.none
            : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          border: const OutlineInputBorder(),
        ),
        validator: validator ?? _requiredText,
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: AppColors.orange),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String? _requiredText(String? value) {
  return value == null || value.trim().isEmpty
      ? 'Ezt a mezőt töltsd ki.'
      : null;
}

String? _optionalWebAddress(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http')
      ? null
      : 'Teljes http:// vagy https:// címet adj meg.';
}

String? _requiredWebAddress(String? value) {
  return _requiredText(value) ?? _optionalWebAddress(value);
}

String? _emailAddress(String? value) {
  final requiredError = _requiredText(value);
  if (requiredError != null) return requiredError;
  final email = value!.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Érvényes e-mail-címet adj meg.';
}

String? _coordinateValue(String? value, double minimum, double maximum) {
  final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  return number != null && number >= minimum && number <= maximum
      ? null
      : 'Hibás érték';
}

void _showError(BuildContext context, Object error) {
  final message =
      error is FirebaseException && error.code == 'permission-denied'
      ? 'Nincs jogosultság a művelethez. Jelentkezz be újra az adminfiókkal.'
      : 'A mentés nem sikerült. Ellenőrizd a kapcsolatot, majd próbáld újra.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
