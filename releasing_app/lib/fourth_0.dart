
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';
import 'fourth_1.dart';
import 'fourth_2.dart';

double _buttonOpacity = 1.0;
const double kDefaultFontSize = 14.0;

class FourthPage extends StatefulWidget {
  const FourthPage({Key? key}) : super(key: key);

  @override
  State<FourthPage> createState() => _FourthPageState();
}

class _FourthPageState extends State<FourthPage> {
  // --- State variables for infinite PageView ---

  late PageController _pageController;

  late final List<Widget> _actualPages;

  late final int _actualPageCount;

  final int _virtualPageCount = 10000; // Large number for "infinite" scrolling

  // --- End PageView state variables ---
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
    _actualPages = [

      // Your existing HomePage widget

      const LinkQrGenerator(), // Your second page widget

      const FourthMedia(),     // Your third page widget
      const HomePage(),
      // Add more widgets here if needed

    ];

    _actualPageCount = _actualPages.length; // Calculate the real number of pages



    // Initialize the PageController starting near the middle of the virtual count

    _pageController = PageController(

      initialPage: _virtualPageCount ~/ 2,

    );
  }


  @override
  void dispose() {

    _pageController.dispose(); // Dispose the PageController

    WakelockPlus(); // Consider disabling wakelock here if appropriate for your app lifecycle
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
            child: PageView.builder(

              controller: _pageController,          // Assign the controller

              scrollDirection: Axis.horizontal,     // Keep horizontal scrolling

              physics: const BouncingScrollPhysics(), // Keep the physics

              itemCount: _virtualPageCount,         // Use the large virtual count

              itemBuilder: (context, index) {

                // Calculate the actual page index using modulo

                final actualIndex = index % _actualPageCount;

                // Return the corresponding page from your list

                return _actualPages[actualIndex];

              },

            ),
          ),
        ],
      ),
    );
  }
}

// HomePage class with improved responsiveness and floating save button
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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

  // Key for SharedPreferences
  static const String _prefsKey = 'user_profile_data';

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

  // Improved user interaction handler to keep button visible when typing
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

  // Improved fieldBlock method with better responsiveness
  Widget fieldBlock(
      String label,
      TextEditingController controller, {
        double fontSize = 14,
      }) {
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
          appBar: null,
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
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 1.0),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          "LANGUAGES:",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: kDefaultFontSize,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: languageOptions.map((lang) {
                                              final isSelected = selectedLanguages.contains(lang);
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    if (isSelected) {
                                                      selectedLanguages.remove(lang);
                                                    } else {
                                                      selectedLanguages.add(lang);
                                                    }
                                                  });
                                                  _onUserInteraction(); // Make button visible when changing selection
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        lang,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: isSelected
                                                              ? Colors.black
                                                              : Colors.black,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                      AnimatedContainer(
                                                        duration: const Duration(milliseconds: 200),
                                                        height: 3,
                                                        width: isSelected ? 20 : 0,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                          "(",
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        height: 30,
                                        child: Center(
                                          child: TextField(
                                            controller: _languageNoteController,
                                            textAlignVertical: TextAlignVertical.center,
                                            onChanged: (_) => _onUserInteraction(),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 0,
                                                horizontal: 6,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.height * 0.050,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                          ")",
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Status section
                              Expanded(
                                flex: 9,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 1.0),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Text(
                                          "STATUS",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: kDefaultFontSize,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: statusOptions.map((status) {
                                              final isSelected = selectedStatus == status;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedStatus = isSelected ? '' : status;
                                                  });
                                                  _onUserInteraction(); // Make button visible when changing selection
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  margin: const EdgeInsets.only(right: 6),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        status,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                          color: isSelected
                                                              ? Colors.black
                                                              : Colors.black,
                                                        ),
                                                      ),
                                                      AnimatedContainer(
                                                        duration: const Duration(milliseconds: 200),
                                                        height: 3,
                                                        width: isSelected ? 70 : 0,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black,
                                                          borderRadius: BorderRadius.circular(2),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                          "(",
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)
                                      ),
                                      SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.35,
                                        height: 30,
                                        child: Center(
                                          child: TextField(
                                            controller: _statusNoteController,
                                            textAlignVertical: TextAlignVertical.center,
                                            onChanged: (_) => _onUserInteraction(),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 0,
                                                horizontal: 6,
                                              ),
                                              border: InputBorder.none,
                                            ),
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context).size.height * 0.050,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Text(
                                          ")",
                                          style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Hobby section
                              Expanded(
                                flex: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: fieldBlock(
                                    "HOBBY • SPECIAL SKILL • ETC",
                                    _hobbyController,
                                  ),
                                ),
                              ),
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
            child: FloatingActionButton.extended(
              onPressed: () async {
                await _saveData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved successfully')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save Profile'),

            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }
}