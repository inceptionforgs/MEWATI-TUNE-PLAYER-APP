// lib/screens/singers/singers_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/themes/app_theme_id.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../models/singer.dart';
import '../../providers/singers_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/route_names.dart';
import '../../services/app_cache_manager.dart';

double _cardRadius(AppThemeId id) {
  switch (id) {
    case AppThemeId.cyberBlack:
      return 4;
    case AppThemeId.silverChrome:
      return 10;
    default:
      return 14;
  }
}

class SingersScreen extends StatefulWidget {
  const SingersScreen({Key? key}) : super(key: key);

  @override
  State<SingersScreen> createState() => _SingersScreenState();
}

class _SingersScreenState extends State<SingersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<SingersProvider>(context, listen: false).loadSingers();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<SingersProvider>(context, listen: false).loadMoreSingers();
    }
  }

  void _openSingerProfile(Singer singer) {
    Navigator.of(context).pushNamed(RouteNames.singerProfile, arguments: singer);
  }

  @override
  Widget build(BuildContext context) {
    final singersProvider = context.watch<SingersProvider>();
    final t = context.watch<ThemeProvider>().theme;

    if (singersProvider.isLoading && singersProvider.allSingers.isEmpty) {
      return const LoadingWidget(message: AppStrings.loading);
    }

    if (singersProvider.errorMessage != null &&
        singersProvider.allSingers.isEmpty) {
      return AppErrorWidget(
        error: singersProvider.errorMessage,
        onRetry: () => singersProvider.loadSingers(),
      );
    }

    if (singersProvider.filteredSingers.isEmpty &&
        !singersProvider.isLoading) {
      return Center(
        child: Text('No singers found.',
            style: TextStyle(color: t.textSecondary)),
      );
    }

    final singers = singersProvider.filteredSingers;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: 16),
      itemCount: singers.length + (singersProvider.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == singers.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final singer = singers[index];
        return _singerRow(singer, t);
      },
    );
  }

  Widget _singerRow(Singer singer, dynamic t) {
    final initial = singer.name.isNotEmpty
        ? singer.name[0].toUpperCase()
        : '?';
    final radius = _cardRadius(t.id as AppThemeId);

    return InkWell(
      onTap: () => _openSingerProfile(singer),
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: t.surface.withOpacity(0.15),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: t.textPrimary.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.textPrimary, width: 2),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2B180D), Color(0xFF120C08)],
                ),
              ),
              child: (singer.photoUrl != null && singer.photoUrl!.isNotEmpty)
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: singer.photoUrl!,
                        fit: BoxFit.cover,
                        cacheManager: AppCacheManager.instance,
                        memCacheWidth: 160,
                        memCacheHeight: 160,
                        placeholder: (context, url) => Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 21,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: t.textPrimary,
                              fontSize: 21,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 21,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    singer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${singer.songCount ?? 0} songs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textPrimary, size: 24),
          ],
        ),
      ),
    );
  }
}
