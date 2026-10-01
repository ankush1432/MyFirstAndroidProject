import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class SubCatNewsRemoteDataSource {
  Future<dynamic> getSubCatNews(
      {required String limit,
      required String offset,
      String? catId,
      String? subCatId,
      String? latitude,
      String? longitude,
      required String langCode}) async {
    try {
      final body = {LIMIT: limit, OFFSET: offset, LANGUAGE_CODE: langCode};
      if (catId != null) body[CATEGORY_ID] = catId;
      if (subCatId != null) body[SUBCAT_ID] = subCatId;
      if (latitude != null && latitude != "null") body[LATITUDE] = latitude;
      if (longitude != null && longitude != "null") body[LONGITUDE] = longitude;

      final result = await Api.sendApiRequest(body: body, url: Api.getNewsApi);
      return result;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }
}
