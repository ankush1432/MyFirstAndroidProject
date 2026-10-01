import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/utils/ui_utils.dart';

Widget titleView({required String title, required BuildContext context}) {
  return Padding(
      padding: const EdgeInsetsDirectional.only(top: 6.0),
      child: CustomTextLabel(
          text: title,
          textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
              fontWeight: FontWeight.w600)));
}
