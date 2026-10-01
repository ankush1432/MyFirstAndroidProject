import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/utils/ui_utils.dart';

Widget tagView(
    {required NewsModel model,
    required BuildContext context,
    bool? isFromDetailsScreen = false}) {
  List<String> tagList = [];

  if (model.tagName! != "") {
    final tagName = model.tagName!;
    tagList = tagName.split(',');
  }

  List<String> tagId = [];

  if (model.tagId != null && model.tagId! != "") {
    tagId = model.tagId!.split(",");
  }

  return model.tagName! != ""
      ? SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(tagList.length, (index) {
              return Padding(
                  padding:
                      EdgeInsetsDirectional.only(start: index == 0 ? 0 : 7),
                  child: InkWell(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(3.0),
                        child: (isFromDetailsScreen != null &&
                                isFromDetailsScreen)
                            ? tagsContainer(
                                context: context,
                                tagList: tagList,
                                index: index)
                            : BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                                child: tagsContainer(
                                    context: context,
                                    tagList: tagList,
                                    index: index))),
                    onTap: () {
                      if (index >= tagId.length || tagId[index].isEmpty) return;
                      Navigator.of(context).pushNamed(Routes.tagScreen,
                          arguments: {
                            "tagId": tagId[index],
                            "tagName": tagList[index]
                          });
                    },
                  ));
            }),
          ),
        )
      : const SizedBox.shrink();
}

Widget tagsContainer(
    {required BuildContext context,
    required List<String> tagList,
    required int index}) {
  return Container(
      height: 30.0,
      alignment: Alignment.center,
      padding: const EdgeInsetsDirectional.only(
          start: 9.0, end: 9.0, top: 1.0, bottom: 1.0),
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          color: UiUtils.getColorScheme(context).outline.withAlpha(60)),
      child: CustomTextLabel(
          text: tagList[index],
          textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: UiUtils.getColorScheme(context).primaryContainer,
              fontSize: 12),
          overflow: TextOverflow.ellipsis,
          softWrap: true));
}
