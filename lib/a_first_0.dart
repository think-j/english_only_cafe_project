import 'package:flutter/material.dart';

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  // Your existing state variables
  int stampCount = 1;
  bool isAvailable = false;
  bool isStaffMode = false;


  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive layouts
    final screenSize = MediaQuery.of(context).size;

    // Calculate adaptive sizes based on screen dimensions
    final double memberFontSize = screenSize.width * 0.04; // Smaller font for "MEMBER"
    final double passportFontSize = screenSize.width * 0.08; // Larger font for "PASSPORT"
    final double cafeFontSize = screenSize.width * 0.045; // Size for "ENGLISH ONLY CAFE"
    final double iconSize = screenSize.width * 0.2; // 20% of screen width
    final double spacingUnit = screenSize.width * 0.04; // 4% of screen width for spacing

    // We're rotating the content 90 degrees
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: RotatedBox(
            quarterTurns: 3, // Rotate 90 degrees clockwise
            child: Container(
              // Use constraints to control the size
              constraints: BoxConstraints(
                maxWidth: screenSize.height, // Note the swap of width/height
                maxHeight: screenSize.width,
              ),
              // Add padding that scales with screen size
              padding: EdgeInsets.all(spacingUnit),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // "MEMBER" text with light weight
                  Text(
                    'MEMBER',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display', // System font similar to Helvetica
                      fontSize: memberFontSize * 0.9,
                      fontWeight: FontWeight.w300, // Light weight as seen in image
                      letterSpacing: memberFontSize * 0.15,
                      color: Colors.black87,
                    ),
                  ),
                  // "PASSPORT" text with bold weight
                  Text(
                    'PASSPORT',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display', // System font similar to Helvetica
                      fontSize: passportFontSize * 0.55,
                      fontWeight: FontWeight.w800, // Extra bold as seen in image
                      letterSpacing: passportFontSize * 0.15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: spacingUnit * 3.5),
                  // Coffee cup icon with customizations to look more like the image
              Image.asset('assets/a.jpg'),


                  SizedBox(height: spacingUnit * 2.5),
                  // "ENGLISH ONLY CAFE" text
                  // "ENGLISH ONLY CAFE" text with RichText for better alignment
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontSize: cafeFontSize * 0.6,
                          letterSpacing: cafeFontSize * 0.15,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'ENGLISH ',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'ONLY',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' CAFE',
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}