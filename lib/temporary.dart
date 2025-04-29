import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
double _buttonOpacity = 1.0;
const double kDefaultFontSize = 14.0;

class ForthPage extends StatefulWidget {
  const ForthPage({Key? key}) : super(key: key);

  @override
  State<ForthPage> createState() => _ForthPageState();
}

class _ForthPageState extends State<ForthPage> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    debugPaintSizeEnabled = false;
    super.initState();
    WakelockPlus.enable(); // Keeps the screen awake

    // Ensure immersive mode is applied in initState too
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Re-enforce landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force orientation check at build time
    final Orientation currentOrientation = MediaQuery.of(context).orientation;

    if (currentOrientation == Orientation.portrait) {
      // Force it back to landscape immediately
      Future.microtask(() {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      });
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          Expanded(
            // Replace HomePage with PageView
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                HomePage(pageIndex: 0),
                HomePage(pageIndex: 1),
                HomePage(pageIndex: 2),
                // Add more pages as needed
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Modified HomePage class to support page identification
class HomePage extends StatefulWidget {
  final int pageIndex;

  const HomePage({Key? key, required this.pageIndex}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
    _loadSavedData(); // Load previously saved data

    // Ensure immersive mode is applied in initState too
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _statusNoteController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _languageNoteController = TextEditingController();

  // Modified key for SharedPreferences to include page index
  String get _prefsKey => 'user_profile_data_page_${widget.pageIndex}';

  final List<String> selectedLanguages = [];
  final List<String> languageOptions = [
    'JP',
    'EN',
    'FR',
    'ES',
    'PT',
    'AR',
    'CH',
    'KR',
  ];

  String selectedStatus = "";
  final List<String> statusOptions = ['STUDENT', 'WORKER'];

  Timer? _inactivityTimer;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _statusNoteController.dispose();
    _hobbyController.dispose();
    _languageNoteController.dispose();
    super.dispose();
  }

  // Method to load saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_prefsKey);

    if (savedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(savedData);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _countryController.text = data['country'] ?? '';
          _cityController.text = data['city'] ?? '';
          _statusNoteController.text = data['statusNote'] ?? '';
          _hobbyController.text = data['hobby'] ?? '';
          _languageNoteController.text = data['languageNote'] ?? '';

          // Load selected languages
          selectedLanguages.clear();
          if (data['selectedLanguages'] != null) {
            List<dynamic> langs = data['selectedLanguages'];
            selectedLanguages.addAll(langs.map((e) => e.toString()));
          }

          // Load selected status
          selectedStatus = data['selectedStatus'] ?? '';
        });
      } catch (e) {
        debugPrint("Error occurred: $e");
      }
    }
  }

  // Method to save data to SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      'name': _nameController.text,
      'country': _countryController.text,
      'city': _cityController.text,
      'statusNote': _statusNoteController.text,
      'hobby': _hobbyController.text,
      'languageNote': _languageNoteController.text,
      'selectedLanguages': selectedLanguages,
      'selectedStatus': selectedStatus,
      'lastSaved': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_prefsKey, json.encode(data));
  }

  // Rest of the code remains the same

  // ... (rest of your code unchanged) ...

  // Same fieldBlock method and build method

  void _onUserInteraction() {
    setState(() {
      _buttonOpacity = 1.0; // Always set to visible on interaction
    });
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      setState(() {
        _buttonOpacity = 0.0;
      });
    });
  }

  // Existing fieldBlock method
  Widget fieldBlock(
      String label,
      TextEditingController controller, {
        double fontSize = 14,
      }) {
    // ... existing implementation ...
    bool isBigField = label.contains("NAME") || label.contains("HOBBY");
    bool isOriginField = label.contains("COUNTRY") || label.contains("CITY");

    // Calculate dynamic font sizes based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Scale font sizes relative to screen dimensions
    final dynamicSize = screenHeight * 0.025; // 2.5% of screen height

    // Set label font size
    final labelFontSize = fontSize + (dynamicSize * 0.7);

    // Calculate input text size based on field type and screen size
    double inputTextSize;
    if (isBigField) {
      inputTextSize = screenHeight * 0.09; // Larger font for name and hobby (adjusted)
    } else if (isOriginField) {
      inputTextSize = screenHeight * 0.055; // Smaller font for country/city (adjusted)
    } else {
      inputTextSize = screenHeight * 0.045; // Default size for other fields (adjusted)
    }

    // Adjust text sizes for smaller screens
    if (screenWidth < 600) {
      inputTextSize *= 0.85;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: labelFontSize),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: TextField(
                controller: controller,
                maxLines: 1,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (_) => _onUserInteraction(), // Ensure button stays visible when typing
                style: TextStyle(
                  fontSize: inputTextSize,
                  height: 1.1,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use FocusScope to detect when keyboard appears
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _onUserInteraction();
      }
    });

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Scaffold(
          resizeToAvoidBottomInset: false, // Prevent keyboard from causing layout issues
          extendBody: true, // Important: ensures content isn't hidden behind FAB
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              "Profile Page ${widget.pageIndex + 1}",
              style: const TextStyle(color: Colors.black),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Main form content - takes all available space
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Column(
                            children: [
                              Expanded(
                                flex: 25,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 0.8),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: fieldBlock("NAME (NICK NAME)", _nameController),
                                ),
                              ),
                              // Rest of your form content
                              Expanded(
                                flex: 20,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 1.0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: fieldBlock(
                                            "COUNTRY OF ORIGIN",
                                            _countryController,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: fieldBlock(
                                            "CITY OF ORIGIN",
                                            _cityController,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Languages section
                              Expanded(
                                flex: 9,
                                child: Container(
                                  // ... existing implementation ...
                                  // Rest of your content remains the same
                                ),
                              ),
                              // ... rest of your sections ...
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: AnimatedOpacity(
            opacity: _buttonOpacity,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: () async {
                    await _saveData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile saved successfully')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile'),
                ),
                const SizedBox(height: 10),
                // Add page indicator

              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}