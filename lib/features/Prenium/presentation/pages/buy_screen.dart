import 'package:carwidget/app/theme/app_theme.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:carwidget/features/Prenium/presentation/widgets/plan_card.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  int selectedPlan = 0;
  int currentSlide = 0;

  late final PageController _pageController;

  Timer? _sliderTimer;

  final List<_PremiumSlide> slides = const [
    _PremiumSlide(
      image: 'assets/images/nav_paywall.png',
      title: 'Enable All Nav Features',
      description:
          'Carplay sounds, high-res maps, and intelligent router planning',
    ),
    _PremiumSlide(
      image: 'assets/images/nav_paywall.png',
      title: 'Drive Smarter',
      description: 'Enjoy intelligent navigation and premium driving features',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _startSliderTimer();
  }

  void _startSliderTimer() {
    _sliderTimer?.cancel();

    _sliderTimer = Timer(const Duration(seconds: 60), () {
      if (!mounted) return;

      if (!_pageController.hasClients) return;

      if (slides.length <= 1) return;

      final nextSlide = (currentSlide + 1) % slides.length;

      _pageController.animateToPage(
        nextSlide,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goToSlide(int index) {
    if (!_pageController.hasClients) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    _startSliderTimer();
  }

  void showBillingNotice() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Billing unavailable'),
          content: const Text(
            'Purchases and trial activation are not connected yet. '
            'You can explore the app without a charge.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();

    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification &&
                            notification.dragDetails != null) {
                          _startSliderTimer();
                        }

                        return false;
                      },
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const PageScrollPhysics(),
                        itemCount: slides.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentSlide = index;
                          });

                          _startSliderTimer();
                        },
                        itemBuilder: (context, index) {
                          final slide = slides[index];

                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // ==========================================
                              // IMAGE
                              // ==========================================
                              Image.asset(slide.image, fit: BoxFit.cover),

                              // ==========================================
                              // DARK GRADIENT
                              // ==========================================
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: AppGradients.heroFade,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: SafeArea(
                      bottom: false,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Explore app',
                                    onPressed: widget.onContinue,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: showBillingNotice,
                                    style: TextButton.styleFrom(
                                      backgroundColor: AppColors.muted,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Restore',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ======================================================
                          // TITLE + DESCRIPTION
                          // Positioned over the hero image.
                          // ======================================================
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 44,
                            child: IgnorePointer(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                child: Column(
                                  key: ValueKey(currentSlide),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      slides[currentSlide].title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      slides[currentSlide].description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(slides.length, (index) {
                                final isActive = currentSlide == index;

                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    _goToSlide(index);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeInOut,
                                      width: isActive ? 7 : 5,
                                      height: isActive ? 7 : 5,
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppColors.green
                                            : AppColors.inactiveDot,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                children: [
                  Container(
                    height: 44,
                    padding: const EdgeInsets.only(left: 14, right: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Enable Free Trial',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: selectedPlan == 0,
                          activeTrackColor: AppColors.green,
                          onChanged: (enabled) {
                            setState(() {
                              selectedPlan = enabled ? 0 : 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  PlanCard(
                    title: '3-DAY FREE TRIAL',
                    subtitle: 'then \$7.99 week',
                    price: 'FREE',
                    selected: selectedPlan == 0,
                    badge: 'Best Value',
                    onTap: () {
                      setState(() {
                        selectedPlan = 0;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  PlanCard(
                    title: 'WEEKLY PLAN',
                    price: '\$7.99/week',
                    selected: selectedPlan == 1,
                    onTap: () {
                      setState(() {
                        selectedPlan = 1;
                      });
                    },
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: showBillingNotice,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              selectedPlan == 0
                                  ? 'Start Free Trial'
                                  : 'Continue',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Terms of use',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gpp_good_rounded,
                              size: 16,
                              color: AppColors.green,
                            ),
                            Flexible(
                              child: Text(
                                'Cancel Anytime',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
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

class _PremiumSlide {
  const _PremiumSlide({
    required this.image,
    required this.title,
    required this.description,
  });

  final String image;
  final String title;
  final String description;
}
