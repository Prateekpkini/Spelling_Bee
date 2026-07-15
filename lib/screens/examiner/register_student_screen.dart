import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/providers/student_provider.dart';
import 'package:spelling_bee/widgets/glass_scaffold.dart';
import 'package:spelling_bee/widgets/glass_container.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterStudentScreen extends ConsumerStatefulWidget {
  const RegisterStudentScreen({super.key});

  @override
  ConsumerState<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends ConsumerState<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _schoolNameCtrl = TextEditingController();
  final _schoolAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();

  String _selectedGrade = '1';
  bool _isLoading = false;
  String? _generatedLink;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sectionCtrl.dispose();
    _schoolNameCtrl.dispose();
    _schoolAddressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _mobileCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tokenService = ref.read(tokenServiceProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final token = tokenService.generateToken();

      final student = Student(
        id: '',
        name: _nameCtrl.text.trim(),
        grade: _selectedGrade,
        section: _sectionCtrl.text.trim(),
        schoolName: _schoolNameCtrl.text.trim(),
        schoolAddress: _schoolAddressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        parentMobile: _mobileCtrl.text.trim(),
        token: token,
        tokenStatus: 'active',
      );

      await firestoreService.addStudent(student);

      String baseUrl;
      if (kIsWeb) {
        final uri = Uri.base;
        baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      } else {
        baseUrl = 'https://everest-spelling-bee-26.web.app';
      }
      final link = '$baseUrl/play?token=$token';

      setState(() {
        _generatedLink = link;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _copyLink() {
    if (_generatedLink == null) return;
    Clipboard.setData(ClipboardData(text: _generatedLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Game link copied to clipboard!', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _sectionCtrl.clear();
    _schoolNameCtrl.clear();
    _schoolAddressCtrl.clear();
    _cityCtrl.clear();
    _districtCtrl.clear();
    _stateCtrl.clear();
    _mobileCtrl.clear();
    setState(() {
      _selectedGrade = '1';
      _generatedLink = null;
    });
  }

  InputDecoration _glassInput(String label, [IconData? icon]) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Register Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 700;
              final content = _generatedLink != null ? _buildSuccessView() : _buildForm();
              final stats = _buildQuickStats();

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: content),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: stats),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    content,
                    const SizedBox(height: 24),
                    stats,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFFFD700)),
              const SizedBox(width: 12),
              Text(
                'Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Register a student to generate a unique one-time game token.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _InfoBullet('Game tokens are single-use.'),
          _InfoBullet('Select the correct Grade to fetch appropriate words.'),
          _InfoBullet('Test the game link in-app without wiping memory state.'),
        ],
      ),
    );
  }

  Widget _InfoBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 8),
            child: Icon(Icons.circle, size: 8, color: Color(0xFFFFD700)),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            'Student Registered!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_nameCtrl.text.trim()} (Grade $_selectedGrade)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 32),

          // Game link
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GAME LINK',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _generatedLink!,
                  style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyLink,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Link', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0A1128),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.go('/play?token=${_generatedLink!.split('token=').last}');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test In-App'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _resetForm,
              icon: const Icon(Icons.person_add),
              label: const Text('Register Another Student'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFD700),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Student Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInput('Full Name *', Icons.person_outline),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGrade,
                    dropdownColor: const Color(0xFF102B6E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput('Grade *', Icons.grade_outlined),
                    items: List.generate(10, (i) => '${i + 1}')
                        .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g', style: const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGrade = v ?? '1'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _sectionCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput('Section', Icons.class_outlined),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolNameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInput('School Name *', Icons.apartment_outlined),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'School name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolAddressCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInput('School Address', Icons.location_on_outlined),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput('City *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _districtCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _glassInput('District'),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInput('State *', Icons.map_outlined),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'State is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _glassInput('Parent Mobile *', Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Mobile is required';
                if (v.trim().length < 10) return 'Enter a valid 10-digit number';
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700), // Gold
                  foregroundColor: const Color(0xFF0A1128),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: const Color(0xFFFFD700).withOpacity(0.4),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A1128)),
                      )
                    : const Text(
                        'Register & Generate Link',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
