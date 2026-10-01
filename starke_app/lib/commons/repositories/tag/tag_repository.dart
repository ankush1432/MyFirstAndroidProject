import 'package:starke_app/features/news/models/tag_model.dart';
import 'package:starke_app/commons/repositories/tag/tag_remote_data_source.dart';
import 'package:starke_app/core/constants/strings.dart';

class TagRepository {
  static final TagRepository _tagRepository = TagRepository._internal();

  late TagRemoteDataSource _tagRemoteDataSource;

  factory TagRepository() {
    _tagRepository._tagRemoteDataSource = TagRemoteDataSource();
    return _tagRepository;
  }

  TagRepository._internal();

  Future<Map<String, dynamic>> getTag(
      {required String langCode,
      required String offset,
      required String limit}) async {
    final result = await _tagRemoteDataSource.getTag(
        langCode: langCode, limit: limit, offset: offset);

    return {
      "Tag": (result[DATA][DATA] as List)
          .map((e) => TagModel.fromJson(e))
          .toList(),
      "total": result[DATA][TOTAL]
    };
  }
}
