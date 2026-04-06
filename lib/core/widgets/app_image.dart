import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppImage extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final double? width;
  final double? height;

  const AppImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.width,
    this.height,
  });

  @override
  State<AppImage> createState() => _AppImageState();
}

class _AppImageState extends State<AppImage> {
  late String _resolvedImagePath;
  bool _loadingSignedUrl = false;

  @override
  void initState() {
    super.initState();
    _resolvedImagePath = widget.imagePath;
    _resolveSignedUrlIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AppImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _resolvedImagePath = widget.imagePath;
      _loadingSignedUrl = false;
      _resolveSignedUrlIfNeeded();
    }
  }

  bool get _isNetworkImage {
    final uri = Uri.tryParse(_resolvedImagePath);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool get _isSupabasePublicStorageUrl {
    final uri = Uri.tryParse(widget.imagePath);
    return uri != null && uri.path.contains('/storage/v1/object/public/');
  }

  Future<void> _resolveSignedUrlIfNeeded() async {
    if (!_isSupabasePublicStorageUrl || _loadingSignedUrl) return;

    final uri = Uri.tryParse(widget.imagePath);
    if (uri == null) return;

    final segments = uri.pathSegments;
    final publicIndex = segments.indexOf('public');
    if (publicIndex == -1 || publicIndex + 2 >= segments.length) return;

    final bucket = segments[publicIndex + 1];
    final objectPath = segments.sublist(publicIndex + 2).join('/');

    setState(() {
      _loadingSignedUrl = true;
    });

    try {
      final signedUrl = await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(objectPath, 60 * 60);

      if (!mounted) return;
      setState(() {
        _resolvedImagePath = signedUrl;
      });
    } catch (_) {
      // Keep the original URL if signing fails.
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingSignedUrl = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSignedUrl && _isNetworkImage) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isNetworkImage) {
      return Image.network(
        _resolvedImagePath,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: widget.errorBuilder,
      );
    }

    return Image.asset(
      _resolvedImagePath,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: widget.errorBuilder,
    );
  }
}
