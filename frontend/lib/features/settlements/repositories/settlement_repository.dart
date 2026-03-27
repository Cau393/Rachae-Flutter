import 'package:dio/dio.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';

class SettlementCreateResult {
  const SettlementCreateResult({
    required this.message,
    required this.totalSettled,
    required this.transactionsCreated,
  });

  final String message;
  final String totalSettled;
  final List<TransactionModel> transactionsCreated;
}

class SettlementRepository {
  const SettlementRepository(this._dio);

  final Dio _dio;

  Future<SettlementCreateResult> createTransaction({
    required String receiverId,
    required String amount,
    required String currency,
    String? groupId,
    String? note,
    List<String>? proofUrls,
    bool isOffset = false,
  }) async {
    final body = <String, dynamic>{
      'receiver_id': receiverId,
      'amount': amount,
      'currency': currency,
      'group_id': ?groupId,
      if (isOffset) 'is_offset': true,
      if (note != null && note.trim().isNotEmpty) 'note': note,
      if (proofUrls != null && proofUrls.isNotEmpty) 'proof_urls': proofUrls,
    };
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/transactions/',
        data: body,
      );
      final txnsRaw = response.data!['data'] as List<dynamic>? ?? const [];
      return SettlementCreateResult(
        message: 'Settlement processed successfully',
        totalSettled: amount,
        transactionsCreated: txnsRaw
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      final nested = e.error;
      if (nested is ApiException) {
        final detail = _detailMessageFromResponse(e.response?.data);
        throw ApiException(
          statusCode: nested.statusCode,
          message: detail ?? nested.message,
        );
      }
      rethrow;
    }
  }

  /// Credit [receiver] owes [current user] outside [excludeGroupId] (report currency).
  Future<({String credit, String currency})> fetchOffsetCreditPreview({
    required String withUserId,
    required String excludeGroupId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions/offset-credit-preview/',
      queryParameters: <String, dynamic>{
        'with_user': withUserId,
        'exclude_group': excludeGroupId,
      },
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (
      credit: data['credit'].toString(),
      currency: data['currency'] as String,
    );
  }

  static String? _detailMessageFromResponse(dynamic data) {
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    final d = m['detail'];
    if (d is String) return d;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      return first is String ? first : first.toString();
    }
    return null;
  }

  Future<List<TransactionModel>> fetchTransactionsWithUser(
    String userId, {
    int page = 1,
    String? status,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions/',
      queryParameters: <String, dynamic>{
        'with_user': userId,
        'page': page,
        'limit': 20,
        'status': ?status,
      },
    );
    final data = response.data;
    if (data == null) {
      return [];
    }
    final list = data['data'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// [pendingRole] is `receiver` (incoming payments to confirm) or `payer` (outgoing awaiting confirmation).
  Future<List<TransactionModel>> fetchPendingByRole(
    String pendingRole, {
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions/',
      queryParameters: <String, dynamic>{
        'pending_role': pendingRole,
        'page': page,
        'limit': 20,
      },
    );
    final data = response.data;
    if (data == null) {
      return [];
    }
    final list = data['data'] as List<dynamic>? ?? const <dynamic>[];
    return list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> confirmTransaction(String transactionId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/$transactionId/confirm/',
    );
    return TransactionModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<TransactionModel> disputeTransaction(String transactionId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/$transactionId/dispute/',
    );
    return TransactionModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<({String uploadUrl, String fileKey})> fetchProofUploadUrl(
    String transactionId, {
    String contentType = 'image/jpeg',
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/transactions/$transactionId/proof-upload-url/',
      queryParameters: <String, dynamic>{'content_type': contentType},
    );
    final data = response.data!['data'] as Map<String, dynamic>;
    return (
      uploadUrl: data['upload_url'] as String,
      fileKey: data['file_key'] as String,
    );
  }

  Future<TransactionModel> confirmProofUpload(
    String transactionId,
    String fileKey,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/transactions/$transactionId/proofs/confirm/',
      data: <String, dynamic>{'file_key': fileKey},
    );
    return TransactionModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
