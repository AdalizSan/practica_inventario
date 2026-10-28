class Profile {
  const Profile({
    required this.store,
    required this.responsible,
    required this.currency,
  });
  final String store, responsible, currency;
}

abstract interface class ProfileRepository {
  Future<Profile?> getProfile();
  Future<void> saveProfile(Profile profile);
}
