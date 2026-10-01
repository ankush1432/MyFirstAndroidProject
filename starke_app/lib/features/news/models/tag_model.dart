import 'package:starke_app/core/constants/strings.dart';

class TagModel {
  String? id, tagName;

  TagModel({this.id, this.tagName});

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(id: json[ID].toString(), tagName: json[TAGNAME]);
  }
}
