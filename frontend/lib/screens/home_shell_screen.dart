import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import 'home_and_upload_screens.dart';
import 'documents_and_viewer_screens.dart';
import 'chat_screen.dart';
import 'history_and_profile_screens.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
      context.read<ChatProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final pages = <Widget>[
      HomeDashboardScreen(
        onNavigateTab: _switchToTab,
      ),
      DocumentsScreen(
        onOpenChatTab: () => _switchToTab(2),
      ),
      const ChatScreen(),
      HistoryScreen(
        onOpenChatTab: () => _switchToTab(2),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _switchToTab,
        indicatorColor: primaryColor.withValues(alpha: 0.14),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded, color: primaryColor),
            label: 'Documents',
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded, color: primaryColor),
            label: 'Ask AI',
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: primaryColor),
            label: 'History',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: primaryColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}