# KYNZA SKILL — AI CODING RULES | Version 1.0 | Lire avant toute intervention

> Domaine : guide opérationnel pour tout agent IA — règles R01-R20 illustrées, patterns interdits, templates de réponse par type de tâche.
> C'est le fichier le plus "méta" des 10 skills — il indique comment se comporter, pas seulement quoi coder.

## 1. Règles R01-R20 — exemples bon vs mauvais

### R01 — Jamais d'argent hébergé
```dart
// ❌ MAUVAIS — vocabulaire et logique de néo-banque
class WalletBalance { double kynzaBalance; void withdraw(double amount) { ... } }

// ✅ BON — miroir comptable read-only, l'argent ne passe jamais par KYNZA
class RevenueSummary { final int totalCollectedBif; final int pendingBif; const RevenueSummary(...); }
```

### R02 — RLS partout, salon_id depuis le JWT
```dart
// ❌ MAUVAIS — le client décide de quel salon il veut lire
await supabase.from('bookings').select().eq('salon_id', userInputSalonId);

// ✅ BON — la policy RLS filtre déjà côté serveur via auth.jwt(), le client ne fait que demander "mes données"
await supabase.from('bookings').select(); // RLS applique automatiquement salon_id = jwt.salon_id
```

### R06 — BIF uniquement
```dart
// ❌ MAUVAIS
Text('\$${(amountBif / 2700).toStringAsFixed(2)}'); // conversion USD inventée dans l'UI

// ✅ BON
KynzaAmountWidget(amountBif: amountBif); // formaté "45 000 FBu", jamais d'autre devise affichée
```

### R08 — Idempotency key obligatoire
```dart
// ❌ MAUVAIS — aucune protection contre le double-tap
onPressed: () => leapaService.initiatePayment(bookingId);

// ✅ BON
final key = buildIdempotencyKey(bookingId);
onPressed: isLoading ? null : () => leapaService.initiatePayment(bookingId, idempotencyKey: key);
```

### R10 — Confirmer arrivée SANS pop-up
```dart
// ❌ MAUVAIS — viole R10 explicitement
KynzaButton(label: 'Confirmer arrivée', onPressed: () => showConfirmDialog(onConfirm: markArrived));

// ✅ BON — action directe
KynzaButton(label: 'Confirmer arrivée', onPressed: markArrived);
```

### R11 — Jamais les montants des collègues
```dart
// ❌ MAUVAIS
class TeamRanking { final List<StaffRevenue> rankedByRevenue; } // expose amountBif par collègue

// ✅ BON
class TeamRanking { final int myPosition; final int teamSize; } // position uniquement
```

### R12 — Soft delete uniquement
```sql
-- ❌ MAUVAIS
DELETE FROM services WHERE id = $1;

-- ✅ BON
UPDATE services SET deleted_at = now() WHERE id = $1;
```

### R13 — Performance device bas de gamme
```dart
// ❌ MAUVAIS
ListView(children: salons.map((s) => SalonCard(s)).toList()); // tout rendu d'un coup
BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: ...);

// ✅ BON
ListView.builder(itemCount: salons.length, itemBuilder: (_, i) => SalonCard(salons[i]));
Container(color: AppColors.glassSurface, child: ...); // glassmorphism émulé, pas de blur réel
```

### R16 — Jamais d'appel Leapa direct
```dart
// ❌ MAUVAIS — clé API exposée côté client
final res = await http.post(Uri.parse('https://api.leapa.bi/v1/payments'), headers: {'Authorization': 'Bearer $leapaKey'});

// ✅ BON
final res = await supabase.functions.invoke('create-payment', body: {'bookingId': id, 'method': 'lumicash'});
```

### R18 — Buffer time invisible client
```dart
// ❌ MAUVAIS — montre le vrai créneau interne avec le tampon au client
Text('Disponible jusqu\'à ${booking.bufferEndTime}');

// ✅ BON — le client ne voit que la disponibilité nette, le buffer reste un détail serveur
Text('Disponible jusqu\'à ${booking.endTime}');
```

## 2. Patterns interdits — avec alternative correcte

| Interdit | Pourquoi | Alternative |
|---|---|---|
| Logique métier dans un `Widget.build()` | Viole Clean Architecture (R09), intestable | UseCase + Notifier |
| `Color(0xFF...)` inline | Viole design system centralisé (R19) | `AppColors.xxx` |
| `salon_id` reçu comme paramètre de fonction côté serveur sans vérification JWT | Faille d'autorisation horizontale (IDOR) | Toujours dériver de `auth.jwt()->>'salon_id'` |
| `try { ... } catch (e) {}` silencieux sur une écriture financière | Perte silencieuse de données / d'erreurs critiques | Logger, re-throw typé, ou mettre en Outbox si offline |
| Nouvelle table sans `deleted_at` | Viole R12, suppression irréversible | Toujours `deleted_at TIMESTAMPTZ` |
| `Future.delayed` pour simuler un appel réseau en dev | Masque les vrais états loading/error en test | Toujours appeler le vrai client Supabase, même en environnement dev |
| Pop-up de confirmation ajoutée "par cohérence" sur une action déjà classée R10 | Contredit une règle produit explicite | Vérifier section 1 de ce fichier avant d'ajouter un `showDialog` |

## 3. Checklist avant de soumettre du code KYNZA

1. Le code respecte-t-il la couche à laquelle il appartient (Widget/Notifier/UseCase/Repository/DataSource) ?
2. Toute couleur vient-elle de `AppColors` ?
3. Toute table modifiée a-t-elle une policy RLS à jour ?
4. Tout montant affiché passe-t-il par `KynzaAmountWidget` (BIF, mode confidentiel respecté) ?
5. Tout paiement a-t-il un idempotency key et passe-t-il par une Edge Function ?
6. L'écran couvre-t-il les 5 états UI (loading/error/empty/offline/data) ?
7. Une action destructive déclenche-t-elle une confirmation (sauf R10) ?
8. Une suppression est-elle un `UPDATE deleted_at` et jamais un `DELETE` ?
9. Un Staff peut-il, via ce code, voir une donnée financière d'un collègue ou de l'Owner ? Si oui → bug bloquant.
10. Le nom "SalonYawe" apparaît-il quelque part dans le diff ? Si oui → à corriger avant tout commit.

## 4. Guide — Edge Function vs appel direct Supabase

| Situation | Edge Function obligatoire | Appel direct (`supabase.from(...)`) acceptable |
|---|---|---|
| Lecture simple filtrée par RLS (agenda, fiches clients) | Non | ✅ |
| Création/modification d'un paiement | ✅ Toujours | ❌ Jamais |
| Remboursement | ✅ Toujours (OTP + Leapa Payout) | ❌ |
| Calcul nécessitant une clé secrète (HMAC, signature, appel tiers) | ✅ Toujours | ❌ |
| Révocation de session, changement de rôle | ✅ Toujours (SECURITY DEFINER restreint) | ❌ |
| Mise à jour d'une note technique client | Non | ✅ (RLS suffit, pas de secret impliqué) |
| Envoi WhatsApp/SMS | ✅ Toujours (token Meta/Twilio côté serveur) | ❌ |
| Webhook entrant (Leapa, autre fournisseur) | ✅ Toujours | — (n'est jamais appelé par le client) |

Règle de décision rapide : **dès qu'un secret, un calcul de confiance (idempotence, signature) ou un effet de bord financier est impliqué → Edge Function.** Sinon, RLS + appel direct suffit et est préférable (latence plus faible, moins de code à maintenir).

## 5. Répartition des responsabilités par couche

| Couche | Porte la responsabilité de | Ne porte jamais |
|---|---|---|
| Widget | Affichage, état UI local (animation, focus) | Logique métier, calculs, accès réseau |
| Notifier/Cubit | Orchestration d'un écran, état asynchrone | Règles métier complexes, accès SQL direct |
| UseCase | Règle métier unitaire et testable (ex. `ApplyDiscountUseCase`) | Détails de transport (HTTP, Supabase) |
| Repository | Contrat d'accès aux données, mapping erreurs → `Failure` | Logique métier |
| DataSource | I/O brut (Supabase, Hive, API tierce) | Toute décision métier |
| RLS / Triggers Postgres | Autorisation et invariants de données au niveau le plus bas | UX, formatage |
| Edge Function | Opérations sensibles nécessitant un secret ou un effet de bord financier | Rendu UI |

## 6. Templates de réponse — tâches courantes

### "Créer un nouvel écran"
1. Identifier la feature (`lib/features/xxx`) et le rôle autorisé.
2. Créer `domain/entities`, `domain/usecases` si nouvelle règle métier.
3. Créer le `Notifier` avec un état `sealed class` couvrant les 5 cas UI.
4. Créer le `screen` avec un `switch` exhaustif sur cet état.
5. Ajouter la route dans `core/router/routes.dart` + guard de rôle si nécessaire.
6. Vérifier les tokens de couleur/spacing utilisés contre `kynza-uiux-design-system.md`.

### "Ajouter une table Supabase"
1. Écrire la migration SQL avec `salon_id` + `deleted_at` (sauf table globale type `salons`).
2. Activer RLS, écrire au moins une policy `SELECT` par rôle concerné (cf. `kynza-supabase-backend.md` §3).
3. Ajouter les index nécessaires (`salon_id` minimum).
4. Si table contient une colonne sensible analogue à `users` : étendre `protect_user_columns` si pertinent.
5. Écrire la suite de test RLS correspondante (`kynza-testing-quality.md`).
6. Documenter la table dans `KNOWLEDGE.md` si elle devient une table core durable.

### "Nouveau flux de paiement / remboursement"
1. Vérifier si une Edge Function existante peut être étendue avant d'en créer une nouvelle.
2. Générer l'idempotency key au format standard (`kynza-payments-leapa.md` §3).
3. Valider toute entrée externe (webhook) par HMAC avant traitement.
4. Écrire les messages UX en respectant le tableau anti-stress (jamais de code HTTP brut).
5. Logger l'opération dans `activity_logs` si elle est sensible (remboursement, remise).
6. Tester explicitement les cas timeout et double-tap avant de livrer.

## 7. Erreurs les plus fréquentes constatées sur ce type de projet

1. **Oublier le filtre `deleted_at IS NULL`** dans un nouveau `SELECT` — la donnée "supprimée" réapparaît dans l'UI.
2. **Recréer une logique de remise/calcul de prix** dans un widget au lieu de réutiliser un UseCase existant — dérive de cohérence entre écrans.
3. **Confondre Manager et Owner** sur l'accès au Wallet — toujours vérifier la matrice RBAC (`KNOWLEDGE.md`) avant d'écrire une condition de rôle.
4. **Ajouter un état de chargement générique** (`CircularProgressIndicator` seul plein écran) au lieu du skeleton shimmer obligatoire (R04).
5. **Stocker un montant en `double`** au lieu d'`int` pour `amount_bif` — le BIF n'a pas de sous-unité décimale utilisée en pratique, les erreurs d'arrondi flottant sont une source de bugs comptables.
6. **Oublier le debounce 300ms** sur un listener Realtime — rafales d'updates qui font clignoter l'UI.
7. **Tester uniquement le cas Owner** sur une nouvelle feature multi-rôle, en repoussant "plus tard" les tests Staff/Client — toujours écrire les 4 perspectives dès la conception.
