import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/singer.dart';
import 'supabase_service.dart';

class SingersService {
  final _supabase = SupabaseService().client;

  String _escapeLikePattern(String input) {
    return input.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
  }

  Future<List<Singer>> fetchAllSingers() async {
    try {
      final response = await _supabase
          .from('singers_with_song_count')
          .select()
          .order('name', ascending: true);

      return (response as List<dynamic>)
          .map((json) => Singer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load singers: ${e.toString()}');
    }
  }

  Future<List<Singer>> fetchSingersPage({required int offset, required int limit}) async {
    try {
      final response = await _supabase
          .from('singers_with_song_count')
          .select()
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((json) => Singer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load singers page: ${e.toString()}');
    }
  }

  Future<Singer?> fetchSingerById(String singerId) async {
    try {
      final response = await _supabase
          .from('singers_with_song_count')
          .select()
          .eq('id', singerId)
          .maybeSingle();

      if (response == null) return null;
      return Singer.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load singer: ${e.toString()}');
    }
  }

  Future<List<Singer>> searchSingers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final safeQuery = _escapeLikePattern(query.trim());

      final response = await _supabase
          .from('singers_with_song_count')
          .select()
          .ilike('name', '%$safeQuery%')
          .limit(20);

      return (response as List<dynamic>)
          .map((json) => Singer.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Search failed for singers: ${e.toString()}');
    }
  }
}