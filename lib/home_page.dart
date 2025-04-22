import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:wakelock/wakelock.dart';

double _buttonOpacity = 1.0;
Timer? _inactivityTimer; // for fade in and out
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  SystemChannels.lifecycle.setMessageHandler((msg) async {
    if (msg == AppLifecycleState.resumed.toString()) {
      // Re-enforce landscape when app is resumed
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    return null;
  });
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // Enable edge-to-edge by default
  runApp(const MaterialApp(home: HomePage()));
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}




class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Wakelock.enable(); // Keeps the screen awake
  }
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _statusNoteController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _languageNoteController = TextEditingController();

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

  bool isFullScreen = false;
  final bool _showButtons = true;
  Timer? _inactivityTimer;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _onUserInteraction() {
    if (_buttonOpacity != 1.0) {
      setState(() {
        _buttonOpacity = 1.0;
      });
    }
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _buttonOpacity = 0.0;
      });
    });
  }

  void toggleFullscreen() {
    setState(() {
      isFullScreen = !isFullScreen;
      if (isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Widget fieldBlock(
      String label,
      TextEditingController controller, {
        double fontSize = 14,
      }) {
    bool isBigField = label.contains("NAME") || label.contains("HOBBY");
    bool isLanguageOrStatus = label.contains("LANGUAGE") || label == "STATUS";

    // Calculate dynamic font sizes based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Scale more aggressively with screen size
    final dynamicSize = screenHeight * 0.025; // 2.5% of screen height

    // Set label font size
    final labelFontSize = fontSize + (dynamicSize * 0.7);

    // Set text field font size based on field type
    double textFieldFontSize;
    if (isBigField) {
      textFieldFontSize = dynamicSize * 1.6; // Larger font for name and hobby
    } else if (isLanguageOrStatus) {
      textFieldFontSize = dynamicSize * 1.5; // Make language and status fonts bigger
    } else {
      textFieldFontSize = dynamicSize * 1.3; // Standard size for other fields
    }

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: labelFontSize),
          ),
          const SizedBox(height: 1),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.060),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force orientation check at build time
    final Orientation currentOrientation = MediaQuery.of(context).orientation;
    final screenHeight = MediaQuery.of(context).size.height;
    final dynamicFontSize = screenHeight * 0.02;
    if (currentOrientation == Orientation.portrait) {
      // Force it back to landscape immediately
      Future.microtask(() {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      });
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(), // catch drag/touch too
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFFFFFFF),
        appBar: null,
        body: SafeArea(
          child: Column(
            children: [
              // Main form content - takes all available space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 20,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.black, width: 0.8),
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 8.0),
                            child: fieldBlock("NAME (NICK NAME)", _nameController),
                          ),
                        ),
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
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: fieldBlock(
                                      "COUNTRY OF ORIGIN",
                                      _countryController,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: const Text(
                                    "LANGUAGES:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:kDefaultFontSize,
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
                                Text("(", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: 30,
                                  child: TextField(
                                    controller: _languageNoteController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 6,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040),
                                  ),
                                ),
                                Text(")", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
                              ],
                            ),
                          ),
                        ),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: const Text(
                                    "STATUS",
                                    style :  TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize:kDefaultFontSize,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: statusOptions.map((status) {
                                        final isSelected = selectedStatus == status;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedStatus = isSelected ? '' : status;
                                            });
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            child: Column(
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
                                Text("(", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.35,
                                  height: 30,
                                  child: TextField(
                                    controller: _statusNoteController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 6,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040),
                                  ),
                                ),
                                Text(")", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 32,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.black, width: 1.0),
                              ),
                            ),
                            padding: const EdgeInsets.only(left: 8),
                            child: fieldBlock(
                              "HOBBY • SPECIAL SKILL • ETC",
                              _hobbyController,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 30.0), // Adjust left padding as needed
              child: AnimatedOpacity(
                opacity: _buttonOpacity,
                duration: const Duration(milliseconds: 500),
                child: FloatingActionButton.extended(
                  heroTag: "fullscreen_btn", // Unique tag for each FAB
                  onPressed: toggleFullscreen,
                  icon: Icon(
                    isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  ),
                  label: Text(
                    isFullScreen ? "Exit Fullscreen" : "Fullscreen",
                  ),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _buttonOpacity,
              duration: const Duration(milliseconds: 500),
              child: FloatingActionButton.extended(
                heroTag: "save_btn", // Unique tag for each FAB
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Saved!")),
                  );
                },
                label: const Text("Save"),
                icon: const Icon(Icons.save),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Or try endFloat
      ),
    );
  }
}