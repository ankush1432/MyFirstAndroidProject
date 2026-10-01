import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/like_action.dart';
import 'package:starke_app/core/theme/theme_colors.dart';

import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/utils/ui_utils.dart';

Widget likeBtn(BuildContext context, NewsModel model) {
  return BlocBuilder<LikeAndDisLikeCubit, LikeAndDisLikeState>(
      bloc: context.read<LikeAndDisLikeCubit>(),
      builder: (context, likeAndDislikeState) {
        return BlocConsumer<UpdateLikeAndDisLikeStatusCubit,
                UpdateLikeAndDisLikeStatusState>(
            bloc: context.read<UpdateLikeAndDisLikeStatusCubit>(),
            listener: ((context, state) {
              onLikeStatusChanged(context, state, model);
            }),
            builder: (context, state) {
              final bool isLike = isNewsLiked(context, model);
              final bool isInProgress = isLikeInProgress(context, model);
              return Positioned.directional(
                  textDirection: Directionality.of(context),
                  top: MediaQuery.of(context).size.height / 2.90,
                  end: MediaQuery.of(context).size.width / 10.8,
                  child: Column(
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        onTap: () => onLikeTap(context, model),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(52.0),
                            child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 39,
                                  width: 39,
                                  decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 6,
                                            offset: const Offset(5.0, 5.0),
                                            color:
                                                UiUtils.getColorScheme(context)
                                                    .primaryContainer
                                                    .withOpacity(0.4),
                                            spreadRadius: 0),
                                      ],
                                      color: secondaryColor,
                                      shape: BoxShape.circle),
                                  child: isInProgress
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: UiUtils.showCircularProgress(
                                              true,
                                              Theme.of(context).primaryColor))
                                      : isLike
                                          ? const Icon(Icons.thumb_up_alt,
                                              color: darkSecondaryColor)
                                          : const Icon(Icons.thumb_up_off_alt,
                                              color: darkSecondaryColor),
                                ))),
                      ),
                      (model.totalLikes != null &&
                              model.totalLikes != "null" &&
                              model.totalLikes!.isNotEmpty)
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width / 7.5,
                              child: Padding(
                                padding:
                                    const EdgeInsetsDirectional.only(top: 5.0),
                                child: CustomTextLabel(
                                  text: ((int.tryParse(model.totalLikes!) ?? 0) >
                                          0)
                                      ? "${model.totalLikes!} ${UiUtils.getTranslatedLabel(context, 'likeLbl')}"
                                      : "",
                                  maxLines: 2,
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: UiUtils.getColorScheme(context)
                                              .primaryContainer
                                              .withOpacity(0.7)),
                                ),
                              ),
                            )
                          : const SizedBox.shrink()
                    ],
                  ));
            });
      });
}
