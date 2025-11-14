import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _workoutReminders = true;
  bool _achievementNotifications = true;
  bool _soundEnabled = true;
  bool _hapticFeedback = true;
  String _weightUnit = 'kg';
  String _distanceUnit = 'km';

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
          _SectionHeader(title: 'Account'),
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
          _SectionHeader(title: 'Notifications'),
          _SwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive workout reminders and updates',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          _SwitchTile(
            icon: Icons.alarm_outlined,
            title: 'Workout Reminders',
            subtitle: 'Daily workout reminders',
            value: _workoutReminders,
            enabled: _notificationsEnabled,
            onChanged: (value) => setState(() => _workoutReminders = value),
          ),
          _SwitchTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievement Notifications',
            subtitle: 'Get notified about milestones',
            value: _achievementNotifications,
            enabled: _notificationsEnabled,
            onChanged: (value) => setState(() => _achievementNotifications = value),
          ),

          const Divider(height: 32),

          // Preferences Section
          _SectionHeader(title: 'Preferences'),
          _SettingsTile(
            icon: Icons.fitness_center,
            title: 'Weight Unit',
            subtitle: _weightUnit.toUpperCase(),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUnitPicker(
              context,
              'Weight Unit',
              _weightUnit,
              ['kg', 'lbs'],
              (value) => setState(() => _weightUnit = value),
            ),
          ),
          _SettingsTile(
            icon: Icons.straighten,
            title: 'Distance Unit',
            subtitle: _distanceUnit.toUpperCase(),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUnitPicker(
              context,
              'Distance Unit',
              _distanceUnit,
              ['km', 'mi'],
              (value) => setState(() => _distanceUnit = value),
            ),
          ),
          _SettingsTile(
            icon: Icons.access_time,
            title: 'Rest Timer Default',
            subtitle: '90 seconds',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestTimerDialog(context),
          ),

          const Divider(height: 32),

          // App Settings Section
          _SectionHeader(title: 'App Settings'),
          _SwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Sound Effects',
            subtitle: 'Play sounds for actions',
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          _SwitchTile(
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on button press',
            value: _hapticFeedback,
            onChanged: (value) => setState(() => _hapticFeedback = value),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: context.watch<ThemeProvider>().isDarkMode ? 'Dark' : 'Light',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemePicker(context),
          ),

          const Divider(height: 32),

          // Data & Privacy Section
          _SectionHeader(title: 'Data & Privacy'),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Last backup: Never',
            onTap: () => _showBackupDialog(context),
          ),
          _SettingsTile(
            icon: Icons.restore_outlined,
            title: 'Restore Data',
            onTap: () => _showRestoreDialog(context),
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Clear Workout History',
            titleColor: Colors.orange,
            onTap: () => _showClearHistoryDialog(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            titleColor: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),

          const Divider(height: 32),

          // About Section
          _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: context.read<AppState>().currentUser!.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Update user name
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker(BuildContext context, String title, String current, List<String> options, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return RadioListTile<String>(
              title: Text(option.toUpperCase()),
              value: option,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  onSelect(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRestTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rest Timer Default'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [60, 90, 120, 180].map((seconds) {
            return RadioListTile<int>(
              title: Text('$seconds seconds'),
              value: seconds,
              groupValue: 90,
              onChanged: (value) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rest timer set to $value seconds')),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              title: const Text('Dark'),
              value: true,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setTheme(value);
                  Navigator.pop(dialogContext);
                }
              },
            ),
            RadioListTile<bool>(
              title: const Text('Light'),
              value: false,
              groupValue: themeProvider.isDarkMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setTheme(value);
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Data'),
        content: const Text('Your workout data will be backed up to your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data backed up successfully')),
              );
            },
            child: const Text('Backup'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text('This will restore your workout data from the last backup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data restored successfully')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Workout History'),
        content: const Text('This will permanently delete all your workout history. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Workout history cleared')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete your account and all data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3B82F6),
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
        activeColor: const Color(0xFF3B82F6),
      ),
    );
  }
}
