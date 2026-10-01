import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:starke_app/features/dynamic_pages/cubits/privacy_terms_cubit.dart';
import 'package:starke_app/features/language/cubits/app_localization_cubit.dart';
import 'package:starke_app/features/language/cubits/language_cubit.dart';
import 'package:starke_app/features/language/cubits/language_json_cubit.dart';
import 'package:starke_app/commons/cubits/setting_cubit.dart';
import 'package:starke_app/commons/widgets/svg_picture_widget.dart';
import 'package:starke_app/core/theme/app_theme.dart';
import 'package:starke_app/core/theme/theme_colors.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/error_container_widget.dart';
import 'package:starke_app/core/error_handler/error_message_keys.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/core/routes/routes.dart';
import 'package:starke_app/commons/cubits/app_system_setting_cubit.dart';
import 'package:starke_app/core/constants/hive_box_keys.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    fetchAppConfigurations();
  }

  fetchAppConfigurations() {
    context.read<AppConfigurationCubit>().fetchAppConfiguration();
  }

  fetchLanguages({required AppConfigurationFetchSuccess state}) async {
    String currentLanguage =
        Hive.box(settingsBoxKey).get(currentLanguageCodeKey) ?? "";
    //state.appConfiguration.defaultLangDataModel!.code ?? ""; //
    if (currentLanguage == "" &&
        state.appConfiguration.defaultLangDataModel != null) {
      context.read<AppLocalizationCubit>().changeLanguage(
          state.appConfiguration.defaultLangDataModel!.code!,
          state.appConfiguration.defaultLangDataModel!.id!,
          state.appConfiguration.defaultLangDataModel!.isRTL!);
      context.read<LanguageJsonCubit>().fetchCurrentLanguageAndLabels(
          state.appConfiguration.defaultLangDataModel!.code!);
    } else {
      context
          .read<LanguageJsonCubit>()
          .fetchCurrentLanguageAndLabels(currentLanguage);
    }
  }

  @override
  void dispose() {
    // _splashIconController!.dispose();
    // _newsImgController!.dispose();
    // _slideControllerBottom!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Set UiOverlayStyle to dark - due to the fixed (navy) splash background the
    //status bar icons must stay white. AnnotatedRegion is used instead of an
    //imperative setSystemUIOverlayStyle() call in build() because the latter
    //can be reset on the next frame, leaving the icons dark on the navy bg.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: UiUtils.overlayStyleForTheme(AppTheme.Dark),
      child: Scaffold(
          backgroundColor: Theme.of(context).secondaryHeaderColor,
          body: buildScale()),
    );
  }

  Future<void> navigationPage() async {
    Future.delayed(const Duration(seconds: 4), () async {
      final currentSettings = context.read<SettingsCubit>().state.settingsModel;
      if (context.read<AppConfigurationCubit>().getMaintenanceMode() == "1") {
        //app is in maintenance mode - no function should be performed
        Navigator.of(context).pushReplacementNamed(Routes.maintenance);
      } else if (currentSettings!.showIntroSlider) {
        Navigator.of(context).pushReplacementNamed(Routes.introSlider);
      } else {
        Navigator.of(context)
            .pushReplacementNamed(Routes.home, arguments: false);
      }
    });
  }

  Widget buildScale() {
    return BlocConsumer<AppConfigurationCubit, AppConfigurationState>(
        bloc: context.read<AppConfigurationCubit>(),
        listener: (context, state) {
          if (state is AppConfigurationFetchSuccess) {
            fetchLanguages(state: state);
            context.read<PrivacyTermsCubit>().getPrivacyTerms(
                langCode:
                    context.read<AppLocalizationCubit>().state.languageCode);
          }
        },
        builder: (context, state) {
          return BlocConsumer<LanguageJsonCubit, LanguageJsonState>(
              bloc: context.read<LanguageJsonCubit>(),
              listener: (context, state) {
                if (state is LanguageJsonFetchSuccess) {
                  navigationPage();
                  context
                      .read<LanguageCubit>()
                      .getLanguage(); //Load languages for dynamic link
                }
              },
              builder: (context, langState) {
                if (state is AppConfigurationFetchFailure) {
                  return ErrorContainerWidget(
                    errorMsg: (state.errorMessage
                            .contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : state.errorMessage,
                    onRetry: () {
                      fetchAppConfigurations();
                    },
                  );
                } else if (langState is LanguageJsonFetchFailure) {
                  return ErrorContainerWidget(
                    errorMsg: (langState.errorMessage
                            .contains(ErrorMessageKeys.noInternet))
                        ? UiUtils.getTranslatedLabel(context, 'internetmsg')
                        : langState.errorMessage,
                    onRetry: () {
                      fetchLanguages(
                          state: state as AppConfigurationFetchSuccess);
                    },
                  );
                } else {
                  return Container(
                    width: double.maxFinite,
                    decoration: const BoxDecoration(color: darkSecondaryColor),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 220),
                      splashLogoIcon(),
                      newsTextIcon(),
                      subTitle(),
                      const Spacer(),
                      bottomText()
                    ]),
                  );
                }
              });
        });
  }

  Widget splashLogoIcon() {
    return Center(
        child: SvgPictureWidget(
            assetName: "splash_icon", height: 110.0, fit: BoxFit.fill));
  }

  Widget newsTextIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
          child: SvgPictureWidget(
              assetName: "news", height: 25.0, fit: BoxFit.fill)),
    );
  }

  Widget subTitle() => CustomTextLabel(
      text: 'fastTrendNewsLbl',
      textAlign: TextAlign.center,
      textStyle: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(color: backgroundColor, fontWeight: FontWeight.bold));

  Widget bottomText() => Container(
      margin: const EdgeInsetsDirectional.only(bottom: 20),
      child: SvgPictureWidget(
          assetName: "wrteam_logo", height: 40.0, fit: BoxFit.fill));
}
