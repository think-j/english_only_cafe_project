import 'package:flutter/material.dart';
/*import 'first_page.dart';
import 'second_page.dart';*/
import 'third_page.dart';
import 'forth_page.dart';

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

class OrderedPageView extends StatelessWidget {
  const OrderedPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        scrollDirection: Axis.vertical,
        children: [

          ThirdPage(),
          ForthPage(), // Include ForthPage here
        ],
      ),
    );
  }
}