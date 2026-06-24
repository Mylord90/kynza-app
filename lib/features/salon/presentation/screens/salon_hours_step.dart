import 'package:flutter/material.dart';
import '../../../../core/models/working_hour_model.dart';
import '../widgets/working_hours_editor.dart';

class SalonHoursStep extends StatelessWidget {
  const SalonHoursStep({
    super.key,
    required this.hours,
    required this.onChanged,
  });

  final List<WorkingHourModel> hours;
  final void Function(List<WorkingHourModel>) onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [WorkingHoursEditor(hours: hours, onChanged: onChanged)],
    );
  }
}
