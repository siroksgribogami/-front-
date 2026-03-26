import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class IosPickerSheet {
  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    TimeOfDay? initialTime,
    bool use24hFormat = true,
    String title = 'Выберите время',
  }) async {
    final now = DateTime.now();
    DateTime tempDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      initialTime?.hour ?? now.hour,
      initialTime?.minute ?? now.minute,
    );

    TimeOfDay? result;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: 320,
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Отмена'),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        result = TimeOfDay(
                          hour: tempDateTime.hour,
                          minute: tempDateTime.minute,
                        );
                        Navigator.pop(ctx);
                      },
                      child: const Text('Готово'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: use24hFormat,
                  initialDateTime: tempDateTime,
                  onDateTimeChanged: (value) => tempDateTime = value,
                ),
              ),
            ],
          ),
        );
      },
    );

    return result;
  }
}

