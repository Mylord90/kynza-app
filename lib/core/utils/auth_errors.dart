String getAuthErrorMessage(Object? error) {
  final msg = error?.toString().toLowerCase() ?? '';
  if (msg.contains('invalid_credentials')) {
    return 'Email ou mot de passe incorrect.';
  }
  if (msg.contains('email_not_confirmed')) {
    return 'Vérifiez votre email avant de continuer.';
  }
  if (msg.contains('user_already_exists')) return 'Cet email est déjà utilisé.';
  if (msg.contains('weak_password')) {
    return 'Mot de passe trop faible (8 car. min, 1 majuscule, 1 chiffre).';
  }
  if (msg.contains('rate_limit') || msg.contains('too_many')) {
    return 'Trop de tentatives. Attendez quelques minutes.';
  }
  if (msg.contains('network') || msg.contains('socket')) {
    return 'Erreur réseau. Vérifiez votre connexion.';
  }
  if (msg.contains('provider is not enabled')) {
    return 'Ce service est temporairement indisponible.';
  }
  if (msg.contains('missing oauth secret')) {
    return 'Configuration OAuth incomplète.';
  }
  if (msg.contains('popup_closed') || msg.contains('cancelled')) {
    return 'Connexion annulée.';
  }
  if (msg.contains('expired')) {
    return 'Ce lien a expiré. Faites une nouvelle demande.';
  }
  return 'Une erreur est survenue. Réessayez.';
}
