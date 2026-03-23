import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';

class DashboardRepository {
  const DashboardRepository(this._dio);

  final Dio _dio;

  Future<BalanceSummaryModel> fetchBalanceSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me/');
      final data = response.data;
      if (data == null) {
        throw const ApiException(statusCode: 0, message: 'Empty response');
      }
      return BalanceSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<List<ActivityItemModel>> fetchActivity({
    int page = 1,
    int limit = 20,
    String? groupId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'page': page, 'limit': limit};
      if (groupId != null) {
        queryParameters['group_id'] = groupId;
      }
      final response = await _dio.get<Map<String, dynamic>>(
        '/ledger/activity/',
        queryParameters: queryParameters,
      );
      final data = response.data;
      if (data == null) {
        return [];
      }
      final inner = data['data'] as Map<String, dynamic>?;
      final activities = inner?['activities'] as List<dynamic>? ?? [];
      return ActivityItemModel.fromJsonList(activities);
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  Future<List<ActivityItemModel>> fetchNextActivityPage(int page) =>
      fetchActivity(page: page);

  Future<List<PairwiseBalanceRowModel>> fetchPairwiseBalances() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/users/me/pairwise-balances/',
      );
      final data = response.data;
      if (data == null) {
        return [];
      }
      final inner = data['data'] as Map<String, dynamic>?;
      final list = inner?['balances'] as List<dynamic>? ?? const <dynamic>[];
      return list
          .map(
            (e) => PairwiseBalanceRowModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw _mapDioToApi(e);
    }
  }

  ApiException _mapDioToApi(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final message =
        e.response?.data?.toString() ?? e.message ?? 'Unknown error';
    return ApiException(statusCode: status, message: message);
  }
}
