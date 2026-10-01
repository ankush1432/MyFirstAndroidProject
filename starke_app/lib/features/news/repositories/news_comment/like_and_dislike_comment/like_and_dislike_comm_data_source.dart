import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class LikeAndDislikeCommRemoteDataSource {
  Future likeAndDislikeComm(
      {required String langCode,
      required String commId,
      required String status}) async {
    try {
      final body = {
        LANGUAGE_CODE: langCode,
        COMMENT_ID: commId,
        STATUS: status
      };
      final result =
          await Api.sendApiRequest(body: body, url: Api.setLikeDislikeComApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
