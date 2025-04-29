import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path; // Import path package with prefix

// Data model for each photo item in the album. (Remains the same)
class PhotoItem {
  String filePath;
  PhotoItem({required this.filePath});
}

// A StatefulWidget that displays a horizontal, scrollable photo album.
class FourthMedia extends StatefulWidget {
  const FourthMedia({Key? key}) : super(key: key);

  @override
  _FourthMediaState createState() => _FourthMediaState();
}

// The State class for FourthMedia, handling album logic and UI updates.
class _FourthMediaState extends State<FourthMedia> {
  final List<PhotoItem> photoItems = [];
  final ImagePicker _picker = ImagePicker();

  String _albumName = "My Photo Collection";
  // Keep _isEditMode BUT only for showing delete icons, not for the Add button
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    // --- Screen Size & Padding Calculations (Remain the same) ---
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
    final double totalItemContainerHeight = itemSquareSize;

    // --- MODIFIED item count ---
    // Count is always photoItems + 1 for the Add button
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
            // --- Editable Title Section (Remains the same) ---
            GestureDetector(
              onTap: _editAlbumName,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _albumName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_rounded, size: 20, color: Colors.grey[600]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Horizontal Photo List Container ---
            SizedBox(
              height: totalItemContainerHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: listHorizontalPaddingValue),
                // Use the MODIFIED item count
                itemCount: listViewItemCount,
                itemBuilder: (context, index) {
                  // --- MODIFIED logic to determine Add Button ---
                  // The Add button is always the last item (index == photoItems.length)
                  final bool isAddButton = index == photoItems.length;

                  return Padding(
                    padding: EdgeInsets.only(
                        right: (index == listViewItemCount - 1) ? 0 : calculatedItemSpacing),
                    child: isAddButton
                        ? _buildAddPhotosButton(itemSquareSize) // Always build Add button at the end
                        : _buildPhotoItem(index, itemSquareSize), // Build photo item otherwise
                  );
                },
              ),
            ),

            // --- Edit Mode Toggle Button (Modified Label) ---
            // This button now ONLY controls the visibility of delete icons
            const SizedBox(height: 20), // Add some space
            Center(
              child: ElevatedButton.icon(
                  icon: Icon(_isEditMode ? Icons.check_rounded : Icons.delete_sweep_rounded), // Changed edit icon to delete
                  label: Text(_isEditMode ? "Done Deleting" : "Delete Photos"), // Modified label
                  onPressed: () {
                    setState(() {
                      _isEditMode = !_isEditMode; // Toggle flag for delete icons
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditMode ? Colors.red[400] : null, // Optional: Change color in delete mode
                    foregroundColor: _isEditMode ? Colors.white : null,
                  )
              ),
            ),
            const Spacer(), // Pushes content below down
          ],
        ),
      ),
    );
  }

  // --- Build Photo Item (Remains mostly the same, delete icon controlled by _isEditMode) ---
  Widget _buildPhotoItem(int index, double itemSquareSize) {
    if (index < 0 || index >= photoItems.length) {
      return SizedBox(width: itemSquareSize, height: itemSquareSize);
    }
    final PhotoItem item = photoItems[index];

    return SizedBox(
      width: itemSquareSize,
      height: itemSquareSize,
      child: GestureDetector(
        // --- MODIFIED onTap: Always view slideshow ---
        onTap: () => _viewSlideshow(index),
        // --- REMOVED onLongPress (or repurpose if needed) ---
        // onLongPress: () { ... },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(0), // Adjusted for sharp corners if needed
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Photo
                Image.file(
                  File(item.filePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print("Error loading photo file (${item.filePath}): $error");
                    return const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40));
                  },
                ),
                // Delete Button Overlay (Visibility controlled by _isEditMode)
                if (_isEditMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _confirmRemoveItem(index), // Call confirmation method
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
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

  // --- Build Add Photos Button (Remains the same, always shown by ListView logic) ---
  Widget _buildAddPhotosButton(double itemSquareSize) {
    return SizedBox(
      width: itemSquareSize,
      height: itemSquareSize,
      child: GestureDetector(
        onTap: _pickMultipleImages, // Directly call image picker
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            // borderRadius: BorderRadius.circular(12), // Optional rounding
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate_rounded, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Add Photos', style: TextStyle(color: Colors.grey, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // --- Action Methods ---

  // _editAlbumName (Remains the same)
  Future<void> _editAlbumName() async {
    final TextEditingController nameController = TextEditingController(text: _albumName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Album'),
        content: TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(hintText: 'Enter album name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim().isNotEmpty ? nameController.text.trim() : _albumName),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName != null && newName != _albumName && mounted) {
      setState(() { _albumName = newName; });
    }
  }

  // _pickMultipleImages (Remains the same)
  Future<void> _pickMultipleImages() async {
    // No need to check _isEditMode here, button is always tappable
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
      if (pickedFiles.isEmpty || !mounted) return;
      // --- Optional: Show processing indicator ---
      List<PhotoItem> newItems = [];
      for (XFile imageFile in pickedFiles) {
        final savedFilePath = await _saveMediaToAppDirectory(imageFile.path);
        if (savedFilePath != null) {
          newItems.add(PhotoItem(filePath: savedFilePath));
        } else {
          print("Failed to save image: ${imageFile.path}");
          if (mounted) _showErrorSnackbar('Failed to save one or more images');
        }
        if (!mounted) return;
      }
      // --- Optional: Hide processing indicator ---
      if (newItems.isNotEmpty && mounted) {
        setState(() {
          photoItems.addAll(newItems); // Simply add to the end
        });
      }
    } catch (e) {
      print('Error picking multiple images: $e');
      if (mounted) _showErrorSnackbar('Error picking images: ${e.toString().characters.take(100)}');
    }
  }

  // _saveMediaToAppDirectory (Remains the same)
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

  // --- ADDED Confirmation Dialog for Removal ---
  Future<void> _confirmRemoveItem(int index) async {
    if (!mounted || index < 0 || index >= photoItems.length) return;
    final itemToRemove = photoItems[index];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: Column( // Use column to show image preview
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to permanently delete this photo?'),
            const SizedBox(height: 15),
            Image.file(File(itemToRemove.filePath), height: 100, fit: BoxFit.cover), // Preview
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
      _removeItem(index); // Call the actual removal logic
    }
  }


  // _removeItem (Now private, called by _confirmRemoveItem)
  void _removeItem(int index) async {
    // No need to check _isEditMode, confirmation dialog handles intent
    if (!mounted || index < 0 || index >= photoItems.length) return;
    final itemToRemove = photoItems[index];
    try {
      final mediaFile = File(itemToRemove.filePath);
      if (await mediaFile.exists()) {
        await mediaFile.delete();
        print('Deleted file: ${itemToRemove.filePath}');
      }
    } catch (e) {
      print("Error deleting file for item at index $index: $e");
      if (mounted) _showErrorSnackbar('Could not delete file', isWarning: true);
      // Decide if you want to stop UI update if deletion fails
      // return;
    }
    if (mounted) {
      setState(() {
        photoItems.removeAt(index);
      });
      _showErrorSnackbar('Photo deleted', isWarning: true); // Use warning color for delete feedback
    }
  }

  // _viewSlideshow (Remains the same)
  void _viewSlideshow(int startIndex) {
    if (photoItems.isEmpty) return;
    print("Navigate to slideshow starting at index $startIndex");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSlideshowScreen(
          photoItems: photoItems,
          initialIndex: startIndex,
        ),
      ),
    );
  }

  // _showErrorSnackbar (Remains the same)
  void _showErrorSnackbar(String message, {bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isWarning ? Colors.orangeAccent : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}

// ===============================================
// ==       PhotoSlideshowScreen WIDGET         ==
// ===============================================
// (This widget remains unchanged from the previous version)
class PhotoSlideshowScreen extends StatefulWidget {
  final List<PhotoItem> photoItems;
  final int initialIndex;

  const PhotoSlideshowScreen({
    Key? key,
    required this.photoItems,
    required this.initialIndex,
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
        title: Text(
          widget.photoItems.isNotEmpty ? '${_currentIndex + 1} / ${widget.photoItems.length}' : '',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photoItems.length,
        onPageChanged: (index) {
          setState(() { _currentIndex = index; });
        },
        itemBuilder: (context, index) {
          if (index < 0 || index >= widget.photoItems.length) {
            return const Center(child: Text("Invalid index", style: TextStyle(color: Colors.white)));
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
                  return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 60));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}