import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/features/alerts/models/alert_item_data.dart';
import 'package:starke_app/features/alerts/widgets/alert_card.dart';
import 'package:starke_app/utils/ui_utils.dart';

/// Home-page "Alerts" section below the Weather Forecast: a header with
/// "View More" and a row of [AlertCard]s — the caller decides how many to pass.
class AlertsView extends StatelessWidget {
  final List<AlertItemData> alerts;
  final VoidCallback? onViewMore;

  const AlertsView({super.key, required this.alerts, this.onViewMore});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final colorScheme = UiUtils.getColorScheme(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(
                child: CustomTextLabel(
                  text: 'alerts',
                  textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.primaryContainer,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
              GestureDetector(
                onTap: onViewMore,
                child: CustomTextLabel(
                  text: 'viewMore',
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primaryContainer.withOpacity(0.7),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int i = 0; i < alerts.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 16.0),
                Expanded(child: AlertCard(item: alerts[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
