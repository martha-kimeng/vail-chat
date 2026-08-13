// ─── User profile model + in-memory store ────────────────────────────────────
// In a real app this would be persisted and fetched from a backend.
// Everything is mutable so the profile screen can update it in place.

class UserProfile {
  UserProfile({
    required this.nickname,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.town,
    required this.interestedIn,
    this.occupation = '',
    this.hobbies = '',
    this.maritalStatus = '',
    this.avatarStyle = 'lorelei',
    this.avatarSeed = 'vail-user-default',
  });

  String nickname;
  String email;
  String firstName;
  String lastName;
  int age;
  String gender;
  String town;
  List<String> interestedIn;
  String occupation;
  String hobbies;
  String maritalStatus;
  String avatarStyle; // DiceBear style slug
  String avatarSeed; // DiceBear seed string

  /// Constructs the DiceBear SVG URL for this profile's avatar.
  String get avatarUrl =>
      'https://api.dicebear.com/10.x/$avatarStyle/svg?seed=$avatarSeed'
      '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf&backgroundType=gradientLinear';

  UserProfile copyWith({
    String? nickname,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? town,
    List<String>? interestedIn,
    String? occupation,
    String? hobbies,
    String? maritalStatus,
    String? avatarStyle,
    String? avatarSeed,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      town: town ?? this.town,
      interestedIn: interestedIn ?? this.interestedIn,
      occupation: occupation ?? this.occupation,
      hobbies: hobbies ?? this.hobbies,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }
}

/// Global singleton — replaces a real state management solution for this demo.
final currentUser = UserProfile(
  nickname: 'MidnightFox',
  email: 'you@example.com',
  firstName: 'Midnight',
  lastName: 'Fox',
  age: 26,
  gender: 'Woman',
  town: 'Cape Town',
  interestedIn: ['Men', 'Women'],
  occupation: 'UX Designer',
  hobbies: 'Hiking, Jazz, Reading',
  maritalStatus: 'Single',
  avatarStyle: 'lorelei',
  avatarSeed: 'MidnightFox-42',
);
