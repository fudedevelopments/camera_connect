import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/camera_image.dart';
import '../models/connection_status.dart';
import '../services/camera_service.dart';

/// Image gallery widget for displaying camera images
class ImageGallery extends StatefulWidget {
  const ImageGallery({super.key});

  @override
  State<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<ImageGallery> {
  final CameraService _cameraService = CameraService();

  List<CameraImage> _images = [];
  bool _isLoading = false;
  bool _isConnected = false;
  String? _errorMessage;
  final Map<String, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _isConnected = _cameraService.currentStatus.isConnected;

    _cameraService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isConnected = status.isConnected;
          if (!_isConnected) {
            _images = [];
            _thumbnailCache.clear();
          }
        });
      }
    });

    _cameraService.imagesStream.listen((images) {
      if (mounted) {
        setState(() {
          _images = images;
        });
      }
    });

    if (_isConnected) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    if (!_isConnected) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final images = await _cameraService.getImages();
      setState(() {
        _images = images;
        _isLoading = false;
      });

      // Load thumbnails
      for (final image in images) {
        _loadThumbnail(image.objectHandle);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadThumbnail(String objectHandle) async {
    if (_thumbnailCache.containsKey(objectHandle)) return;

    final thumbnail = await _cameraService.downloadThumbnail(objectHandle);
    if (thumbnail != null && mounted) {
      setState(() {
        _thumbnailCache[objectHandle] = thumbnail;
      });
    }
  }

  Future<void> _downloadImage(CameraImage image) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Downloading ${image.filename}...'),
          ],
        ),
      ),
    );

    final imageData = await _cameraService.downloadImage(image.objectHandle);

    Navigator.of(context).pop();

    if (imageData != null) {
      _showImagePreview(image.filename, imageData);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to download image')));
    }
  }

  void _showImagePreview(String filename, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(filename),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(child: InteractiveViewer(child: Image.memory(imageData))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected) {
      return _buildNotConnectedMessage();
    }

    if (_isLoading && _images.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading images...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorMessage();
    }

    if (_images.isEmpty) {
      return _buildEmptyMessage();
    }

    return _buildImageGrid();
  }

  Widget _buildNotConnectedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('Not Connected', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Connect to a camera to view images',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading images',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadImages,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'No Images Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The camera storage appears to be empty',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadImages,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return RefreshIndicator(
      onRefresh: _loadImages,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '${_images.length} images',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadImages,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return _buildImageTile(_images[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(CameraImage image) {
    final thumbnail = _thumbnailCache[image.objectHandle];

    return GestureDetector(
      onTap: () => _showImageDetails(image),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail or placeholder
            if (thumbnail != null)
              Image.memory(thumbnail, fit: BoxFit.cover)
            else if (image.thumbnailData != null)
              Image.memory(image.thumbnailData!, fit: BoxFit.cover)
            else
              Container(
                color: Colors.grey[800],
                child: const Center(
                  child: Icon(Icons.image, size: 32, color: Colors.grey),
                ),
              ),

            // Overlay with file info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.filename,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      image.formattedSize,
                      style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ),

            // File type badge
            if (image.isRaw || image.isVideo)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: image.isRaw ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    image.extension,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showImageDetails(CameraImage image) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    image.filename,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDetailRow('Size', image.formattedSize),
            _buildDetailRow('Format', image.format),
            if (image.width != null && image.height != null)
              _buildDetailRow('Dimensions', '${image.width} x ${image.height}'),
            if (image.captureDate != null)
              _buildDetailRow('Date', image.captureDate.toString()),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadImage(image);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
