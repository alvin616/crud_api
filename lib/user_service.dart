
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'user_model.dart';

class UserService {
  static const String baseUrl = 'https://reqres.in/api';
  static const String apiKey = 'reqres-free-v1';

  Map<String, String> get headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'x-api-key': apiKey,
  };

  // Menangani error koneksi dan waktu tunggu.
  Exception handleError(Object error) {
    if (error is SocketException) {
      return Exception(
        'Tidak ada koneksi internet. Periksa Wi-Fi atau data seluler.',
      );
    }

    if (error is TimeoutException) {
      return Exception(
        'Permintaan terlalu lama. Silakan coba lagi.',
      );
    }

    if (error is http.ClientException) {
      return Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }

    if (error is FormatException) {
      return Exception('Format data dari server tidak valid.');
    }

    if (error is Exception) {
      return error;
    }

    return Exception('Terjadi kesalahan: $error');
  }

  // GET: mengambil daftar user
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/users?page=1'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengambil data. HTTP ${response.statusCode}',
        );
      }

      final jsonData =
      jsonDecode(response.body) as Map<String, dynamic>;

      final List<dynamic> users = jsonData['data'] as List<dynamic>;

      return users
          .map(
            (item) => UserModel.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  // POST: membuat user baru
  Future<Map<String, dynamic>> createUser(
      String name,
      String job,
      ) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 201) {
        throw Exception(
          'Gagal membuat user. HTTP ${response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }

  // PUT: mengubah user
  Future<Map<String, dynamic>> updateUser(
      int id,
      String name,
      String job,
      ) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mengubah user. HTTP ${response.statusCode}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw handleError(e);
    }
  }

  // DELETE: menghapus user
  Future<bool> deleteUser(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
      )
          .timeout(const Duration(seconds: 20));

      // Reqres biasanya mengembalikan HTTP 204 untuk DELETE.
      if (response.statusCode == 204 ||
          response.statusCode == 200) {
        return true;
      }

      throw Exception(
        'Gagal menghapus user. HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw handleError(e);
    }
  }
}
