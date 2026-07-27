import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/features/appbar/appbar.dart';
import 'package:komorebi/src/features/nav_bar/navbar.dart';
import 'package:komorebi/src/core/utils/init.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:libtorrent_flutter/libtorrent_flutter.dart';

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
    // Initialize db etc.
    initializeSettings(ref);

    super.initState();
  }

  @override
  void dispose() async {
    super.dispose();

    try {
      await LibtorrentFlutter.instance.dispose();
    } catch (e, t) {
      talker.error("error disposing libtorrent instance", e, t);
    }
  }
}
