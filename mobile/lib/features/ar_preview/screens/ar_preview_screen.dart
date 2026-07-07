import 'package:cached_network_image/cached_network_image.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/theme/spoil_colors.dart';
import '../../catalog/providers/catalog_provider.dart';

class ArPreviewScreen extends ConsumerStatefulWidget {
  const ArPreviewScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ArPreviewScreen> createState() => _ArPreviewScreenState();
}

class _ArPreviewScreenState extends ConsumerState<ArPreviewScreen> {
  CameraController? _camera;
  double _scale = 1.0;
  Offset _offset = const Offset(0, 0);
  bool _cameraReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await controller.initialize();
      if (mounted) {
        setState(() {
          _camera = controller;
          _cameraReady = true;
        });
      }
    } catch (e) {
      setState(() => _error = 'Camera access unavailable.');
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  bool _useNativeAr(String previewMode, String modelUrl) =>
      previewMode == 'model_3d' && modelUrl.isNotEmpty && !kIsWeb;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Preview in your space'),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: SpoilColors.teal)),
        error: (e, _) => Center(child: Text('Could not load product.\n$e', style: const TextStyle(color: Colors.white))),
        data: (product) {
          if (_useNativeAr(product.previewMode, product.model3dUrl)) {
            return _NativeArView(
              productName: product.name,
              modelUrl: product.model3dUrl,
              scale: double.tryParse(product.previewScale) ?? 1.0,
            );
          }
          return _ImageOverlayView(
            product: product,
            camera: _camera,
            cameraReady: _cameraReady,
            error: _error,
            scale: _scale,
            offset: _offset,
            onPanUpdate: (d) => setState(() => _offset += d.delta),
            onScaleUpdate: (d) => setState(() => _scale = (_scale * d.scale).clamp(0.4, 2.5)),
          );
        },
      ),
    );
  }
}

class _NativeArView extends StatelessWidget {
  const _NativeArView({
    required this.productName,
    required this.modelUrl,
    required this.scale,
  });

  final String productName;
  final String modelUrl;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ModelViewer(
          src: modelUrl,
          alt: productName,
          ar: true,
          arModes: const ['webxr', 'scene-viewer', 'quick-look'],
          cameraControls: true,
          autoRotate: true,
          scale: '$scale $scale $scale',
          backgroundColor: const Color(0xFF1A2E2E),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Tap the AR icon to place this gift in your room (ARCore / ARKit)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageOverlayView extends StatelessWidget {
  const _ImageOverlayView({
    required this.product,
    required this.camera,
    required this.cameraReady,
    required this.error,
    required this.scale,
    required this.offset,
    required this.onPanUpdate,
    required this.onScaleUpdate,
  });

  final dynamic product;
  final CameraController? camera;
  final bool cameraReady;
  final String? error;
  final double scale;
  final Offset offset;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(ScaleUpdateDetails) onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final baseScale = double.tryParse(product.previewScale) ?? 1.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (cameraReady && camera != null)
          CameraPreview(camera!)
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C4A4A), Color(0xFF1A2E2E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Text(
                error ?? (kIsWeb ? 'Drag the gift to preview placement.' : 'Starting camera…'),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Center(
          child: GestureDetector(
            onPanUpdate: onPanUpdate,
            onScaleUpdate: onScaleUpdate,
            child: Transform.translate(
              offset: offset,
              child: Transform.scale(
                scale: scale * baseScale,
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        width: 220,
                        fit: BoxFit.contain,
                      )
                    : Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: SpoilColors.blush,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.card_giftcard, size: 72, color: SpoilColors.teal),
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  product.model3dUrl.isEmpty
                      ? 'Pinch to resize · drag to move (image overlay)'
                      : 'Add a 3D model URL in admin for native AR placement',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}