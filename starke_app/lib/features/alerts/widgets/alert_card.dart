import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/features/alerts/models/alert_item_data.dart';
import 'package:starke_app/utils/ui_utils.dart';

/// A single alert card, shared by the home [AlertsView] row and [AlertsScreen].
/// IPO rows have no trend, so they render without the arrow or trend color.

const Color kAlertUpColor = Color(0xff3A960C);

class AlertCard extends StatelessWidget {
  final AlertItemData item;

  const AlertCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    final bool hasTrend = item.hasTrend;
    // A 0.00% row keeps its percent text but drops the arrow and trend color.
    final bool showTrend = hasTrend && !item.isFlat;
    final Color trendColor = !showTrend
        ? colorScheme.primaryContainer
        : (item.isUp ? kAlertUpColor : Theme.of(context).primaryColor);
    final String valueText = hasTrend ? item.changeText : item.ipoPriceText;
    final String subValueText = hasTrend ? item.priceText : item.alertType;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 3.0, color: colorScheme.primaryContainer),
            Expanded(
              child: Container(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: CustomTextLabel(
                        text: item.name,
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: colorScheme.primaryContainer,
                                fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (showTrend) ...<Widget>[
                          Icon(
                              item.isUp
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 24.0,
                              color: trendColor),
                          const SizedBox(width: 8.0),
                        ],
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            CustomTextLabel(
                              text: valueText,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                      color: trendColor,
                                      fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            CustomTextLabel(
                              text: subValueText,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: colorScheme.primaryContainer),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
