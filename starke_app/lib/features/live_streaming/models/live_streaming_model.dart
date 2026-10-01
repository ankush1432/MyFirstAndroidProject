import 'package:starke_app/core/constants/strings.dart';

class LiveStreamingModel {
  String? id, image, title, type, url, updatedDate;

  LiveStreamingModel(
      {this.id, this.image, this.title, this.type, this.url, this.updatedDate});

  factory LiveStreamingModel.fromJson(Map<String, dynamic> json) {
    return LiveStreamingModel(
        id: json[ID].toString(),
        image: json[IMAGE],
        title: json[TITLE],
        type: json[TYPE],
        url: json[URL],
        updatedDate: json[UPDATED_DATE]);
  }
}
