import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class DeleteCommRemoteDataSource {
  Future deleteComm({required String commId}) async {
    try {
      final body = {COMMENT_ID: commId};
      final result =
          await Api.sendApiRequest(body: body, url: Api.setCommentDeleteApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
