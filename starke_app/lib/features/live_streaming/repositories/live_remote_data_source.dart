import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class LiveStreamRemoteDataSource {
  Future<dynamic> getLiveStreams(
      {required String langCode,
      required String limit,
      required String offset}) async {
    try {
      final body = {
        LANGUAGE_CODE: langCode,
        LIMIT: limit,
        OFFSET: offset,
      };
      final result =
          await Api.sendApiRequest(body: body, url: Api.getLiveStreamingApi);

      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
