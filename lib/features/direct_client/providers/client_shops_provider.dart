import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/shop.dart';
import '../../../shared/providers/api_provider.dart';

/// Loads all shops for [clientId] by paginating through the backend.
///
/// - `autoDispose` — freed when the detail screen is popped, so navigating
///   back always gets fresh data.
/// - `family` — scoped per clientId, so different clients never share state.
final clientShopsProvider =
    FutureProvider.autoDispose.family<List<Shop>, int?>((ref, clientId) async {
  if (clientId == null) return const [];

  final api = ref.read(apiProvider);
  final all = <Shop>[];
  int page = 1;
  int lastPage = 1;

  do {
    final result =
        await api.getShops(page: page, perPage: 100, clientId: clientId);
    all.addAll(result.data);
    lastPage = result.lastPage <= 0 ? 1 : result.lastPage;
    page++;
  } while (page <= lastPage);

  return all;
});
