import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class NewsByIdRemoteDataSource {
  Future<dynamic> getNewsById(
      {required String newsId, required String langCode}) async {
    try {
      final body = {LANGUAGE_CODE: langCode, ID: newsId};
      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
