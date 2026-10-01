import 'package:flutter/cupertino.dart';
import 'package:starke_app/features/category/repositories/subcategory/subcat_remote_data_source.dart';
import 'package:starke_app/core/constants/strings.dart';
import 'package:starke_app/utils/ui_utils.dart';
import 'package:starke_app/features/category/models/category_model.dart';

class SubCategoryRepository {
  static final SubCategoryRepository _subCategoryRepository =
      SubCategoryRepository._internal();

  late SubCategoryRemoteDataSource _subCategoryRemoteDataSource;

  factory SubCategoryRepository() {
    _subCategoryRepository._subCategoryRemoteDataSource =
        SubCategoryRemoteDataSource();
    return _subCategoryRepository;
  }

  SubCategoryRepository._internal();

  Future<Map<String, dynamic>> getSubCategory(
      {required BuildContext context,
      required String catId,
      required String langCode}) async {
    final result = await _subCategoryRemoteDataSource.getSubCategory(
        langCode: langCode, catId: catId);

    List<SubCategoryModel> subCatList = [];

    subCatList.insert(
        0,
        SubCategoryModel(
            id: "0",
            subCatName: UiUtils.getTranslatedLabel(context, 'allLbl')));
 
    subCatList.addAll((result[DATA] as List)
        .map((e) => SubCategoryModel.fromJson(e))
        .toList());

    return {"SubCategory": subCatList};
  }
}
