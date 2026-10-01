import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class CommentNewsRemoteDataSource {
  Future<dynamic> getCommentNews(
      {required String limit,
      required String offset,
      required String newsId}) async {
    try {
      final body = {LIMIT: limit, OFFSET: offset, NEWS_ID: newsId};
      final result =
          await Api.sendApiRequest(body: body, url: Api.getCommentByNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
