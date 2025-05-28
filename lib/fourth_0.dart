// 1. UserProfileData class (NO CHANGES HERE)
// Create a new file named user_profile_data.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'fourth_1.dart';
import 'fourth_2.dart';


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


// 2. FourthPage class (NO CHANGES HERE)

double _buttonOpacity = 1.0; // This global variable might be better inside a stateful widget or a state management solution
const double kDefaultFontSize = 14.0;

class FourthPage extends StatefulWidget {
  const FourthPage({Key? key}) : super(key: key);

  @override
  State<FourthPage> createState() => _FourthPageState();
}

class _FourthPageState extends State<FourthPage> {

  final PageStorageBucket _bucket = PageStorageBucket();
  late PageController _pageController;
  late final List<Widget> _actualPages;
  late final int _actualPageCount;
  final int _virtualPageCount = 10000;
  final UserProfileData _profileData = UserProfileData();
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _profileData.loadSavedData();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // In _FourthPageState, initState or where _actualPages is defined:
    _actualPages = [
      PageStorage( // Index 0: LinkQrGenerator
        key: const PageStorageKey('linkQrGenerator'),
        bucket: _bucket, // Make sure _bucket is initialized: final PageStorageBucket _bucket = PageStorageBucket();
        child: LinkQrGenerator(), // Assuming LinkQrGenerator is defined
      ),
      // FourthMedia (index 1) WITHOUT PageStorage wrapper
      const FourthMedia(), // Or FourthMedia() if its constructor isn't const
      PageStorage( // Index 2: HomePage
        key: const PageStorageKey('homePage'),
        bucket: _bucket,
        child: const HomePage(),
      ),
    ];

    _actualPageCount = _actualPages.length;
    _pageController = PageController(
      initialPage: _virtualPageCount ~/ 2,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Orientation currentOrientation = MediaQuery.of(context).orientation;

    if (currentOrientation == Orientation.portrait) {
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
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _virtualPageCount,
              // In _FourthPageState, build method, PageView.builder:
              itemBuilder: (context, index) {
                final actualIndex = index % _actualPageCount; // _actualPageCount here is for FourthPage's internal pages
                final Widget currentPage = _actualPages[actualIndex];

                if (actualIndex == 1) { // Index 1 is FourthMedia
                  print("FourthPage: Building FourthMedia (index $actualIndex) - NOT kept alive.");
                  return currentPage;
                } else {
                  // Other pages within FourthPage (LinkQrGenerator, HomePage)
                  print("FourthPage: Building page index $actualIndex - Kept alive.");
                  return KeepAlivePage(child: currentPage);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// KeepAlivePage class (NO CHANGES HERE)
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


// 3. HomePage class (CHANGES APPLIED HERE)

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final UserProfileData _profileData = UserProfileData();
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await _profileData.saveData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully')),
      );
    }
  }

  void _onUserInteraction() {
    setState(() {
      _buttonOpacity = 1.0;
    });
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _buttonOpacity = 0.0;
        });
      }
    });
  }

  Widget fieldBlock(
      String label,
      TextEditingController controller, {
        double fontSize = 14, // kDefaultFontSize can be used if defined globally
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
                onChanged: (_) => _onUserInteraction(),
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
    final FocusNode focusNode = FocusNode();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _onUserInteraction();
      }
    });

    final nameController = _profileData.nameController;
    final countryController = _profileData.countryController;
    final cityController = _profileData.cityController;
    final statusNoteController = _profileData.statusNoteController;
    final hobbyController = _profileData.hobbyController;
    final languageNoteController = _profileData.languageNoteController;

    final List<String> languageOptions = [
      'JP', 'EN', 'FR', 'ES', 'PT', 'AR', 'CH', 'KR',
    ];
    final List<String> statusOptions = ['STUDENT', 'WORKER'];

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          extendBody: true,
          backgroundColor: const Color(0xFFFFFFFF),
          appBar: null,
          body: SafeArea(
            child: Column(
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
                              Expanded(
                                flex: 25,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: Colors.black, width: 0.8),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: fieldBlock("NAME (NICK NAME)", nameController),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: fieldBlock(
                                            "COUNTRY OF ORIGIN",
                                            countryController,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8), // This SizedBox was missing a 'const'
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: fieldBlock(
                                            "CITY OF ORIGIN",
                                            cityController,
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
                                child: SingleChildScrollView( // <--- FIX APPLIED HERE
                                  physics: const ClampingScrollPhysics(),
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
                                              fontSize: kDefaultFontSize, // Using const kDefaultFontSize
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: languageOptions.map((lang) {
                                                final isSelected = _profileData.selectedLanguages.contains(lang);
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _profileData.setLanguageSelection(lang, !isSelected);
                                                    });
                                                    _onUserInteraction();
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
                                                            color: Colors.black, // Simplified
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
                                              controller: languageNoteController,
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
                              ),
                              // Status section
                              Expanded(
                                flex: 9,
                                child: SingleChildScrollView( // <--- FIX APPLIED HERE
                                  physics: const ClampingScrollPhysics(),
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
                                              fontSize: kDefaultFontSize, // Using const kDefaultFontSize
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
                                                final isSelected = _profileData.selectedStatus == status;
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _profileData.setStatusSelection(status);
                                                    });
                                                    _onUserInteraction();
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
                                                            color: Colors.black, // Simplified
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
                                              controller: statusNoteController,
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
                              ),
                              // Hobby section
                              Expanded(
                                flex: 30,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: fieldBlock(
                                    "HOBBY • SPECIAL SKILL • ETC",
                                    hobbyController,
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
              onPressed: _saveProfile,
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