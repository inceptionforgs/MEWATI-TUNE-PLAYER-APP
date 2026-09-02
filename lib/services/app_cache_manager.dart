import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager with a maximum cache size to prevent unlimited
/// storage usage by cover images.
class AppCacheManager extends CacheManager {
  static final AppCacheManager instance = AppCacheManager._();

  AppCacheManager._()
      : super(
          Config(
            'mewati_image_cache',
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 500,
            repo: JsonCacheInfoRepository(databaseName: 'image_cache'),
            fileSystem: IOFileSystem('image_cache'),
            fileService: HttpFileService(),
          ),
        );
}