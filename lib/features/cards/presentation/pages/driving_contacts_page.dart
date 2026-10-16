import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrivingContactsPage extends StatefulWidget {
  const DrivingContactsPage({super.key});

  @override
  State<DrivingContactsPage> createState() => _DrivingContactsPageState();
}

class _DrivingContactsPageState extends State<DrivingContactsPage> {
  static const _contactsChannel = MethodChannel('carwidget/contacts');

  final _searchController = TextEditingController();
  final _numberController = TextEditingController();
  List<_DrivingContact> _contacts = const [];
  String _permission = 'loading';
  String? _errorMessage;
  bool _showKeypad = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (mounted) {
      setState(() {
        _permission = 'loading';
        _errorMessage = null;
      });
    }
    try {
      final response = await _contactsChannel.invokeMapMethod<String, dynamic>(
        'loadContacts',
      );
      final status = response?['status'] as String? ?? 'unavailable';
      final rawContacts = response?['contacts'] as List<dynamic>? ?? const [];
      final contacts =
          rawContacts
              .whereType<Map<dynamic, dynamic>>()
              .map(_DrivingContact.fromMap)
              .where((contact) => contact.name.isNotEmpty)
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      if (!mounted) return;
      setState(() {
        _permission = status;
        _contacts = contacts;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _permission = 'error';
        _errorMessage = error.message;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() => _permission = 'unavailable');
    }
  }

  Future<void> _openSettings() async {
    try {
      await _contactsChannel.invokeMethod<void>('openSettings');
    } on PlatformException {
      _showMessage('Could not open iPhone Settings.');
    } on MissingPluginException {
      _showMessage('Contact access settings are only available on iPhone.');
    }
  }

  Future<void> _call(String phoneNumber) async {
    final number = phoneNumber.trim();
    if (number.isEmpty) {
      _showMessage('This contact does not have a phone number.');
      return;
    }
    try {
      await _contactsChannel.invokeMethod<void>('call', number);
    } on PlatformException catch (error) {
      _showMessage(error.message ?? 'Could not start the call.');
    } on MissingPluginException {
      _showMessage('Calling is only available on iPhone.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredContacts = _contacts.where((contact) {
      return query.isEmpty || contact.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xC9081B2A),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: _showKeypad
                      ? _NumberDisplay(controller: _numberController)
                      : _SearchField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                        ),
                ),
                Expanded(
                  child: _showKeypad
                      ? _Keypad(
                          controller: _numberController,
                          onChanged: () => setState(() {}),
                          onCall: () => _call(_numberController.text),
                        )
                      : _contactsContent(filteredContacts),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ContactsTabs(
          showKeypad: _showKeypad,
          onContactsTap: () => setState(() => _showKeypad = false),
          onKeypadTap: () => setState(() => _showKeypad = true),
        ),
      ],
    );
  }

  Widget _contactsContent(List<_DrivingContact> contacts) {
    if (_permission == 'loading') {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF168EFF)),
      );
    }
    if (_permission == 'denied' || _permission == 'restricted') {
      return _PermissionMessage(onOpenSettings: _openSettings);
    }
    if (_permission == 'unavailable' || _permission == 'error') {
      return _EmptyContactsMessage(
        message: _errorMessage ?? 'Contacts are not available on this device.',
        onRetry: _loadContacts,
      );
    }
    if (contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts found.',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: contacts.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 74,
        color: Colors.white.withValues(alpha: .07),
      ),
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _call(contact.phoneNumber ?? ''),
            child: SizedBox(
              height: 68,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF344759),
                      child: Text(
                        contact.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        contact.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Call ${contact.name}',
                      onPressed: () => _call(contact.phoneNumber ?? ''),
                      icon: Icon(
                        Icons.call_rounded,
                        color: contact.phoneNumber == null
                            ? Colors.white38
                            : const Color(0xFF168EFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DrivingContact {
  const _DrivingContact({
    required this.name,
    required this.initial,
    required this.phoneNumber,
  });

  final String name;
  final String initial;
  final String? phoneNumber;

  factory _DrivingContact.fromMap(Map<dynamic, dynamic> map) {
    final name = map['name'] as String? ?? '';
    final initial =
        map['initial'] as String? ??
        (name.isEmpty ? '?' : String.fromCharCode(name.runes.first));
    final phoneNumbers = map['phoneNumbers'] as List<dynamic>? ?? const [];
    final phoneNumber = phoneNumbers.whereType<String>().firstOrNull;
    return _DrivingContact(
      name: name,
      initial: initial,
      phoneNumber: phoneNumber,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white, fontSize: 16),
    cursorColor: const Color(0xFF168EFF),
    decoration: InputDecoration(
      hintText: 'Search person',
      hintStyle: const TextStyle(color: Color(0xFF9AA5B0)),
      prefixIcon: const Icon(Icons.search, color: Color(0xFFB6C0C9)),
      filled: true,
      fillColor: const Color(0xFF09111B),
      contentPadding: const EdgeInsets.symmetric(vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF168EFF)),
      ),
    ),
  );
}

class _PermissionMessage extends StatelessWidget {
  const _PermissionMessage({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.contacts_rounded, color: Colors.white70, size: 38),
          const SizedBox(height: 12),
          const Text(
            'Allow contact access to see people and call them from Driving Mode.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpenSettings,
            child: const Text('Open Settings'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyContactsMessage extends StatelessWidget {
  const _EmptyContactsMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _NumberDisplay extends StatelessWidget {
  const _NumberDisplay({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF09111B),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
    ),
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => Text(
        value.text.isEmpty ? 'Enter number' : value.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: value.text.isEmpty ? const Color(0xFF9AA5B0) : Colors.white,
          fontSize: 22,
        ),
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.controller,
    required this.onChanged,
    required this.onCall,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onCall;

  static const _digits = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '*',
    '0',
    '#',
  ];

  static const _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '+',
  };

  void _addDigit(String digit) {
    final value = controller.value;
    final text = value.text.replaceRange(
      value.selection.start < 0 ? value.text.length : value.selection.start,
      value.selection.end < 0 ? value.text.length : value.selection.end,
      digit,
    );
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 320;
            final horizontalPadding = compact ? 12.0 : 24.0;
            final crossSpacing = compact ? 8.0 : 14.0;
            final cellWidth =
                (constraints.maxWidth -
                    horizontalPadding * 2 -
                    crossSpacing * 2) /
                3;
            final buttonSize = cellWidth.clamp(48.0, 96.0).toDouble();
            return GridView.builder(
              primary: false,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 4,
              ),
              itemCount: _digits.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                mainAxisSpacing: 8,
                crossAxisSpacing: crossSpacing,
              ),
              itemBuilder: (context, index) {
                final digit = _digits[index];
                final letters = _letters[digit] ?? '';
                return Center(
                  child: SizedBox.square(
                    dimension: buttonSize,
                    child: Material(
                      color: const Color(0xFF2D4057),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _addDigit(digit),
                        onLongPress: digit == '0' ? () => _addDigit('+') : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              digit,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                height: 1.05,
                              ),
                            ),
                            if (letters.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                letters,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: .4,
                                  height: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 54),
            SizedBox.square(
              dimension: 64,
              child: FilledButton(
                onPressed: controller.text.trim().isEmpty ? null : onCall,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF21C55D),
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.call_rounded, color: Colors.white),
              ),
            ),
            SizedBox(
              width: 54,
              child: IconButton(
                tooltip: 'Delete last digit',
                onPressed: controller.text.isEmpty
                    ? null
                    : () {
                        final text = controller.text;
                        controller.text = text.substring(0, text.length - 1);
                        onChanged();
                      },
                icon: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ContactsTabs extends StatelessWidget {
  const _ContactsTabs({
    required this.showKeypad,
    required this.onContactsTap,
    required this.onKeypadTap,
  });

  final bool showKeypad;
  final VoidCallback onContactsTap;
  final VoidCallback onKeypadTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ContactsTab(
          label: 'Contacts',
          icon: Icons.account_circle_outlined,
          selected: !showKeypad,
          onTap: onContactsTap,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ContactsTab(
          label: 'Keypad',
          icon: Icons.dialpad_rounded,
          selected: showKeypad,
          onTap: onKeypadTap,
        ),
      ),
    ],
  );
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: selected ? Colors.white : const Color(0xCC355364),
        foregroundColor: selected ? const Color(0xFF101820) : Colors.white70,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
