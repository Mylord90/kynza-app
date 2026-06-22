# KYNZA — KNOWLEDGE.md

## PRODUCT
KYNZA — SaaS gestion & réservation salons de beauté. Marché V1 : Burundi (Bujumbura), devise BIF/FBu exclusive. Extension Afrique de l'Est prévue. Rôles : OWNER>MANAGER>STAFF>CLIENT, multi-tenant via `salon_id`. Principe non-custodial : KYNZA n'héberge jamais l'argent — Client paie via Leapa → Mobile Money Owner direct. KYNZA = miroir comptable read-only. Stack : Flutter + Supabase + Leapa API + Firebase FCM + Riverpod.

## DESIGN TOKENS
primary=#EAB308 (light:#D97706) | primary-variant=#CA8A04 (#B45309) | background=#09090B (#FAFAFA) | surface=#18181B (#FFFFFF) | surface-variant=#27272A (#F4F4F5) | border=#3F3F46 (#E4E4E7) | text-primary=#FAFAFA (#09090B) | text-secondary=#A1A1AA (#71717A) | success=#22C55E | error=#EF4444 | warning=#F97316
Gradient CTA : #EAB308→#D97706 à 135°. Règle 80/15/5 (noir/texte/or).
Typo (Plus Jakarta Sans/Inter) : H1=24px/700 · H2=18px/600 · H3=15px/500 · Body=14px/400 · Button=14px/600 · Badge=11px/700.
Spacing 8pt : xl=24 · lg=16 · md=12 · sm=8 · xs=4.
Radius : card=16dp · button=12dp · bottom-sheet=24dp(haut). Bouton CTA=48dp. Champ saisie=52dp. Chip horaire=32dp.
Anim : transition écran=200ms cubic-bezier(.16,1,.3,1) · tap=100ms linear · confirmation RDV=400ms ease-out · succès paiement=2s · upgrade plan=1.5s ease-in-out.

## ARCHITECTURE
Feature-first + Clean Architecture : Widget → Cubit/Notifier (Riverpod) → UseCase → Repository → DataSource (Supabase).
```
lib/core/{constants,theme,router,providers,models,services,utils,enums}
lib/shared/widgets/{KynzaButton,KynzaCard,KynzaSkeleton,KynzaToast,KynzaEmptyState,KynzaOfflineBanner,KynzaAmountWidget}
lib/features/{auth,home_owner,home_staff,home_client,payments,notifications,subscription}
```
Navigation : GoRouter, guards par rôle, deep links `/booking/:id` `/payment/:id`. Jamais de logique métier dans un widget (R09).

## DATABASE
```
salons(id,name,owner_id,plan,plan_status,country_code,currency=BIF,is_online,employees_count,deleted_at)
users(id=auth.uid(),salon_id,role,phone,full_name,email,email_verified,reliability_score=100,locale,deleted_at)
bookings(id,salon_id,client_id,practitioner_id,service_id,status,start_time,end_time,buffer_end_time,
         amount_bif,payment_status,deposit_required,idempotency_key UNIQUE,UNIQUE(practitioner_id,start_time))
transactions(id,salon_id,booking_id,leapa_reference UNIQUE,amount_bif,method,status,
             idempotency_key UNIQUE,confirmed_at,deleted_at)
services(id,salon_id,name,price_bif,duration_min,buffer_min,is_active,deleted_at)
subscriptions(id,salon_id,plan,status,expires_at,deleted_at)
loyalty_cards(id,salon_id,client_id,stamps,required,reward,expires_at)
activity_logs(id,salon_id,user_id,type_action,old_values JSONB,new_values JSONB,ip_address,created_at) -- APPEND-ONLY
```
RLS : `transactions`/`subscriptions`=owner only · `bookings` staff=`practitioner_id=auth.uid()` · `bookings` client=`client_id=auth.uid()` · `users`=self row only, `salon_id`/`role` immuables · `activity_logs`=SELECT owner only.
JWT claims : `{user_id,salon_id,role,plan_status,preferred_currency,country_code,email}`

## BOOKING ENGINE
États : `pending_payment→confirmed→in_progress→completed` | `confirmed→cancelled`(remboursement si P1) | `confirmed→no_show`(H+15min).
Priorités : P1=`CONFIRMED_PAID` (non déplaçable sans OTP, remboursement auto) · P2=`CONFIRMED` (déplaçable) · P3=`PENDING` (expire 30min, verrou paiement 5min) · P4=`WALK_IN` (sans garantie).
Race condition : `UNIQUE(practitioner_id,start_time)` + `SELECT FOR UPDATE` transaction atomique. 2e arrivé → alternatives proposées.
No-show : `reliability_score -= 1` par no-show. ≥3 no-shows → alert owner + `deposit_required=true` auto.
Buffer : `buffer_end_time = end_time + service.buffer_min`, invisible client, bloque uniquement planning praticien.
Fast-Pass "Réserver à nouveau" : 2 clics, service+praticien pré-remplis, direct étape Date&Heure.

## PAYMENTS
Flux : Flutter → Edge Function → Leapa API (idempotency_key obligatoire) → USSD push client (max 3min) → PIN → Webhook HMAC-SHA256 → Edge Fn → `transactions.status=completed` → Realtime (<300ms) → succès + Push + WhatsApp.
Idempotency key : `${bookingId}_${Math.floor(Date.now()/60000)}`.
États transaction : `pending→processing→completed|failed|reversed|expired`.
Méthodes V1 : Lumicash, EcoCash. V1.5 : eNoti (Bancobu). V2 : Carte bancaire.
Remboursement : >4h=100% auto · 2-4h=%config · <2h=0%(défaut) · manuel=OTP SMS owner obligatoire.
Jamais d'appel Leapa direct depuis Flutter (R16).

## SECURITY
1. `protect_user_columns` trigger : `salon_id`/`email_verified`/`reliability_score`/`role` immuables côté client.
2. `sync_email_verified` trigger : sync depuis `auth.users` uniquement.
3. `has_role(uid,role,salon_id?)` SECURITY INVOKER scope salon, utilisé dans toutes les policies sensibles.
4. `logs_self_insert_safe` : WITH CHECK `salon_id` cohérent + whitelist `type_action`.
5. REVOKE EXECUTE sur `handle_new_user`/`protect_user_columns`/`sync_email_verified`/`custom_access_token_hook`.
6. `users_self_update_safe` : WITH CHECK bloque colonnes sensibles même en UPDATE partiel.
7. HMAC-SHA256 vérifié sur chaque webhook Leapa avant tout traitement.

## RBAC
| Feature | Owner | Manager | Staff | Client |
|---|---|---|---|---|
| Wallet/CA global | ✅ | ❌ | ❌ | — |
| Agenda équipe | ✅ | ✅ | ses RDV | — |
| Créer/Annuler RDV | ✅ | ✅ | ses RDV | selon politique |
| Fiche client globale | ✅ | ✅ | ses clients | — |
| Encaisser | ✅ | ✅ | si permission | — |
| Marketing | ✅ | ✅ | ❌ | — |
| Gérer équipe | ✅ | ❌ | ❌ | — |
| Remise | 0-100% | max 15% loggé | ❌ | — |
| Remboursement | ✅ OTP | soumis owner | ❌ | — |
| Analytics | complet | restreint | ses stats | — |
| Réserver/Payer/Fidélité | — | — | — | ✅ |

## OFFLINE
R/W offline : agenda J+7, notes clients, nouveaux RDV, cash. R-only : historique 30j, fiches clients, KPIs. Réseau requis : paiement Mobile Money, push.
Ordre sync reconnexion : 1.Nouveaux RDV → 2.Statuts → 3.Cash → 4.Notes.
Conflit : Server-Wins systématique (Supabase = source de vérité).

## FREEMIUM
Gratuit=0 FBu, 20 RDV/mois max. Pro=45 000 FBu/mois, illimité, ≤10 praticiens. Premium=125 000 FBu/an, illimité + features exclusives.
Seuils : 15 RDV(75%)=bandeau ambre+CTA · 18 RDV(90%)=bandeau rouge+CTA fort · 20 RDV(100%)=blocage+modal upgrade.
Grâce : 3j après expiration, accès complet maintenu. Données jamais supprimées (R12), réactivation=accès immédiat.

## NOTIFICATIONS
WhatsApp Business API en premier canal, Push FCM en second. Jamais d'email opérationnel.
Anti-spam : max 2 promos/semaine/salon, max 50 msg WhatsApp/heure. Opt-out STOP/ARRET auto immédiat.
Rappels RDV : H-24 + H-2 (bouton Confirmer), max 2 occurrences.
Template confirmation : Nom salon · Service · Praticien · Date · Heure · Prix FBu · Adresse · Lien Maps · deep link modifier/annuler.

## RULES R01-R20
R01 Jamais d'argent hébergé, Leapa=intermédiaire agréé. R02 RLS partout, HTTP 403 non-owner. R03 Confirmation obligatoire avant action destructive (sauf R10). R04 Aucun écran vide sans CTA. R05 Max 3 actions/écran, max 3 taps. R06 Feedback <1s sur toute action. R07 Offline=bandeau gris non bloquant, boutons réseau grisés. R08 BIF uniquement, jamais USD/EUR. R09 Score fiabilité local au salon, actif après ≥3 RDV. R10 Confirmer arrivée=action directe SANS pop-up. R11 Classement staff=position uniquement, jamais montants collègues. R12 Anti-spam max 2 promos/semaine/salon. R13 Opt-out WhatsApp auto sur STOP/ARRET. R14 Données jamais supprimées, réactivation=accès total. R15 Interface Caméléon Solo↔Team via AnimatedSwitcher 400ms. R16 Idempotency key obligatoire sur tout paiement. R17 Remboursement=OTP SMS owner obligatoire. R18 Buffer time invisible client. R19 Staff max 15% remise, >5% loggé dans activity_logs. R20 Session staff expire 7j inactivité, révocation owner instantanée.
