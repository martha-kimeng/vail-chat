// ─── Vail Request — shared models & mock data ────────────────────────────────
//
// In a real app these would be fetched from a backend. For this prototype
// everything lives here so every screen can import from one place.

import 'package:flutter/material.dart';

// ─── Active user (someone you can send a Vail Request to) ────────────────────

enum Gender { any, male, female, nonBinary }

enum AgeGroup { any, teens, twenties, thirties, forties, fiftyPlus }

class ActiveUser {
  const ActiveUser({
    required this.id,
    required this.alias,
    required this.gender,
    required this.ageGroup,
    required this.location,
    required this.avatarColor,
    required this.isOnline,
    this.bio = '',
  });

  final String id;
  final String alias; // Anonymous handle — never a real name
  final Gender gender;
  final AgeGroup ageGroup;
  final String location; // Town / city
  final Color avatarColor;
  final bool isOnline;
  final String bio;

  String get genderLabel => switch (gender) {
    Gender.male => 'Man',
    Gender.female => 'Woman',
    Gender.nonBinary => 'Non-binary',
    Gender.any => '',
  };

  String get ageGroupLabel => switch (ageGroup) {
    AgeGroup.teens => '13–19',
    AgeGroup.twenties => '20s',
    AgeGroup.thirties => '30s',
    AgeGroup.forties => '40s',
    AgeGroup.fiftyPlus => '50+',
    AgeGroup.any => '',
  };
}

// ─── Vail Request ─────────────────────────────────────────────────────────────

enum VailRequestStatus {
  pending, // Waiting for receiver to respond
  unveiled, // Receiver accepted — chat is now open
  declined, // Receiver declined
}

class VailRequest {
  VailRequest({
    required this.id,
    required this.senderId,
    required this.senderAlias,
    required this.senderAvatarColor,
    required this.receiverId,
    required this.sentAt,
    this.heartCount = 1,
    this.status = VailRequestStatus.pending,
  });

  final String id;
  final String senderId;
  final String senderAlias;
  final Color senderAvatarColor;
  final String receiverId;
  final DateTime sentAt;
  int heartCount; // How many times the sender has tapped the request
  VailRequestStatus status;

  /// The automated message shown on the request card.
  String get vailMessage =>
      'A stranger stands behind the veil, hoping you will lift it. '
      'Will you unveil?';

  /// Sub-label that scales with heart count.
  String get insistenceLabel {
    if (heartCount >= 10) {
      return 'Absolutely enchanted by you \u2728';
    }
    if (heartCount >= 7) {
      return 'Really, really hoping you will unveil \u{1F4AB}';
    }
    if (heartCount >= 4) {
      return 'Genuinely curious about you \u{1F339}';
    }
    return 'Sending you a gentle knock \u{1FA84}';
  }
}

// ─── Mock data ────────────────────────────────────────────────────────────────

final mockActiveUsers = <ActiveUser>[
  const ActiveUser(
    id: 'u1',
    alias: 'MidnightSage',
    gender: Gender.female,
    ageGroup: AgeGroup.twenties,
    location: 'Yaoundé',
    avatarColor: Color(0xFF9B59B6),
    isOnline: true,
    bio: 'Books, late-night walks, and too much coffee.',
  ),
  const ActiveUser(
    id: 'u2',
    alias: 'OakAndIron',
    gender: Gender.male,
    ageGroup: AgeGroup.thirties,
    location: 'Douala',
    avatarColor: Color(0xFF4A90D9),
    isOnline: true,
    bio: 'Woodworker by day, philosopher by night.',
  ),
  const ActiveUser(
    id: 'u3',
    alias: 'VelvetStorm',
    gender: Gender.nonBinary,
    ageGroup: AgeGroup.twenties,
    location: 'Bafoussam',
    avatarColor: Color(0xFF27AE60),
    isOnline: true,
    bio: 'Art, music, and the spaces in between.',
  ),
  const ActiveUser(
    id: 'u4',
    alias: 'CrimsonTide',
    gender: Gender.female,
    ageGroup: AgeGroup.thirties,
    location: 'Bamenda',
    avatarColor: Color(0xFFE8516A),
    isOnline: false,
    bio: 'Neuroscientist who loves terrible puns.',
  ),
  const ActiveUser(
    id: 'u5',
    alias: 'FrostAndFire',
    gender: Gender.male,
    ageGroup: AgeGroup.twenties,
    location: 'Limbe',
    avatarColor: Color(0xFF16A085),
    isOnline: true,
    bio: 'Surfer, chef, overthinker.',
  ),
  const ActiveUser(
    id: 'u6',
    alias: 'AuroraVeil',
    gender: Gender.female,
    ageGroup: AgeGroup.forties,
    location: 'Buea',
    avatarColor: Color(0xFFE67E22),
    isOnline: true,
    bio: 'Still figuring it all out, and loving it.',
  ),
  const ActiveUser(
    id: 'u7',
    alias: 'SilverEcho',
    gender: Gender.male,
    ageGroup: AgeGroup.fiftyPlus,
    location: 'Garoua',
    avatarColor: Color(0xFF7F8C8D),
    isOnline: false,
    bio: 'Stories, scars, and a good sense of humour.',
  ),
  const ActiveUser(
    id: 'u8',
    alias: 'CobaltDream',
    gender: Gender.nonBinary,
    ageGroup: AgeGroup.teens,
    location: 'Kribi',
    avatarColor: Color(0xFF2980B9),
    isOnline: true,
    bio: 'Just discovering the world, one weird idea at a time.',
  ),
];

/// Requests incoming to the current user (mock "me").
/// In a real app this would be a stream from the backend.
final mockIncomingRequests = <VailRequest>[
  VailRequest(
    id: 'vr1',
    senderId: 'u2',
    senderAlias: 'OakAndIron',
    senderAvatarColor: const Color(0xFF4A90D9),
    receiverId: 'me',
    sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
    heartCount: 3,
  ),
  VailRequest(
    id: 'vr2',
    senderId: 'u5',
    senderAlias: 'FrostAndFire',
    senderAvatarColor: const Color(0xFF16A085),
    receiverId: 'me',
    sentAt: DateTime.now().subtract(const Duration(minutes: 35)),
    heartCount: 7,
  ),
  VailRequest(
    id: 'vr3',
    senderId: 'u8',
    senderAlias: 'CobaltDream',
    senderAvatarColor: const Color(0xFF2980B9),
    receiverId: 'me',
    sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    heartCount: 1,
  ),
];
