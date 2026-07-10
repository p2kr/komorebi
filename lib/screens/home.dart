import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/screens/appbar/appbar.dart';
import 'package:komorebi/screens/nav_bar/navbar.dart';
import 'package:komorebi/utils/init.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: appBar(context, ref), body: const NavBar());
  }

  @override
  void initState() {
    super.initState();

    // Initialize db etc.
    initializeSettings(ref);
  }
}
