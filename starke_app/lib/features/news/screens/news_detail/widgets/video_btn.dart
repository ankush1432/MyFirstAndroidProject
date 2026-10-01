import 'package:flutter/material.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/core/routes/routes.dart';

Widget videoBtn(
    {required BuildContext context,
    required bool isFromBreak,
    NewsModel? model,
    BreakingNewsModel? breakModel}) {
  if ((breakModel != null && breakModel.contentValue != "") ||
      model != null && model.contentValue != null && model.contentValue != "") {
    return InkWell(
      child: SvgPictureWidget(
          assetName: 'videoPlay',
          height: 39,
          width: 39,
          assetColor: ColorFilter.mode(secondaryColor, BlendMode.srcIn)),

     
      onTap: () {
        Navigator.of(context).pushNamed(Routes.newsVideo,
            arguments: (!isFromBreak)
                ? {"from": 1, "model": model}
                : {
                    "from": 3,
                    "breakModel": breakModel,
                    "otherVideos": [],
                    "otherBreakingVideos": []
                  });
      },
    );
  } else {
    return const SizedBox.shrink();
  }
}
