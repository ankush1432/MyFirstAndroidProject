import 'package:starke_app/core/api/api.dart';
import 'package:starke_app/core/constants/strings.dart';

class SystemRepository {
  Future<dynamic> fetchSettings() async {
    try {
      final result = await Api.sendApiRequest(url: Api.getSettingApi, body: {});
      return result[DATA];
    } catch (e) {
      throw ApiException(e.toString());
    }
  }
}
