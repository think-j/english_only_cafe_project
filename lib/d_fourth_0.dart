// 1. First, create a UserProfileData class to hold all profile information
// Create a new file named user_profile_data.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';


class UserProfileData extends ChangeNotifier {
  static final UserProfileData _instance = UserProfileData._internal();

  factory UserProfileData() {
    return _instance;
  }

  UserProfileData._internal();

  // Profile data fields
  String name = '';
  String country = '';
  String city = '';
  String statusNote = '';
  String hobby = '';
  String languageNote = '';
  List<String> selectedLanguages = [];
  String selectedStatus = '';

  // Controllers
  final nameController = TextEditingController();
  final countryController = TextEditingController();
  final cityController = TextEditingController();
  final statusNoteController = TextEditingController();
  final hobbyController = TextEditingController();
  final languageNoteController = TextEditingController();

  // SharedPreferences key
  static const String prefsKey = 'user_profile_data';

  // Initialize controllers with data
  void initControllers() {
    nameController.text = name;
    countryController.text = country;
    cityController.text = city;
    statusNoteController.text = statusNote;
    hobbyController.text = hobby;
    languageNoteController.text = languageNote;
  }

  // Update the data from controllers
  void updateFromControllers() {
    name = nameController.text;
    country = countryController.text;
    city = cityController.text;
    statusNote = statusNoteController.text;
    hobby = hobbyController.text;
    languageNote = languageNoteController.text;
    notifyListeners();
  }

  // Load data from SharedPreferences
  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(prefsKey);

    if (savedData != null) {
      try {
        final Map<String, dynamic> data = json.decode(savedData);

        name = data['name'] ?? '';
        country = data['country'] ?? '';
        city = data['city'] ?? '';
        statusNote = data['statusNote'] ?? '';
        hobby = data['hobby'] ?? '';
        languageNote = data['languageNote'] ?? '';

        // Load selected languages
        selectedLanguages = [];
        if (data['selectedLanguages'] != null) {
          List<dynamic> langs = data['selectedLanguages'];
          selectedLanguages = langs.map((e) => e.toString()).toList();
        }

        // Load selected status
        selectedStatus = data['selectedStatus'] ?? '';

        // Update controllers
        initControllers();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading data: $e");
      }
    }
  }

  // Save data to SharedPreferences
  Future<void> saveData() async {
    // First update from controllers
    updateFromControllers();

    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> data = {
      'name': name,
      'country': country,
      'city': city,
      'statusNote': statusNote,
      'hobby': hobby,
      'languageNote': languageNote,
      'selectedLanguages': selectedLanguages,
      'selectedStatus': selectedStatus,
      'lastSaved': DateTime.now().toIso8601String(),
    };

    await prefs.setString(prefsKey, json.encode(data));
  }

  // Set language selection
  void setLanguageSelection(String lang, bool isSelected) {
    if (isSelected && !selectedLanguages.contains(lang)) {
      selectedLanguages.add(lang);
    } else if (!isSelected && selectedLanguages.contains(lang)) {
      selectedLanguages.remove(lang);
    }
    notifyListeners();
  }

  // Set status selection
  void setStatusSelection(String status) {
    selectedStatus = (selectedStatus == status) ? '' : status;
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    countryController.dispose();
    cityController.dispose();
    statusNoteController.dispose();
    hobbyController.dispose();
    languageNoteController.dispose();
    super.dispose();
  }
}


// 2. Now, modify your FourthPage class to implement PageStorage

double _buttonOpacity = 1.0;
const double kDefaultFontSize = 14.0;

class FourthPage extends StatefulWidget {
  const FourthPage({Key? key}) : super(key: key);

  @override
  State<FourthPage> createState() => _FourthPageState();
}

class _FourthPageState extends State<FourthPage> {
  // Create an instance of UserProfileData
  final UserProfileData _profileData = UserProfileData();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();

    // Load saved data on initialization
    _profileData.loadSavedData();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Since HomePage builds its own Scaffold, FourthPage can directly return HomePage.
    // The Scaffold previously in FourthPage is removed to avoid nested Scaffolds.
    // HomePage will now be the root UI for this route.
    return const HomePage();
  }
}

// Add this wrapper to ensure page state is preserved
class KeepAlivePage extends StatefulWidget {
  final Widget child;

  const KeepAlivePage({Key? key, required this.child}) : super(key: key);

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}


// 3. Finally, modify your HomePage class to use the shared UserProfileData

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// At the top of your file, the global _buttonOpacity should be removed.
// const double kDefaultFontSize = 14.0; // This can remain global or be moved into the class

class _HomePageState extends State<HomePage> {
  final UserProfileData _profileData = UserProfileData();
  Timer? _inactivityTimer; // For FAB opacity

  // --- ADDITIONS FOR AUTO-SAVE ---
  Timer? _autoSaveDebounceTimer;
  final Duration _autoSaveDebounceDuration = const Duration(seconds: 1); // Save 2s after last change
  // --- END OF ADDITIONS FOR AUTO-SAVE ---

  // --- Make _buttonOpacity a state variable ---
  double _buttonOpacity = 1.0;
  // ---

  // --- Make FocusNode a state variable ---
  late FocusNode _pageFocusNode;
  // ---

  @override
  void initState() {
    super.initState();
    _pageFocusNode = FocusNode(); // Initialize FocusNode

    _startInactivityTimer(); // For FAB opacity
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // --- ADD LISTENERS FOR AUTO-SAVE ---
    _profileData.nameController.addListener(_scheduleAutoSave);
    _profileData.countryController.addListener(_scheduleAutoSave);
    _profileData.cityController.addListener(_scheduleAutoSave);
    _profileData.statusNoteController.addListener(_scheduleAutoSave);
    _profileData.hobbyController.addListener(_scheduleAutoSave);
    _profileData.languageNoteController.addListener(_scheduleAutoSave);

    _pageFocusNode.addListener(() { // For FAB opacity reset
      if (_pageFocusNode.hasFocus) {
        _onUserInteraction();
      }
    });
    // --- END OF ADDITIONS FOR AUTO-SAVE ---
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();

    // --- DISPOSE AUTO-SAVE TIMER AND LISTENERS, PERFORM FINAL SAVE ---
    _autoSaveDebounceTimer?.cancel();

    _profileData.nameController.removeListener(_scheduleAutoSave);
    _profileData.countryController.removeListener(_scheduleAutoSave);
    _profileData.cityController.removeListener(_scheduleAutoSave);
    _profileData.statusNoteController.removeListener(_scheduleAutoSave);
    _profileData.hobbyController.removeListener(_scheduleAutoSave);
    _profileData.languageNoteController.removeListener(_scheduleAutoSave);

    _pageFocusNode.dispose(); // Dispose FocusNode

    // Perform a final save if there were pending changes not caught by the timer
    // This is optional, as the debounce should catch most, but good for safety.
    // Consider if _profileData.saveData() is too heavy for dispose.
    // If debouncer was active, it might be better to just let it be cancelled.
    // For simplicity and to ensure data isn't lost if user exits quickly:
    print("Performing final save on dispose (if data changed)...");
    _profileData.saveData(); // This will save the latest controller values.
    // --- END OF DISPOSE ADDITIONS ---

    super.dispose();
  }

  // --- NEW METHOD TO SCHEDULE AUTO-SAVE ---
  void _scheduleAutoSave() {
    _autoSaveDebounceTimer?.cancel(); // Cancel any existing timer
    _autoSaveDebounceTimer = Timer(_autoSaveDebounceDuration, () async {
      print("Auto-saving profile data...");
      await _profileData.saveData(); // saveData calls updateFromControllers internally
      if (mounted) {
        // Optional: show a subtle auto-save confirmation, e.g., a temporary icon
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('Profile auto-saved'), duration: Duration(seconds: 1)),
        // );
      }
    });
  }
  // --- END OF NEW METHOD ---

  // Method for the explicit save button
  Future<void> _saveProfile() async {
    _autoSaveDebounceTimer?.cancel(); // Cancel pending auto-save if user saves explicitly
    await _profileData.saveData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }

  // User interaction handler for FAB opacity
  void _onUserInteraction() {
    if (!mounted) return;
    setState(() {
      _buttonOpacity = 1.0;
    });
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _buttonOpacity = 0.0;
        });
      }
    });
  }

  Widget fieldBlock(
      String label,
      TextEditingController controller, {
        double fontSize = kDefaultFontSize, // Use the const if defined outside, or just 14.0
      }) {
    bool isBigField = label.contains("NAME") || label.contains("HOBBY");
    bool isOriginField = label.contains("COUNTRY") || label.contains("CITY");

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final dynamicSize = screenHeight * 0.025;
    final labelFontSize = fontSize + (dynamicSize * 0.7);

    double inputTextSize;
    if (isBigField) {
      inputTextSize = screenHeight * 0.09;
    } else if (isOriginField) {
      inputTextSize = screenHeight * 0.055;
    } else {
      inputTextSize = screenHeight * 0.045;
    }

    if (screenWidth < 600) {
      inputTextSize *= 0.85;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: const BoxDecoration(color: Colors.white), // Added const
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
                // onChanged listener in TextField now primarily handles _onUserInteraction for opacity
                // The controller listener added in initState handles auto-saving.
                // If you also want _onUserInteraction on every char change, keep this.
                onChanged: (_) {
                  _onUserInteraction(); // For FAB opacity
                  // _scheduleAutoSave(); // Alternative: schedule save on every char change (covered by controller listener)
                },
                onTap: _onUserInteraction, // Reset opacity when field is tapped
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
    // final FocusNode focusNode = FocusNode(); // THIS WAS INCORRECT - creating new node on every build
    // focusNode.addListener(() { ... }); // Listener would be on a temporary node

    // Access controllers from the shared ProfileData
    final nameController = _profileData.nameController;
    final countryController = _profileData.countryController;
    final cityController = _profileData.cityController;
    final statusNoteController = _profileData.statusNoteController;
    final hobbyController = _profileData.hobbyController;
    final languageNoteController = _profileData.languageNoteController;

    final List<String> languageOptions = ['JP', 'EN', 'FR', 'ES', 'PT', 'AR', 'CH', 'KR'];
    final List<String> statusOptions = ['STUDENT', 'WORKER'];

    return Focus(
      focusNode: _pageFocusNode, // Use the state variable FocusNode
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () { // Handle tap on background
          _onUserInteraction();
          FocusScope.of(context).unfocus(); // Optionally unfocus fields
        },
        onPanDown: (_) => _onUserInteraction(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: null,
          body:  Column(
              children: [
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
                              // NAME Field
                              Expanded(
                                flex: 25,
                                child: Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 0.8))),
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: fieldBlock("NAME (NICK NAME)", nameController),
                                ),
                              ),
                              // COUNTRY/CITY Fields
                              Expanded(
                                flex: 20,
                                child: Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 1.0))),
                                  child: Row(
                                    children: [
                                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: fieldBlock("COUNTRY OF ORIGIN", countryController))),
                                      const SizedBox(width: 8),
                                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: fieldBlock("CITY OF ORIGIN", cityController))),
                                    ],
                                  ),
                                ),
                              ),
                              // Languages section
                              Expanded(
                                flex: 9,
                                child: Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 1.0))),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Padding(padding: EdgeInsets.only(left: 8), child: Text("LANGUAGES:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: kDefaultFontSize))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: languageOptions.map((lang) {
                                              final isSelected = _profileData.selectedLanguages.contains(lang);
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() { _profileData.setLanguageSelection(lang, !isSelected); });
                                                  _onUserInteraction();
                                                  _scheduleAutoSave(); // <--- TRIGGER AUTO-SAVE
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                                    Text(lang, style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                                    AnimatedContainer(duration: const Duration(milliseconds: 200), height: 3, width: isSelected ? 20 : 0, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
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
                                      SizedBox(width: MediaQuery.of(context).size.width * 0.35, height: 30, child: Center(child: TextField(controller: languageNoteController, textAlignVertical: TextAlignVertical.center, onChanged: (_) => _onUserInteraction(), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 6), border: InputBorder.none), style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.050, height: 1.1)))),
                                      Text(")", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
                                    ],
                                  ),
                                ),
                              ),
                              // Status section
                              Expanded(
                                flex: 9,
                                child: Container(
                                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black, width: 1.0))),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Padding(padding: EdgeInsets.only(left: 8), child: Text("STATUS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: kDefaultFontSize))),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: statusOptions.map((status) {
                                              final isSelected = _profileData.selectedStatus == status;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() { _profileData.setStatusSelection(status); });
                                                  _onUserInteraction();
                                                  _scheduleAutoSave(); // <--- TRIGGER AUTO-SAVE
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 6), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                                    Text(status, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
                                                    AnimatedContainer(duration: const Duration(milliseconds: 200), height: 3, width: isSelected ? 70 : 0, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(2))),
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
                                      SizedBox(width: MediaQuery.of(context).size.width * 0.35, height: 30, child: Center(child: TextField(controller: statusNoteController, textAlignVertical: TextAlignVertical.center, onChanged: (_) => _onUserInteraction(), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 6), border: InputBorder.none), style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.050, height: 1.1)))),
                                      Text(")", style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.040)),
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
                                  child: fieldBlock("HOBBY • SPECIAL SKILL • ETC", hobbyController),
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

        ),
      );

  }
}