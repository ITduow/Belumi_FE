import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Trợ lý AI giúp cá nhân hóa\nquy trình chăm sóc da',
      subtitle: 'Giải pháp được thiết kế riêng cho bạn',
      buttonText: 'Tiếp tục',
      imagePath: 'assets/images/onboarding_1.jpg',
    ),
    OnboardingPageData(
      title: 'Phân tích làn da',
      subtitle: 'Dựa trên loại da và tình trạng da của bạn',
      buttonText: 'Tiếp tục',
      imagePath: 'assets/images/onboarding_2.jpg',
    ),
    OnboardingPageData(
      title: 'Tra cứu thành phần',
      subtitle: 'Phân tích an toàn thành phần sản phẩm',
      buttonText: 'Tiếp tục',
      imagePath: 'assets/images/onboarding_3.jpg',
    ),
    OnboardingPageData(
      title: 'Bảo mật thông tin',
      subtitle: 'Dữ liệu cá nhân được bảo vệ tuyệt đối',
      buttonText: 'Bắt đầu ngay',
      imagePath: 'assets/images/onboarding_4.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seen_onboarding', true);
    } catch (_) {}
    if (mounted) {
      context.go('/login');
    }
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.66; // Top image height (occupies 66% height for larger overlap)
    final cardHeight = size.height * 0.40;  // Bottom card height matching image proportions exactly (40% height)

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0ED), // var(--main-brand-background)
      body: Stack(
        children: [
          // Onboarding Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Stack(
                children: [
                  // 1. Top Photo
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: imageHeight,
                    child: Container(
                      color: const Color(0xFFEFE8E3),
                      child: Image.asset(
                        page.imagePath,
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.25), // Offset matching background y: -45.081px
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // 2. Bottom Card (overlapping the photo)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: cardHeight,
                    child: ClipPath(
                      clipper: CardCurveClipper(),
                      child: Container(
                        color: const Color(0xFFF5F0ED), // var(--main-brand-background)
                        padding: const EdgeInsets.fromLTRB(24.0, 72.0, 24.0, 28.0),
                        child: Column(
                          children: [
                            // Dots Indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _pages.length,
                                (dotIndex) => Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == dotIndex
                                        ? const Color(0xFF976D48) // Active indicator color
                                        : const Color(0xFFD9D9D9), // Inactive indicator color
                                  ),
                                ),
                              ),
                            ),
                            
                            const Spacer(flex: 2),
                            
                            // Text Content
                            Column(
                              children: [
                                SizedBox(
                                  width: 319,
                                  child: Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF3F2E1E), // var(--main-brand-foreground)
                                      height: 32 / 28, // line-height: 32px
                                      letterSpacing: -0.408,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    page.subtitle,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.monaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontStyle: FontStyle.normal,
                                      color: const Color(0xFF3F2E1E), // var(--main-brand-foreground)
                                      height: 1.25, // line-height: 125%
                                      letterSpacing: 0.14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const Spacer(flex: 3),
                            
                            // Action Button
                            SizedBox(
                              width: double.infinity, // align-self: stretch
                              height: 48, // min-height: 40px
                              child: ElevatedButton(
                                onPressed: _onNextPage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF976D48), // var(--main-brand-primary)
                                  foregroundColor: const Color(0xFFF6F5F4), // var(--neutral-fixed-light)
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999), // var(--size-full)
                                  ),
                                ),
                                child: Text(
                                  page.buttonText,
                                  style: GoogleFonts.monaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.normal,
                                    color: const Color(0xFFF6F5F4),
                                    height: 1.25, // line-height: 125%
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Skip button positioned at the top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: TextButton(
              onPressed: _completeOnboarding,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(76),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Bỏ qua',
                style: TextStyle(
                  color: Color(0xFF7A5A3C),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card curve clipper (concave U-shape dipping in the middle)
class CardCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final s = size.width / 402;
    
    // Start at scaled (127.103, 28.7603)
    path.moveTo(127.103 * s, 28.7603 * s);
    
    // Cubic to scaled (0, 0)
    path.cubicTo(
      62.4676 * s, 44.2466 * s,
      15.4363 * s, 16.0394 * s,
      0, 0,
    );
    
    // Line to bottom left corner
    path.lineTo(0, size.height);
    
    // Line to bottom right corner
    path.lineTo(size.width, size.height);
    
    // Line to scaled (402, 10.5086)
    path.lineTo(size.width, 10.5086 * s);
    
    // Cubic to scaled (286.721, 34.2911)
    path.cubicTo(
      369.978 * s, 42.5873 * s,
      332.044 * s, 49.2243 * s,
      286.721 * s, 34.2911 * s,
    );
    
    // Cubic to scaled (127.103, 28.7603)
    path.cubicTo(
      241.397 * s, 19.3579 * s,
      207.897 * s, 9.4024 * s,
      127.103 * s, 28.7603 * s,
    );
    
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String buttonText;
  final String imagePath;

  OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.imagePath,
  });
}
