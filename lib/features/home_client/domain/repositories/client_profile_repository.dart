abstract class ClientProfileRepository {
  Future<void> updateProfile({
    required String userId,
    required String fullName,
    String? phone,
    String? email,
  });
}
