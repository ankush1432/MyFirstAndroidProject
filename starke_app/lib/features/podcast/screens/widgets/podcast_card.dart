// The one channel row: cover, title and the listener / episode counts. 65px on the
// home section, 93px in the dashboard and the author's list.

import 'package:flutter/material.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/features/podcast/screens/widgets/podcast_deactive_notice.dart';
import 'package:starke_app/utils/ui_utils.dart';

class PodcastCardData {
  final String? id;
  final String? slug;
  final String imageUrl;
  final String title;
  final String? description;

  final String listenersCount;

  final String episodesCount;

  final String authorName;
  final String authorImageUrl;
  final bool isFollowed;

  /// `status == "1"` on the API. Only the author's own list ever carries a
  /// deactivated channel — the public lists never return one — so this stays
  /// true everywhere else.
  final bool isActive;

  const PodcastCardData({
    this.id,
    this.slug,
    required this.imageUrl,
    required this.title,
    this.description,
    required this.listenersCount,
    required this.episodesCount,
    this.authorName = '',
    this.authorImageUrl = '',
    this.isFollowed = false,
    this.isActive = true,
  });
}

class PodcastCard extends StatelessWidget {
  final PodcastCardData data;
  final VoidCallback? onTap;

  final double imageSize;

  final Widget? trailing;

  const PodcastCard(
      {super.key,
      required this.data,
      this.onTap,
      this.imageSize = 65,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = UiUtils.getColorScheme(context);
    // A deactivated channel has no detail page to open — the badge is the only
    // thing the row does.
    return GestureDetector(
      onTap: data.isActive ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: colorScheme.primaryContainer.withOpacity(0.1),
              width: 0.678),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomNetworkImage(
                  networkImageUrl: data.imageUrl,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 22.3 / 16,
                        letterSpacing: 0.1018,
                        color: colorScheme.primaryContainer,
                      )),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _stat(context, 'podcast_listeners', data.listenersCount),
                      const SizedBox(width: 8),
                      _stat(context, 'podcast_episodes', data.episodesCount),
                    ],
                  ),
                  if (!data.isActive) ...[
                    const SizedBox(height: 6),
                    const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PodcastDeactiveBadge()),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String iconName, String value) {
    final colorScheme = UiUtils.getColorScheme(context);
    final mutedColor = colorScheme.primaryContainer.withOpacity(0.7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPictureWidget(
            assetName: iconName,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            assetColor: ColorFilter.mode(mutedColor, BlendMode.srcIn)),
        const SizedBox(width: 4),
        Text(value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 16 / 11,
              letterSpacing: 0.5,
              color: mutedColor,
            )),
      ],
    );
  }
}
