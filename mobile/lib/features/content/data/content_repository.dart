import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/content_models.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(dio: ref.watch(apiClientProvider));
});

class ContentRepository {
  ContentRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<StaticPageModel> fetchPage(String pageType) async {
    final response = await _dio.get('/content/pages/$pageType/');
    return StaticPageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FaqModel>> fetchFaqs() async {
    final response = await _dio.get('/content/faq/');
    return (response.data as List<dynamic>)
        .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}