import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _achievementNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load notification settings from preferences
    final appState = context.read<AppState>();
    final prefs = await appState.getUserPreferences();
    
    setState(() {
      _notificationsEnabled = prefs['notificationsEnabled'] ?? true;
      _workoutReminders = prefs['workoutReminders'] ?? true;
      _achievementNotifications = prefs['achievementNotifications'] ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final appState = context.read<AppState>();
    await appState.saveUserPreferences({
      'notificationsEnabled': _notificationsEnabled,
      'workoutReminders': _workoutReminders,
      'achievementNotifications': _achievementNotifications,
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          const _SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: user.name,
            onTap: () => _showEditProfileDialog(context),
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: user.email,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: () => _showChangePasswordDialog(context),
          ),

          const Divider(height: 32),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive workout reminders and updates',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              _saveSettings();
            },
          ),
          _SwitchTile(
            icon: Icons.alarm_outlined,
            title: 'Workout Reminders',
            subtitle: 'Daily workout reminders',
            value: _workoutReminders,
            enabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _workoutReminders = value);
              _saveSettings();
            },
          ),
          _SwitchTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievement Notifications',
            subtitle: 'Get notified about milestones',
            value: _achievementNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _achievementNotifications = value);
              _saveSettings();
            },
          ),

          const Divider(height: 32),

          // About Section
          const _SectionHeader(title: 'About'),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () => _showTermsDialog(context),
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => _showPrivacyDialog(context),
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => _showHelpDialog(context),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final currentUser = appState.currentUser!;
    final nameController = TextEditingController(text: currentUser.name);
    final ageController = TextEditingController(text: currentUser.age?.toString() ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name cannot be empty')),
                );
                return;
              }
              
              // Update user profile
              final age = int.tryParse(ageController.text);
              await appState.updateUserProfile(
                name: nameController.text,
                age: age,
              );
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validation
              if (newPasswordController.text.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters')),
                );
                return;
              }
              
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              try {
                // Update password
                await context.read<AppState>().updateUserPassword(
                  currentPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              } catch (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $error')),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open URL')),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'G-Fit Terms of Service',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '1. Use of Service\nYou agree to use G-Fit only for lawful purposes and in a way that does not infringe upon the rights of others or restrict their use and enjoyment of the service.\n\n'
                '2. User Accounts\nWhen you create an account with us, you must provide accurate, complete, and current information. You are responsible for maintaining your login credentials.\n\n'
                '3. Content\nAll content on G-Fit is owned by or licensed to us. The copying, reproduction, or distribution of content without permission is prohibited.\n\n'
                '4. Limitation of Liability\nIn no case shall G-Fit be liable for any damages resulting from your use of our service.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'G-Fit Privacy Policy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '1. Information We Collect\nWe collect personal information such as your name, email, age, and workout data to provide and improve our services.\n\n'
                '2. How We Use Your Data\nYour data is used to personalize your experience, send notifications, and improve our service. We do not share your data with third parties without consent.\n\n'
                '3. Data Security\nWe use industry-standard security measures to protect your data. However, no method of transmission is 100% secure.\n\n'
                '4. Your Rights\nYou have the right to access, modify, or delete your personal data at any time.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('Q: How do I start a workout?\nA: Go to Home and tap the + button to start a new workout.'),
              SizedBox(height: 12),
              Text('Q: How do I track my progress?\nA: Your workouts are automatically saved. View them in the History tab.'),
              SizedBox(height: 12),
              Text('Q: Can I export my data?\nA: Contact support for data export requests.'),
              SizedBox(height: 12),
              Text('Q: How are my workouts synced?\nA: Your data is automatically synced to the cloud.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF3B82F6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: titleColor ?? Colors.white),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.white,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool enabled;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? Colors.white : Colors.white.withOpacity(0.3),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                color: enabled
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
              ),
            )
          : null,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: const Color(0xFF3B82F6),
      ),
    );
  }
}
