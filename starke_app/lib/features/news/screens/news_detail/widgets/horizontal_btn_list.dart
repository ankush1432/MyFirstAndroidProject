import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starke_app/commons/widgets/font_size_bottom_sheet.dart';
import 'package:starke_app/commons/widgets/vertical_dotted_divider.dart';
import 'package:starke_app/features/authentication/cubits/auth_cubit.dart';
import 'package:starke_app/features/bookmarks/cubits/update_bookmark_cubit.dart';
import 'package:starke_app/features/bookmarks/cubits/bookmark_cubit.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/like_and_dislike_cubit.dart';
import 'package:starke_app/features/news/cubits/like_and_dislike_news/update_like_and_dislike_cubit.dart';
import 'package:starke_app/features/news/screens/news_detail/widgets/like_action.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/features/news/models/breaking_news_model.dart';
import 'package:starke_app/features/news/models/news_model.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/snackbar_widget.dart';
import 'package:starke_app/utils/ui_utils.dart';

Widget allRowBtn(
    {required bool isFromBreak,
    required BuildContext context,
    BreakingNewsModel? breakModel,
    NewsModel? model,
    required int fontVal,
    required ValueChanged<int> updateFont,
    required bool isPlaying,
    required Function speak,
    required Function stop,
    required Function updateComEnabled}) {
  return !isFromBreak
      ? Container(
          height: 72,
          width: double.maxFinite,
          decoration:
              BoxDecoration(color: UiUtils.getColorScheme(context).surface),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              if (context.read<AppConfigurationCubit>().getCommentsMode() ==
                  "1")
                Expanded(
                  child: actionItem(
                    onTap: () {
                      if (model!.isCommentEnabled != null &&
                          model.isCommentEnabled == 0) {
                        //comments disabled by Admin
                        showSnackBar(
                            UiUtils.getTranslatedLabel(
                                context, "disabledCommentsMsg"),
                            context);
                      } else {
                        updateComEnabled(true);
                      }
                    },
                    icon: SvgPictureWidget(
                        assetName: "comment",
                        height: 24,
                        assetColor: ColorFilter.mode(
                            UiUtils.getColorScheme(context).primaryContainer,
                            BlendMode.srcIn)),
                    title: CustomTextLabel(
                        text: 'comLbl',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        textStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: UiUtils.getColorScheme(context)
                                    .primaryContainer
                                    .withOpacity(0.8),
                                fontSize: 9.0)),
                  ),
                ),
              const VerticalDottedDivider(),
              Flexible(child: likeBtn(context, model!)),
              const VerticalDottedDivider(),
              Expanded(child: bookmarkBtn(context, model)),
              const VerticalDottedDivider(),
              Expanded(
                child: actionItem(
                  onTap: () {
                    // Applies to this article only — never written to storage.
                    changeFontSizeSheet(context,
                        fontSize: fontVal, onFontSizeChanged: updateFont);
                  },
                  icon: SvgPictureWidget(
                      assetName: "text_size",
                      height: 24,
                      assetColor: ColorFilter.mode(
                          UiUtils.getColorScheme(context).primaryContainer,
                          BlendMode.srcIn)),
                  title: CustomTextLabel(
                    text: "txtSizeLbl",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.8),
                        fontSize: 9.0),
                  ),
                ),
              ),
              const VerticalDottedDivider(),
              Expanded(
                  child: speakBtn(
                      context, model, breakModel, isPlaying, speak, stop)),
            ],
          ))
      : Container(
          height: 72,
          width: double.maxFinite,
          decoration:
              BoxDecoration(color: UiUtils.getColorScheme(context).surface),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: actionItem(
                  onTap: () {
                    // Applies to this article only — never written to storage.
                    changeFontSizeSheet(context,
                        fontSize: fontVal, onFontSizeChanged: updateFont);
                  },
                  icon: SvgPictureWidget(
                      assetName: "text_size",
                      height: 24,
                      assetColor: ColorFilter.mode(
                          UiUtils.getColorScheme(context).primaryContainer,
                          BlendMode.srcIn)),
                  title: CustomTextLabel(
                    text: "txtSizeLbl",
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.8),
                        fontSize: 9.0),
                  ),
                ),
              ),
              const VerticalDottedDivider(),
              Expanded(
                child: speakBtn(
                    context, model, breakModel, isPlaying, speak, stop),
              ),
            ],
          ));
}

Widget speakBtn(
    BuildContext context,
    NewsModel? model,
    BreakingNewsModel? breakModel,
    bool isPlaying,
    Function speak,
    Function stop) {
  return actionItem(
    onTap: () {
      if (isPlaying) {
        stop();
      } else {
        final textTospeak = breakModel != null
            ? "${breakModel.title}\n${breakModel.desc}"
            : "${model!.title}\n${model.desc}";

        final document =
            parse(textTospeak); //Speak Title along with Description
        String parsedString = parse(document.body!.text).documentElement!.text;
        speak(parsedString);
      }
    },
    icon: SvgPictureWidget(
        assetName: "speak",
        height: 24,
        assetColor: ColorFilter.mode(
            isPlaying
                ? Theme.of(context).primaryColor
                : UiUtils.getColorScheme(context).primaryContainer,
            BlendMode.srcIn)),
    title: CustomTextLabel(
      text: "speakLoudLbl",
      maxLines: 2,
      textAlign: TextAlign.center,
      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
          color:
              UiUtils.getColorScheme(context).primaryContainer.withOpacity(0.8),
          fontSize: 9.0),
    ),
  );
}

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
              return actionItem(
                onTap: () => onLikeTap(context, model),
                icon: SvgPictureWidget(
                    assetName: isLike ? "like_filled" : "like",
                    height: 24,
                    assetColor: ColorFilter.mode(
                        UiUtils.getColorScheme(context).primaryContainer,
                        BlendMode.srcIn)),
                title: Wrap(
                  children: [
                    (model.totalLikes != null &&
                            model.totalLikes != "null" &&
                            model.totalLikes!.isNotEmpty)
                        ? SizedBox(
                            child: CustomTextLabel(
                              text: ((int.tryParse(model.totalLikes!) ?? 0) > 0)
                                  ? "${model.totalLikes!} "
                                  : "",
                              maxLines: 1,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: UiUtils.getColorScheme(context)
                                          .primaryContainer
                                          .withOpacity(0.7),
                                      fontSize: 9.0),
                            ),
                          )
                        : const SizedBox.shrink(),
                    CustomTextLabel(
                      text: UiUtils.getTranslatedLabel(context, 'likeLbl'),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      textStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: UiUtils.getColorScheme(context)
                                  .primaryContainer
                                  .withOpacity(0.8),
                              fontSize: 9.0),
                    ),
                  ],
                ),
              );
            });
      });
}

Widget bookmarkBtn(BuildContext context, NewsModel model) {
  return BlocBuilder<BookmarkCubit, BookmarkState>(
      bloc: context.read<BookmarkCubit>(),
      builder: (context, bookmarkState) {
        bool isBookmark =
            context.read<BookmarkCubit>().isNewsBookmark(model.newsId!);
        return BlocConsumer<UpdateBookmarkStatusCubit,
                UpdateBookmarkStatusState>(
            bloc: context.read<UpdateBookmarkStatusCubit>(),
            listener: ((context, state) {
              if (state is UpdateBookmarkStatusSuccess) {
                if (state.wasBookmarkNewsProcess) {
                  context.read<BookmarkCubit>().addBookmarkNews(state.news);
                } else {
                  context.read<BookmarkCubit>().removeBookmarkNews(state.news);
                }
              }
              isBookmark =
                  context.read<BookmarkCubit>().isNewsBookmark(model.newsId!);
            }),
            builder: (context, state) {
              return actionItem(
                onTap: () {
                  if (context.read<AuthCubit>().getUserId() != "0") {
                    if (state is UpdateBookmarkStatusInProgress) {
                      return;
                    }
                    context.read<UpdateBookmarkStatusCubit>().setBookmarkNews(
                        news: model, status: (isBookmark) ? "0" : "1");
                  } else {
                    UiUtils.loginRequired(context);
                  }
                },
                icon: SvgPictureWidget(
                    assetName: (isBookmark) ? "save_filled" : "save",
                    height: 24,
                    assetColor: ColorFilter.mode(
                        UiUtils.getColorScheme(context).primaryContainer,
                        BlendMode.srcIn)),
                title: CustomTextLabel(
                  text: "saveLbl",
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UiUtils.getColorScheme(context)
                          .primaryContainer
                          .withOpacity(0.8),
                      fontSize: 9.0),
                ),
              );
            });
      });
}

setSpeakBtn(BuildContext context, bool isPlaying) {
  return SizedBox(
    width: MediaQuery.of(context).size.width * 0.13,
    child: Column(
      children: [
        Icon(Icons.speaker_phone_rounded,
            color: isPlaying
                ? Theme.of(context).primaryColor
                : UiUtils.getColorScheme(context).primaryContainer),
        Padding(
            padding: const EdgeInsetsDirectional.only(top: 4.0),
            child: CustomTextLabel(
                text: 'speakLoudLbl',
                maxLines: 2,
                textAlign: TextAlign.center,
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPlaying
                        ? Theme.of(context).primaryColor
                        : UiUtils.getColorScheme(context)
                            .primaryContainer
                            .withOpacity(0.8),
                    fontSize: 9.0)))
      ],
    ),
  );
}

Widget actionItem({
  required Widget icon,
  required Widget title,
  VoidCallback? onTap,
}) {
  return Center(
    child: InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: title,
          )
        ],
      ),
    ),
  );
}
