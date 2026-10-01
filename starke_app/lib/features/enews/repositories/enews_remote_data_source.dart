import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class ENewsRemoteDataSource {
  Future<dynamic> getENews({
    required String languageCode,
    required String perPage,
    required String page,
  }) async {
    try {
      final body = {
        LANGUAGE_CODE: languageCode,
        PER_PAGE: perPage,
        PAGE: page,
      };
      final result = await Api.sendApiRequest(body: body, url: Api.getENewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
