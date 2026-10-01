import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/utils/ui_utils.dart';

Widget dateView(BuildContext context, String date) {
  return Row(
    children: [
      const Icon(Icons.access_time_filled_rounded, size: 15),
      const SizedBox(width: 3),
      CustomTextLabel(
          text: UiUtils.formatMyDateTime(DateTime.parse(date)),
          textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: UiUtils.getColorScheme(context)
                  .primaryContainer
                  .withOpacity(0.8),
              fontSize: 12.0,
              fontWeight: FontWeight.w600))
    ],
  );
}
