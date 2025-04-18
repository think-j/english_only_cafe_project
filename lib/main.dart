import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

double _buttonOpacity = 1.0;
Timer? _inactivityTimer; // for fade in and out
void main() {
  runApp(const MaterialApp(home: InfoCardFullScreen()));
}

class InfoCardFullScreen extends StatefulWidget {
  const InfoCardFullScreen({super.key});

  @override
  State<InfoCardFullScreen> createState() => _InfoCardFullScreenState();
}

class _InfoCardFullScreenState extends State<InfoCardFullScreen> {
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
  bool _showButtons = true;
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

    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
          const SizedBox(height: 1),
          TextField(
            controller: controller,
            maxLines: isBigField ? 1 : 1,
            style: TextStyle(fontSize: isBigField ? 30 : 20),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(), // catch drag/touch too
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        appBar:
            isFullScreen
                ? null
                : AppBar(
                  title: const Text("Info Card"),
                  backgroundColor: Colors.white,
                ),
        body: SafeArea(
          child: Stack(
            children: [
              // Main form content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 016.0),
                child: Column(
                  children: [
                    // Border starts here
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 0.8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                            ), // Adjust as needed
                            child: fieldBlock(
                              "NAME (NICK NAME)",
                              _nameController,
                            ),
                          ),
                          const Divider(
                            color: Colors.black,
                            thickness: 0.8,
                            height: 1,
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
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
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
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
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Scrollable row of language chips with no bottom padding
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children:
                                          languageOptions.map((lang) {
                                            final isSelected = selectedLanguages
                                                .contains(lang);

                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  if (isSelected) {
                                                    selectedLanguages.remove(
                                                      lang,
                                                    );
                                                  } else {
                                                    selectedLanguages.add(lang);
                                                  }
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.transparent,
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      lang,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                            isSelected
                                                                ? Colors.black
                                                                : Colors.black,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                      ),
                                                    ),
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      height: 3,
                                                      width:
                                                          isSelected ? 20 : 0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
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

                                const Text("(", style: TextStyle(fontSize: 14)),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.35,
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
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const Text(")", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),

                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: const Text(
                                    "STATUS",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children:
                                          statusOptions.map((status) {
                                            final isSelected =
                                                selectedStatus == status;
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedStatus =
                                                      isSelected ? '' : status;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 200,
                                                ),
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      status,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            isSelected
                                                                ? FontWeight
                                                                    .bold
                                                                : FontWeight
                                                                    .normal,
                                                        color:
                                                            isSelected
                                                                ? Colors.black
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                    AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      height: 3,
                                                      width:
                                                          isSelected ? 70 : 0,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
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
                                const Text("(", style: TextStyle(fontSize: 14)),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.35,
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
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const Text(")", style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          // ... other sections (COUNTRY, LANGUAGE, STATUS) ...
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: fieldBlock(
                              "HOBBY • SPECIAL SKILL • ETC",
                              _hobbyController,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                left: 16,
                child: AnimatedOpacity(
                  opacity: _buttonOpacity,
                  duration: const Duration(milliseconds: 500),
                  child: ElevatedButton.icon(
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

              // Save button on bottom right
              Positioned(
                bottom: 10,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _buttonOpacity,
                  duration: const Duration(milliseconds: 500),
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text("Saved!")));
                    },
                    child: const Text("Save"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
