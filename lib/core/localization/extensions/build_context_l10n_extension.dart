import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

/// Accès ergonomique aux traductions : context.l10n.commonCancel
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
