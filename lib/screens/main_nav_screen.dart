import 'package:flutter/material.dart';
import '../theme/fonts.dart';
import 'home_screen.dart';
import 'live_tv_screen.dart';
import 'search_screen.dart';
import 'watchlist_screen.dart';
import 'downloads_screen.dart';
import '../widgets/ai_agent_fab.dart';

class MainNavScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;
  bool _isFullscreen = false;

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_filled, 'label': 'Home'},
    {'icon': Icons.live_tv_rounded, 'label': 'Live TV', 'isLive': true},
    {'icon': Icons.search_rounded, 'label': 'Search'},
    {'icon': Icons.bookmark_rounded, 'label': 'Watchlist'},
    {'icon': Icons.download_rounded, 'label': 'Downloads'},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          LiveTVScreen(
            isActive: _currentIndex == 1,
            onFullscreenChanged: (isFull) {
              if (mounted) {
                setState(() => _isFullscreen = isFull);
              }
            },
          ),
          const SearchScreen(),
          const WatchlistScreen(),
          const DownloadsScreen(),
        ],
      ),
      floatingActionButton: _isFullscreen
          ? null
          : AIAgentFab(
              onNavigateTab: (index) {
                if (index >= 0 && index < _navItems.length) {
                  setState(() => _currentIndex = index);
                }
              },
            ),
      bottomNavigationBar: _isFullscreen
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    // Crisp Ceramic Pure White Floating Dock Container
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: const Color(0xFFE4E4E7),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_navItems.length, (index) {
                      final item = _navItems[index];
                      final isSelected = _currentIndex == index;

                      return GestureDetector(
                        onTap: () => setState(() => _currentIndex = index),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: isSelected
                              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 9)
                              : const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            // Active Selected: Clean Solid Black Pill with White Glyphs & Text
                            color: isSelected ? const Color(0xFF09090B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 20,
                                    color: isSelected ? Colors.white : const Color(0xFF27272A),
                                  ),
                                  if (item['isLive'] == true && !isSelected)
                                    Positioned(
                                      top: -1,
                                      right: -2,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Colors.black87,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Text(
                                  item['label'] as String,
                                  style: AppFonts.sCoreDream(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
