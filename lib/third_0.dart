import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter/services.dart';

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

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(

                child: LayoutBuilder(

                  builder: (context, constraints) {
                    // Calculate adaptive sizes based on available space
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // Use aspectRatio to determine orientation
                    final isVeryTallAspectRatio = availableHeight / availableWidth > 2.0;

                    // Adjust card size based on aspect ratio
                    final cardWidth = isVeryTallAspectRatio
                        ? availableWidth * 0.95  // Use more width on tall devices
                        : availableWidth * 0.7;  // Original width for normal devices

                    return Container(

                      width: cardWidth,
                      // Let height be determined by content
                      decoration: BoxDecoration(
                        color: Colors.white,

                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: cardWidth,
                          height: cardWidth * 0.65, // Maintain a 5:3 aspect ratio
                          child: _buildLandscapeGrid(cardWidth, screenSize),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Updated grid builder method
  Widget _buildLandscapeGrid(double cardWidth, Size screenSize) {
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.only(top: 15),
      physics: const NeverScrollableScrollPhysics(), // Keep this to prevent interference with PageView
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
  // Helper method for grid items
  Widget _buildGridItem(int index, double cardWidth, Size screenSize) {
    bool isFilled = index < stampCount;
    bool isFreeReward = index == 7 || index == 14; // 8th and 15th spots

    // Calculate font size based on screen dimensions
    final baseFontSize = screenSize.width * 0.018; // Adjust this multiplier as needed

    // Calculate cell size to position elements relatively
    final cellSize = cardWidth / 5; // Since we have 5 columns

    return LayoutBuilder(

        builder: (context, constraints) {
          // Get the actual size of each grid cell
          final cellWidth = constraints.maxWidth;
          final cellHeight = constraints.maxHeight;

          return Container(
            margin: const EdgeInsets.only(),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5),
              color: isFreeReward ? Colors.grey[300] : Colors.white,
            ),
            child: Stack(
              children: [
                if (isFilled && !isFreeReward)
                  Center(
                    child: Image.asset('assets/Maple_leaf_grey.png'),
                  ),

                if (isFilled && isFreeReward)
                  Positioned(
                    top: cellHeight * 0.1, // Position at 10% from top
                    right: cellWidth * 0.1, // Position at 10% from right
                    child: Text('STAMPED\nREWARD',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: baseFontSize * 1.1,
                        )),
                  ),

                if (!isFilled && isFreeReward)
                  Positioned(
                    top: cellHeight * 0.025, // Position at 10% from top
                    right: cellWidth * 0.025, // Position at 10% from right
                    child: Text(
                      index == 7 ? 'FREE\nREFILL' : 'FREE\nDRINK',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize, // Responsive font size
                      ),
                    ),
                  ),

                Positioned(
                  bottom: cellHeight * 0.05, // Position at 5% from bottom
                  right: cellWidth * 0.05, // Position at 5% from right
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: baseFontSize * 0.9, // Slightly smaller
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (index == 1 && isFilled)
                  Positioned(
                    top: cellHeight * 0.05, // Position at 5% from top
                    right: cellWidth * 0.05, // Position at 5% from right
                    child: SizedBox(
                      width: cellWidth * 0.4,
                      height: cellHeight * 0.4,
                      child: const FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(Icons.eco, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
    );
  }
}