import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

// Enhanced data model for photo items that can contain multiple photos
class PhotoItem {
  String filePath;
  List<String>? subPhotos; // Additional photos in this album
  String? albumName; // Name to display beneath the album

  PhotoItem({
    required this.filePath,
    this.subPhotos,
    this.albumName
  });

  // Helper to get total photo count (main photo + sub photos)
  int get totalPhotoCount => 1 + (subPhotos?.length ?? 0);
}

// A StatefulWidget that displays a horizontal, scrollable photo album
class FourthMedia extends StatefulWidget {
  const FourthMedia({Key? key}) : super(key: key);

  @override
  _FourthMediaState createState() => _FourthMediaState();
}

// The State class for FourthMedia, handling album logic and UI updates
class _FourthMediaState extends State<FourthMedia> {
  final List<PhotoItem> photoItems = [];
  final ImagePicker _picker = ImagePicker();

  String _appTitle = "My Photo Albums";
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final double responsiveHorizontalPadding = screenWidth * 0.05;
    const double fixedVerticalPadding = 16.0;
    const double listHorizontalPaddingValue = 16.0;
    const double calculatedItemSpacing = 16.0;
    final double itemsToShow = 3.2;
    final double estimatedVisibleSpaces = (itemsToShow - 1).clamp(0, double.infinity);
    double baseItemWidth = (screenWidth - (listHorizontalPaddingValue * 2) - (estimatedVisibleSpaces * calculatedItemSpacing)) / itemsToShow;
    double scaledItemWidth = baseItemWidth * 1.0;
    const double minimumItemSize = 90.0;
    if (scaledItemWidth < minimumItemSize) {
      scaledItemWidth = minimumItemSize;
    }
    final double finalItemSize = scaledItemWidth;
    final double itemSquareSize = finalItemSize;

    // Height for the entire item container including album name
    final double totalItemContainerHeight = itemSquareSize;

    // Always include add button at the end
    final int listViewItemCount = photoItems.length + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: responsiveHorizontalPadding,
            vertical: fixedVerticalPadding
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title Section
            GestureDetector(
              onTap: _editAppTitle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _appTitle,
                    style: const TextStyle(fontSize: 24, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded, size: 20, color: Colors.grey[600]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal Photo Albums Container
            SizedBox(
              height: totalItemContainerHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: listHorizontalPaddingValue),
                itemCount: listViewItemCount,
                itemBuilder: (context, index) {
                  // The Add button is always the last item
                  final bool isAddButton = index == photoItems.length;

                  return Padding(
                    padding: EdgeInsets.only(
                        right: (index == listViewItemCount - 1) ? 0 : calculatedItemSpacing
                    ),
                    child: isAddButton
                        ? _buildAddPhotosButton(itemSquareSize) // Add button
                        : _buildPhotoItemWithLabel(index, itemSquareSize), // Photo album
                  );
                },
              ),
            ),

            // Edit Mode Toggle Button
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                  icon: Icon(_isEditMode ? Icons.check_rounded : Icons.edit),
                  label: Text(_isEditMode ? "Done Editing" : "Edit Albums"),
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Colors.green : null,
                    foregroundColor: _isEditMode ? Colors.white : null,
                  )
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // Build a photo item that can contain multiple photos
  Widget _buildPhotoItem(int index, double itemSquareSize) {
    if (index < 0 || index >= photoItems.length) {
      return SizedBox(width: itemSquareSize, height: itemSquareSize);
    }

    final PhotoItem item = photoItems[index];

    return SizedBox(
      width: itemSquareSize,
      height: itemSquareSize,
      child: GestureDetector(
        // Tap to view slideshow of all photos in album
        onTap: () => _viewSlideshow(index),
        // Long press to show options menu
        onLongPress: () => _showItemOptionsMenu(index, context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Main photo display
                Image.file(
                  File(item.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading photo file (${item.filePath}): $error");
                    return const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40));
                  },
                ),

                // Photo counter badge (shows if this album has multiple photos)
                if (item.subPhotos != null && item.subPhotos!.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "+${item.subPhotos!.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Delete Button Overlay (visible in edit mode)
                if (_isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _confirmRemoveItem(index),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build photo item with album name label beneath it
  Widget _buildPhotoItemWithLabel(int index, double itemSquareSize) {
    if (index < 0 || index >= photoItems.length) {
      return SizedBox(width: itemSquareSize, height: itemSquareSize + 30);
    }

    final PhotoItem item = photoItems[index];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPhotoItem(index, itemSquareSize),
        Container(
          width: itemSquareSize,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            item.albumName ?? "Album ${index + 1}", // Use provided name or default
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Build Add Photos Button (creates new albums)
  Widget _buildAddPhotosButton(double itemSquareSize) {
    return SizedBox(
      width: itemSquareSize,
      height: itemSquareSize,
      child: GestureDetector(
        onTap: _createNewAlbum,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Create Album', style: TextStyle(color: Colors.grey, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // Edit application title
  Future<void> _editAppTitle() async {
    final TextEditingController titleController = TextEditingController(text: _appTitle);

    final String? newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Title'),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter title'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              titleController.text.trim().isNotEmpty ? titleController.text.trim() : _appTitle,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle != _appTitle && mounted) {
      setState(() { _appTitle = newTitle; });
    }
  }

  // Create a new album
  void _createNewAlbum() async {
    final TextEditingController nameController = TextEditingController(text: "New Album");

    final String? albumName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Album'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Album Name',
            hintText: 'Enter a name for your album',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (albumName != null && albumName.isNotEmpty && mounted) {
      _pickImagesForNewAlbum(albumName);
    }
  }

  // Pick images for a new album
  void _pickImagesForNewAlbum(String albumName) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 85);

      if (pickedFiles.isEmpty || !mounted) return;

      // First image becomes the main photo (cover)
      final String? mainPhotoPath = await _saveMediaToAppDirectory(pickedFiles[0].path);
      if (mainPhotoPath == null) {
        if (mounted) _showErrorSnackbar('Failed to create album');
        return;
      }

      // Rest of images become sub-photos
      List<String> subPhotoPaths = [];
      for (int i = 1; i < pickedFiles.length; i++) {
        final savedPath = await _saveMediaToAppDirectory(pickedFiles[i].path);
        if (savedPath != null) {
          subPhotoPaths.add(savedPath);
        }
      }

      setState(() {
        photoItems.add(
          PhotoItem(
            filePath: mainPhotoPath,
            subPhotos: subPhotoPaths.isEmpty ? null : subPhotoPaths,
            albumName: albumName,
          ),
        );
      });

      _showErrorSnackbar('Album created with ${pickedFiles.length} photos');
    } catch (e) {
      print('Error creating album: $e');
      if (mounted) _showErrorSnackbar('Error creating album');
    }
  }

  // Add photos to an existing album
  Future<void> _addPhotosToItem(int index) async {
    if (index < 0 || index >= photoItems.length) return;

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isEmpty || !mounted) return;

      List<String> newPaths = [];
      for (XFile imageFile in pickedFiles) {
        final savedFilePath = await _saveMediaToAppDirectory(imageFile.path);
        if (savedFilePath != null) {
          newPaths.add(savedFilePath);
        } else {
          print("Failed to save image: ${imageFile.path}");
        }
      }

      if (newPaths.isNotEmpty && mounted) {
        setState(() {
          // Create the subPhotos list if it doesn't exist
          photoItems[index].subPhotos ??= [];
          photoItems[index].subPhotos!.addAll(newPaths);
        });
        _showErrorSnackbar('${newPaths.length} photos added to album');
      }
    } catch (e) {
      print('Error adding multiple images: $e');
      if (mounted) _showErrorSnackbar('Error adding photos');
    }
  }

  // View slideshow of all photos in an album
  void _viewSlideshow(int index) {
    if (index < 0 || index >= photoItems.length) return;

    final PhotoItem item = photoItems[index];

    // Create a list of all PhotoItem objects for slideshow
    List<PhotoItem> allPhotos = [];

    // Add main photo
    allPhotos.add(PhotoItem(filePath: item.filePath));

    // Add all sub-photos
    if (item.subPhotos != null && item.subPhotos!.isNotEmpty) {
      for (String path in item.subPhotos!) {
        allPhotos.add(PhotoItem(filePath: path));
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSlideshowScreen(
          photoItems: allPhotos,
          initialIndex: 0,
          albumName: item.albumName,
        ),
      ),
    );
  }

  // Show options menu for a photo item
  void _showItemOptionsMenu(int index, BuildContext context) async {
    if (index < 0 || index >= photoItems.length) return;

    final PhotoItem item = photoItems[index];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Add Photos to Album'),
              onTap: () {
                Navigator.pop(context);
                _addPhotosToItem(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Album Name'),
              onTap: () {
                Navigator.pop(context);
                _editAlbumName(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.slideshow),
              title: const Text('View Slideshow'),
              onTap: () {
                Navigator.pop(context);
                _viewSlideshow(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Album', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveItem(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Edit album name
  Future<void> _editAlbumName(int index) async {
    if (index < 0 || index >= photoItems.length) return;

    final PhotoItem item = photoItems[index];
    final TextEditingController nameController = TextEditingController(text: item.albumName ?? "");

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Album Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter album name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && mounted) {
      setState(() {
        photoItems[index].albumName = newName.isEmpty ? null : newName;
      });
    }
  }

  // Confirm before removing a photo item
  Future<void> _confirmRemoveItem(int index) async {
    if (!mounted || index < 0 || index >= photoItems.length) return;
    final itemToRemove = photoItems[index];
    final int totalPhotos = itemToRemove.totalPhotoCount;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Album?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to delete "${itemToRemove.albumName ?? "this album"}"?'),
            const SizedBox(height: 8),
            Text('This will permanently delete all $totalPhotos photos in this album.',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                  File(itemToRemove.filePath),
                  height: 100,
                  fit: BoxFit.cover
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _removeItem(index);
    }
  }

  // Remove a photo item and all associated files
  void _removeItem(int index) async {
    if (!mounted || index < 0 || index >= photoItems.length) return;
    final itemToRemove = photoItems[index];

    // Delete the main photo file
    try {
      final mainFile = File(itemToRemove.filePath);
      if (await mainFile.exists()) {
        await mainFile.delete();
      }

      // Delete all sub-photo files
      if (itemToRemove.subPhotos != null) {
        for (final subPath in itemToRemove.subPhotos!) {
          try {
            final subFile = File(subPath);
            if (await subFile.exists()) {
              await subFile.delete();
            }
          } catch (e) {
            print("Error deleting sub-file: $subPath, error: $e");
          }
        }
      }
    } catch (e) {
      print("Error deleting files for item at index $index: $e");
      if (mounted) _showErrorSnackbar('Could not delete all files', isWarning: true);
    }

    // Remove from the list
    setState(() {
      photoItems.removeAt(index);
    });

    if (mounted) {
      _showErrorSnackbar('Album deleted', isWarning: true);
    }
  }

  // Save media file to app directory
  Future<String?> _saveMediaToAppDirectory(String sourcePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileExtension = path.extension(sourcePath).split('?').first;
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'img_$timestamp$fileExtension';
      final destinationPath = path.join(directory.path, fileName);
      await File(sourcePath).copy(destinationPath);
      print('Saved photo to: $destinationPath');
      return destinationPath;
    } catch (e) {
      print('Error saving photo to app directory: $e');
      return null;
    }
  }

  // Show snackbar with message
  void _showErrorSnackbar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isWarning ? Colors.orangeAccent : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}

// ===============================================
// == PhotoSlideshowScreen WIDGET ==
// ===============================================
class PhotoSlideshowScreen extends StatefulWidget {
  final List<PhotoItem> photoItems;
  final int initialIndex;
  final String? albumName;

  const PhotoSlideshowScreen({
    Key? key,
    required this.photoItems,
    required this.initialIndex,
    this.albumName,
  }) : super(key: key);

  @override
  _PhotoSlideshowScreenState createState() => _PhotoSlideshowScreenState();
}

class _PhotoSlideshowScreenState extends State<PhotoSlideshowScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            if (widget.albumName != null)
              Text(
                widget.albumName!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            Text(
              widget.photoItems.isNotEmpty
                  ? "${_currentIndex + 1} / ${widget.photoItems.length}"
                  : "",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoItems.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          if (index < 0 || index >= widget.photoItems.length) {
            return const Center(
              child: Text(
                  "Invalid image index",
                  style: TextStyle(color: Colors.white)
              ),
            );
          }

          final PhotoItem item = widget.photoItems[index];

          return InteractiveViewer(
            panEnabled: true,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(item.filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading slideshow image (${item.filePath}): $error");
                  return const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 60),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}