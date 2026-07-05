import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/states/auth_ui_state.dart';
import '../notifiers/auth_notifier.dart';

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthUiState>(
  AuthNotifier.new,
);
