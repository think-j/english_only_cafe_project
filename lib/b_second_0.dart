import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const SecondPage());
}

// Optimized responsive text sizing for compact layouts
class ResponsiveTextSize {
  static double getSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final aspectRatio = height / width;

    // More aggressive scaling for foldable devices
    double factor = 1.0;

    // Special case for Galaxy Fold 5 and similar foldable devices
    if (aspectRatio > 2.0) {
      // Very aggressive scaling for tall/narrow devices
      factor = 0.65;
    } else if (width < 400) {
      factor = 0.7;
    } else if (width < 600) {
      factor = 0.8;
    } else {
      factor = 0.9;
    }

    return baseSize * factor;
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> cardsData = [
      {
        'id': '001',
        'qrData': 'https://event1.example.com',
        'title': 'NOTICE',
      },
      {
        'id': '002',
        'qrData': 'https://event2.example.com',
        'title': 'NOTICE',
      },
      {
        'id': '003',
        'qrData': 'https://event3.example.com',
        'title': 'NOTICE',
      },
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Event Cards',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(cardsData: cardsData),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cardsData;
  const MainScreen({Key? key, required this.cardsData}) : super(key: key);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  int currentCardIndex = 0;

  void nextCard() {
    if (currentCardIndex < widget.cardsData.length - 1) {
      setState(() {
        currentCardIndex++;
      });
    }
  }

  void previousCard() {
    if (currentCardIndex > 0) {
      setState(() {
        currentCardIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: EventCardPage(
              cardData: widget.cardsData[currentCardIndex],
            ),
          ),
          // Navigation controls removed to save space
        ],
      ),
    );
  }
}

// Compact event card page with fixed cardData handling
class EventCardPage extends StatelessWidget {
  final Map<String, dynamic> cardData;

  // Default constructor with proper initialization
  const EventCardPage({
    Key? key,
    required this.cardData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Safe access to map values
    final String title = cardData['title'] ?? 'NOTICE';
    final String id = cardData['id'] ?? '';
    final String qrData = cardData['qrData'] ?? 'https://example.com';

    final Size screenSize = MediaQuery.of(context).size;
    final bool isNarrowDevice = screenSize.width < 600;
    final bool isVeryNarrow = screenSize.width < 400;

    final double compactPadding = screenSize.width * 0.02;
    final double smallSpacing = screenSize.width * 0.01;
    final double qrSize = isVeryNarrow ? 70.0 : (isNarrowDevice ? 80.0 : 100.0);
    final double fontSize = ResponsiveTextSize.getSize(context, 16.0);

    return SafeArea(
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: Container(
            width: screenSize.width * 0.98,
            padding: EdgeInsets.all(compactPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top section with better space utilization
                isNarrowDevice
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row containing NOTICE title and first info item
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: _buildCompactTitle(context, title),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildCompactTextRow(
                            context,
                            regular: ['- Check the '],
                            bold: ['INFORMATION'],
                            regular2: [' from the '],
                            bold2: ['QR code.'],
                            fontSize: fontSize,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: smallSpacing),
                    Center(child: _buildCompactIdSection(context, id)),
                  ],
                )
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side: Title and first info item
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCompactTitle(context, title),
                          SizedBox(height: smallSpacing),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Check the '],
                            bold: ['INFORMATION'],
                            regular2: [' from the '],
                            bold2: ['QR code.'],
                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Book the event from '],
                            bold: ['Meetup'],
                            regular2: [' before coming.'],
                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: [ '- Put this on the table when you join.',],

                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Card reissue is '],
                            bold: ['100 JPY.'],
                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Bring this card to get a new one.'],

                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Collect 8 stamps, get a '],
                            bold: ['FREE REFILL.'],
                            regular2: [' *1,2'],
                            fontSize: fontSize,
                          ),
                          _buildCompactTextRow(
                            context,
                            regular: ['- Collect 15 stamps, get a '],
                            bold: ['FREE DRINK.'],
                            regular2: [' *2'],
                            fontSize: fontSize,
                          ),
                        ],
                      ),
                    ),

                    // Right side: ID section
                    _buildCompactIdSection(context, id),
                  ],
                ),

                SizedBox(height: smallSpacing),

                // Remaining info items
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [


                   ]
                ),

                SizedBox(height: smallSpacing),

                // Bottom section
                isNarrowDevice
                    ? Column(
                  children: [
                    _buildCompactFootnotes(context),
                    SizedBox(height: smallSpacing),
                    Center(
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: qrSize,
                      ),
                    ),
                  ],
                )
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildCompactFootnotes(context),
                    ),
                    QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: qrSize * 1.3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // All helper methods with underscore prefix to indicate they're private
  Widget _buildCompactTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: ResponsiveTextSize.getSize(context, 18.0),
      ),
    );
  }

  Widget _buildCompactIdSection(BuildContext context, String id) {
    final size = MediaQuery.of(context).size;
    final bool isNarrowDevice = size.width < 600;

    final double boxWidth = isNarrowDevice ? size.width * 0.6 : 100.0;
    final double boxHeight = isNarrowDevice ? boxWidth * 0.6 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: boxWidth,
          height: boxHeight,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'This is my No.',
                style: TextStyle(
                  fontSize: ResponsiveTextSize.getSize(context, 10.0),
                ),
              ),
              Text(
                id,
                style: TextStyle(
                  fontSize: ResponsiveTextSize.getSize(context, 12.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          'PASSPORT',
          style: TextStyle(
            fontSize: ResponsiveTextSize.getSize(context, 10.0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTextRow(
      BuildContext context, {
        List<String> regular = const [],
        List<String> bold = const [],
        List<String> regular2 = const [],
        List<String> bold2 = const [],
        required double fontSize,
      }) {
    return Wrap(
      spacing: 0,
      children: [
        ...regular.map((text) => Text(
          text,
          style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
        )),
        ...bold.map((text) => Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        )),
        ...regular2.map((text) => Text(
          text,
          style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
        )),
        ...bold2.map((text) => Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        )),
      ],
    );
  }

  Widget _buildCompactFootnotes(BuildContext context) {
    final fontSize = ResponsiveTextSize.getSize(context, 11.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCompactTextRow(
          context,
          regular: ['1 ', 'Available until your '],
          bold: ['15th stamp'],
          fontSize: fontSize * 1.2,
        ),

        SizedBox(height: 1.0),

        _buildCompactTextRow(
          context,
          regular: ['2 ', '500 JPY discount for '],
          bold: ['drinks.'],
          fontSize: fontSize * 1.2,
        ),

        SizedBox(height: 1.0),

        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            'Other drinks can be ordered by paying the difference',
            style: TextStyle(fontSize: fontSize * 1.2, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}