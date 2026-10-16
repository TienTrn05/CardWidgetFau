import 'package:carwidget/app/theme/app_theme.dart';
import 'package:carwidget/core/storage/local_state_store.dart';
import 'package:carwidget/features/cards/data/car_catalog.dart';
import 'package:carwidget/features/cards/presentation/pages/driving_mode_page.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/material.dart';

class MyCarPage extends StatefulWidget {
  const MyCarPage({super.key});

  @override
  State<MyCarPage> createState() => _MyCarPageState();
}

class _MyCarPageState extends State<MyCarPage> {
  late final PageController _garageController;
  final List<_GarageCar> _cars = [
    const _GarageCar(brand: 'Acura', bodyStyle: 'SUV', year: '2025'),
  ];
  int _currentCar = 0;

  @override
  void initState() {
    super.initState();
    final saved = LocalStateStore.instance.readMap('garage');
    if (saved != null) {
      _cars
        ..clear()
        ..addAll(
          (saved['cars'] as List).map((entry) {
            final car = Map<String, dynamic>.from(entry as Map);
            return _GarageCar(
              brand: car['brand'] as String,
              bodyStyle: car['bodyStyle'] as String,
              year: car['year'] as String,
            );
          }),
        );
      _currentCar = _cars.isEmpty
          ? 0
          : (saved['selectedIndex'] as int? ?? 0).clamp(0, _cars.length - 1);
    }
    _garageController = PageController(initialPage: _currentCar);
  }

  void _saveGarage() => LocalStateStore.instance.setValue('garage', {
    'cars': [
      for (final car in _cars)
        {'brand': car.brand, 'bodyStyle': car.bodyStyle, 'year': car.year},
    ],
    'selectedIndex': _currentCar,
  });

  @override
  void dispose() {
    _garageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 18),
        child: Text(
          'My Car',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      _DrivingModeCard(onTap: _showDrivingMode),
      const SizedBox(height: 15),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Garage',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _addCar,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Car', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      const SizedBox(height: 6),
      if (_cars.isEmpty)
        _EmptyGarageCard(onAddCar: _addCar)
      else ...[
        SizedBox(
          height: 174,
          child: PageView.builder(
            controller: _garageController,
            itemCount: _cars.length,
            onPageChanged: (index) {
              setState(() => _currentCar = index);
              _saveGarage();
            },
            itemBuilder: (context, index) => _GarageCarCard(
              car: _cars[index],
              onDelete: () => _removeCar(index),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < _cars.length; index++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentCar == index ? 6 : 5,
                height: _currentCar == index ? 6 : 5,
                decoration: BoxDecoration(
                  color: _currentCar == index
                      ? AppColors.green
                      : Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ],
    ],
  );

  Future<void> _addCar() async {
    final car = await Navigator.of(context).push<_GarageCar>(
      CupertinoPageRoute<_GarageCar>(builder: (_) => const _AddCarFlowPage()),
    );
    if (car == null || !mounted) return;
    setState(() {
      _cars.add(car);
      _currentCar = _cars.length - 1;
    });
    _saveGarage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_garageController.hasClients && _cars.isNotEmpty) {
        _garageController.animateToPage(
          _cars.length - 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _removeCar(int index) async {
    final car = _cars[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove car?'),
        content: Text('Remove ${car.brand} from your garage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _cars.removeAt(index);
      _currentCar = _cars.isEmpty ? 0 : index.clamp(0, _cars.length - 1);
    });
    _saveGarage();
    if (_cars.isNotEmpty && _garageController.hasClients) {
      _garageController.jumpToPage(_currentCar);
    }
  }

  void _showDrivingMode() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DrivingModePage()));
}

class _GarageCar {
  const _GarageCar({
    required this.brand,
    required this.bodyStyle,
    required this.year,
  });

  final String brand;
  final String bodyStyle;
  final String year;
}

class _DrivingModeCard extends StatelessWidget {
  const _DrivingModeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(17),
    child: Container(
      height: (148 * MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
        148.0,
        double.infinity,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFF303940)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * .47,
            child: Opacity(
              opacity: .78,
              child: Image.asset(
                'assets/images/nav_paywall.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, .12),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surface,
                    Color(0xEE232C33),
                    Color(0x00232C33),
                  ],
                  stops: [0, .54, 1],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Driving Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const SizedBox(
                  width: 160,
                  child: Text(
                    'Enjoy seamless driving dashboard experience.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 164,
                  height: (38 * MediaQuery.textScalerOf(context).scale(12) / 12)
                      .clamp(38.0, double.infinity),
                  child: FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text(
                      'Go Now',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GarageCarCard extends StatelessWidget {
  const _GarageCarCard({required this.car, required this.onDelete});

  final _GarageCar car;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 2),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF303940)),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 98,
              height: 98,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1117),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _CarBrandMark(brand: car.brand),
            ),
            const SizedBox(height: 11),
            Text(
              car.brand,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${car.bodyStyle} ${car.year}',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
        Positioned(
          top: 6,
          right: 7,
          child: Material(
            color: const Color(0xFF111820),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onDelete,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CarBrandMark extends StatelessWidget {
  const _CarBrandMark({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 19,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFAAB7C2), width: 1.2),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(
          child: Text(
            brand.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFDCE4EA),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        brand.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF176BB2),
          fontSize: 8,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _EmptyGarageCard extends StatelessWidget {
  const _EmptyGarageCard({required this.onAddCar});

  final VoidCallback onAddCar;

  @override
  Widget build(BuildContext context) => Container(
    height: 174,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF303940)),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Your garage is empty',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onAddCar, child: const Text('Add a car')),
        ],
      ),
    ),
  );
}

enum _AddCarStep { brand, model, year }

class _AddCarFlowPage extends StatefulWidget {
  const _AddCarFlowPage();

  @override
  State<_AddCarFlowPage> createState() => _AddCarFlowPageState();
}

class _AddCarFlowPageState extends State<_AddCarFlowPage> {
  final _searchController = TextEditingController();
  _AddCarStep _step = _AddCarStep.brand;
  bool _isGoingBack = false;
  String _query = '';
  String? _selectedBrand;
  String? _selectedModel;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _title => switch (_step) {
    _AddCarStep.brand => 'Select Brand',
    _AddCarStep.model => 'Select Model',
    _AddCarStep.year => 'Select Year',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 400),
                    child: Text(
                      _title,
                      key: ValueKey(_step),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          if (_step != _AddCarStep.year) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 9),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _step == _AddCarStep.brand
                      ? 'Search brand name'
                      : 'Search model',
                  hintStyle: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 36),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFF252D33),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
          Expanded(
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final incoming = child.key == ValueKey(_step);
                  final direction = _isGoingBack ? -1.0 : 1.0;
                  final offset = incoming ? direction : -direction;
                  return IgnorePointer(
                    ignoring: !incoming,
                    child: FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(.12 * offset, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: _buildOptions(),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildOptions() {
    final step = _step;
    if (step == _AddCarStep.year) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        itemCount: carModelYears.length,
        separatorBuilder: (_, _) => const SizedBox(height: 7),
        itemBuilder: (context, index) {
          final year = carModelYears[index];
          return _CarOptionTile(
            label: '$year',
            onTap: () => Navigator.of(context).pop(
              _GarageCar(
                brand: _selectedBrand!,
                bodyStyle: _selectedModel!,
                year: '$year',
              ),
            ),
          );
        },
      );
    }

    final options = step == _AddCarStep.brand ? carBrandNames : carModelOptions;
    final filteredOptions = options
        .where((option) => option.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    if (filteredOptions.isEmpty) {
      return const Center(
        child: Text(
          'No results found',
          style: TextStyle(color: AppColors.muted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      itemCount: filteredOptions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final option = filteredOptions[index];
        return _CarOptionTile(
          label: option,
          leading: step == _AddCarStep.brand
              ? _BrandInitialBadge(brand: option)
              : null,
          onTap: () {
            if (step != _step) return;
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() {
              _isGoingBack = false;
              if (step == _AddCarStep.brand) {
                _selectedBrand = option;
                _step = _AddCarStep.model;
              } else {
                _selectedModel = option;
                _step = _AddCarStep.year;
              }
              _query = '';
              _searchController.clear();
            });
          },
        );
      },
    );
  }

  void _goBack() {
    if (_step == _AddCarStep.brand) {
      Navigator.of(context).pop();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isGoingBack = true;
      _step = _step == _AddCarStep.year ? _AddCarStep.model : _AddCarStep.brand;
      _query = '';
      _searchController.clear();
    });
  }
}

class _CarOptionTile extends StatelessWidget {
  const _CarOptionTile({
    required this.label,
    required this.onTap,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF252D33),
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: SizedBox(
        height: 46,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BrandInitialBadge extends StatelessWidget {
  const _BrandInitialBadge({required this.brand});

  final String brand;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF111820),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      brand.substring(0, 1).toUpperCase(),
      style: const TextStyle(
        color: AppColors.green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
