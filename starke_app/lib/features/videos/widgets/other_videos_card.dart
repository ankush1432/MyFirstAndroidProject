import 'package:flutter/material.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/live_streaming/models/live_streaming_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/network_image.dart';
import 'package:starke_app/utils/ui_utils.dart';

class OtherVideosCard extends StatelessWidget {
  final NewsModel? model;
  final BreakingNewsModel? brModel;
  final LiveStreamingModel? liveModel;
  OtherVideosCard({super.key, this.model, this.brModel, this.liveModel});

  @override
  Widget build(BuildContext context) {
    bool isLive = liveModel != null;
    return InkWell(
      splashColor: Colors.transparent,
      onTap: () {
        bool isNews = (model != null) ? true : false;
        bool isBreakingNews = (brModel != null) ? true : false;
        // bool isLive = (liveModel != null) ? true : false;
        int fromVal = (isNews)
            ? 1
            : (isBreakingNews
                ? 2
                : 3); // VAL 1 = news, 2 = liveNews , 3 = breakingNews
        // and pass current model accordingly.Do not pass other videos - set it from newsVideo screen only
        Map<String, dynamic> videoArguments = {
          "from": fromVal,
        };
        if (fromVal == 1) {
          videoArguments.addAll({"model": model});
        } else if (fromVal == 2) {
          videoArguments.addAll({"brModel": brModel});
        } else {
          videoArguments.addAll({"liveModel": liveModel});
        }
        Navigator.pushReplacementNamed(context, Routes.newsVideo,
            arguments: videoArguments);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
            color: UiUtils.getColorScheme(context).surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dividerColor.withAlpha(70))),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              height: 60,
              width: 90,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomNetworkImage(
                      networkImageUrl: (isLive)
                          ? liveModel!.image!
                          : (model != null)
                              ? model!.image!
                              : brModel!.image!,
                      height: 60,
                      width: 90,
                      fit: BoxFit.cover)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (!isLive &&
                          (model != null &&
                              model!.categoryName != null &&
                              model!.categoryName!.isNotEmpty))
                      ? Container(
                          height: 25.0,
                          width: 85,
                          alignment: Alignment.center,
                          margin: const EdgeInsetsDirectional.only(
                              start: 2.0, end: 2.0, top: 1.0, bottom: 1.0),
                          decoration: BoxDecoration(
                              color: UiUtils.getColorScheme(context)
                                  .onPrimary
                                  .withAlpha(40),
                              borderRadius: BorderRadius.circular(5)),
                          child: CustomTextLabel(
                              text: model!.categoryName ?? "",
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: UiUtils.getColorScheme(context)
                                          .onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              softWrap: true))
                      : SizedBox.shrink(),
                  SizedBox(height: 4),
                  CustomTextLabel(
                      text: (isLive)
                          ? liveModel!.title!
                          : (model != null)
                              ? model!.title ?? ""
                              : brModel!.title ?? "",
                      textStyle: TextStyle(
                          color: UiUtils.getColorScheme(context).onPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
