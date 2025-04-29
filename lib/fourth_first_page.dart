import 'dart:convert'; // Import for JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flip_card/flip_card.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

// --- Data Model ---
// Add toJson and fromJson for persistence
class LinkItem {
  // Store the key (String) instead of IconData directly for easier saving
  final String iconKey;
  final String name;
  String? url;

  // Map iconKey back to IconData when needed
  IconData get icon => predefinedLinkOptions[iconKey] ?? Icons.link; // Default icon

  LinkItem({
    required this.iconKey, // Use iconKey
    required this.name,
    this.url,
  });

  // Convert LinkItem object to a JSON map
  Map<String, dynamic> toJson() => {
    'iconKey': iconKey,
    'name': name,
    'url': url,
  };

  // Create a LinkItem object from a JSON map
  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(
    // Provide default values in case of missing/invalid keys during loading
    iconKey: json['iconKey'] as String? ?? 'Custom Link',
    name: json['name'] as String? ?? 'Unknown',
    url: json['url'] as String?,
  );
}

// --- Predefined Options for Adding ---
// Keep this map accessible for mapping keys back to icons
const Map<String, IconData> predefinedLinkOptions = {
  'Instagram': Icons.photo_camera,
  'Line': Icons.chat_bubble_outline,
  'LinkedIn': Icons.workspace_premium,
  'GitHub': Icons.code,
  'X (Twitter)': Icons.alternate_email,
  'Website': Icons.link,
  'Portfolio': Icons.person_outline,
  'Email': Icons.email_outlined,
  'Phone': Icons.phone_outlined,
  'Facebook': Icons.facebook,
  'YouTube': Icons.play_circle_outline,
  'TikTok': Icons.music_note_outlined,
  'Custom Link': Icons.add_link,
};

// --- Instructions for each link type ---
// Value can be null if no specific instruction popup is needed for that type.
// \n creates a new line in the dialog text.
const Map<String, String?> linkTypeInstructions = {
  'Instagram': '1. Go to your Instagram Profile.\n'
      '2. Note your exact Username shown at the top.\n'
      '3. Tap OK below and enter only the Username (without @) in the next step.',
  'Line': '1. Open Line -> Home tab.\n'
      '2. Tap your Profile name/pic -> Profile.\n'
      '3. Find QR code icon or Share button.\n'
      '4. Choose "Copy link".\n'
      '5. Tap OK below and paste the full link (https://line.me/...) in the next step.',
  'LinkedIn': '1. Open LinkedIn (app or web).\n'
      '2. Go to your Profile ("Me" -> "View Profile").\n'
      '3. Tap "More..." or the three dots -> "Contact info".\n'
      '4. Copy your "Profile URL".\n'
      '5. Tap OK below and paste the URL in the next step.',
  'GitHub': '1. Go to github.com and log in.\n'
      '2. Click your profile picture (top-right) -> "Your profile".\n'
      '3. Copy the URL from your browser\'s address bar (github.com/YourUsername).\n'
      '4. Tap OK below and paste the URL in the next step.',
  'X (Twitter)': '1. Go to your X/Twitter Profile.\n'
      '2. Note your exact Username (handle) shown under your name (e.g., @YourHandle).\n'
      '3. The URL is https://x.com/YourHandle (or twitter.com/YourHandle).\n'
      '4. Tap OK below and enter the full URL in the next step.',
  'Website': null, // No extra instructions needed, just enter URL
  'Portfolio': null, // No extra instructions needed, just enter URL
  'Email': 'Tap OK below and enter your email address (e.g., name@example.com) in the next step. It will be formatted as a "mailto:" link.',
  'Phone': 'Tap OK below and enter your phone number (including country code if needed) in the next step. It will be formatted as a "tel:" link.',
  'Facebook': '1. Go to your Facebook Profile page (not feed).\n'
      '2. Tap the "..." (three dots) menu below your name.\n'
      '3. Select "Copy link to profile".\n'
      '4. Tap OK below and paste the URL in the next step.',
  'YouTube': '1. Go to your YouTube Channel page.\n'
      '2. Tap the three dots (top-right) -> Share -> Copy link.\n'
      '3. Tap OK below and paste the Channel URL in the next step.',
  'TikTok': '1. Go to your TikTok Profile.\n'
      '2. Tap your username near the top (it should say "Link copied").\n'
      '3. Alternatively, tap "Edit Profile" and copy the username.\n'
      '4. The URL is https://www.tiktok.com/@YourUsername.\n'
      '5. Tap OK below and paste the full URL in the next step.',
  'Custom Link': null, // No extra instructions needed, just enter URL
};


// Key for storing data in SharedPreferences
const String _linksPrefKey = 'linkItemsList_v1'; // Added version in case structure changes later


// --- Main Widget ---
class LinkQrGenerator extends StatefulWidget {
  const LinkQrGenerator({Key? key}) : super(key: key);

  @override
  _LinkQrGeneratorState createState() => _LinkQrGeneratorState();
}

class _LinkQrGeneratorState extends State<LinkQrGenerator> {
  // --- State ---
  List<LinkItem> _linkItems = []; // Initialize empty, will be loaded
  bool _isLoading = true; // Flag to show loading indicator

  final String _pageTitle = "Your Links & QR Codes";

  @override
  void initState() {
    super.initState();
    _loadLinks(); // Load saved links when the state is initialized
  }

  // --- Load links from SharedPreferences ---
  Future<void> _loadLinks() async {
    // No need to set _isLoading true here, already true initially
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? linksJson = prefs.getString(_linksPrefKey); // Get saved JSON string
      if (linksJson != null && linksJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(linksJson) as List;
        // Convert JSON maps back to LinkItem objects safely
        _linkItems = decodedList
            .map((itemJson) {
          try {
            return LinkItem.fromJson(itemJson as Map<String, dynamic>);
          } catch (e) {
            print("Error decoding single item: $e, item: $itemJson");
            return null; // Skip invalid items
          }
        })
            .whereType<LinkItem>() // Filter out nulls
            .toList();
      } else {
        _linkItems = []; // Start fresh if nothing saved or empty string
      }
    } catch (e) {
      print("Error loading links: $e");
      _linkItems = []; // Start fresh on error
      _showSnackbar("Error loading saved links.", isWarning: true);
    } finally {
      // Use mounted check before calling setState in async gap
      if (mounted) {
        setState(() { _isLoading = false; }); // Hide loading indicator
      }
    }
  }

  // --- Save links to SharedPreferences ---
  Future<void> _saveLinks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert LinkItem list to a list of JSON maps, then encode to string
      final String linksJson = jsonEncode(
          _linkItems.map((item) => item.toJson()).toList()
      );
      await prefs.setString(_linksPrefKey, linksJson); // Save the JSON string
      print("Links saved successfully."); // Optional: confirmation log
    } catch (e) {
      print("Error saving links: $e");
      // Only show snackbar if the widget is still visible
      if(mounted){
        _showSnackbar("Error saving links.", isWarning: true);
      }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final double responsiveHorizontalPadding = screenWidth * 0.05;
    const double fixedVerticalPadding = 16.0;
    const double listHorizontalPaddingValue = 16.0; // Padding inside listview itself
    const double calculatedItemSpacing = 16.0;
    final double itemsToShow = 2.8; // Adjust how many items are roughly visible
    final double estimatedVisibleSpaces = (itemsToShow - 1).clamp(0, double.infinity);

    double baseItemWidth = (screenWidth -
        ((responsiveHorizontalPadding + listHorizontalPaddingValue) * 2) - // Account for outer + inner padding
        (estimatedVisibleSpaces * calculatedItemSpacing)) /
        itemsToShow;

    const double minimumItemSize = 110.0; // Min size for better touchability
    if (baseItemWidth < minimumItemSize) {
      baseItemWidth = minimumItemSize;
    }
    final double finalItemWidth = baseItemWidth;
    // Keep height slightly larger for better QR display on back
    final double finalItemHeight = finalItemWidth * 1.25;

    // Calculate total list view item count (items + 1 add button)
    // Add null check for safety during initial loading phase
    final int listViewItemCount = _isLoading ? 0 : _linkItems.length + 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_pageTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(vertical: 0), // Removed vertical padding here, adjust if needed
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use Padding widget for the instruction text

            // const SizedBox(height: 16), // Removed SizedBox, padding added above

            // --- Horizontal Link List Container ---
            SizedBox(
              height: finalItemHeight * 0.85, // Use calculated height
              child: _isLoading // Show indicator while loading
                  ? const Center(child: CircularProgressIndicator())
                  : listViewItemCount == 1 // Only show "Add" button if list empty and not loading
                  ? Padding( // Center the Add button if it's the only item
                padding: EdgeInsets.symmetric(horizontal: responsiveHorizontalPadding + listHorizontalPaddingValue),
                child: _buildAddLinkButton(finalItemWidth, finalItemHeight),
              )
                  : ListView.builder( // Show list once loaded and not empty
                scrollDirection: Axis.horizontal,
                // Padding inside the list view - accounts for screen edges
                padding: EdgeInsets.symmetric(horizontal: responsiveHorizontalPadding + listHorizontalPaddingValue),
                itemCount: listViewItemCount, // Items + Add button
                itemBuilder: (context, index) {
                  final bool isAddButton = index == _linkItems.length;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: (index == listViewItemCount - 1) ? 0 : calculatedItemSpacing),
                    child: isAddButton
                        ? _buildAddLinkButton(finalItemWidth, finalItemHeight)
                        : _buildFlipCardLinkItem(index, finalItemWidth, finalItemHeight),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }

  // --- Build "Add Link" Button ---
  Widget _buildAddLinkButton(double itemWidth, double itemHeight) {
    return GestureDetector(
      onTap: _promptToAddLink, // Trigger the add link dialog
      child: Container(
        width: itemWidth,
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.grey[50], // Slightly off-white background
          border: Border.all(
            color: Colors.grey.shade400, // Lighter border
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8), // Consistent rounding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Add Link',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  // --- Build Individual Flippable Link Item Widget ---
  Widget _buildFlipCardLinkItem(
      int index,
      double itemWidth,
      double itemHeight,
      ) {
    // Safety check in case index is somehow out of bounds after loading/rebuild
    if (index < 0 || index >= _linkItems.length) {
      return SizedBox(width: itemWidth, height: itemHeight); // Return empty placeholder
    }
    final LinkItem item = _linkItems[index];
    final bool hasUrl = item.url != null && item.url!.isNotEmpty;

    // Common border decoration
    final boxDecoration = BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.black, width: 1.0),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

    return SizedBox( // Constrain the size of the FlipCard
      width: itemWidth,
      height: itemHeight,
      child: FlipCard(
        flipOnTouch: hasUrl, // Only allow flipping if URL exists
        direction: FlipDirection.HORIZONTAL, // Or VERTICAL

        // --- FRONT OF CARD ---
        front: GestureDetector(
          // If no URL, this tap prompts to add one.
          // If URL exists, flipOnTouch handles the tap.
          onTap: !hasUrl ? () => _promptForUrl(index) : null,
          child: Container(
            decoration: boxDecoration,
            child: Stack( // Use Stack to overlay delete button
              alignment: Alignment.center, // Center main content
              children: [
                // Main Content (Icon, Name, Hint)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 32, color: Colors.black), // Use getter here
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        item.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        // Updated hint logic
                        !hasUrl
                            ? (item.name == 'Instagram' ? 'Tap to add Username' : 'Tap to add ${item.name == 'Email' || item.name == 'Phone' ? 'Info' : 'URL'}')
                            : 'Tap to view QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasUrl ? Colors.green.shade700 : Colors.blueGrey,
                          fontSize: 11,
                          fontWeight: hasUrl ? FontWeight.normal : FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Delete Button Overlay
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[400]),
                    padding: const EdgeInsets.all(4), // Add padding around icon
                    constraints: const BoxConstraints(),
                    tooltip: 'Remove this link',
                    onPressed: () => _removeLinkItem(index),
                    splashRadius: 18, // Smaller splash
                  ),
                ),
              ],
            ),

          ),
        ),

        // --- BACK OF CARD ---
        back: Container(
          decoration: boxDecoration,
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Padding inside the back
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QR Code takes up most space
                Expanded(
                  child: Center(
                    child: QrImageView(
                      data: item.url ?? '', // Use URL, provide fallback
                      version: QrVersions.auto,
                      size: itemWidth * 0.75, // Adjust size relative to card width
                      padding: const EdgeInsets.all(4), // Padding around QR
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      errorStateBuilder: (cxt, err) {
                        return const Center(child: Text("Error", style: TextStyle(fontSize: 10)));
                      },
                    ),
                  ),
                ),
                // Link Name/URL at the bottom
                Text(
                  item.name, // Show name on back for context
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                SelectableText(
                  item.url ?? '', // Display the saved URL/mailto/tel link
                  style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Edit button on the back
                SizedBox(
                  height: 24, // Constrain button height
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit, size: 12),
                    label: const Text('Edit', style: TextStyle(fontSize: 10)), // Shortened label
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _promptForUrl(index); // Then prompt for URL/Username/Info
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // --- Action Handlers ---

  /// Shows a dialog to select the type of link to add.
  Future<void> _promptToAddLink() async {
    final selectedOption = await showDialog<MapEntry<String, IconData>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Link Type'),
        content: SizedBox(
          width: double.maxFinite, // Use available width
          child: ListView( // Use ListView for potentially many options
            shrinkWrap: true, // Take minimum space
            children: predefinedLinkOptions.entries.map((entry) {
              return ListTile(
                leading: Icon(entry.value),
                title: Text(entry.key),
                onTap: () {
                  Navigator.pop(context, entry); // Return selected MapEntry
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    // If user selected an option
    if (selectedOption != null && mounted) {
      final String linkTypeName = selectedOption.key;
      // final IconData linkTypeIcon = selectedOption.value; // Not needed directly here

      // --- SHOW INFO DIALOG IF INSTRUCTIONS EXIST ---
      final String? instructions = linkTypeInstructions[linkTypeName];
      if (instructions != null && instructions.isNotEmpty) {
        await _showInfoDialog(linkTypeName, instructions); // Pass type name and instructions

        // Check if still mounted after async gap
        if (!mounted) return;
      }

      // --- ALWAYS ADD ITEM AND PROMPT FOR URL/USERNAME AFTER INFO (or if no info needed) ---
      final newItem = LinkItem(
        iconKey: linkTypeName, // Use the selected key
        name: linkTypeName,
        url: null,
      );
      setState(() {
        _linkItems.add(newItem);
      });

      // Use WidgetsBinding to prompt *after* potential state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _linkItems.isNotEmpty) {
          _promptForUrl(_linkItems.length - 1); // Prompt for the newly added item
        }
      });
      // Saving happens within _promptForUrl after data is entered
    }
  }

  /// Shows generic informational dialog based on link type.
  Future<void> _showInfoDialog(String linkTypeName, String instructions) async {
    // Use mounted check BEFORE showing dialog in async function
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('How to get $linkTypeName info'), // Generic title
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Display the instructions passed to the function
                Text(instructions),
                const SizedBox(height: 12),
                Text(
                  'Tap OK below, then enter the required info in the next step.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the info dialog
              },
            ),
          ],
        );
      },
    );
  }


  /// Removes the item at the given index.
  Future<void> _removeLinkItem(int index) async { // Made async for await _saveLinks
    if (index < 0 || index >= _linkItems.length) return; // Bounds check

    final itemToRemove = _linkItems[index];
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Link?'),
        content: Text('Are you sure you want to remove the "${itemToRemove.name}" link?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel'),),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    // If confirmed, remove and save
    if (confirmed == true && mounted) { // Check if true
      setState(() {
        _linkItems.removeAt(index);
      });
      await _saveLinks(); // Save the list after removal
      _showSnackbar('${itemToRemove.name} link removed.', isWarning: true);
    }
  }

  /// Shows a dialog to input the URL or Username/Email/Phone for the selected item.
  Future<void> _promptForUrl(int index) async { // Made async for await _saveLinks
    if (index < 0 || index >= _linkItems.length) return; // Bounds check

    final LinkItem currentItem = _linkItems[index];
    // Extract current username/email/phone if editing
    String initialValue = ''; // Start empty for prompt
    bool isInstagram = currentItem.name == 'Instagram';
    bool isEmail = currentItem.name == 'Email';
    bool isPhone = currentItem.name == 'Phone';

    // --- Pre-fill Logic ---
    if (isInstagram && (currentItem.url?.startsWith('https://www.instagram.com/') ?? false)) {
      initialValue = currentItem.url!.split('instagram.com/').last.replaceAll('/', '');
    } else if (isEmail && (currentItem.url?.startsWith('mailto:') ?? false)) {
      initialValue = currentItem.url!.substring(7); // Remove 'mailto:'
    } else if (isPhone && (currentItem.url?.startsWith('tel:') ?? false)) {
      initialValue = currentItem.url!.substring(4); // Remove 'tel:'
    } else if (!isInstagram && !isEmail && !isPhone) {
      // Pre-fill with existing URL for other types
      initialValue = currentItem.url ?? '';
    }
    // --- End Pre-fill ---

    final TextEditingController inputController = TextEditingController(text: initialValue);

    // --- Dialog Setup ---
    String title = 'Enter URL for ${currentItem.name}';
    String hintText = 'https://example.com';
    String labelText = 'URL';
    TextInputType keyboardType = TextInputType.url;
    String? prefixText;
    TextStyle? prefixStyle;

    if (isInstagram) {
      title = 'Enter Instagram Username'; hintText = 'your_username'; labelText = 'Username'; keyboardType = TextInputType.text; prefixText = '@'; prefixStyle = const TextStyle(color: Colors.grey);
    } else if (isEmail) {
      title = 'Enter Email Address'; hintText = 'name@example.com'; labelText = 'Email'; keyboardType = TextInputType.emailAddress;
    } else if (isPhone) {
      title = 'Enter Phone Number'; hintText = '+1234567890'; labelText = 'Phone'; keyboardType = TextInputType.phone;
    }
    // --- End Dialog Setup ---


    final String? result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: inputController,
          autofocus: true,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
            prefixText: prefixText,
            prefixStyle: prefixStyle,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => inputController.clear(),
              tooltip: 'Clear',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel returns null
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String enteredText = inputController.text.trim();
              String finalUrl = ''; // Initialize

              // --- URL/Data Construction ---
              if (enteredText.isNotEmpty) { // Only process if not empty
                if (isInstagram) {
                  if (enteredText.startsWith('@')) enteredText = enteredText.substring(1);
                  // Basic check to avoid empty username in URL
                  if (enteredText.isNotEmpty) {
                    finalUrl = 'https://www.instagram.com/$enteredText/';
                  }
                } else if (isEmail) {
                  // Basic check for '@' symbol
                  if (enteredText.contains('@')) {
                    finalUrl = 'mailto:$enteredText'; // Add mailto prefix
                  } else {
                    // Optionally show an error or just save the invalid text?
                    // For now, we save it as is, but QR might not work as expected.
                    finalUrl = enteredText;
                    print("Warning: Invalid email format entered.");
                  }
                } else if (isPhone) {
                  // Remove common formatting characters for tel: link
                  enteredText = enteredText.replaceAll(RegExp(r'[\s()-]+'), '');
                  finalUrl = 'tel:$enteredText'; // Add tel prefix
                } else {
                  // Standard URL handling (same as before)
                  if (!enteredText.startsWith(RegExp(r'[a-zA-Z]+:'))){ // Check if scheme exists
                    if (enteredText.contains('.') && !enteredText.contains('@')) {
                      enteredText = 'https://$enteredText';
                    }
                  }
                  finalUrl = enteredText;
                }
              }
              // --- End URL Construction ---

              Navigator.pop(context, finalUrl); // Return the constructed/processed URL (or empty string)
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // --- State Update and Save ---
    // Only update state if a result was returned (Save was pressed) and it's different
    if (result != null && mounted) {
      final finalUrlToSave = result.isNotEmpty ? result : null; // Treat empty string as null URL
      if (_linkItems[index].url != finalUrlToSave) {
        setState(() {
          _linkItems[index].url = finalUrlToSave;
        });
        await _saveLinks(); // <<< SAVE THE LIST HERE after update
        _showSnackbar('Data for ${currentItem.name} ${finalUrlToSave != null ? 'saved' : 'cleared'}!',
            isSuccess: finalUrlToSave != null, isWarning: finalUrlToSave == null);
      }
    }
    // --- End State Update ---
  }

  /// Helper method to show feedback messages using a SnackBar.
  void _showSnackbar(String message, {bool isSuccess = false, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Colors.green
            : isWarning
            ? Colors.orangeAccent
            : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// --- Example Usage ---
class LinkQrPage extends StatelessWidget {
  const LinkQrPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If integrating into an existing app with MaterialApp, just use:
    // return const LinkQrGenerator();

    // Wrap with MaterialApp for context if running standalone
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Optional: hide debug banner
      home: LinkQrGenerator(),
    );
  }
}

/*
// Example main.dart if running this file standalone
import 'package:flutter/material.dart';
// Assuming your file is named link_qr_generator.dart
// import 'link_qr_generator.dart'; // Import your widget file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Link QR Generator Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const LinkQrPage(), // Start with your main page
    );
  }
}
*/
