import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/user_profile_service.dart';
import '../../core/widgets/vail_field.dart';
import 'user_profile.dart';

// ─── Profile Screen ───────────────────────────────────────────────────────────

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Null while loading from Firestore.
  UserProfile? _profile;
  bool _loadError = false;

  // We work on a local copy and only commit on Save.
  late UserProfile _draft;
  bool _editing = false;
  bool _saving = false;

  // Text controllers (initialised from draft)
  late TextEditingController _nicknameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _townCtrl;
  late TextEditingController _occupationCtrl;
  late TextEditingController _hobbiesCtrl;

  final _formKey = GlobalKey<FormState>();

  static const _genders = ['Man', 'Woman', 'Non-binary', 'Prefer not to say'];
  static const _meetOptions = ['Men', 'Women', 'Everyone'];
  static const _maritalOpts = [
    'Single',
    'Divorced',
    'Widowed',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Load from Firestore ─────────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final uid = UserProfileService.instance.currentUid;
      final profile = await UserProfileService.instance.fetchProfile(uid);
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _profile = profile;
          _initDraft(profile);
        });
      } else {
        setState(() => _loadError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  void _initDraft(UserProfile source) {
    _draft = source.copyWith(interestedIn: List.from(source.interestedIn));
    _nicknameCtrl = TextEditingController(text: _draft.nickname);
    _emailCtrl = TextEditingController(text: _draft.email);
    _townCtrl = TextEditingController(text: _draft.town);
    _occupationCtrl = TextEditingController(text: _draft.occupation);
    _hobbiesCtrl = TextEditingController(text: _draft.hobbies);
  }

  void _resetDraft() {
    if (_profile == null) return;
    _nicknameCtrl.dispose();
    _emailCtrl.dispose();
    _townCtrl.dispose();
    _occupationCtrl.dispose();
    _hobbiesCtrl.dispose();
    _initDraft(_profile!);
  }

  @override
  void dispose() {
    // Controllers may not be initialised if the profile never loaded.
    if (_profile != null) {
      _nicknameCtrl.dispose();
      _emailCtrl.dispose();
      _townCtrl.dispose();
      _occupationCtrl.dispose();
      _hobbiesCtrl.dispose();
    }
    super.dispose();
  }

  void _startEditing() => setState(() => _editing = true);

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _resetDraft();
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_draft.interestedIn.isEmpty) {
      _showSnack('Please select who you are interested in meeting.');
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = UserProfileService.instance.currentUid;
      await UserProfileService.instance.updateProfile(
        uid: uid,
        profile: _draft,
      );
      // Commit the draft back as the live profile.
      setState(() {
        _profile = _draft.copyWith(
          interestedIn: List.from(_draft.interestedIn),
        );
        _editing = false;
      });
      _showSnack('Profile saved ✨');
    } catch (_) {
      _showSnack('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 14)),
        backgroundColor: VailColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openAvatarPicker() async {
    final result = await showModalBottomSheet<({String style, String seed})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvatarPickerSheet(
        currentStyle: _draft.avatarStyle,
        currentSeed: _draft.avatarSeed,
      ),
    );
    if (result != null) {
      setState(() {
        _draft.avatarStyle = result.style;
        _draft.avatarSeed = result.seed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Loading state ───────────────────────────────────────────────────────
    if (_profile == null && !_loadError) {
      return const Scaffold(
        backgroundColor: VailColors.mist,
        body: Center(child: CircularProgressIndicator(color: VailColors.rose)),
      );
    }

    // ── Error state ─────────────────────────────────────────────────────────
    if (_loadError) {
      return Scaffold(
        backgroundColor: VailColors.mist,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: VailColors.inkLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load your profile.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: VailColors.inkLight,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loadError = false);
                  _loadProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: VailColors.mist,
      body: Stack(
        children: [
          // Gradient hero at the top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: VailColors.heroGradient,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        _buildAvatarSection(),
                        const SizedBox(height: 24),
                        _editing ? _buildEditForm() : _buildViewMode(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Full-screen saving overlay
          if (_saving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: VailColors.rose),
              ),
            ),
        ],
      ),
    );
  }

  // ── App bar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          Text(
            'My Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (!_editing)
            TextButton(
              onPressed: _startEditing,
              child: Text(
                'Edit',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: _cancelEditing,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: VailColors.rose,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Avatar section ──────────────────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _editing ? _openAvatarPicker : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow ring
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: VailColors.rose.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
              // Avatar circle
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                child: SvgPicture.network(
                  _draft.avatarUrl,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => Container(
                    color: VailColors.roseSoft,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: VailColors.rose,
                      ),
                    ),
                  ),
                ),
              ),
              // Edit badge
              if (_editing)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: VailColors.rose,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ).animate().scale(
          begin: const Offset(0.9, 0.9),
          curve: Curves.easeOutBack,
          duration: 500.ms,
        ),
        const SizedBox(height: 12),
        Text(
          _profile!.nickname,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.08),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 13,
              color: Colors.white54,
            ),
            const SizedBox(width: 3),
            Text(
              _profile!.town,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
            ),
          ],
        ).animate(delay: 150.ms).fadeIn(),
        if (_editing) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openAvatarPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Change avatar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── View mode ───────────────────────────────────────────────────────────────
  Widget _buildViewMode() {
    final p = _profile!;
    return Column(
      children: [
        _InfoCard(
          title: 'About Me',
          rows: [
            _InfoRow(
              icon: Icons.cake_outlined,
              label: 'Age',
              value: '${p.age}',
            ),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: 'I am a',
              value: p.gender,
            ),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Town',
              value: p.town,
            ),
            _InfoRow(
              icon: Icons.favorite_outline_rounded,
              label: 'Looking to meet',
              value: p.interestedIn.join(', '),
            ),
          ],
        ).animate(delay: 200.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 12),

        _InfoCard(
          title: 'More About Me',
          rows: [
            if (p.occupation.isNotEmpty)
              _InfoRow(
                icon: Icons.work_outline_rounded,
                label: 'Occupation',
                value: p.occupation,
              ),
            if (p.hobbies.isNotEmpty)
              _InfoRow(
                icon: Icons.star_outline_rounded,
                label: 'Hobbies',
                value: p.hobbies,
              ),
            if (p.maritalStatus.isNotEmpty)
              _InfoRow(
                icon: Icons.volunteer_activism_outlined,
                label: 'Status',
                value: p.maritalStatus,
              ),
          ],
          emptyLabel: 'No optional info added yet.',
        ).animate(delay: 260.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),

        const SizedBox(height: 12),

        _InfoCard(
          title: 'Account',
          rows: [
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: p.email,
            ),
          ],
        ).animate(delay: 310.ms).fadeIn(duration: 300.ms).slideY(begin: 0.05),
      ],
    );
  }

  // ── Edit form ───────────────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Account card
          _EditCard(
            title: 'Account',
            child: Column(
              children: [
                VailField(
                  controller: _nicknameCtrl,
                  label: 'NICKNAME',
                  hint: 'e.g. MidnightFox',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.length < 3)
                      ? 'At least 3 characters'
                      : null,
                  onChanged: (v) => _draft.nickname = v,
                ),
                const SizedBox(height: 16),
                VailField(
                  controller: _emailCtrl,
                  label: 'EMAIL',
                  hint: 'your@email.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                  onChanged: (v) => _draft.email = v,
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 12),

          // Identity card
          _EditCard(
            title: 'About Me',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('AGE'),
                const SizedBox(height: 8),
                _InlineAgePicker(
                  value: _draft.age,
                  onChanged: (v) =>
                      setState(() => _draft.age = v ?? _draft.age),
                ),
                const SizedBox(height: 20),
                _SectionLabel('I AM A'),
                const SizedBox(height: 8),
                _ChoiceChips(
                  options: _genders,
                  selected: [_draft.gender],
                  multiSelect: false,
                  onToggle: (v) =>
                      setState(() => _draft.gender = v ?? _draft.gender),
                ),
                const SizedBox(height: 20),
                VailField(
                  controller: _townCtrl,
                  label: 'TOWN / CITY',
                  hint: 'e.g. Cape Town',
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter your town'
                      : null,
                  onChanged: (v) => _draft.town = v,
                ),
                const SizedBox(height: 20),
                _SectionLabel('INTERESTED IN MEETING'),
                const SizedBox(height: 8),
                _ChoiceChips(
                  options: _meetOptions,
                  selected: _draft.interestedIn,
                  multiSelect: true,
                  onToggle: (v) {
                    if (v == null) {
                      return;
                    }
                    setState(() {
                      _draft.interestedIn.contains(v)
                          ? _draft.interestedIn.remove(v)
                          : _draft.interestedIn.add(v);
                    });
                  },
                ),
              ],
            ),
          ).animate(delay: 210.ms).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 12),

          // Optional card
          _EditCard(
            title: 'More About Me (optional)',
            child: Column(
              children: [
                VailField(
                  controller: _occupationCtrl,
                  label: 'OCCUPATION',
                  hint: 'e.g. Teacher, Designer…',
                  icon: Icons.work_outline_rounded,
                  onChanged: (v) => _draft.occupation = v,
                ),
                const SizedBox(height: 16),
                VailField(
                  controller: _hobbiesCtrl,
                  label: 'HOBBIES / INTERESTS',
                  hint: 'e.g. Hiking, Jazz, Reading…',
                  icon: Icons.star_outline_rounded,
                  onChanged: (v) => _draft.hobbies = v,
                ),
                const SizedBox(height: 20),
                _SectionLabel('MARITAL STATUS'),
                const SizedBox(height: 8),
                _ChoiceChips(
                  options: _maritalOpts,
                  selected: _draft.maritalStatus.isNotEmpty
                      ? [_draft.maritalStatus]
                      : [],
                  multiSelect: false,
                  onToggle: (v) =>
                      setState(() => _draft.maritalStatus = v ?? ''),
                ),
              ],
            ),
          ).animate(delay: 260.ms).fadeIn().slideY(begin: 0.05),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Save Changes',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar picker bottom sheet ───────────────────────────────────────────────

class _AvatarPickerSheet extends StatefulWidget {
  const _AvatarPickerSheet({
    required this.currentStyle,
    required this.currentSeed,
  });
  final String currentStyle;
  final String currentSeed;

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  // Curated styles that look great for a social app
  static const _styles = [
    (slug: 'lorelei', label: 'Lorelei'),
    (slug: 'avataaars', label: 'Avataaars'),
    (slug: 'miniavs', label: 'Miniavs'),
    (slug: 'pixel-art', label: 'Pixel Art'),
    (slug: 'bottts-neutral', label: 'Bottts'),
    (slug: 'croodles-neutral', label: 'Croodles'),
  ];

  // 12 seeds per style = 12 × 6 = 72 unique combos to browse
  static const _seedCount = 12;

  late String _selectedStyle;
  late String _selectedSeed;
  late List<String> _seeds;

  @override
  void initState() {
    super.initState();
    _selectedStyle = widget.currentStyle;
    _selectedSeed = widget.currentSeed;
    _seeds = _buildSeeds();
  }

  List<String> _buildSeeds() {
    final rng = Random(42); // fixed seed so re-opening gives same grid
    return List.generate(
      _seedCount,
      (i) => 'vail-$_selectedStyle-${rng.nextInt(9999) + i * 100}',
    );
  }

  void _pickStyle(String slug) {
    setState(() {
      _selectedStyle = slug;
      _seeds = _buildSeeds();
      // Keep current seed if it belongs to this style, else pick first
      if (!_seeds.contains(_selectedSeed)) {
        _selectedSeed = _seeds.first;
      }
    });
  }

  String _avatarUrl(String style, String seed) =>
      'https://api.dicebear.com/10.x/$style/svg?seed=$seed'
      '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf'
      '&backgroundType=gradientLinear';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: VailColors.inkLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Text(
                  'Choose Your Avatar',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: VailColors.ink,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context, (
                    style: _selectedStyle,
                    seed: _selectedSeed,
                  )),
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: VailColors.rose,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Style tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _styles.length,
              itemBuilder: (_, i) {
                final s = _styles[i];
                final active = s.slug == _selectedStyle;
                return GestureDetector(
                  onTap: () => _pickStyle(s.slug),
                  child: AnimatedContainer(
                    duration: 180.ms,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active ? VailColors.rose : VailColors.mist,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : VailColors.inkLight,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Avatar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _seedCount,
              itemBuilder: (_, i) {
                final seed = _seeds[i];
                final selected = seed == _selectedSeed;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSeed = seed);
                  },
                  child: AnimatedContainer(
                    duration: 180.ms,
                    decoration: BoxDecoration(
                      color: selected ? VailColors.roseSoft : VailColors.mist,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? VailColors.rose : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: VailColors.rose.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SvgPicture.network(
                        _avatarUrl(_selectedStyle, seed),
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: VailColors.rose,
                            ),
                          ),
                        ),
                      ),
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

// ─── View-mode widgets ────────────────────────────────────────────────────────

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows, this.emptyLabel});
  final String title;
  final List<_InfoRow> rows;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: VailColors.ink.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: VailColors.inkLight,
                letterSpacing: 1.1,
              ),
            ),
          ),
          if (rows.isEmpty && emptyLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                emptyLabel!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: VailColors.inkLight.withOpacity(0.5),
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((e) {
              final row = e.value;
              final last = e.key == rows.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(row.icon, size: 18, color: VailColors.rose),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: VailColors.inkLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: VailColors.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!last)
                    Divider(height: 1, indent: 52, color: VailColors.mist),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─── Edit-mode widgets ────────────────────────────────────────────────────────

class _EditCard extends StatelessWidget {
  const _EditCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: VailColors.ink.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: VailColors.inkLight,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _ChoiceChips extends StatelessWidget {
  const _ChoiceChips({
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
        final on = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: 180.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: on ? VailColors.rose : VailColors.mist,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: on ? VailColors.rose : Colors.transparent,
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? Colors.white : VailColors.inkLight,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InlineAgePicker extends StatefulWidget {
  const _InlineAgePicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int?> onChanged;

  @override
  State<_InlineAgePicker> createState() => _InlineAgePickerState();
}

class _InlineAgePickerState extends State<_InlineAgePicker> {
  static const _min = 18;
  static const _max = 80;
  late final FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(
      initialItem: (widget.value - _min).clamp(0, _max - _min),
    );
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
            onSelectedItemChanged: (i) => widget.onChanged(_min + i),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: _max - _min + 1,
              builder: (_, i) {
                final age = _min + i;
                final sel = widget.value == age;
                return Center(
                  child: Text(
                    '$age',
                    style: GoogleFonts.inter(
                      fontSize: sel ? 18 : 15,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? VailColors.rose : VailColors.inkLight,
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
