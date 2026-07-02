import 'package:flutter/material.dart';
import 'package:komorebi/screens/custom_appbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: customAppBar(context), body: Placeholder());
  }
}
