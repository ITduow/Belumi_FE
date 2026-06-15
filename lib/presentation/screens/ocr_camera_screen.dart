import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Custom camera screen with flash toggle and auto-contrast guidance.
/// Returns the captured image file path via Navigator.pop.
class OcrCameraScreen extends StatefulWidget {
  const OcrCameraScreen({super.key});

  @override
  State<OcrCameraScreen> createState() => _OcrCameraScreenState();
}

class _OcrCameraScreenState extends State<OcrCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.auto;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'Không tìm thấy camera');
        return;
      }

      // Use the first back camera
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);

      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _error = 'Lỗi khởi tạo camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    final nextMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.torch,
      FlashMode.torch => FlashMode.off,
    };

    try {
      await _controller!.setFlashMode(nextMode);
      setState(() => _flashMode = nextMode);
    } catch (_) {
      // Some devices don't support all flash modes
    }
  }

  IconData get _flashIcon => switch (_flashMode) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        FlashMode.torch => Icons.flashlight_on,
      };

  String get _flashLabel => switch (_flashMode) {
        FlashMode.off => 'Tắt',
        FlashMode.auto => 'Tự động',
        FlashMode.always => 'Bật',
        FlashMode.torch => 'Đèn pin',
      };

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      // Enable auto-focus before capture for best quality
      await _controller!.setFocusMode(FocusMode.auto);
      // Small delay for focus to lock
      await Future.delayed(const Duration(milliseconds: 200));

      final xFile = await _controller!.takePicture();

      if (!mounted) return;
      Navigator.of(context).pop(xFile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chụp ảnh: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _error != null
            ? _buildError()
            : !_isInitialized
                ? _buildLoading()
                : _buildCamera(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Đang khởi tạo camera...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(child: CameraPreview(_controller!)),

        // Scan guide overlay
        _buildScanOverlay(),

        // Top bar with flash toggle and close button
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                // Close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                ),
                const Spacer(),
                // Flash toggle
                _FlashButton(
                  icon: _flashIcon,
                  label: _flashLabel,
                  onTap: _toggleFlash,
                ),
              ],
            ),
          ),
        ),

        // Bottom bar with capture button and instructions
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Đưa nhãn thành phần vào khung và chụp rõ nét',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Capture button
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing
                            ? Colors.grey
                            : Colors.white,
                      ),
                      child: _isCapturing
                          ? const Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.black54,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Corner decorations
              ..._cornerDecorations(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerDecorations() {
    const cornerSize = 24.0;
    const cornerWidth = 3.0;
    const color = Colors.white;

    return [
      // Top-left
      Positioned(
        top: -1,
        left: -1,
        child: SizedBox(
          width: cornerSize,
          height: cornerSize,
          child: CustomPaint(painter: _CornerPainter(cornerWidth, color, 0)),
        ),
      ),
      // Top-right
      Positioned(
        top: -1,
        right: -1,
        child: SizedBox(
          width: cornerSize,
          height: cornerSize,
          child: CustomPaint(painter: _CornerPainter(cornerWidth, color, 1)),
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: -1,
        left: -1,
        child: SizedBox(
          width: cornerSize,
          height: cornerSize,
          child: CustomPaint(painter: _CornerPainter(cornerWidth, color, 2)),
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: -1,
        right: -1,
        child: SizedBox(
          width: cornerSize,
          height: cornerSize,
          child: CustomPaint(painter: _CornerPainter(cornerWidth, color, 3)),
        ),
      ),
    ];
  }
}

class _FlashButton extends StatelessWidget {
  const _FlashButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(this.strokeWidth, this.color, this.corner);

  final double strokeWidth;
  final Color color;
  final int corner; // 0=TL, 1=TR, 2=BL, 3=BR

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    switch (corner) {
      case 0: // Top-left
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
      case 1: // Top-right
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      case 2: // Bottom-left
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      case 3: // Bottom-right
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
