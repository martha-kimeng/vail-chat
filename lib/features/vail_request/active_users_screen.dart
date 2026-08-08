import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'vail_request_models.dart';

// ─── Active Users Screen ──────────────────────────────────────────────────────
// Shows who is currently online / reachable. The user can filter by gender,
// age group and location, then tap any card to send a Vail Request.

class ActiveUsersScreen extends StatefulWidget {
  const ActiveUsersScreen({super.key});

  @override
  State<ActiveUsersScreen> createState() => _ActiveUsersScreenState();
}

class _ActiveUsersScreenState extends State<ActiveUsersScreen> {
  // ── filter state ─────────────────────────────────────────────────────────
  Gender _genderFilter = Gender.any;
  AgeGroup _ageFilter = AgeGroup.any;
  String _locationFilter = 'Any';
  bool _onlineOnly = true;
  final _searchCtrl = TextEditingController();

  static const _locations = [
    'Any',
    'Cape Town',
    'Johannesburg',
    'Durban',
    'Pretoria',
    'George',
    'Port Elizabeth',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ActiveUser> get _filtered {
    final query = _searchCtrl.text.trim().toLowerCase();
    return mockActiveUsers.where((u) {
      if (_onlineOnly && !u.isOnline) {
        return false;
      }
      if (_genderFilter != Gender.any && u.gender != _genderFilter) {
        return false;
      }
      if (_ageFilter != AgeGroup.any && u.ageGroup != _ageFilter) {
        return false;
      }
      if (_locationFilter != 'Any' && u.location != _locationFilter) {
        return false;
      }
      if (query.isNotEmpty &&
          !u.alias.toLowerCase().contains(query) &&
          !u.location.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _hasActiveFilters =>
      _genderFilter != Gender.any ||
      _ageFilter != AgeGroup.any ||
      _locationFilter != 'Any' ||
      !_onlineOnly;

  void _clearFilters() => setState(() {
    _genderFilter = Gender.any;
    _ageFilter = AgeGroup.any;
    _locationFilter = 'Any';
    _onlineOnly = true;
    _searchCtrl.clear();
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: VailColors.mist,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            _buildFilterRow(),
            const SizedBox(height: 4),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmpty()
                  : _buildUserList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: VailColors.ink,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Who\'s Here',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: VailColors.ink,
                ),
              ),
              Text(
                'Send a Vail Request to someone new',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: VailColors.inkLight,
                ),
              ),
            ],
          ),
          const Spacer(),
          // online count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: VailColors.online.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: VailColors.online,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${mockActiveUsers.where((u) => u.isOnline).length} online',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: VailColors.online,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(fontSize: 14, color: VailColors.ink),
        decoration: InputDecoration(
          hintText: 'Search by alias or city…',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: VailColors.inkLight,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: VailColors.inkLight,
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: VailColors.inkLight,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _searchCtrl.clear()),
                )
              : null,
          filled: true,
          fillColor: VailColors.mist,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── filter row ──────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: VailColors.mist),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Filter',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: VailColors.inkLight,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: _clearFilters,
                  child: Text(
                    'Clear all',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: VailColors.rose,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipWidget<Gender>(
                  label: 'Gender',
                  value: _genderFilter,
                  items: const [
                    (Gender.any, 'Any'),
                    (Gender.female, 'Women'),
                    (Gender.male, 'Men'),
                    (Gender.nonBinary, 'Non-binary'),
                  ],
                  onSelected: (v) => setState(() => _genderFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterChipWidget<AgeGroup>(
                  label: 'Age',
                  value: _ageFilter,
                  items: const [
                    (AgeGroup.any, 'Any age'),
                    (AgeGroup.teens, '13–19'),
                    (AgeGroup.twenties, '20s'),
                    (AgeGroup.thirties, '30s'),
                    (AgeGroup.forties, '40s'),
                    (AgeGroup.fiftyPlus, '50+'),
                  ],
                  onSelected: (v) => setState(() => _ageFilter = v),
                ),
                const SizedBox(width: 8),
                _FilterChipWidget<String>(
                  label: 'Location',
                  value: _locationFilter,
                  items: _locations.map((l) => (l, l)).toList(),
                  onSelected: (v) => setState(() => _locationFilter = v),
                ),
                const SizedBox(width: 8),
                // Online-only toggle chip
                GestureDetector(
                  onTap: () => setState(() => _onlineOnly = !_onlineOnly),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _onlineOnly
                          ? VailColors.online.withOpacity(0.12)
                          : VailColors.mist,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _onlineOnly
                            ? VailColors.online
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _onlineOnly
                                ? VailColors.online
                                : VailColors.inkLight,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Online now',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _onlineOnly
                                ? VailColors.online
                                : VailColors.inkLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── user list ───────────────────────────────────────────────────────────────
  Widget _buildUserList(List<ActiveUser> users) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: users.length,
      itemBuilder: (context, i) {
        return _UserCard(user: users[i])
            .animate(delay: (i * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.06, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: VailColors.inkLight.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No one matches those filters',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: VailColors.inkLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try broadening your search',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: VailColors.inkLight.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _clearFilters,
            child: Text(
              'Clear filters',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: VailColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Generic filter chip with bottom sheet picker ─────────────────────────────

class _FilterChipWidget<T> extends StatelessWidget {
  const _FilterChipWidget({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
  });

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onSelected;

  bool get _isActive => value != items.first.$1;

  String get _displayLabel {
    for (final (v, l) in items) {
      if (v == value) return l;
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _isActive ? VailColors.roseSoft : VailColors.mist,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isActive ? VailColors.rose : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              _isActive ? _displayLabel : label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isActive ? VailColors.rose : VailColors.inkLight,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: _isActive ? VailColors.rose : VailColors.inkLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: VailColors.ink,
                ),
              ),
            ),
            const Divider(height: 1),
            ...items.map((item) {
              final (v, l) = item;
              final selected = v == value;
              return ListTile(
                title: Text(
                  l,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? VailColors.rose : VailColors.ink,
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: VailColors.rose)
                    : null,
                onTap: () {
                  onSelected(v);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});
  final ActiveUser user;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vail-request/send/${user.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: VailColors.ink.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: user.avatarColor.withOpacity(0.15),
                    border: Border.all(
                      color: user.avatarColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      user.alias[0],
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: user.avatarColor,
                      ),
                    ),
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: VailColors.online,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.alias,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: VailColors.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!user.isOnline)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VailColors.away.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Away',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: VailColors.away,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.bio,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: VailColors.inkLight,
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      _Tag(
                        icon: Icons.location_on_outlined,
                        label: user.location,
                      ),
                      if (user.genderLabel.isNotEmpty)
                        _Tag(
                          icon: Icons.person_outline_rounded,
                          label: user.genderLabel,
                        ),
                      if (user.ageGroupLabel.isNotEmpty)
                        _Tag(
                          icon: Icons.cake_outlined,
                          label: user.ageGroupLabel,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // CTA arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VailColors.roseSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: VailColors.rose,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: VailColors.inkLight.withOpacity(0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: VailColors.inkLight.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
