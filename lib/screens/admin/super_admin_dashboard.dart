import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/examiner.dart';
import 'package:spelling_bee/providers/auth_provider.dart';
import 'package:spelling_bee/providers/result_provider.dart';
import 'package:spelling_bee/services/api_service.dart';

import 'package:file_picker/file_picker.dart';

class SuperAdminDashboard extends ConsumerStatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  ConsumerState<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends ConsumerState<SuperAdminDashboard> {
  int _selectedIndex = 0;
  String _eventName = 'Everest Spelling Bee Open Challenge';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await apiService.getConfig();
      if (mounted) {
        setState(() {
          _eventName = config['event_name'] ?? _eventName;
        });
      }
    } catch (e) {
      debugPrint('Failed to load config: $e');
    }
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.people, label: 'Manage Teachers'),
    _NavItem(icon: Icons.settings, label: 'Game Settings'),
    _NavItem(icon: Icons.upload_file, label: 'Word Bank Upload'),
    _NavItem(icon: Icons.leaderboard, label: 'Global Leaderboard'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A1128), // Midnight Blue
            Color(0xFF102B6E), // Royal Blue
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              if (isMobile) {
                return _buildMobileLayout();
              }
              return _buildDesktopLayout();
            },
          ),
        ),
      ),
    );
  }

  // ── Desktop Layout (sidebar + content) ──────────────────
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildDesktopHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sidebar
                SizedBox(
                  width: 240,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isSelected = _selectedIndex == index;
                        return InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFFD700).withOpacity(0.15)
                                  : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? const Color(0xFFFFD700) : Colors.white54,
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white54,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile Layout (bottom nav + full-width content) ──────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
              ),
              padding: const EdgeInsets.all(16),
              child: _buildContent(),
            ),
          ),
        ),
        // Bottom Navigation
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1128).withOpacity(0.95),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFFFFD700),
            unselectedItemColor: Colors.white38,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: _navItems
                .map((item) => BottomNavigationBarItem(
                      icon: Icon(item.icon, size: 22),
                      label: item.label.split(' ').last, // short label
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── Desktop Header ──────────────────────────────────────
  Widget _buildDesktopHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _eventName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Text(
                    'SUPER ADMIN CONSOLE',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
              context.go('/login');
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Header (compact) ─────────────────────────────
  Widget _buildMobileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/images/logo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'SUPER ADMIN CONSOLE',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            tooltip: 'Sign Out',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }



  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const _ManageTeachersTab();
      case 1:
        return _GameSettingsTab(
          onSaved: (newName) {
            setState(() {
              _eventName = newName;
            });
          },
        );
      case 2:
        return const _WordBankUploadTab();
      case 3:
        return const _LeaderboardTab();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ══════════════════════════════════════════════════════════════════════
// Tab 1: Manage Teachers
// ══════════════════════════════════════════════════════════════════════

class _ManageTeachersTab extends StatefulWidget {
  const _ManageTeachersTab();

  @override
  State<_ManageTeachersTab> createState() => _ManageTeachersTabState();
}

class _ManageTeachersTabState extends State<_ManageTeachersTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  List<Examiner> _teachers = [];
  bool _loadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _schoolCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await apiService.getTeachers();
      if (mounted) setState(() { _teachers = teachers; _loadingTeachers = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingTeachers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load teachers: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await apiService.createTeacher(
        _nameCtrl.text.trim(),
        _schoolCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher created successfully!'), backgroundColor: Colors.green),
        );
        _nameCtrl.clear();
        _schoolCtrl.clear();
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _loadTeachers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDeleteTeacher(Examiner teacher) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF102B6E),
        title: const Text('Delete Teacher', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete ${teacher.username}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteTeacher(int.parse(teacher.uid));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher deleted successfully!'), backgroundColor: Colors.green),
          );
          _loadTeachers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFFFFD700), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Manage Teachers',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Create examiner accounts for teachers.',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const Divider(color: Colors.white12, height: 32),

            // Form — responsive layout
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile) ...[
                    // Stack fields vertically on mobile
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDeco('Full Name', Icons.person),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _schoolCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDeco('School', Icons.school),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _emailCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDeco('Email', Icons.email),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _passwordCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: _inputDeco('Password', Icons.lock),
                      obscureText: true,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTeacher,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)))
                            : const Icon(Icons.add, size: 20),
                        label: const Text('Create Teacher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0A1128),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Wrap layout for desktop
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _nameCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDeco('Full Name', Icons.person),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _schoolCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDeco('School', Icons.school),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _emailCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDeco('Email', Icons.email),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: TextFormField(
                            controller: _passwordCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: _inputDeco('Password', Icons.lock),
                            obscureText: true,
                            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createTeacher,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)))
                                : const Icon(Icons.add, size: 20),
                            label: const Text('Create Teacher'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: const Color(0xFF0A1128),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text('Registered Teachers',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),

            // Teachers list
            Expanded(
              child: _loadingTeachers
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : _teachers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_off, color: Colors.white24, size: 48),
                              const SizedBox(height: 12),
                              Text('No teachers registered yet.',
                                  style: TextStyle(color: Colors.white38)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _teachers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final t = _teachers[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
                                    child: Text(
                                      t.username.isNotEmpty ? t.username[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                          color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t.username,
                                            style: const TextStyle(
                                                color: Colors.white, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(
                                          isMobile
                                              ? t.email
                                              : '${t.email}  •  ${t.school ?? 'No School'}',
                                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Delete Teacher',
                                    onPressed: () => _confirmDeleteTeacher(t),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Tab 2: Game Settings
// ══════════════════════════════════════════════════════════════════════

class _GameSettingsTab extends StatefulWidget {
  final Function(String) onSaved;
  const _GameSettingsTab({required this.onSaved});

  @override
  State<_GameSettingsTab> createState() => _GameSettingsTabState();
}

class _GameSettingsTabState extends State<_GameSettingsTab> {
  final _timerCtrl = TextEditingController();
  final _shieldsCtrl = TextEditingController();
  final _passesCtrl = TextEditingController();
  final _eventNameCtrl = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _shieldsCtrl.dispose();
    _passesCtrl.dispose();
    _eventNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await apiService.getSettings();
      _timerCtrl.text = settings['timer_seconds'].toString();
      _shieldsCtrl.text = settings['initial_shields'].toString();
      _passesCtrl.text = settings['initial_passes'].toString();
      _eventNameCtrl.text = settings['event_name']?.toString() ?? 'Everest Spelling Bee Open Challenge';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load settings: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await apiService.updateSettings(
        int.parse(_timerCtrl.text),
        int.parse(_shieldsCtrl.text),
        int.parse(_passesCtrl.text),
        _eventNameCtrl.text.trim(),
      );
      if (mounted) {
        widget.onSaved(_eventNameCtrl.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _settingsDeco(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white24),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 22),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxFormWidth = constraints.maxWidth < 500 ? constraints.maxWidth : 450.0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Color(0xFFFFD700), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Game Settings',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Configure championship timer, shields, and passes.',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
              const Divider(color: Colors.white12, height: 32),

              SizedBox(
                width: maxFormWidth,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _eventNameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _settingsDeco('Event Name', Icons.event, 'e.g. Everest Spelling Bee'),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _timerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _settingsDeco('Timer (Seconds)', Icons.timer, 'e.g. 1800 = 30 minutes'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _shieldsCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _settingsDeco('Initial Shields', Icons.shield, 'e.g. 5'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passesCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _settingsDeco('Initial Passes', Icons.skip_next, 'e.g. 5'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)))
                            : const Icon(Icons.save, size: 20),
                        label: const Text('Save Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0A1128),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Tab 3: Word Bank Upload
// ══════════════════════════════════════════════════════════════════════

class _WordBankUploadTab extends StatefulWidget {
  const _WordBankUploadTab();

  @override
  State<_WordBankUploadTab> createState() => _WordBankUploadTabState();
}

class _WordBankUploadTabState extends State<_WordBankUploadTab> {
  String _selectedGrade = '1';
  bool _isUploading = false;
  String? _uploadResult;

  Future<void> _pickAndUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() { _isUploading = true; _uploadResult = null; });
      try {
        final res = await apiService.uploadWords(
          _selectedGrade,
          result.files.single.bytes!.toList(),
          result.files.single.name,
        );
        if (mounted) {
          setState(() {
            _uploadResult = '✅ Upload successful! Inserted: ${res['inserted']}, Updated: ${res['updated']}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload successful! Inserted: ${res['inserted']}, Updated: ${res['updated']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _uploadResult = '❌ Error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.upload_file, color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Word Bank Upload',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a CSV file with columns: spelling_british, spelling_american, part_of_speech, meaning, jumbled_letters',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Divider(color: Colors.white12, height: 32),

          // Grade selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Step 1: Select Grade',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    dropdownColor: const Color(0xFF1A2744),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.grade, color: Color(0xFFFFD700), size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                      ),
                    ),
                    items: List.generate(10, (i) => (i + 1).toString()).map((g) {
                      return DropdownMenuItem(value: g, child: Text('Grade $g'));
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedGrade = v!),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Step 2: Upload CSV File',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickAndUpload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)))
                      : const Icon(Icons.cloud_upload, size: 20),
                  label: Text(_isUploading ? 'Uploading...' : 'Select & Upload CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_uploadResult != null) ...[
                  const SizedBox(height: 16),
                  Text(_uploadResult!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Tab 4: Global Leaderboard
// ══════════════════════════════════════════════════════════════════════

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(resultsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.leaderboard, color: Color(0xFFFFD700), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Global Leaderboard',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.refresh(resultsProvider),
              color: const Color(0xFFFFD700),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const Divider(color: Colors.white12, height: 24),
        Expanded(
          child: resultsAsync.when(
            data: (results) {
              if (results.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      Text('No results yet.', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 400;
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = results[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 14 : 18,
                              backgroundColor: index < 3
                                  ? const Color(0xFFFFD700).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: index < 3 ? const Color(0xFFFFD700) : Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                            SizedBox(width: isMobile ? 8 : 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.studentName,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: isMobile ? 13 : 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text('Grade ${r.grade}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Score: ${r.finalScore}',
                                    style: TextStyle(
                                        color: const Color(0xFFFFD700),
                                        fontWeight: FontWeight.bold,
                                        fontSize: isMobile ? 12 : 14)),
                                Text('${r.correctAnswers} Correct',
                                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ],
    );
  }
}
