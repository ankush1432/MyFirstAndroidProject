import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:starke_app/core/constants/hive_box_keys.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/features/homepage/models/weather_data.dart';
import 'package:starke_app/commons/widgets/custom_text_label.dart';
import 'package:starke_app/commons/widgets/network_image.dart';

/// Home-page "Weather Forecast" card.
///
/// Two columns inside a rounded surface: the label + current temperature on
/// the start side, and location / day + condition / high-low on the end side.
/// The design's static sun is sample data — the icon is the one WeatherAPI
/// returns for the current condition.
class WeatherDataView extends StatefulWidget {
  final WeatherDetails weatherData;

  const WeatherDataView({super.key, required this.weatherData});

  @override
  WeatherDataState createState() => WeatherDataState();
}

class WeatherDataState extends State<WeatherDataView> {
  late Future<void> _future;

  /// Figma "sun1" box — the condition icon keeps its aspect ratio inside it.
  static const double _iconWidth = 36.0;
  static const double _iconHeight = 34.0;

  @override
  void initState() {
    super.initState();
    _future = UiUtils.checkIfValidLocale(
        langCode: Hive.box(settingsBoxKey).get(currentLanguageCodeKey));
  }

  /// M3 Label Medium (12 / w500 / 0.5) — not what the M2 text theme calls
  /// `labelMedium`, so the size and tracking are spelled out here.
  TextStyle? _labelMediumStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
          color: UiUtils.getColorScheme(context).primaryContainer,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5);

  /// M3 Label Small (11 / w500 / 0.5), same reason as [_labelMediumStyle].
  TextStyle? _labelSmallStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
          color: UiUtils.getColorScheme(context).primaryContainer,
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5);

  /// M3 Body Small (12 / w400 / 0.4) — matches the M2 `bodySmall` as-is.
  TextStyle? _bodySmallStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .bodySmall
      ?.copyWith(color: UiUtils.getColorScheme(context).primaryContainer);

  /// Null when the response carries no icon, so the temperature closes the gap
  /// instead of sitting behind an empty slot.
  Widget? _conditionIcon() {
    final String? icon = widget.weatherData.icon;
    if (icon == null || icon.isEmpty) return null;
    return SizedBox(
      width: _iconWidth,
      height: _iconHeight,
      child: CustomNetworkImage(
        networkImageUrl: icon.startsWith('http') ? icon : 'https:$icon',
        width: _iconWidth,
        height: _iconHeight,
        fit: BoxFit.contain,
        errorBuilder: const SizedBox.shrink(),
      ),
    );
  }

  Widget _startColumn(BuildContext context) {
    final Widget? icon = _conditionIcon();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CustomTextLabel(
            text: 'weatherLbl',
            textStyle: _bodySmallStyle(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: true),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[icon, const SizedBox(width: 3.0)],
            Flexible(
              child: CustomTextLabel(
                  text: '${widget.weatherData.tempC ?? ''}°C',
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: UiUtils.getColorScheme(context).primaryContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget _endColumn(BuildContext context, String day) {
    final WeatherDetails weatherData = widget.weatherData;
    final String location = <String?>[
      weatherData.name,
      weatherData.region,
      weatherData.country
    ].where((part) => part != null && part.trim().isNotEmpty).join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        CustomTextLabel(
            text: location,
            textStyle: _labelMediumStyle(context),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: CustomTextLabel(
                  text: day,
                  textStyle: _bodySmallStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
            const SizedBox(width: 12.0),
            Container(
                width: 1.0,
                height: 16.0,
                color: UiUtils.getColorScheme(context).primaryContainer),
            const SizedBox(width: 12.0),
            Flexible(
              child: CustomTextLabel(
                  text: weatherData.text ?? '',
                  textStyle: _bodySmallStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: CustomTextLabel(
                  text: 'H:${weatherData.maxTempC ?? ''}°C',
                  textStyle: _labelSmallStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
            const SizedBox(width: 9.0),
            Flexible(
              child: CustomTextLabel(
                  text: 'L:${weatherData.minTempC ?? ''}°C',
                  textStyle: _labelSmallStyle(context),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false),
            ),
          ],
        ),
      ],
    );
  }

  Widget weatherDataView() {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        final String day = DateFormat('EEEE').format(DateTime.now());
        return Container(
          margin: const EdgeInsetsDirectional.only(top: 15.0),
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: UiUtils.getColorScheme(context).surface),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Flexible(flex: 3, child: _startColumn(context)),
              const SizedBox(width: 8.0),
              Flexible(flex: 4, child: _endColumn(context, day)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return weatherDataView();
  }
}
