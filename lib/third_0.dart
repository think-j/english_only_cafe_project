import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import QR Scanner

// --- QR Scanner Page (New Widget) ---
// ... (QrScannerPage code remains the same as the previous version)
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

  bool isAvailable = false;
  bool isStaffMode = false;
  bool isReward8Claimed = false;
  bool isReward15Claimed = false;

  List<String?> collectedStamps = List.filled(15, null);

  int get currentStampCount =>
      collectedStamps
          .where((s) => s != null)
          .length;

  final List<String> availableStampTypes = List.generate(
      7, (i) => "TYPE_${String.fromCharCode(65 + i)}");

  final Map<String, Map<String, dynamic>> stampVisuals = {
    "TYPE_MAPLE": {
      "imageAssetPath": "assets/Maple_leaf_grey.png", // <-- CHECK THIS PATH CAREFULLY
      "color": Colors.grey.shade600
    },
    "TYPE_A": { // Changed from "red_stamp"
      "imageAssetPath": "assets/Red.png",
      "color": Colors.red.shade700 // Optional: Color can be for tint or background
    },
    "TYPE_B": { // Changed from "orange_stamp"
      "imageAssetPath": "assets/Orange.png",
      "color": Colors.orange.shade700
    },
    "TYPE_C": { // Changed from "yellow_stamp"
      "imageAssetPath": "assets/Yellow.png",
      "color": Colors.yellow.shade400
    },
    "TYPE_D": { // Changed from "green_stamp"
      "imageAssetPath": "assets/Green.png",
      "color": Colors.green.shade700
    },
    "TYPE_E": { // Changed from "blue_stamp"
      "imageAssetPath": "assets/Blue.png",
      "color": Colors.blue.shade700
    },
    "TYPE_F": { // Changed from "indigo_stamp"
      "imageAssetPath": "assets/Indigo.png",
      "color": Colors.indigo.shade700
    },
    "TYPE_G": { // Changed from "purple_stamp"
      "imageAssetPath": "assets/Purple.png",
      "color": Colors.purple.shade700
    },

    // If you have more than 7 types defined in availableStampTypes,
    // ensure there's a corresponding "TYPE_H", "TYPE_I", etc. here.
    // Currently, availableStampTypes generates 7 types (TYPE_A to TYPE_G).
  };

  final Map<String, String> scannedValueToStampType = {
    "MYCAFE_COFFEE_REWARD_001": "TYPE_A",
    "MYCAFE_TEA_BONUS_XYZ": "TYPE_B",
    "EVENT_STAMP_JULY_2025": "TYPE_C",
    "SPECIAL_OFFER_STAMP_004": "TYPE_D",
  };

  int? _claimingRewardIndex;
  Timer? _rewardClaimTimer;
  final Duration _rewardClaimHoldDuration = const Duration(seconds: 1);

  final String staffPin = '1234';
  final TextEditingController _pinController = TextEditingController();
  final PageController _pageController = PageController();

  final String staffActivationPayload = "MYCAFE_STAFF_ACCESS_V1";
  final String stampTypePrefix = "STAMP_TYPE:";
  final String stampIssuancePayloadKey = "STAMP_ISSUED_BY_STAFF_DEVICE_XYZ";

  @override
  void initState() {
    super.initState();
    _initializeNFC();
    _setLandscapeOrientation();

    // --- START: Code to pre-populate stamps for testing ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Create a mutable copy of collectedStamps to modify
          List<String?> newStampsConfiguration = List.from(collectedStamps);

          // 1. Set the first stamp (index 0) to Maple Leaf
          if (newStampsConfiguration.isNotEmpty) { // Check if card has at least one slot
            newStampsConfiguration[0] = "TYPE_MAPLE";
          }

          // 2. Add the next 7 standard types (TYPE_A to TYPE_G)
          //    availableStampTypes should contain ["TYPE_A", "TYPE_B", ..., "TYPE_G"]
          for (int i = 0; i < availableStampTypes.length; i++) {
            int targetSlotIndex = i + 1; // This will fill slots 1, 2, 3, ..., 7

            if (targetSlotIndex < newStampsConfiguration.length) {
              newStampsConfiguration[targetSlotIndex] = availableStampTypes[i];
            } else {
              break; // Stop if we run out of card slots
            }
          }
          // Assign the fully configured list back to collectedStamps
          collectedStamps = newStampsConfiguration;
        });

      }
    });
    // --- END: Code to pre-populate stamps for testing ---
  }

  Future<void> _initializeNFC() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) {
        setState(() {
          isAvailable = available;
        });
      }
    } catch (e) {
      print("Error initializing NFC: $e");
      _showSnackBar("Error initializing NFC: ${e.toString()}", Colors.red);
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

    if (!availableStampTypes.contains(stampType)) {
      _showSnackBar('Unknown stamp type ($stampType) from $sourceDescription.',
          Colors.red);
      return;
    }

    int firstEmptySlot = collectedStamps.indexOf(null);
    if (firstEmptySlot != -1) {
      setState(() {
        collectedStamps[firstEmptySlot] = stampType;
        _showSnackBar(
            'Stamp ($stampType) received from $sourceDescription! You now have $currentStampCount stamps.',
            Colors.green);
      });
    } else {
      _showSnackBar(
          'Your card is full! Cannot add stamp from $sourceDescription.',
          Colors.orange);
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
      await NfcManager.instance.stopSession();

      Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        _showSnackBar('Tag is not NDEF formatted.', Colors.red);
        return;
      }
      NdefMessage? message = await ndef.read();
      if (message == null || message.records.isEmpty) {
        _showSnackBar('No message found on tag.', Colors.red);
        return;
      }
      String actualTextPayload = _parseNdefTextPayload(message.records.first);
      print("Discovered Tag Payload: $actualTextPayload");

      if (isStaffMode) {
        if (actualTextPayload == staffActivationPayload) {
          _showSnackBar('Staff Mode already active.', Colors.blue);
        } else {
          _showSnackBar(
              'In Staff Mode. Scan ignored: $actualTextPayload', Colors.orange);
        }
        return;
      }

      if (actualTextPayload == staffActivationPayload) {
        if (mounted) {
          setState(() {
            isStaffMode = true;
          });
          _showSnackBar('Staff Mode Activated!', Colors.green);
        }
      } else if (scannedValueToStampType.containsKey(actualTextPayload)) {
        final stampType = scannedValueToStampType[actualTextPayload]!;
        _addStampToCard(stampType, "scanned NFC tag");
      } else if (actualTextPayload.contains(stampIssuancePayloadKey) &&
          actualTextPayload.startsWith(stampTypePrefix)) {
        String? receivedStampType;
        final parts = actualTextPayload.split(';');
        final typePart = parts.firstWhere((part) =>
            part.startsWith(stampTypePrefix), orElse: () => "");
        if (typePart.isNotEmpty) {
          receivedStampType = typePart.substring(stampTypePrefix.length);
        }

        if (receivedStampType != null) {
          _addStampToCard(receivedStampType, "staff-issued NFC");
        } else {
          _showSnackBar('Invalid staff-issued stamp data.', Colors.red);
        }
      } else {
        _showSnackBar(
            'Unknown NFC tag content: $actualTextPayload', Colors.red);
      }
    } catch (e) {
      print("Error in _handleCustomerNfcDiscovery: $e");
      _showSnackBar('Error processing NFC tag: ${e.toString()}', Colors.red);
    }
  }


  void _onSingleNfcButtonPressed() {
    if (!isAvailable) {
      _showSnackBar('NFC is not available on this device.', Colors.red);
      return;
    }

    if (isStaffMode) {
      _issueStamp();
    } else {
      _showSnackBar('Ready: Tap NFC Tag or long-press for QR.', Colors.blue);
      NfcManager.instance.startSession(
        onDiscovered: _handleCustomerNfcDiscovery,
        onError: (NfcError error) async {
          await NfcManager.instance.stopSession();
          _showSnackBar('NFC Error: ${error.message}', Colors.red);
        },
      ).catchError((e) {
        _showSnackBar(
            'Error starting NFC session: ${e.toString()}', Colors.red);
      });
    }
  }

  void _issueStamp() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Staff Authentication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter staff PIN to issue a stamp'),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'PIN'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pinController.clear();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_pinController.text == staffPin) {
                    Navigator.pop(context);
                    _pinController.clear();
                    _promptForStampTypeAndIssue();
                  } else {
                    _showSnackBar('Invalid PIN', Colors.red);
                    _pinController.clear();
                  }
                },
                child: const Text('Authenticate'),
              ),
            ],
          ),
    );
  }

  Future<void> _promptForStampTypeAndIssue() async {
    String? selectedType = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Stamp Type to Issue'),
          content: SizedBox( // Ensures the AlertDialog content tries to be as small as possible
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true, // Important for ListView inside AlertDialog
              itemCount: availableStampTypes.length,
              itemBuilder: (BuildContext context, int index) {
                final type = availableStampTypes[index];
                // Robust lookup for visual details, with a fallback
                final Map<String, dynamic> visual = stampVisuals[type] ??
                    {"icon": Icons.help, "color": Colors.grey, "imageAssetPath": null};

                Widget leadingWidget;
                final String? imagePath = visual["imageAssetPath"] as String?;
                final IconData? iconData = visual["icon"] as IconData?; // For fallback or mixed use
                final Color? color = visual["color"] as Color?; // May not be needed if image is self-contained

                if (imagePath != null) {
                  leadingWidget = Image.asset(
                    imagePath,
                    width: 36, // Suitable size for a ListTile leading icon
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Log error for debugging
                      print('Error loading image in dialog for type $type, path $imagePath: $error');
                      return const Icon(Icons.broken_image, size: 36); // Fallback for dialog if image fails
                    },
                  );
                } else if (iconData != null) {
                  leadingWidget = Icon(iconData, color: color, size: 36);
                } else {
                  // If neither imagePath nor iconData is defined for the type
                  leadingWidget = const Icon(Icons.help_outline, size: 36);
                }

                return ListTile(
                  leading: leadingWidget,
                  title: Text(type),
                  onTap: () {
                    Navigator.of(context).pop(type); // Return the selected stamp type
                  },
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Pops the dialog, selectedType will be null
              },
            ),
          ],
        );
      },
    );

    // After the dialog closes, handle the result
    if (selectedType != null) {
      _initiateNfcWriteForIssuance(selectedType);
    } else {
      _showSnackBar('Stamp issuance cancelled.', Colors.orange);
    }
  }





  void _initiateNfcWriteForIssuance(String stampType) {
    _showSnackBar('Ready to issue ($stampType) stamp. Touch customer\'s phone.',
        Colors.blue);
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag customerTag) async {
        Ndef? ndef = Ndef.from(customerTag);
        if (ndef == null) {
          await NfcManager.instance.stopSession(
              errorMessage: 'Customer device does not support NDEF.');
          _showSnackBar('Customer device does not support NDEF.', Colors.red);
          return;
        }
        if (!(await ndef.isWritable)) {
          await NfcManager.instance.stopSession(
              errorMessage: 'Customer device is not writable.');
          _showSnackBar('Customer device is not writable.', Colors.red);
          return;
        }
        NdefMessage message = NdefMessage([
          NdefRecord.createText(
              "$stampTypePrefix$stampType;$stampIssuancePayloadKey"),
        ]);
        try {
          await ndef.write(message);
          await NfcManager.instance.stopSession(
              alertMessage: 'Stamp issued to customer!');
          if (mounted) {
            _showSnackBar(
                'Stamp ($stampType) issued to customer!', Colors.green);
          }
        } catch (e) {
          await NfcManager.instance.stopSession(
              errorMessage: 'Failed to issue stamp: ${e.toString()}');
          print("Error writing stamp to customer: $e");
          _showSnackBar('Failed to issue stamp: ${e.toString()}', Colors.red);
        }
      },
      onError: (NfcError error) async {
        await NfcManager.instance.stopSession();
        _showSnackBar(
            'NFC Error during issuance: ${error.message}', Colors.red);
      },
    ).catchError((e) {
      _showSnackBar('Error starting NFC session for issuance: ${e.toString()}',
          Colors.red);
    });
  }

  Future<void> _startQrCodeScan() async {
    if (isStaffMode) {
      _showSnackBar(
          'QR scanning is for customers. Disable Staff Mode.', Colors.orange);
      return;
    }
    _showSnackBar('Initializing QR Code scanner...', Colors.blue);
    final String? qrCodeValue = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage()),
    );

    if (qrCodeValue != null && qrCodeValue.isNotEmpty) {
      print("QR Code Result: $qrCodeValue");
      if (scannedValueToStampType.containsKey(qrCodeValue)) {
        final stampType = scannedValueToStampType[qrCodeValue]!;
        _addStampToCard(stampType, "scanned QR code");
      } else {
        _showSnackBar('Unknown QR code value: $qrCodeValue', Colors.red);
      }
    } else {
      _showSnackBar(
          'QR scanning cancelled or no value detected.', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _rewardClaimTimer?.cancel();
    _pageController.dispose();
    _pinController.dispose();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenSize = MediaQuery
        .of(context)
        .size;
    String buttonText = isStaffMode
        ? "Issue Stamp (Staff)"
        : "Scan Stamp (NFC/QR)";

    double responsiveButtonWidth = (screenSize.width * 0.12).clamp(70.0, 170.0);
    double responsiveButtonHeight = (screenSize.height * 0.25).clamp(
        180.0, 350.0);
    final double flexibleRightPadding = screenSize.width * 0.03;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidthForGrid = constraints.maxWidth;
                    final availableHeightForGrid = constraints.maxHeight;
                    double cardWidth = availableWidthForGrid;
                    if ((availableHeightForGrid / 0.65) <
                        availableWidthForGrid) {
                      cardWidth = availableHeightForGrid / 0.65;
                    }
                    cardWidth = cardWidth.clamp(
                        screenSize.width * 0.6, availableWidthForGrid);
                    return Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: cardWidth,
                            height: cardWidth * 0.67,
                            child: _buildLandscapeGrid(cardWidth, screenSize),
                          ),
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
              style: TextStyle(fontSize: width * 0.14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500),
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
        childAspectRatio: 1.0,
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
    final IconData? iconData = visual["icon"] as IconData?; // For potential fallback or mixed use
    final Color? color = visual["color"] as Color?;

    if (imagePath != null) {
      return Opacity(
        opacity: 0.4, // Adjust opacity as needed
        child:
          Image.asset(
            imagePath,
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain, // Or BoxFit.cover, etc.
            errorBuilder: (context, error, stackTrace) {
              print("Error loading image $imagePath: $error"); // Log error
              return Icon(Icons.broken_image, size: iconSize , color: Colors.red); // Show broken image icon
            },
          ),

      );
    } else if (iconData != null) {
      return Icon(iconData, size: iconSize, color: color);
    } else {
      return Icon(Icons.image_not_supported, size: iconSize * 0.8, color: Colors.grey.shade300);
    }
  }

  // --- MODIFIED _buildGridItem ---
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
    // final cellPadding = cardWidth * 0.01; // Not strictly needed if no internal padding for text like "REWARD USED" relies on it directly

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth;
        final cellHeight = constraints.maxHeight;
        final iconContainerSize = cellWidth ;
        Widget itemContent;

        if (isCurrentlyAttemptingClaim) {
          itemContent = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 1.0, end: 1.3),
                duration: _rewardClaimHoldDuration,
                builder: (BuildContext context, double scale,
                    Widget? iconToScale) {
                  return Transform.scale(
                    scale: scale,
                    child: iconToScale,
                  );
                },
                child: Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  alignment: Alignment.center,
                  child: isFilled
                      ? _getStampIconWidget(
                      currentStampType, iconContainerSize * 0.9)
                      : Icon(
                    isThisRewardSpot8 ? Icons.emoji_events_outlined : Icons
                        .card_giftcard_outlined,
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
            child: Padding( // Original code had padding for "REWARD USED" text
              padding: const EdgeInsets.all(4.0),
              // Reinstating a small padding for text
              child: Text(
                'REWARD\nUSED',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize * 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(blurRadius: 1.0,
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(1, 1)),
                  ],
                ),
              ),
            ),
          );
        } else if (canBeClaimed) {
          itemContent = Stack(
            alignment: Alignment.center,
            children: [
              Center(child: _getStampIconWidget(
                  currentStampType, iconContainerSize)),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
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
        } else {
          itemContent = Stack(
            alignment: Alignment.center,
            children: [
              if (isFilled)
                Center(child: _getStampIconWidget(
                    currentStampType, iconContainerSize * 0.9)),
              if (isGeneralRewardSpot && !isFilled)
                Positioned(
                  top: cellHeight * 0.05,
                  left: cellWidth * 0.05,
                  right: cellWidth * 0.05,
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
        }

        return GestureDetector(
          onTapDown: canBeClaimed
              ? (_) => _startRewardClaimAttempt(index)
              : null,
          onTapUp: canBeClaimed
              ? (_) => _cancelRewardClaimAttempt(index)
              : null,
          onTapCancel: canBeClaimed
              ? () => _cancelRewardClaimAttempt(index)
              : null,
          child: Container( // The visual part of the cell
            // margin: EdgeInsets.all(cardWidth * 0.005), // REMOVED to prevent intervals
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5),
              // Original border
              color: _getGridItemColor(
                  isClaimed, isCurrentlyAttemptingClaim, canBeClaimed,
                  isGeneralRewardSpot), // Original color logic
              // borderRadius: BorderRadius.circular(cardWidth * 0.01), // REMOVED
            ),
            child: Center(child: itemContent),
          ),
        );
      },
    );
  }

  // --- End MODIFIED _buildGridItem ---

  // --- REVERTED _getGridItemColor to original logic ---
  Color _getGridItemColor(bool isClaimed, bool isCurrentlyAttemptingClaim,
      bool canBeClaimed, bool isGeneralRewardSpot) {
    if (isClaimed) return Colors.blueGrey[300]!;
    if (isCurrentlyAttemptingClaim) return Colors.white38; // Original color
    if (canBeClaimed) return Colors.white38; // Original color
    if (isGeneralRewardSpot) return Colors.grey[300]!;
    return Colors.white; // Default for normal spots (filled or empty)
  }
}
// --- End REVERTED _getGridItemColor ---