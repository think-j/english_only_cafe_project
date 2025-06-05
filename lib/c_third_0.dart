import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert'; // Required for jsonEncode and jsonDecode
import 'package:shared_preferences/shared_preferences.dart'; // Required for local data persistence

// --- QR Scanner Page ---
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              setState(() {
                _isProcessing = true;
              });

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String qrValue = barcodes.first.rawValue!;
                print("QR Scanned: $qrValue");
                Navigator.of(context).pop(qrValue);
              } else {
                setState(() {
                  _isProcessing = false;
                });
              }
            },
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        ],
      ),
    );
  }
}
// --- End QR Scanner Page ---

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> with AutomaticKeepAliveClientMixin<ThirdPage> {
  @override
  bool get wantKeepAlive => true;

  // --- State Variables ---
  bool isAvailable = false;
  bool isStaffMode = false;
  bool isReward8Claimed = false;
  bool isReward15Claimed = false;
  bool isNfcSessionActive = false;
  List<String?> collectedStamps = List.filled(15, null);
  int? _claimingRewardIndex;
  Timer? _rewardClaimTimer;

  // --- New State Variable for Completed Cards ---
  List<Map<String, dynamic>> _completedCardsData = [];

  // --- Constants & Controllers ---
  final Duration _rewardClaimHoldDuration = const Duration(seconds: 1);
  final String staffPin = '1234';
  final TextEditingController _pinController = TextEditingController();

  final String staffActivationPayload = "MYCAFE_STAFF_ACCESS_V1";
  final String stampTypePrefix = "STAMP_TYPE:";
  final String stampIssuancePayloadKey = "STAMP_ISSUED_BY_STAFF_DEVICE_XYZ";

  final List<String> availableStampTypes = List.generate(
      7, (i) => "TYPE_${String.fromCharCode(65 + i)}");

  final Map<String, Map<String, dynamic>> stampVisuals = {
    "TYPE_MAPLE": {"imageAssetPath": "assets/Maple_leaf_grey.png", "color": Colors.grey.shade600},
    "TYPE_A": {"imageAssetPath": "assets/Red.png", "color": Colors.red.shade700},
    "TYPE_B": {"imageAssetPath": "assets/Orange.png", "color": Colors.orange.shade700},
    "TYPE_C": {"imageAssetPath": "assets/Yellow.png", "color": Colors.yellow.shade400},
    "TYPE_D": {"imageAssetPath": "assets/Green.png", "color": Colors.green.shade700},
    "TYPE_E": {"imageAssetPath": "assets/Blue.png", "color": Colors.blue.shade700},
    "TYPE_F": {"imageAssetPath": "assets/Indigo.png", "color": Colors.indigo.shade700},
    "TYPE_G": {"imageAssetPath": "assets/Purple.png", "color": Colors.purple.shade700},
  };

  final Map<String, String> scannedValueToStampType = {
    "MYCAFE_COFFEE_REWARD_001": "TYPE_A",
    "MYCAFE_TEA_BONUS_XYZ": "TYPE_B",
    "EVENT_STAMP_JULY_2025": "TYPE_C",
    "SPECIAL_OFFER_STAMP_004": "TYPE_D",
  };

  // --- SharedPreferences Keys ---
  static const String _kCollectedStampsKey = 'collectedStamps_v3';
  static const String _kIsReward8ClaimedKey = 'isReward8Claimed_v3';
  static const String _kIsReward15ClaimedKey = 'isReward15Claimed_v3';
  static const String _kIsStaffModeKey = 'isStaffMode_v3';
  static const String _kCompletedCardsKey = 'completedCardsData_v3';

  @override
  void initState() {
    super.initState();
    _initializeNFC();
    _setLandscapeOrientation();
    _loadAppState(); // Load saved state instead of pre-populating directly
  }

  Future<void> _loadAppState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // ---- MODIFICATION POINT: Declare savedStampsJson before setState ----
    List<String>? savedStampsJson = prefs.getStringList(_kCollectedStampsKey);
    // ---- END OF MODIFICATION POINT ----

    setState(() {
      // Now use the 'savedStampsJson' variable declared above
      if (savedStampsJson != null) {
        // This part remains the same: Load existing saved stamps
        collectedStamps = savedStampsJson.map((stamp) => stamp == 'null' ? null : stamp).toList();
        if (collectedStamps.length < 15) {
          collectedStamps.addAll(List.filled(15 - collectedStamps.length, null));
        } else if (collectedStamps.length > 15) {
          collectedStamps = collectedStamps.sublist(0, 15);
        }
      } else {
        // This block is executed on first launch / no saved stamps
        print("DEBUG: No saved stamps found, pre-filling 15 stamps for testing.");
        collectedStamps = List.filled(15, null); // Ensure it's a fresh list of 15
        for (int i = 0; i < collectedStamps.length; i++) {
          if (availableStampTypes.isNotEmpty) {
            collectedStamps[i] = availableStampTypes[i % availableStampTypes.length];
          } else {
            collectedStamps[i] = "TYPE_MAPLE"; // Fallback if no available types
          }
        }
        // Ensure the reward slots are filled for testing reward claims on this pre-filled card
        if (collectedStamps.length > 7 && availableStampTypes.isNotEmpty) collectedStamps[7] = availableStampTypes[0];
        if (collectedStamps.length > 14 && availableStampTypes.isNotEmpty) collectedStamps[14] = availableStampTypes[1 % availableStampTypes.length];

        // Ensure rewards are not marked as claimed for this new test card
        // These will be set correctly in the 'if (savedStampsJson == null)' block below.
      }

      // Load other states
      // This 'if' condition now correctly uses 'savedStampsJson' from the outer scope
      if (savedStampsJson == null) { // If we just pre-filled (or it was genuinely null)
        isReward8Claimed = false;
        isReward15Claimed = false;
        isStaffMode = false; // Or your desired default
        _completedCardsData = []; // Start with no completed cards
      } else { // Otherwise, load them from prefs
        isReward8Claimed = prefs.getBool(_kIsReward8ClaimedKey) ?? false;
        isReward15Claimed = prefs.getBool(_kIsReward15ClaimedKey) ?? false;
        isStaffMode = prefs.getBool(_kIsStaffModeKey) ?? false;

        List<String>? savedCompletedCardsJsonList = prefs.getStringList(_kCompletedCardsKey); // Use a different variable name to avoid confusion
        if (savedCompletedCardsJsonList != null) {
          try {
            _completedCardsData = savedCompletedCardsJsonList.map((jsonString) {
              Map<String, dynamic> decodedMap = json.decode(jsonString);
              if (decodedMap['stamps'] is List) {
                decodedMap['stamps'] = (decodedMap['stamps'] as List).map<String?>((s) => s?.toString()).toList();
              }
              return decodedMap;
            }).toList();
          } catch (e) {
            print("Error decoding completed cards: $e");
            _completedCardsData = [];
          }
        } else {
          _completedCardsData = []; // Ensure it's initialized if null from prefs
        }
      }
    }); // End of setState

    // After setting the initial state, save it immediately if it was a fresh setup (i.e., no stamps were loaded from prefs)
    // This 'savedStampsJson' is now correctly from the outer scope.
    if (savedStampsJson == null) {
      _saveAppState();
    }
  }
  Future<void> _saveAppState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kCollectedStampsKey, collectedStamps.map((s) => s ?? 'null').toList());
    await prefs.setBool(_kIsReward8ClaimedKey, isReward8Claimed);
    await prefs.setBool(_kIsReward15ClaimedKey, isReward15Claimed);
    await prefs.setBool(_kIsStaffModeKey, isStaffMode);

    List<String> completedCardsJson = _completedCardsData.map((cardData) {
      // Ensure all parts of cardData are encodable
      Map<String, dynamic> encodableCardData = {
        'stamps': (cardData['stamps'] as List<String?>).map((s) => s ?? 'null').toList(),
        'reward8Claimed': cardData['reward8Claimed'],
        'reward15Claimed': cardData['reward15Claimed'],
        'dateCompleted': cardData['dateCompleted'],
      };
      return json.encode(encodableCardData);
    }).toList();
    await prefs.setStringList(_kCompletedCardsKey, completedCardsJson);
  }


  int get currentStampCount => collectedStamps.where((s) => s != null).length;

  Future<void> _initializeNFC() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) {
        setState(() {
          isAvailable = available;
        });
      }
      print("NFC Available: $available");
    } catch (e) {
      print("Error initializing NFC: $e");
      if (mounted) {
        _showSnackBar("NFC initialization failed: ${e.toString()}", Colors.red);
      }
    }
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _addStampToCard(String stampType, String sourceDescription) {
    if (!mounted) return;

    if (!availableStampTypes.contains(stampType) && stampType != "TYPE_MAPLE") {
      _showSnackBar('Unknown stamp type ($stampType) from $sourceDescription.', Colors.red);
      return;
    }

    if (currentStampCount >= collectedStamps.length) { // Card is full
      _archiveCurrentCard();
      _resetCurrentCardState();
      _addStampToSpecificSlot(stampType, 0, "new card");
    } else { // Card is not full
      int firstEmptySlot = collectedStamps.indexOf(null);
      if (firstEmptySlot != -1) {
        _addStampToSpecificSlot(stampType, firstEmptySlot, sourceDescription);
      } else {
        // This implies all slots are filled, should be caught by the condition above.
        // However, as a fallback, treat as full.
        _archiveCurrentCard();
        _resetCurrentCardState();
        _addStampToSpecificSlot(stampType, 0, "new card");
      }
    }
    _saveAppState();
  }

  void _archiveCurrentCard() {
    Map<String, dynamic> cardToArchive = {
      'stamps': List<String?>.from(collectedStamps),
      'reward8Claimed': isReward8Claimed,
      'reward15Claimed': isReward15Claimed,
      'dateCompleted': DateTime.now().toIso8601String(),
    };
    if (mounted) {
      setState(() {
        _completedCardsData.add(cardToArchive);
      });
    }
    _showSnackBar(
        '🎉 Card #${_completedCardsData.length} Completed! Starting a new card. 🎉',
        Colors.purpleAccent,
        duration: const Duration(seconds: 4));
  }

  void _resetCurrentCardState() {
    if (mounted) {
      setState(() {
        collectedStamps = List.filled(collectedStamps.length, null);
        isReward8Claimed = false;
        isReward15Claimed = false;
        _claimingRewardIndex = null;
        _rewardClaimTimer?.cancel();
        if (collectedStamps.isNotEmpty) {
          collectedStamps[0] = "TYPE_MAPLE";
        }
      });
    }
  }

  void _addStampToSpecificSlot(String stampType, int slotIndex, String sourceDescription) {
    if (mounted && slotIndex >= 0 && slotIndex < collectedStamps.length) {
      setState(() {
        collectedStamps[slotIndex] = stampType;
        _showSnackBar(
            'Stamp ($stampType) added! You have $currentStampCount stamp(s) ${sourceDescription == "new card" ? "on your new card" : "from $sourceDescription"}.',
            Colors.green);
      });
    } else {
      print("Error: Invalid slotIndex $slotIndex or component not mounted in _addStampToSpecificSlot");
      if (mounted) _showSnackBar("Error adding stamp to card.", Colors.red);
    }
  }

  void _startRewardClaimAttempt(int index) {
    if (!mounted || _rewardClaimTimer?.isActive == true) return;
    if (collectedStamps[index] == null) return;
    bool isThisRewardSpot8 = index == 7;
    bool isThisRewardSpot15 = index == 14;
    bool isGeneralRewardSpot = isThisRewardSpot8 || isThisRewardSpot15;
    bool isClaimed = (isThisRewardSpot8 && isReward8Claimed) ||
        (isThisRewardSpot15 && isReward15Claimed);
    if (!isGeneralRewardSpot || isClaimed) return;
    setState(() {
      _claimingRewardIndex = index;
    });
    _rewardClaimTimer = Timer(_rewardClaimHoldDuration, () {
      _finalizeRewardClaim(index);
    });
  }

  void _cancelRewardClaimAttempt(int index) {
    if (!mounted) return;
    _rewardClaimTimer?.cancel();
    if (_claimingRewardIndex == index) {
      setState(() {
        _claimingRewardIndex = null;
      });
    }
  }

  void _finalizeRewardClaim(int index) {
    if (!mounted || _claimingRewardIndex != index) {
      _rewardClaimTimer?.cancel();
      if (_claimingRewardIndex == index) {
        setState(() => _claimingRewardIndex = null);
      }
      return;
    }
    String rewardName = "";
    bool isSpot8 = index == 7;
    bool isSpot15 = index == 14;
    if (isSpot8) rewardName = "Free Refill";
    if (isSpot15) rewardName = "Free Drink";
    if (mounted) {
      setState(() {
        if (isSpot8) {
          isReward8Claimed = true;
        } else if (isSpot15) {
          isReward15Claimed = true;
        }
        _claimingRewardIndex = null;
      });
      _saveAppState(); // Save state after claiming a reward
      _showSnackBar(
          '$rewardName has been claimed! Show this to staff.', Colors.green);
    }
  }

  String _parseNdefTextPayload(NdefRecord record) {
    try {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          String.fromCharCodes(record.type) == 'T') {
        int langCodeLength = record.payload.first & 0x3F;
        return String.fromCharCodes(record.payload.sublist(1 + langCodeLength));
      }
      return String.fromCharCodes(record.payload);
    } catch (e) {
      print("Error parsing NDEF text payload: $e");
      return "";
    }
  }

  Future<void> _handleCustomerNfcDiscovery(NfcTag tag) async {
    try {
      print("NFC Tag discovered");
      Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        await _safeStopNfcSession();
        _showSnackBar('Tag is not NDEF formatted.', Colors.red);
        return;
      }
      NdefMessage? message = await ndef.read();
      if (message == null || message.records.isEmpty) {
        await _safeStopNfcSession();
        _showSnackBar('No message found on tag.', Colors.red);
        return;
      }
      String actualTextPayload = _parseNdefTextPayload(message.records.first);
      print("Discovered Tag Payload: $actualTextPayload");
      await _safeStopNfcSession();

      if (isStaffMode) {
        if (actualTextPayload == staffActivationPayload) {
          _showSnackBar('Staff Mode already active.', Colors.blue);
        } else {
          _showSnackBar('In Staff Mode. Scan ignored: $actualTextPayload', Colors.orange);
        }
        return;
      }

      if (actualTextPayload == staffActivationPayload) {
        if (mounted) {
          setState(() { isStaffMode = true; });
          _saveAppState();
          _showSnackBar('Staff Mode Activated!', Colors.green);
        }
      } else if (scannedValueToStampType.containsKey(actualTextPayload)) {
        final stampType = scannedValueToStampType[actualTextPayload]!;
        _addStampToCard(stampType, "scanned NFC tag");
      } else if (actualTextPayload.contains(stampIssuancePayloadKey) &&
          actualTextPayload.startsWith(stampTypePrefix)) {
        String? receivedStampType;
        final parts = actualTextPayload.split(';');
        final typePart = parts.firstWhere((part) => part.startsWith(stampTypePrefix), orElse: () => "");
        if (typePart.isNotEmpty) {
          receivedStampType = typePart.substring(stampTypePrefix.length);
        }
        if (receivedStampType != null) {
          _addStampToCard(receivedStampType, "staff-issued NFC");
        } else {
          _showSnackBar('Invalid staff-issued stamp data.', Colors.red);
        }
      } else {
        _showSnackBar('Unknown NFC tag content: $actualTextPayload', Colors.red);
      }
    } catch (e) {
      print("Error in _handleCustomerNfcDiscovery: $e");
      await _safeStopNfcSession();
      _showSnackBar('Error processing NFC tag: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _safeStopNfcSession() async {
    try {
      if (isNfcSessionActive) {
        await NfcManager.instance.stopSession();
        if (mounted) {
          setState(() { isNfcSessionActive = false; });
        }
      }
    } catch (e) {
      print("Error stopping NFC session: $e");
      if (mounted) {
        setState(() { isNfcSessionActive = false; });
      }
    }
  }

  void _onSingleNfcButtonPressed() {
    if (!isAvailable) {
      _showSnackBar('NFC is not available on this device.', Colors.red);
      return;
    }
    if (isNfcSessionActive) {
      _showSnackBar('NFC session already active. Please wait.', Colors.orange);
      return;
    }
    if (isStaffMode) {
      _issueStamp();
    } else {
      _startCustomerNfcSession();
    }
  }

  void _startCustomerNfcSession() {
    _showSnackBar('Ready: Tap NFC Tag or long-press for QR.', Colors.blue);
    if (mounted) {
      setState(() { isNfcSessionActive = true; });
    }
    NfcManager.instance.startSession(
      onDiscovered: _handleCustomerNfcDiscovery,
      onError: (NfcError error) async {
        print("NFC Error: ${error.message}");
        await _safeStopNfcSession();
        _showSnackBar('NFC Error: ${error.message}', Colors.red);
      },
    ).catchError((e) {
      print("Error starting NFC session: $e");
      _safeStopNfcSession(); // Ensure session flag is reset
      _showSnackBar('Error starting NFC session: ${e.toString()}', Colors.red);
    });
    Timer(const Duration(seconds: 30), () {
      if (isNfcSessionActive) {
        _safeStopNfcSession();
        _showSnackBar('NFC session timed out.', Colors.orange);
      }
    });
  }

  void _issueStamp() { /* ... same as your existing code ... */ }
  Future<void> _promptForStampTypeAndIssue() async { /* ... same as your existing code ... */ }
  void _initiateNfcWriteForIssuance(String stampType) { /* ... same as your existing code ... */ }
  Future<void> _startQrCodeScan() async { /* ... same as your existing code ... */ }

  void _showSnackBar(String message, Color color, {Duration duration = const Duration(seconds: 3)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: duration,
      ),
    );
  }

  @override
  void dispose() {
    _rewardClaimTimer?.cancel();
    _pinController.dispose();
    _safeStopNfcSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery.of(context).size;
    String buttonText = isStaffMode
        ? "Issue Stamp (Staff)"
        : "Scan Stamp (NFC/QR)";

    double responsiveButtonWidth = (screenSize.width * 0.12).clamp(70.0, 170.0);
    double responsiveButtonHeight = (screenSize.height * 0.25).clamp(180.0, 350.0);
    final double flexibleRightPadding = screenSize.width * 0.03;

    return
       Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child:



                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableGridWidth = constraints.maxWidth;
                        // Calculate available height for grid, considering the text above and some padding
                        final availableGridHeight = constraints.maxHeight - ((screenSize.height * 0.022).clamp(14.0, 18.0) + 16);

                        double cardWidth;
                        // Determine cardWidth based on aspect ratio (0.66 for 3 rows in a 5-column grid)
                        // If constrained by height:
                        double heightDerivedCardWidth = availableGridHeight / 0.66;
                        // If constrained by width:
                        double widthDerivedCardWidth = availableGridWidth;

                        // Use the smaller of the two, but ensure it's within reasonable bounds
                        cardWidth = (heightDerivedCardWidth < widthDerivedCardWidth) ? heightDerivedCardWidth : widthDerivedCardWidth;
                        cardWidth = cardWidth.clamp(screenSize.width * 0.50, availableGridWidth); // Ensure it's not too small or wider than available

                        // Defensive check for availableGridHeight
                        if (availableGridHeight <= 0) {
                          return const Center(child: Text("Not enough space for grid")); // Or some placeholder
                        }
                        return  SizedBox(
                            width: cardWidth,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: cardWidth,
                                height: cardWidth * 0.65,
                                child: _buildLandscapeGrid(cardWidth, screenSize),
                              ),
                            ),
                          );

                      },
                    ),


              ),
              Padding(
                padding: EdgeInsets.only(right: flexibleRightPadding * 0.2),
                child: _buildNfcButton(
                  buttonText: buttonText,
                  width: responsiveButtonWidth,
                  height: responsiveButtonHeight,
                  onPressed: _onSingleNfcButtonPressed,
                  onLongPress: isStaffMode ? null : _startQrCodeScan,
                ),
              ),
            ],
          ),
        ),
      );

  }

  Widget _buildNfcButton({
    required String buttonText,
    required double width,
    required double height,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          shadowColor: Colors.grey.withOpacity(0.5),
          elevation: 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.nfc, size: width * 0.65, color: Colors.grey.shade700),
            SizedBox(height: width * 0.1),
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: width * 0.14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeGrid(double cardWidth, Size screenSize) {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 15),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1.0, // Each cell is square
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        return _buildGridItem(index, cardWidth, screenSize);
      },
    );
  }

  Widget _getStampIconWidget(String? stampType, double iconSize) {
    if (stampType == null || !stampVisuals.containsKey(stampType)) {
      return Icon(Icons.help_outline, size: iconSize * 0.8, color: Colors.grey.shade400);
    }

    final visual = stampVisuals[stampType]!;
    final String? imagePath = visual["imageAssetPath"] as String?;
    final IconData? iconData = visual["icon"] as IconData?; // Not used in your current visuals map but good for flexibility
    final Color? color = visual["color"] as Color?;

    if (imagePath != null) {
      return Opacity(
        opacity: 0.4, // As per your original code
        child: Image.asset(
          imagePath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print("Error loading image $imagePath: $error");
            return Icon(Icons.broken_image, size: iconSize, color: Colors.red);
          },
        ),
      );
    } else if (iconData != null) { // Fallback if you add icon data later
      return Icon(iconData, size: iconSize, color: color);
    } else { // Default if no image or icon
      return Icon(Icons.image_not_supported, size: iconSize * 0.8, color: Colors.grey.shade300);
    }
  }

  Widget _buildGridItem(int index, double cardWidth, Size screenSize) {
    String? currentStampType = collectedStamps[index];
    bool isFilled = currentStampType != null;

    bool isThisRewardSpot8 = index == 7;
    bool isThisRewardSpot15 = index == 14;
    bool isGeneralRewardSpot = isThisRewardSpot8 || isThisRewardSpot15;

    bool isClaimed = (isThisRewardSpot8 && isReward8Claimed) ||
        (isThisRewardSpot15 && isReward15Claimed);
    bool canBeClaimed = isGeneralRewardSpot && isFilled && !isClaimed;
    bool isCurrentlyAttemptingClaim = _claimingRewardIndex == index;
    final baseFontSize = (screenSize.width * 0.018).clamp(8.0, 14.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth;
        final cellHeight = constraints.maxHeight;
        // iconContainerSize should ideally be based on min(cellWidth, cellHeight) for square cells
        final iconContainerSize = (cellWidth < cellHeight ? cellWidth : cellHeight) * 0.9; // Make icon slightly smaller than cell
        Widget itemContent;

        if (isCurrentlyAttemptingClaim) {
          itemContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: 1.3),
                duration: _rewardClaimHoldDuration,
                builder: (BuildContext context, double scale, Widget? iconToScale) {
                  return Transform.scale(scale: scale, child: iconToScale);
                },
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  alignment: Alignment.center,
                  child: isFilled
                      ? _getStampIconWidget(currentStampType, iconContainerSize)
                      : Icon(
                    isThisRewardSpot8 ? Icons.emoji_events_outlined : Icons.card_giftcard_outlined,
                    size: iconContainerSize * 0.8,
                    color: Colors.deepOrangeAccent.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          );
        } else if (isClaimed) {
          itemContent = TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'REWARD\nUSED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize * 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 1.0, color: Colors.black.withOpacity(0.5), offset: const Offset(1, 1)),
                  ],
                ),
              ),
            ),
          );
        } else if (canBeClaimed) {
          itemContent = Stack(
            alignment: Alignment.center,
            children: [
              Center(child: _getStampIconWidget(currentStampType, iconContainerSize)),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      'REWARD\nREADY!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.90,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: cellHeight * 0.05,
                right: cellWidth * 0.05,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: baseFontSize * 0.85,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.7)),
                ),
              ),
            ],
          );
        } else { // Default, empty or filled non-reward
          itemContent = Stack(
            alignment: Alignment.center,
            children: [
              if (isFilled)
                Center(child: _getStampIconWidget(currentStampType, iconContainerSize * 0.9)), // Slightly smaller for non-highlighted
              if (isGeneralRewardSpot && !isFilled) // Text for empty reward spots
                Positioned(
                  top: cellHeight * 0.05, left: cellWidth * 0.05, right: cellWidth * 0.05,
                  child: Text(
                    isThisRewardSpot8 ? 'FREE\nREFILL' : 'FREE\nDRINK',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize * 0.85,
                      color: Colors.black45,
                    ),
                  ),
                ),
              Positioned( // Number for all spots
                bottom: cellHeight * 0.05,
                right: cellWidth * 0.05,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(fontSize: baseFontSize * 0.85,
                      fontWeight: FontWeight.bold,
                      color: Colors.black.withOpacity(0.7)),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          onTapDown: canBeClaimed ? (_) => _startRewardClaimAttempt(index) : null,
          onTapUp: canBeClaimed ? (_) => _cancelRewardClaimAttempt(index) : null,
          onTapCancel: canBeClaimed ? () => _cancelRewardClaimAttempt(index) : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5),
              color: _getGridItemColor(isClaimed, isCurrentlyAttemptingClaim, canBeClaimed, isGeneralRewardSpot),
            ),
            child: Center(child: itemContent),
          ),
        );
      },
    );
  }

  Color _getGridItemColor(bool isClaimed, bool isCurrentlyAttemptingClaim,
      bool canBeClaimed, bool isGeneralRewardSpot) {
    if (isClaimed) return Colors.blueGrey[300]!;
    if (isCurrentlyAttemptingClaim) return Colors.white38;
    if (canBeClaimed) return Colors.white38;
    if (isGeneralRewardSpot) return Colors.grey[300]!;
    return Colors.white;
  }
}