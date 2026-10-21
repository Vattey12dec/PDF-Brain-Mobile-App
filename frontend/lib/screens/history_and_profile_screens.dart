import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback onOpenChatTab;

  const HistoryScreen({super.key, required this.onOpenChatTab});

  @override
  Widget build(BuildContext context) {
    final chatProv = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Conversation',
            onPressed: () {
              chatProv.startNewConversation();
              onOpenChatTab();
            },
          ),
        ],
      ),
      body: chatProv.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : chatProv.conversations.isEmpty
              ? const EmptyStateView(
                  icon: Icons.history_toggle_off,
                  title: 'No Saved Conversations Yet',
                  message: 'Your questions and grounded answers will be saved here automatically.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProv.conversations.length,
                  itemBuilder: (context, idx) {
                    final conv = chatProv.conversations[idx];
                    final formatted = DateFormat.yMMMd().add_jm().format(conv.updatedAt.toLocal());
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(conv.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Updated $formatted'),
                        onTap: () async {
                          await chatProv.openConversation(conv.id);
                          onOpenChatTab();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => chatProv.deleteConversation(conv.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = auth.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user?.userMetadata?['full_name'] ?? 'Authenticated Student'),
              subtitle: Text(user?.email ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark Mode'),
              subtitle: const Text('Switch between Material 3 light and dark themes'),
              value: isDark,
              onChanged: (val) => auth.toggleTheme(val),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Sign Out'),
            ),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
    );
  }
}