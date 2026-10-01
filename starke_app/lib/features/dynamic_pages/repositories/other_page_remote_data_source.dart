import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class OtherPageRemoteDataSource {
  Future<dynamic> getOtherPages({required String langCode}) async {
    try {
      final body = {LANGUAGE_CODE: langCode};
      final result = await Api.sendApiRequest(body: body, url: Api.getPagesApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
