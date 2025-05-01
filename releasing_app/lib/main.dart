import 'package:flutter/material.dart';
import 'first_0.dart';
import 'second_0.dart';
import 'third_0.dart';
import 'fourth_0.dart';

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
void main() async {
  debugPaintSizeEnabled = false;
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([

    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  // ... other main() configurations ...

  runApp(const MaterialApp(
    home: OrderedPageView(),
  ));
}
class OrderedPageView extends StatefulWidget {
  const OrderedPageView({super.key});

  @override
  State<OrderedPageView> createState() => _OrderedPageViewState();
}

class _OrderedPageViewState extends State<OrderedPageView> {
  late PageController _pageController;
  final int _actualPageCount = 4;
  // Set a very large number for "infinite" scrolling
  final int _virtualPageCount = 10000;

  @override
  void initState() {
    super.initState();
    // Start from the middle to allow scrolling in both directions
    _pageController = PageController(initialPage: _virtualPageCount ~/ 2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _virtualPageCount,
        itemBuilder: (context, index) {
          // Map the virtual index to actual pages (0,1,2,3)
          final actualIndex = index % _actualPageCount;

          switch (actualIndex) {
            case 0:
              return const FirstPage();
            case 1:
              return const SecondPage();
            case 2:
              return const ThirdPage();
            case 3:
              return const FourthPage();
            default:
              return const SizedBox(); // Should never reach here
          }
        },
      ),
    );
  }
}