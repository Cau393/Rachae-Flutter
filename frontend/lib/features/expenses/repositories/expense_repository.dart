import 'package:dio/dio.dart';

import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';

class ExpenseRepository {
  const ExpenseRepository(this._dio);

  final Dio _dio;

  Future<List<ExpenseListModel>> fetchOwedToMeExpenses({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/expenses/',
      queryParameters: <String, dynamic>{
        'owed_to_me': true,
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) {
      return [];
    }
    final list = data['data'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => ExpenseListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ExpenseListModel>> fetchGroupExpenses(
    String groupId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/expenses/',
      queryParameters: <String, dynamic>{
        'group_id': groupId,
        'page': page,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) {
      return [];
    }
    final list = data['data'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => ExpenseListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExpenseDetailModel> fetchExpenseDetail(String expenseId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/expenses/$expenseId/',
    );
    final data = response.data!;
    final inner = data['data'] as Map<String, dynamic>;
    return ExpenseDetailModel.fromJson(inner);
  }

  Future<ExpenseDetailModel> createExpense(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/expenses/',
      data: body,
    );
    final data = response.data!;
    return ExpenseDetailModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _dio.delete<void>('/expenses/$expenseId/');
  }

  Future<({String uploadUrl, String fileKey})> fetchReceiptUploadUrl(
    String expenseId, {
    String contentType = 'image/jpeg',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/expenses/$expenseId/receipt-upload-url/',
      queryParameters: <String, dynamic>{'content_type': contentType},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (
      uploadUrl: data['upload_url'] as String,
      fileKey: data['file_key'] as String,
    );
  }

  Future<ExpenseDetailModel> confirmReceiptUpload(
    String expenseId,
    String fileKey,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/expenses/$expenseId/receipts/confirm/',
      data: <String, dynamic>{'file_key': fileKey},
    );
    final data = response.data!;
    return ExpenseDetailModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteReceipt(String expenseId, String fileKey) async {
    await _dio.delete<void>(
      '/expenses/$expenseId/receipts/',
      data: <String, dynamic>{'file_key': fileKey},
    );
  }
}
