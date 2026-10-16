import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DrivingMapView extends StatefulWidget {
  const DrivingMapView({
    super.key,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  State<DrivingMapView> createState() => _DrivingMapViewState();
}

class _DrivingMapViewState extends State<DrivingMapView> {
  final _searchController = TextEditingController();
  MethodChannel? _channel;
  bool _searching = false;
  bool _openingDirections = false;
  bool _placeSheetOpen = false;
  _SelectedPlace? _selectedPlace;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  void _onMapCreated(int viewId) {
    _channel = MethodChannel('carwidget/driving_map_v1/$viewId');
    _channel!.setMethodCallHandler((call) async {
      if (!mounted) return;
      if (call.method == 'mapError') {
        _showError(
          'Apple Maps could not load. Check your internet connection.',
        );
      } else if (call.method == 'placeError') {
        _showError(call.arguments as String? ?? 'Could not load this place.');
      } else if (call.method == 'locationError') {
        _showError(
          call.arguments as String? ?? 'Your current location is unavailable.',
        );
      } else if (call.method == 'placeSelected') {
        final data = call.arguments;
        if (data is Map &&
            data['name'] is String &&
            data['address'] is String) {
          _selectPlace(
            _SelectedPlace(
              name: data['name'] as String,
              address: data['address'] as String,
            ),
          );
        }
      } else if (call.method == 'placeCleared' && _selectedPlace != null) {
        setState(() => _selectedPlace = null);
      }
    });
    _updateExpanded();
    setState(() {});
  }

  Future<void> _updateExpanded() async {
    try {
      await _channel?.invokeMethod<void>('setExpanded', widget.expanded);
    } on PlatformException catch (error) {
      _showError(error.message ?? 'Could not update the map layout.');
    } on MissingPluginException {
      _showError('Rebuild the iOS app to update Apple Maps.');
    }
  }

  @override
  void didUpdateWidget(DrivingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded != oldWidget.expanded) _updateExpanded();
  }

  void _selectPlace(_SelectedPlace place) {
    if (_selectedPlace?.name == place.name &&
        _selectedPlace?.address == place.address &&
        widget.expanded) {
      return;
    }
    setState(() => _selectedPlace = place);
    if (!widget.expanded) widget.onToggleExpanded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.expanded && (context.size?.height ?? 0) < 320) {
        _showPlaceSheet();
      }
    });
  }

  Future<void> _clearPlace() async {
    setState(() => _selectedPlace = null);
    try {
      await _channel?.invokeMethod<void>('clearSelection');
    } on PlatformException catch (error) {
      _showError(error.message ?? 'Could not clear the selected place.');
    } on MissingPluginException {
      _showError('Rebuild the iOS app to update Apple Maps.');
    }
  }

  Future<void> _getDirections() async {
    if (_channel == null || _openingDirections) return;
    _openingDirections = true;
    try {
      await _channel!.invokeMethod<void>('getDirections');
    } on PlatformException catch (error) {
      _showError(error.message ?? 'Could not open directions in Apple Maps.');
    } on MissingPluginException {
      _showError('Rebuild the iOS app to update Apple Maps.');
    } finally {
      _openingDirections = false;
    }
  }

  Future<void> _showPlaceSheet() async {
    final place = _selectedPlace;
    if (place == null || _placeSheetOpen) return;
    _placeSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * .65,
              ),
              child: SingleChildScrollView(
                child: _SelectedPlaceCard(
                  place: place,
                  onClose: () {
                    Navigator.of(sheetContext).pop();
                    _clearPlace();
                  },
                  onDirections: _getDirections,
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      _placeSheetOpen = false;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (_channel == null || _searching || query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _searching = true);
    try {
      await _channel!.invokeMethod<void>('search', {'query': query});
    } on PlatformException catch (error) {
      _showError(error.message ?? 'Could not find that place.');
    } on MissingPluginException {
      _showError('Rebuild the iOS app to enable Apple Maps.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10)],
    ),
    child: Row(
      children: [
        const Icon(CupertinoIcons.search, color: Color(0xFF323A3C), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _searchController,
            enabled: _supported && _channel != null && !_searching,
            textInputAction: TextInputAction.search,
            onSubmitted: _search,
            cursorColor: const Color(0xFF1685FF),
            style: const TextStyle(color: Color(0xFF323A3C), fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Search maps',
              hintStyle: TextStyle(color: Color(0xFF81888F)),
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
        ),
        if (_searching)
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ClipRRect(
    key: const ValueKey('driving-map'),
    borderRadius: BorderRadius.circular(22),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final place = _selectedPlace;
        final showPlaceCard =
            widget.expanded && place != null && constraints.maxHeight >= 320;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (_supported)
              UiKitView(
                viewType: 'carwidget/driving_map_v1',
                layoutDirection: TextDirection.ltr,
                onPlatformViewCreated: _onMapCreated,
                // Vertical drags scroll the dashboard; expanded maps own all gestures.
                gestureRecognizers: widget.expanded
                    ? {
                        Factory<EagerGestureRecognizer>(
                          () => EagerGestureRecognizer(),
                        ),
                      }
                    : const <Factory<OneSequenceGestureRecognizer>>{},
              )
            else
              const ColoredBox(
                color: Color(0xFFF5F3EB),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 72, 24, 64),
                    child: Text(
                      'Apple Maps is available on iPhone and iPad.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF60666B), fontSize: 15),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  if (!widget.expanded) ...[
                    const SizedBox(width: 12),
                    const SizedBox(width: 44),
                  ],
                ],
              ),
            ),
            if (widget.expanded && place != null && !showPlaceCard)
              Positioned(
                top: 70,
                right: 68,
                child: _MapButton(
                  tooltip: 'Place details',
                  onPressed: _showPlaceSheet,
                  icon: CupertinoIcons.placemark_fill,
                  color: const Color(0xFF1685FF),
                ),
              ),
            if (!widget.expanded)
              Positioned(
                right: 14,
                bottom: 44,
                child: _MapButton(
                  tooltip: 'Expand map',
                  onPressed: widget.onToggleExpanded,
                  icon: Icons.fullscreen_rounded,
                  color: const Color(0xFF253039),
                ),
              ),
            if (showPlaceCard)
              Positioned(
                left: 16,
                right: 16,
                // Keep Apple's attribution and Legal controls below the card.
                bottom: 34,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight - 154,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: _SelectedPlaceCard(
                      place: place,
                      onClose: _clearPlace,
                      onDirections: _getDirections,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _SelectedPlace {
  const _SelectedPlace({required this.name, required this.address});

  final String name;
  final String address;
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({
    required this.place,
    required this.onClose,
    required this.onDirections,
  });

  final _SelectedPlace place;
  final VoidCallback onClose;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF161C21),
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Close place details',
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                icon: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: Color(0xFF818B95),
                  size: 21,
                ),
              ),
            ],
          ),
          if (place.address.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              place.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF868E96),
                fontSize: 14,
                height: 1.25,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: onDirections,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1685FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.turn_right_rounded, size: 24),
              label: const Text(
                'Get Direction',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
    required this.color,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: const Color(0x33000000),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 26),
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
    ),
  );
}
