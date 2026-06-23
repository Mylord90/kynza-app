# KYNZA — Convention Soft Delete

Référence : AGENT.md R12 (« Données jamais supprimées physiquement »).

- Toutes les tables métier possèdent une colonne `deleted_at TIMESTAMPTZ` (nullable, `NULL` = ligne active).
- Le code applicatif n'exécute **jamais** de `DELETE` SQL. Une "suppression" est toujours un `UPDATE ... SET deleted_at = NOW()`.
- Toute lecture côté client doit filtrer les lignes soft-deleted :
  ```dart
  await SupabaseService.from('bookings')
      .select()
      .filter('deleted_at', 'is', null);
  ```
- Les policies RLS qui exposent des données en lecture publique ou multi-rôle (ex. `salons_public_select`) incluent systématiquement `AND deleted_at IS NULL` dans leur `USING`.
- Réactivation (ex. reprise d'abonnement après expiration) = remettre `deleted_at = NULL` sur la ligne existante. L'historique complet reste immédiatement accessible — jamais de recréation depuis zéro.
- `activity_logs` est une exception : table append-only, sans colonne `deleted_at`, sans policy `UPDATE`/`DELETE` (l'audit trail ne se "supprime" jamais, même en soft delete).