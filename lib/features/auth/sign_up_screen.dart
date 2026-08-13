import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/auth_service.dart';
import '../../core/theme.dart';
import '../../core/user_profile_service.dart';
import '../../core/widgets/vail_field.dart';
import '../profile/user_profile.dart';

// ─── Sign-Up Screen (2-step) ──────────────────────────────────────────────────
// Step 1: Nickname, email, password
// Step 2: Age, gender, town, who to meet, optional extras

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // Step 1
  final _nicknameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  // Step 2 — required
  int? _age;
  String? _gender;
  final _townCtrl = TextEditingController();
  final List<String> _interestedIn = [];

  // Step 2 — optional
  final _occupationCtrl = TextEditingController();
  final _hobbiesCtrl = TextEditingController();
  String? _maritalStatus;

  int _step = 1;
  bool _loading = false;

  static const _genders = ['Man', 'Woman', 'Non-binary', 'Prefer not to say'];
  static const _meetOptions = ['Men', 'Women', 'Everyone'];
  static const _maritalOptions = [
    'Single',
    'Divorced',
    'Widowed',
    'Prefer not to say',
  ];

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _townCtrl.dispose();
    _occupationCtrl.dispose();
    _hobbiesCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step1Key.currentState?.validate() ?? false) {
      setState(() => _step = 2);
    }
  }

  Future<void> _submit() async {
    final formValid = _step2Key.currentState?.validate() ?? false;
    if (!formValid ||
        _age == null ||
        _gender == null ||
        _interestedIn.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    try {
      // Step 1: create the Firebase Auth account.
      final credential = await AuthService.instance.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      // Step 2: persist the full profile to Firestore.
      // The UID comes from the freshly-created auth credential.
      final uid = credential.user!.uid;

      // Build a deterministic avatar seed from the nickname so new users
      // immediately have a distinct avatar without any extra input.
      final avatarSeed = '${_nicknameCtrl.text.trim()}-${uid.substring(0, 6)}';

      final profile = UserProfile(
        nickname: _nicknameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        age: _age!,
        gender: _gender!,
        town: _townCtrl.text.trim(),
        interestedIn: List<String>.from(_interestedIn),
        occupation: _occupationCtrl.text.trim(),
        hobbies: _hobbiesCtrl.text.trim(),
        maritalStatus: _maritalStatus ?? '',
        avatarStyle: 'lorelei',
        avatarSeed: avatarSeed,
      );

      await UserProfileService.instance.createProfile(
        uid: uid,
        profile: profile,
      );

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(AuthService.messageFor(e));
    } catch (_) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: VailColors.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),
          Positioned(
            top: 60,
            left: -80,
            child: _Blob(color: VailColors.rose.withOpacity(0.10), size: 240),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: _Blob(
              color: const Color(0xFF9B59B6).withOpacity(0.09),
              size: 190,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: AnimatedSwitcher(
                duration: 350.ms,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _step == 1
                    ? _Step1(
                        key: const ValueKey(1),
                        formKey: _step1Key,
                        nicknameCtrl: _nicknameCtrl,
                        firstNameCtrl: _firstNameCtrl,
                        lastNameCtrl: _lastNameCtrl,
                        emailCtrl: _emailCtrl,
                        passwordCtrl: _passwordCtrl,
                        obscure: _obscure,
                        onToggleObscure: () =>
                            setState(() => _obscure = !_obscure),
                        onNext: _nextStep,
                      )
                    : _Step2(
                        key: const ValueKey(2),
                        formKey: _step2Key,
                        age: _age,
                        gender: _gender,
                        townCtrl: _townCtrl,
                        interestedIn: _interestedIn,
                        occupationCtrl: _occupationCtrl,
                        hobbiesCtrl: _hobbiesCtrl,
                        maritalStatus: _maritalStatus,
                        genders: _genders,
                        meetOptions: _meetOptions,
                        maritalOptions: _maritalOptions,
                        onAgeChanged: (v) => setState(() => _age = v),
                        onGenderChanged: (v) => setState(() => _gender = v),
                        onMeetToggled: (v) => setState(() {
                          _interestedIn.contains(v)
                              ? _interestedIn.remove(v)
                              : _interestedIn.add(v);
                        }),
                        onMaritalChanged: (v) =>
                            setState(() => _maritalStatus = v),
                        onBack: () => setState(() => _step = 1),
                        onSubmit: _submit,
                        loading: _loading,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Account credentials ─────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    super.key,
    required this.formKey,
    required this.nicknameCtrl,
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nicknameCtrl;
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.go('/sign-in'),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 28),
        _StepIndicator(current: 1, total: 2),
        const SizedBox(height: 20),
        Text(
          'Create your\nanonymous profile.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'Pick a nickname — your real name stays private until you spark.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white60,
            height: 1.5,
          ),
        ).animate(delay: 80.ms).fadeIn(),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // Real name row — revealed only on mutual spark
                Row(
                  children: [
                    Expanded(
                      child: VailField(
                        controller: firstNameCtrl,
                        label: 'FIRST NAME',
                        hint: 'e.g. Alex',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: VailField(
                        controller: lastNameCtrl,
                        label: 'LAST NAME',
                        hint: 'e.g. Smith',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '🔒 Only revealed if both of you spark',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: VailColors.inkLight,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                VailField(
                  controller: nicknameCtrl,
                  label: 'NICKNAME',
                  hint: 'e.g. MidnightFox',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.length < 3)
                      ? 'At least 3 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                VailField(
                  controller: emailCtrl,
                  label: 'EMAIL',
                  hint: 'your@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                VailField(
                  controller: passwordCtrl,
                  label: 'PASSWORD',
                  hint: '8+ characters',
                  icon: Icons.lock_outline_rounded,
                  obscure: obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: VailColors.inkLight,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  ),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'At least 8 characters'
                      : null,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: onNext,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue', style: VailTextStyles.button(context)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: 180.ms).fadeIn(duration: 400.ms).slideY(begin: 0.08),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/sign-in'),
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: GoogleFonts.inter(color: Colors.white60, fontSize: 14),
                children: [
                  TextSpan(
                    text: 'Sign in',
                    style: GoogleFonts.inter(
                      color: VailColors.rose,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Step 2: Profile details ──────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  const _Step2({
    super.key,
    required this.formKey,
    required this.age,
    required this.gender,
    required this.townCtrl,
    required this.interestedIn,
    required this.occupationCtrl,
    required this.hobbiesCtrl,
    required this.maritalStatus,
    required this.genders,
    required this.meetOptions,
    required this.maritalOptions,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onMeetToggled,
    required this.onMaritalChanged,
    required this.onBack,
    required this.onSubmit,
    this.loading = false,
  });

  final GlobalKey<FormState> formKey;
  final int? age;
  final String? gender;
  final TextEditingController townCtrl;
  final List<String> interestedIn;
  final TextEditingController occupationCtrl;
  final TextEditingController hobbiesCtrl;
  final String? maritalStatus;
  final List<String> genders;
  final List<String> meetOptions;
  final List<String> maritalOptions;
  final ValueChanged<int?> onAgeChanged;
  final ValueChanged<String?> onGenderChanged;
  final ValueChanged<String> onMeetToggled;
  final ValueChanged<String?> onMaritalChanged;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
            size: 20,
          ),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 28),
        _StepIndicator(current: 2, total: 2),
        const SizedBox(height: 20),
        Text(
          'Tell us a little\nabout yourself.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),
        Text(
          'This helps us connect you with the right people. Your identity stays anonymous.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white60,
            height: 1.5,
          ),
        ).animate(delay: 80.ms).fadeIn(),
        const SizedBox(height: 28),

        // ── Required fields card ────────────────────────────────────────────
        _SectionCard(
          title: 'Required',
          child: Form(
            key: formKey,
            child: Column(
              children: [
                // Age picker
                _FieldLabel(label: 'AGE'),
                const SizedBox(height: 8),
                _AgePicker(value: age, onChanged: onAgeChanged),
                const SizedBox(height: 4),
                if (age == null)
                  _ValidationHint(text: 'Please select your age'),
                const SizedBox(height: 20),

                // Gender
                _FieldLabel(label: 'I AM A'),
                const SizedBox(height: 8),
                _ChoiceGroup(
                  options: genders,
                  selected: gender != null ? [gender!] : [],
                  multiSelect: false,
                  onToggle: onGenderChanged,
                ),
                const SizedBox(height: 4),
                if (gender == null)
                  _ValidationHint(text: 'Please select a gender'),
                const SizedBox(height: 20),

                // Town
                VailField(
                  controller: townCtrl,
                  label: 'TOWN / CITY',
                  hint: 'e.g. Douala',
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your town'
                      : null,
                ),
                const SizedBox(height: 20),

                // Interested in meeting
                _FieldLabel(label: 'INTERESTED IN MEETING'),
                const SizedBox(height: 8),
                _ChoiceGroup(
                  options: meetOptions,
                  selected: interestedIn,
                  multiSelect: true,
                  onToggle: (v) => onMeetToggled(v!),
                ),
                const SizedBox(height: 4),
                if (interestedIn.isEmpty)
                  _ValidationHint(text: 'Select at least one option'),
              ],
            ),
          ),
        ).animate(delay: 150.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06),

        const SizedBox(height: 16),

        // ── Optional fields card ────────────────────────────────────────────
        _SectionCard(
          title: 'Optional — helps people know a bit more',
          child: Column(
            children: [
              VailField(
                controller: occupationCtrl,
                label: 'OCCUPATION',
                hint: 'e.g. Teacher, Designer…',
                icon: Icons.work_outline_rounded,
              ),
              const SizedBox(height: 16),
              VailField(
                controller: hobbiesCtrl,
                label: 'HOBBIES / INTERESTS',
                hint: 'e.g. Hiking, Jazz, Reading…',
                icon: Icons.star_outline_rounded,
              ),
              const SizedBox(height: 20),
              _FieldLabel(label: 'MARITAL STATUS'),
              const SizedBox(height: 8),
              _ChoiceGroup(
                options: maritalOptions,
                selected: maritalStatus != null ? [maritalStatus!] : [],
                multiSelect: false,
                onToggle: onMaritalChanged,
              ),
            ],
          ),
        ).animate(delay: 220.ms).fadeIn(duration: 350.ms).slideY(begin: 0.06),

        const SizedBox(height: 24),

        // Submit
        ElevatedButton(
          onPressed: loading
              ? null
              : () {
                  final formValid = formKey.currentState?.validate() ?? false;
                  if (formValid &&
                      age != null &&
                      gender != null &&
                      interestedIn.isNotEmpty) {
                    onSubmit();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: VailColors.rose,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Create Account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.08),

        const SizedBox(height: 40),
      ],
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: done
                  ? VailColors.rose
                  : active
                  ? Colors.white
                  : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: VailColors.inkLight,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Field label ──────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: VailColors.inkLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Validation hint ─────────────────────────────────────────────────────────

class _ValidationHint extends StatelessWidget {
  const _ValidationHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.red.shade400),
        ),
      ),
    );
  }
}

// ─── Age picker (scrollable drum) ─────────────────────────────────────────────

class _AgePicker extends StatefulWidget {
  const _AgePicker({required this.value, required this.onChanged});
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  State<_AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<_AgePicker> {
  static const _minAge = 18;
  static const _maxAge = 80;
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    final initial = widget.value != null
        ? (widget.value! - _minAge).clamp(0, _maxAge - _minAge)
        : 0;
    _ctrl = FixedExtentScrollController(initialItem: initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: VailColors.mist,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection highlight bar
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: VailColors.roseSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: VailColors.rose.withOpacity(0.3)),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _ctrl,
            itemExtent: 40,
            perspective: 0.004,
            diameterRatio: 2.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (i) => widget.onChanged(_minAge + i),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _maxAge - _minAge + 1,
              builder: (context, i) {
                final age = _minAge + i;
                final selected = widget.value == age;
                return Center(
                  child: Text(
                    '$age',
                    style: GoogleFonts.inter(
                      fontSize: selected ? 18 : 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? VailColors.rose : VailColors.inkLight,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Choice group (single or multi select pill chips) ─────────────────────────

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.options,
    required this.selected,
    required this.multiSelect,
    required this.onToggle,
  });

  final List<String> options;
  final List<String> selected;
  final bool multiSelect;
  final ValueChanged<String?> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? VailColors.rose : VailColors.mist,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected ? VailColors.rose : Colors.transparent,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : VailColors.inkLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Blob background decoration ───────────────────────────────────────────────

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1.06, 1.06),
          duration: 3000.ms,
          curve: Curves.easeInOut,
        );
  }
}
