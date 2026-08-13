import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/conversation_service.dart';
import '../../core/date_service.dart';
import '../../core/theme.dart';

class BlindDateScreen extends StatefulWidget {
  const BlindDateScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  State<BlindDateScreen> createState() => _BlindDateScreenState();
}

class _BlindDateScreenState extends State<BlindDateScreen> {
  // Step 0 = pick type, 1 = pick time, 2 = confirm
  int _step = 0;
  _DateType? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _confirmed = false;
  bool _submitting = false;

  // Loaded from Firestore on init.
  List<String> _participants = [];
  bool _loadingParticipants = true;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
    _checkExistingProposal();
  }

  // ── Load conversation participants ────────────────────────────────────────

  Future<void> _loadParticipants() async {
    try {
      final doc = await ConversationService.instance.fetchConversation(
        widget.conversationId,
      );
      if (!mounted) return;
      setState(() {
        _participants = doc?.participants ?? [];
        _loadingParticipants = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingParticipants = false);
    }
  }

  // ── If a proposal already exists, jump to confirmed view ─────────────────

  Future<void> _checkExistingProposal() async {
    DateService.instance.proposalStream(widget.conversationId).listen((
      proposal,
    ) {
      if (!mounted || _confirmed) return;
      if (proposal != null) {
        // Map Firestore DateType back to the screen's _DateType.
        setState(() {
          _selectedType = _fromServiceType(proposal.dateType);
          _selectedDate = proposal.proposedDate;
          _selectedTime = _parseTime(proposal.proposedTime);
          _confirmed = true;
        });
      }
    });
  }

  // ── Submit proposal to Firestore ──────────────────────────────────────────

  Future<void> _submitProposal() async {
    if (_selectedType == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      await DateService.instance.createProposal(
        conversationId: widget.conversationId,
        participants: _participants,
        dateType: _toServiceType(_selectedType!),
        proposedDate: _selectedDate!,
        proposedTime: timeStr,
      );
      if (mounted) setState(() => _confirmed = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send proposal. Please try again.',
              style: GoogleFonts.inter(fontSize: 14),
            ),
            backgroundColor: VailColors.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Type conversion helpers ───────────────────────────────────────────────

  DateType _toServiceType(_DateType t) => switch (t) {
    _DateType.coffee => DateType.coffee,
    _DateType.dinner => DateType.dinner,
    _DateType.walk => DateType.walk,
    _DateType.activity => DateType.activity,
  };

  _DateType _fromServiceType(DateType t) => switch (t) {
    DateType.coffee => _DateType.coffee,
    DateType.dinner => _DateType.dinner,
    DateType.walk => _DateType.walk,
    DateType.activity => _DateType.activity,
  };

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 19, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 19,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // While loading participants, show a simple spinner so the gradient
    // background is still visible.
    if (_loadingParticipants) {
      return Scaffold(
        body: Stack(
          children: [
            const VailGradientBackground(child: SizedBox.expand()),
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const VailGradientBackground(child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: _step > 0 && !_confirmed
                            ? () => setState(() => _step--)
                            : () => context.go(
                                '/profile/${widget.conversationId}',
                              ),
                      ),
                      const Spacer(),
                      if (!_confirmed)
                        Text(
                          'Step ${_step + 1} of 3',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white60,
                          ),
                        ),
                    ],
                  ),
                ),

                // Step indicator
                if (!_confirmed) _StepIndicator(currentStep: _step),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _confirmed
                        ? _ConfirmedStep(
                            key: const ValueKey('confirmed'),
                            conversationId: widget.conversationId,
                            dateType: _selectedType!,
                            date: _selectedDate!,
                            time: _selectedTime!,
                          )
                        : switch (_step) {
                            0 => _PickTypeStep(
                              key: const ValueKey(0),
                              selected: _selectedType,
                              onSelect: (t) {
                                setState(() {
                                  _selectedType = t;
                                  _step = 1;
                                });
                              },
                            ),
                            1 => _PickTimeStep(
                              key: const ValueKey(1),
                              onPicked: (date, time) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedTime = time;
                                  _step = 2;
                                });
                              },
                            ),
                            _ => _ReviewStep(
                              key: const ValueKey(2),
                              dateType: _selectedType!,
                              date: _selectedDate!,
                              time: _selectedTime!,
                              submitting: _submitting,
                              onConfirm: _submitProposal,
                            ),
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ───────────────────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 3,
                    decoration: BoxDecoration(
                      color: done || active
                          ? VailColors.rose
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 6),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Date types ───────────────────────────────────────────────────────────────
enum _DateType { coffee, dinner, walk, activity }

class _DateTypeInfo {
  const _DateTypeInfo({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _DateType type;
  final IconData icon;
  final String title;
  final String subtitle;
}

const _dateTypes = [
  _DateTypeInfo(
    type: _DateType.coffee,
    icon: Icons.coffee_rounded,
    title: 'Coffee',
    subtitle: 'Low-key, easy to end or extend',
  ),
  _DateTypeInfo(
    type: _DateType.dinner,
    icon: Icons.restaurant_rounded,
    title: 'Dinner',
    subtitle: 'If you\'re feeling confident',
  ),
  _DateTypeInfo(
    type: _DateType.walk,
    icon: Icons.directions_walk_rounded,
    title: 'Walk',
    subtitle: 'Side by side — no awkward eye contact',
  ),
  _DateTypeInfo(
    type: _DateType.activity,
    icon: Icons.sports_esports_rounded,
    title: 'Activity',
    subtitle: 'Escape room, mini-golf, you name it',
  ),
];

// ─── Step 1: Pick date type ───────────────────────────────────────────────────
class _PickTypeStep extends StatelessWidget {
  const _PickTypeStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  final _DateType? selected;
  final ValueChanged<_DateType> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What kind of\nblind date?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 8),
          Text(
            'Both of you will see the same suggestion.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white60),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 28),
          ..._dateTypes.asMap().entries.map((entry) {
            final i = entry.key;
            final dt = entry.value;
            return _DateTypeCard(
                  info: dt,
                  selected: selected == dt.type,
                  onTap: () => onSelect(dt.type),
                )
                .animate(delay: (i * 80).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05);
          }),
        ],
      ),
    );
  }
}

class _DateTypeCard extends StatelessWidget {
  const _DateTypeCard({
    required this.info,
    required this.selected,
    required this.onTap,
  });
  final _DateTypeInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? VailColors.rose : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? VailColors.rose : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withOpacity(0.2)
                    : VailColors.rose.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                info.icon,
                color: selected ? Colors.white : VailColors.rose,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    info.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: selected ? Colors.white70 : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Pick time ────────────────────────────────────────────────────────
class _PickTimeStep extends StatefulWidget {
  const _PickTimeStep({super.key, required this.onPicked});
  final void Function(DateTime date, TimeOfDay time) onPicked;

  @override
  State<_PickTimeStep> createState() => _PickTimeStepState();
}

class _PickTimeStepState extends State<_PickTimeStep> {
  DateTime? _date;
  TimeOfDay? _time;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VailColors.rose,
            surface: Color(0xFF2D1B3D),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: VailColors.rose,
            surface: Color(0xFF2D1B3D),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When should\nit happen?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 8),
          Text(
            'Propose a date and time. They can accept or suggest another.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 32),
          _PickerTile(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _date == null
                ? 'Choose a day'
                : '${_date!.day}/${_date!.month}/${_date!.year}',
            onTap: _pickDate,
          ).animate(delay: 150.ms).fadeIn().slideX(begin: 0.05),
          const SizedBox(height: 12),
          _PickerTile(
            icon: Icons.access_time_rounded,
            label: 'Time',
            value: _time == null ? 'Choose a time' : _time!.format(context),
            onTap: _pickTime,
          ).animate(delay: 220.ms).fadeIn().slideX(begin: 0.05),
          const Spacer(),
          ElevatedButton(
            onPressed: (_date != null && _time != null)
                ? () => widget.onPicked(_date!, _time!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              disabledBackgroundColor: Colors.white12,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VailColors.rose.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: VailColors.rose, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white54,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Review ───────────────────────────────────────────────────────────
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.dateType,
    required this.date,
    required this.time,
    required this.onConfirm,
    this.submitting = false,
  });
  final _DateType dateType;
  final DateTime date;
  final TimeOfDay time;
  final VoidCallback onConfirm;
  final bool submitting;

  String get _typeLabel {
    return switch (dateType) {
      _DateType.coffee => 'Coffee',
      _DateType.dinner => 'Dinner',
      _DateType.walk => 'Walk',
      _DateType.activity => 'Activity',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Looks good?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            "We'll send this proposal to them. They can accept or counter-propose.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
            ),
          ).animate(delay: 100.ms).fadeIn(),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: VailColors.rose.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _ReviewRow(
                  icon: Icons.event_rounded,
                  label: 'Type',
                  value: _typeLabel,
                ),
                const Divider(color: Colors.white12, height: 24),
                _ReviewRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: '${date.day}/${date.month}/${date.year}',
                ),
                const Divider(color: Colors.white12, height: 24),
                _ReviewRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: time.format(context),
                ),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.06),
          const Spacer(),
          ElevatedButton(
            onPressed: submitting ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Send the proposal 💌',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ).animate(delay: 250.ms).fadeIn(),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: VailColors.rose, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Confirmed ────────────────────────────────────────────────────────────────
class _ConfirmedStep extends StatelessWidget {
  const _ConfirmedStep({
    super.key,
    required this.conversationId,
    required this.dateType,
    required this.date,
    required this.time,
  });
  final String conversationId;
  final _DateType dateType;
  final DateTime date;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: VailColors.rose.withOpacity(0.15),
                  border: Border.all(
                    color: VailColors.rose.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: VailColors.rose,
                  size: 52,
                ),
              )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(),
          const SizedBox(height: 28),
          Text(
            'Date proposal sent! 💌',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 14),
          Text(
            "They'll receive your proposal anonymously. Once they accept, both of you will get the full details.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white70,
              height: 1.6,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VailColors.rose,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Back to chats',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ).animate(delay: 400.ms).fadeIn(),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/chat/$conversationId'),
            child: Text(
              'Continue chatting',
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 15),
            ),
          ).animate(delay: 450.ms).fadeIn(),
        ],
      ),
    );
  }
}
