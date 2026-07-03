import 'package:flutter/material.dart';
import 'package:komorebi/screens/appbar/appbar.dart';
import 'package:komorebi/screens/navbar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar(context), body: const NavBar());
  }
}
