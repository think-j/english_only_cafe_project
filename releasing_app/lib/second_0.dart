import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const SecondPage());
}

// Helper class for responsive text sizing
class ResponsiveTextSize {
  static double getSize(BuildContext context, double baseSize) {
    // Get the screen width
    final width = MediaQuery.of(context).size.width;

    // Calculate factor based on screen width
    double factor = 1.0;
    if (width < 320) {
      factor = 0.8; // Smaller devices
    } else if (width < 480) {
      factor = 0.9; // Small devices
    } else if (width < 768) {
      factor = 1.0; // Medium devices (base size)
    } else if (width < 1024) {
      factor = 1.1; // Large devices
    } else {
      factor = 1.2; // Extra large devices
    }

    return baseSize * factor;
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for multiple cards - defined at the app level
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainScreen(cardsData: cardsData),
    );
  }
}

// Main screen with navigation controller
class MainScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cardsData;

  const MainScreen({Key? key, required this.cardsData}) : super(key: key);

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  // Current page index (0 = Home, 1 = Event Cards)
  int _currentIndex = 0;
  // Current card index
  int _currentCardIndex = 0;

  void _goToEventCards() {
    setState(() {
      _currentIndex = 1;
    });
  }

  void _goToHome() {
    setState(() {
      _currentIndex = 0;
    });
  }

  void _nextCard() {
    if (_currentCardIndex < widget.cardsData.length - 1) {
      setState(() {
        _currentCardIndex++;
      });
    }
  }

  void _previousCard() {
    if (_currentCardIndex > 0) {
      setState(() {
        _currentCardIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body:  Column(
        children: [
          Expanded(
            child: EventCardPage(
              cardData: widget.cardsData[_currentCardIndex],
            ),
          ),
          // Navigation controls for cards
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous button

                // Page indicators

                // Next button

              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder classes for other pages

class EventCardPage extends StatelessWidget {
  final Map<String, dynamic> cardData;
  static const double kDefaultFontSize = 12.0;

  // Using a default empty map
  const EventCardPage({
    Key? key,
    this.cardData = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Handle the case when cardData might be empty
    final String title = cardData['title'] ?? 'NOTICE';
    final String id = cardData['id'] ?? '';
    final String qrData = cardData['qrData'] ?? 'https://example.com';

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NOTICE and Passport ID in a Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - NOTICE section
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NOTICE section with larger text
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveTextSize.getSize(context, 20.0),
                        ),
                      ),
                      const SizedBox(height: 8.0),

                      // Information from QR code section
                      Row(
                        children: [
                          Text(
                            '- Check the ',
                            style: TextStyle(
                                fontSize: ResponsiveTextSize.getSize(context, 14.0),
                                color: Colors.grey[600]
                            ),
                          ),
                          Text(
                            'INFORMATION',
                            style: TextStyle(
                              fontSize: ResponsiveTextSize.getSize(context, 14.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' from the ',
                            style: TextStyle(
                                fontSize: ResponsiveTextSize.getSize(context, 14.0),
                                color: Colors.grey[600]
                            ),
                          ),
                          Text(
                            'QR code.',
                            style: TextStyle(
                              fontSize: ResponsiveTextSize.getSize(context, 14.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Book the event from Meetup
                      Row(
                        children: [
                          Text(
                            '- Book the event from ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            'Meetup',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' before coming.',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      // Put this on the table
                      Text(
                        '- Put this on the table when you join.',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      ),

                      // Card reissue
                      Row(
                        children: [
                          Text(
                            '- Card reissue is ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            '100 JPY.',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),

                      // Free drink section
                      Row(
                        children: [
                          Text(
                            '- Collect 8 stamps, get a ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            'FREE REFILL.',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            ' *1,2',
                            style: TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Text(
                            '- Collect 15 stamps, get a ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            'FREE DRINK.',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            ' *2',
                            style: TextStyle(
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),

                      // Bring this card section
                      Text(
                        '- Bring this card to get a new one.',
                        style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Right side - Passport box
                Container(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // "This is my No." section
                      Container(
                        width: 120,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'This is my No.',
                              style: TextStyle(fontSize: ResponsiveTextSize.getSize(context, 12.0)),
                            ),
                            Text(
                              id,
                              style: TextStyle(fontSize: ResponsiveTextSize.getSize(context, 12.0)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'PASSPORT',
                        style: TextStyle(
                          fontSize: kDefaultFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20.0),

            // Bottom row with footnotes and QR code
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Footnotes section (left side)
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '1 ',
                            style: TextStyle(fontSize: 14.0),
                          ),
                          Text(
                            'Available until your ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            '15th stamp',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            '2 ',
                            style: TextStyle(fontSize: 14.0),
                          ),
                          Text(
                            '500 JPY discount for ',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                          ),
                          const Text(
                            'drinks.',
                            style: TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0),
                        child: Text(
                          'Other drinks can be ordered by paying the difference',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),

                // QR code at bottom right
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 120.0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}