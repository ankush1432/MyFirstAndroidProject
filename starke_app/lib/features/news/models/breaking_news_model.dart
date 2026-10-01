import 'package:starke_app/core/constants/strings.dart';

class BreakingNewsModel {
  String? id, image, title, desc, contentType, contentValue, totalViews, slug;
  int? readTime;

  BreakingNewsModel(
      {this.id,
      this.image,
      this.title,
      this.desc,
      this.contentValue,
      this.contentType,
      this.totalViews,
      this.slug,
      this.readTime});

  factory BreakingNewsModel.fromJson(Map<String, dynamic> json) {
    return BreakingNewsModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        title: json[TITLE],
        desc: json[DESCRIPTION] ?? '',
        contentValue: json[CONTENT_VALUE],
        contentType: json[CONTENT_TYPE],
        totalViews: json[TOTAL_VIEWS].toString(),
        slug: json[SLUG],
        readTime: json[READ_TIME] ?? 0);
  }
}
