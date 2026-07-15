import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:spelling_bee/app/theme.dart';
import 'package:spelling_bee/models/student.dart';
import 'package:spelling_bee/providers/student_provider.dart';
import 'package:spelling_bee/widgets/responsive_scaffold.dart';
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

      // Build the game link
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
            content: Text('Error: $e'),
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
        content: Text('Game link copied to clipboard!'),
        backgroundColor: AppColors.success,
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text('Register Student'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _generatedLink != null ? _buildSuccessView() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.check_circle, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 20),
        Text(
          'Student Registered!',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          '${_nameCtrl.text.trim()} (Grade $_selectedGrade)',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 24),

        // Game link card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryDeep.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryDeep.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game Link',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.primaryDeep,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedLink!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _copyLink,
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.primaryDeep,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate in-app so the mock memory isn't wiped by a browser reload
              context.go('/play?token=${_generatedLink!.split('token=').last}');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Test Game (In-App)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              side: const BorderSide(color: AppColors.primaryDeep),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _resetForm,
            icon: const Icon(Icons.person_add),
            label: const Text('Register Another'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Student Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedGrade,
                  decoration: const InputDecoration(
                    labelText: 'Grade *',
                    prefixIcon: Icon(Icons.grade_outlined),
                  ),
                  items: List.generate(10, (i) => '${i + 1}')
                      .map((g) => DropdownMenuItem(value: g, child: Text('Grade $g')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGrade = v ?? '1'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _sectionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _schoolNameCtrl,
            decoration: const InputDecoration(
              labelText: 'School Name *',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'School name is required' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _schoolAddressCtrl,
            decoration: const InputDecoration(
              labelText: 'School Address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cityCtrl,
                  decoration: const InputDecoration(labelText: 'City *'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(labelText: 'District'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _stateCtrl,
            decoration: const InputDecoration(
              labelText: 'State *',
              prefixIcon: Icon(Icons.map_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'State is required' : null,
          ),
          const SizedBox(height: 14),

          TextFormField(
            controller: _mobileCtrl,
            decoration: const InputDecoration(
              labelText: 'Parent Mobile *',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Mobile is required';
              if (v.trim().length < 10) return 'Enter a valid 10-digit number';
              return null;
            },
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Register & Generate Link'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
