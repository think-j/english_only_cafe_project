import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  bool isAvailable = false;
  bool isStaffMode = false;
  bool isReward8Claimed = false; // For the 8th stamp (index 7)
  bool isReward15Claimed = false; // For the 15th stamp (index 14)

  int? _claimingRewardIndex; // Index of the reward item currently being pressed
  Timer? _rewardClaimTimer;
  final Duration _rewardClaimHoldDuration = const Duration(seconds: 2); // How long to hold

  int stampCount = 1;
  final String staffPin = '1234';
  final TextEditingController _pinController = TextEditingController();
  final PageController _pageController = PageController();

  // NFC payload constants
  final String staffActivationPayload = "MYCAFE_STAFF_ACCESS_V1";
  final String stampTypePrefix = "STAMP_TYPE:";
  final String stampIssuancePayloadKey = "STAMP_ISSUED_BY_STAFF_DEVICE_XYZ";


  @override
  void initState() {
    super.initState();
    stampCount = 8; // Initialize with 8 stamps for testing
    _initializeNFC();
    _setLandscapeOrientation();
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
    }
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  // Reward claim methods
  void _startRewardClaimAttempt(int index) {
    if (!mounted || _rewardClaimTimer?.isActive == true) return;

    if (stampCount <= index) return;

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
      _showSnackBar('Reward claim cancelled.', Colors.orange);
    }
  }

  void _finalizeRewardClaim(int index) {
    if (!mounted || _claimingRewardIndex != index) {
      _rewardClaimTimer?.cancel();
      setState(() {
        _claimingRewardIndex = null;
      });
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
      _showSnackBar('$rewardName has been claimed! Show this to staff.', Colors.green);
    }
  }

  // NFC Helper methods
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

      if (actualTextPayload == staffActivationPayload) {
        if (mounted) {
          setState(() {
            isStaffMode = true;
          });
          _showSnackBar('Staff Mode Activated!', Colors.green);
        }
      } else if (actualTextPayload.contains(stampIssuancePayloadKey)) {
        if (!isStaffMode) {
          if (mounted) {
            setState(() {
              if (stampCount < 15) {
                stampCount++;
                _showSnackBar('Stamp received! You now have $stampCount stamps.', Colors.green);
              } else {
                _showSnackBar('Your card is full!', Colors.orange);
              }
            });
          }
        } else {
          _showSnackBar('Stamp issuance signal detected while in staff mode.', Colors.red);
        }
      } else {
        _showSnackBar('Unknown NFC tag content.', Colors.red);
      }
    } catch (e) {
      print("Error in _handleCustomerNfcDiscovery: $e");
      _showSnackBar('Error processing NFC tag: ${e.toString()}', Colors.red);
    }
  }

  // Main NFC button handler
  void _onSingleNfcButtonPressed() {
    if (!isAvailable) {
      _showSnackBar('NFC is not available on this device.', Colors.red);
      return;
    }

    if (isStaffMode) {
      _issueStamp();
    } else {
      _showSnackBar('Ready: Tap Staff Badge or receive stamp.', Colors.blue);
      NfcManager.instance.startSession(
        onDiscovered: _handleCustomerNfcDiscovery,
        onError: (NfcError error) async {
          await NfcManager.instance.stopSession();
          _showSnackBar('NFC Error: ${error.message}', Colors.red);
        },
      );
    }
  }

  // Staff stamp issuance
  void _issueStamp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _initiateNfcWriteForIssuance();
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

  // NFC write for stamp issuance
  void _initiateNfcWriteForIssuance() {
    _showSnackBar('Ready to issue stamp. Touch customer\'s phone.', Colors.blue);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag customerTag) async {
        try {
          await NfcManager.instance.stopSession();

          Ndef? ndef = Ndef.from(customerTag);
          if (ndef == null) {
            _showSnackBar('Customer device does not support NDEF.', Colors.red);
            return;
          }

          if (!(await ndef.isWritable)) {
            _showSnackBar('Customer device is not writable.', Colors.red);
            return;
          }

          NdefMessage message = NdefMessage([
            NdefRecord.createText(stampIssuancePayloadKey),
          ]);
          await ndef.write(message);

          if (mounted) {
            _showSnackBar('Stamp issued to customer!', Colors.green);
          }
        } catch (e) {
          print("Error writing stamp to customer: $e");
          _showSnackBar('Failed to issue stamp: ${e.toString()}', Colors.red);
        }
      },
      onError: (NfcError error) async {
        await NfcManager.instance.stopSession();
        _showSnackBar('NFC Error during issuance: ${error.message}', Colors.red);
      },
    );
  }

  // QR Code scanning placeholder
  Future<void> _startQrCodeScan() async {
    _showSnackBar('Long press detected: Initializing QR Code scanner...', Colors.blue);
    print("Long Press: QR Code scanning initiated.");

    await Future.delayed(const Duration(seconds: 1));
    print("QR Scanner logic would be implemented here using a package.");
  }

  // Utility methods
  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    final screenSize = MediaQuery.of(context).size;
    String buttonText = isStaffMode ? "Issue Stamp to Customer" : "Receive Stamp";

    double responsiveButtonWidth = (screenSize.width * 0.12).clamp(70.0, 120.0);
    double responsiveButtonHeight = (screenSize.height * 0.25).clamp(180.0, 350.0);

    return SafeArea(
      child: Scaffold(
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
                    if ((availableHeightForGrid / 0.65) < availableWidthForGrid) {
                      cardWidth = availableHeightForGrid / 0.65;
                    }
                    cardWidth = cardWidth.clamp(screenSize.width * 0.6, availableWidthForGrid);

                    return Center(
                      child: SizedBox(
                        width: cardWidth,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: cardWidth,
                            height: cardWidth * 0.65,
                            child: _buildLandscapeGrid(cardWidth, screenSize),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Column(
                children: [
                  _buildNfcButton(
                    buttonText: buttonText,
                    width: responsiveButtonWidth,
                    height: responsiveButtonHeight,
                    onPressed: _onSingleNfcButtonPressed,
                    onLongPress: _startQrCodeScan,
                  ),
                  SizedBox(height: responsiveButtonWidth * 0.15),
                  _buildNfcButton(
                    buttonText: buttonText,
                    width: responsiveButtonWidth,
                    height: responsiveButtonHeight,
                    onPressed: _onSingleNfcButtonPressed,
                    onLongPress: null,
                  ),
                ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(width * 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nfc,
              size: width * 0.5,
            ),
            SizedBox(height: width * 0.15),
            Text(
              buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: width * 0.18),
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

  Widget _buildGridItem(int index, double cardWidth, Size screenSize) {
    bool isFilled = index < stampCount;
    bool isThisRewardSpot8 = index == 7;
    bool isThisRewardSpot15 = index == 14;
    bool isGeneralRewardSpot = isThisRewardSpot8 || isThisRewardSpot15;

    bool isClaimed = (isThisRewardSpot8 && isReward8Claimed) ||
        (isThisRewardSpot15 && isReward15Claimed);
    bool canBeClaimed = isGeneralRewardSpot && isFilled && !isClaimed;
    bool isCurrentlyAttemptingClaim = _claimingRewardIndex == index;

    final baseFontSize = screenSize.width * 0.018;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth;
        final cellHeight = constraints.maxHeight;

        return GestureDetector(
          onTapDown: canBeClaimed ? (_) => _startRewardClaimAttempt(index) : null,
          onTapUp: canBeClaimed ? (_) => _cancelRewardClaimAttempt(index) : null,
          onTapCancel: canBeClaimed ? () => _cancelRewardClaimAttempt(index) : null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5),
              color: _getGridItemColor(isClaimed, isCurrentlyAttemptingClaim,
                  canBeClaimed, isGeneralRewardSpot),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Stamp Image
                if (isFilled && !isClaimed && !isCurrentlyAttemptingClaim)
                  Center(
                    child: Image.asset(
                      'assets/Maple_leaf_grey.png', // Your specific image path

                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if image fails to load
                        return const Icon(Icons.local_cafe, size: 30, color: Colors.brown);
                      },
                    ),
                  ),

                // "REWARD READY!" Text
                if (canBeClaimed && !isCurrentlyAttemptingClaim)
                  Positioned(
                    top: cellHeight * 0.05,
                    right: cellWidth * 0.05,
                    child: Text(
                      'REWARD\nREADY!',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 1.0,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),

                // "HOLD TO CLAIM" / Progress Indicator
                if (isCurrentlyAttemptingClaim)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                        strokeWidth: 3.0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'KEEP HOLDING\nTO CLAIM...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: baseFontSize * 0.85,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),

                // "REWARD USED" Text
                if (isClaimed)
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(
                      'REWARD\nUSED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 1.25,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 1.0,
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                // "FREE REFILL / DRINK" Text
                if (isGeneralRewardSpot && !isFilled)
                  Positioned(
                    top: cellHeight * 0.05,
                    right: cellWidth * 0.05,
                    child: Text(
                      isThisRewardSpot8 ? 'FREE\nREFILL' : 'FREE\nDRINK',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize,
                        color: Colors.black54,
                      ),
                    ),
                  ),

                // Visual cue for "REWARD READY"
                if (canBeClaimed && !isCurrentlyAttemptingClaim)
                  Positioned(
                    bottom: 5,
                    left: 5,
                    child: Icon(
                      Icons.touch_app,
                      color: Colors.blueAccent.withOpacity(0.9),
                      size: baseFontSize * 1.5,
                    ),
                  ),

                // Number
                Positioned(
                  bottom: cellHeight * 0.05,
                  right: cellWidth * 0.05,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: baseFontSize * 0.9,
                      fontWeight: FontWeight.bold,
                      color: isClaimed ? Colors.white.withOpacity(0.7) : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getGridItemColor(bool isClaimed, bool isCurrentlyAttemptingClaim,
      bool canBeClaimed, bool isGeneralRewardSpot) {
    if (isClaimed) return Colors.blueGrey[300]!;
    if (isCurrentlyAttemptingClaim) return Colors.yellow[400]!;
    if (canBeClaimed) return Colors.amber[300]!;
    if (isGeneralRewardSpot) return Colors.grey[300]!;
    return Colors.white;
  }
}