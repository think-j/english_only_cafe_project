import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';// Import the home_page.dart file
import 'package:flutter/services.dart'; // Import the services package

class ThirdPage extends StatefulWidget {
  const ThirdPage({super.key});

  @override
  State<ThirdPage> createState() => _ThirdPageState();
}

class _ThirdPageState extends State<ThirdPage> {
  bool isAvailable = false;
  bool isStaffMode = false;
  int stampCount = 1; // Starting with 1 stamp
  final String staffPin = '1234';
  final TextEditingController _pinController = TextEditingController();

  // Add PageController
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Check if NFC is available on the device
    NfcManager.instance.isAvailable().then((available) {
      setState(() {
        isAvailable = available;
      });
    });
    // Set the device orientation to landscape only
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Dispose of the PageController when the widget is disposed
    _pageController.dispose();
    super.dispose();
  }

  // Function to scan for NFC
  void _startNfcScan() {
    if (isStaffMode) {
      _issueStamp();
    } else {
      _receiveStamp();
    }
  }

  // Customer receives stamp
  void _receiveStamp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Place your phone near the staff device')),
    );

    // NFC scan implementation would go here
    // For demo, we'll just add a stamp
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        if (stampCount < 15) stampCount++;
      });
    });
  }

  // Staff issues stamp
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
              decoration: const InputDecoration(
                hintText: 'PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_pinController.text == staffPin) {
                Navigator.pop(context);
                _pinController.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ready to issue stamp. Touch customer\'s phone')),
                );

                // NFC write implementation would go here
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Authenticate'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
        resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 13),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = screenSize.width * 0.7;
                  final cardHeight = screenSize.height * 1;

                  return Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: _buildLandscapeGrid(cardWidth), // Always use landscape layout
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Icon(Icons.keyboard_arrow_up, size: 24, color: Colors.grey),
                    Text('Swipe up to view home', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );

  }

  // Helper method for landscape mode grid
  Widget _buildLandscapeGrid(double cardWidth) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        // Use a horizontal arrangement for landscape
        return _buildGridItem(index, cardWidth);
      },
    );
  }

  // Helper method for grid items
  Widget _buildGridItem(int index, double cardWidth) {
    bool isFilled = index < stampCount;
    bool isFreeReward = index == 7 || index == 14; // 8th and 15th spots

    return Container(
      margin: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 0.5),
        color: isFreeReward ? Colors.grey[300] : Colors.white,
      ),
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Stack(
          children: [
            if (isFilled)
              Center(
                child: isFreeReward
                    ? const Text('STAMPED\nREWARD',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold))
                    : const Icon(Icons.eco, size: 40, color: Colors.grey),
              ),
            if (!isFilled && isFreeReward)
              Positioned(
                bottom: 70,  // Position at the bottom
                left: 0,    // Start from the left edge
                right: -80,   // Extend to the right edge
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: index == 7
                          ? const Text('FREE\nREFILL',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold))
                          : const Text('FREE\nDRINK',
                          textAlign: TextAlign.end,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 4.0,
              right: 4.0,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (index == 0 && isFilled)
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: cardWidth / 6 * 0.6,
                  height: cardWidth / 6 * 0.7,
                  child: const FittedBox(
                    fit: BoxFit.contain,
                    child: Icon(Icons.eco, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }



  }