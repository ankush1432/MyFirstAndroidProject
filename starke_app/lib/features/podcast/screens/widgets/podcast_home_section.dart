// The "Podcast" block on the home screen. Hides itself when there is nothing to
// show; "View More" opens PodcastDashboardScreen.

import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/features/podcast/screens/widgets/podcast_card.dart';
import 'package:starke_app/utils/ui_utils.dart';

class PodcastHomeSection extends StatelessWidget {
  final String title;
  final List<PodcastCardData> podcasts;
  final VoidCallback? onViewMoreTap;
  final void Function(PodcastCardData podcast)? onPodcastTap;

  const PodcastHomeSection({
    super.key,
    required this.title,
    required this.podcasts,
    this.onViewMoreTap,
    this.onPodcastTap,
  });

  @override
  Widget build(BuildContext context) {
    if (podcasts.isEmpty) return const SizedBox.shrink();

    final colorScheme = UiUtils.getColorScheme(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                    letterSpacing: 0.15,
                    color: colorScheme.primaryContainer,
                  )),
            ),
            GestureDetector(
              onTap: onViewMoreTap,
              child: CustomTextLabel(
                  text: 'viewMore',
                  textStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    letterSpacing: 0.25,
                    decoration: TextDecoration.underline,
                    decorationColor: colorScheme.primaryContainer.withOpacity(0.7),
                    color: colorScheme.primaryContainer.withOpacity(0.7),
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < podcasts.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          PodcastCard(
              data: podcasts[i],
              onTap: onPodcastTap == null
                  ? null
                  : () => onPodcastTap!(podcasts[i])),
        ],
      ],
    );
  }
}
