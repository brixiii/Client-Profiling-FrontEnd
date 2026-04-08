import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/api/api_exception.dart';
import '../../../shared/api/backend_api.dart';
import '../../../shared/api/paginated_response.dart';
import '../../../shared/models/availed_service.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/shop.dart';
import '../../../shared/providers/api_provider.dart';

// ── State ──────────────────────────────────────────────────────────────────

@immutable
class ClientListState {
  final List<Map<String, dynamic>> clients;
  final List<Shop> shops;
  final bool isLoading;
  final String? error;
  final int page;
  final int lastPage;
  final int total;
  final String query;

  // Dashboard analytics counts
  final int ownersCount;
  final int shopsCount;
  final int soldProductsCount;
  final int servicesCount;

  const ClientListState({
    this.clients = const [],
    this.shops = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.lastPage = 1,
    this.total = 0,
    this.query = '',
    this.ownersCount = 0,
    this.shopsCount = 0,
    this.soldProductsCount = 0,
    this.servicesCount = 0,
  });

  ClientListState copyWith({
    List<Map<String, dynamic>>? clients,
    List<Shop>? shops,
    bool? isLoading,
    Object? error = _absent,
    int? page,
    int? lastPage,
    int? total,
    String? query,
    int? ownersCount,
    int? shopsCount,
    int? soldProductsCount,
    int? servicesCount,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      shops: shops ?? this.shops,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _absent) ? this.error : error as String?,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      total: total ?? this.total,
      query: query ?? this.query,
      ownersCount: ownersCount ?? this.ownersCount,
      shopsCount: shopsCount ?? this.shopsCount,
      soldProductsCount: soldProductsCount ?? this.soldProductsCount,
      servicesCount: servicesCount ?? this.servicesCount,
    );
  }

  static const Object _absent = Object();
}

// ── Notifier ───────────────────────────────────────────────────────────────

class ClientListNotifier extends StateNotifier<ClientListState> {
  ClientListNotifier(this._api) : super(const ClientListState());

  final BackendApi _api;

  /// Items per page — exposed so the build() method can reference it.
  static const int perPage = 5;

  /// Sequence counter — guards against stale responses from previous calls.
  int _seq = 0;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Fetch (or re-fetch) the client list.  Call after create/update/delete.
  ///
  /// [refreshCounts] — when true (default) also re-fetches the global product
  /// and service totals shown in the analytics cards.  Pass false for page
  /// navigation and search queries so those two extra requests are skipped;
  /// the counts already in state are preserved instead.
  Future<void> fetch({int? page, String? query, bool refreshCounts = true}) async {
    final id = ++_seq;
    final pg = page ?? state.page;
    final q = query ?? state.query;

    state = state.copyWith(isLoading: true, error: null, page: pg, query: q);

    try {
      // Always fetch the client page.  Conditionally add count-only requests.
      final futures = <Future<dynamic>>[
        _api
            .getClients(page: pg, perPage: perPage, q: q.isEmpty ? null : q)
            .catchError(
              (_) => PaginatedResponse<Map<String, dynamic>>(
                data: const [],
                currentPage: pg,
                perPage: perPage,
                total: state.ownersCount,
                lastPage: 1,
                links: const [],
              ),
            ),
      ];
      if (refreshCounts) {
        futures.add(
          _api.getProducts(page: 1, perPage: 1).catchError(
                (_) => PaginatedResponse<Product>(
                  data: const [],
                  currentPage: 1,
                  perPage: 1,
                  total: state.soldProductsCount,
                  lastPage: 1,
                  links: const [],
                ),
              ),
        );
        futures.add(
          _api.getAvailedServices(page: 1, perPage: 1).catchError(
                (_) => PaginatedResponse<AvailedService>(
                  data: const [],
                  currentPage: 1,
                  perPage: 1,
                  total: state.servicesCount,
                  lastPage: 1,
                  links: const [],
                ),
              ),
        );
      }

      final results = await Future.wait(futures);

      if (id != _seq) return; // stale response — discard

      final clientsPage = results[0] as PaginatedResponse<Map<String, dynamic>>;
      final productsPage =
          refreshCounts ? results[1] as PaginatedResponse<Product> : null;
      final servicesPage =
          refreshCounts ? results[2] as PaginatedResponse<AvailedService> : null;

      // Safe pagination fallback: backend sometimes returns total=0 despite
      // having data.  Infer the values from the fetched count instead.
      final fetched = clientsPage.data.length;
      final safeTotal = clientsPage.total > 0
          ? clientsPage.total
          : ((pg - 1) * perPage) + fetched;
      final safeLastPage = clientsPage.lastPage > 1
          ? clientsPage.lastPage
          : (fetched == perPage ? pg + 1 : pg);

      // Publish client list immediately so the UI is responsive.
      state = state.copyWith(
        clients: clientsPage.data,
        shops: const [],
        total: safeTotal,
        lastPage: safeLastPage,
        isLoading: false,
        ownersCount: safeTotal,
        soldProductsCount: productsPage?.total ?? state.soldProductsCount,
        servicesCount: servicesPage?.total ?? state.servicesCount,
      );

      // Shops — best-effort; do not block the client list above.
      try {
        final shopsPage = await _api.getShops(page: 1, perPage: 500);
        if (id != _seq) return;
        final safeShopsTotal =
            shopsPage.total > 0 ? shopsPage.total : shopsPage.data.length;
        state = state.copyWith(
          shops: shopsPage.data,
          shopsCount: safeShopsTotal,
        );
      } catch (_) {
        if (id != _seq) return;
        state = state.copyWith(shops: const []);
      }
    } on ApiException catch (e) {
      if (id != _seq) return;
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      if (id != _seq) return;
      state =
          state.copyWith(isLoading: false, error: 'Failed to load clients.');
    }
  }

  /// Reload the current page without changing the search query.
  Future<void> refresh() => fetch(page: state.page, query: state.query);

  /// Navigate to [page] without changing the search query.
  /// Counts are not re-fetched because they are unaffected by pagination.
  void setPage(int page) => fetch(page: page, refreshCounts: false);

  /// Change the search query and reset to page 1.
  /// Counts are not re-fetched because they reflect global totals, not
  /// the filtered result set.
  void setQuery(String query) => fetch(page: 1, query: query, refreshCounts: false);
}

// ── Provider ───────────────────────────────────────────────────────────────

/// Persistent provider — state survives navigation so returning to the
/// client list shows cached data instantly.  Call [ClientListNotifier.fetch]
/// explicitly after any mutation (add / edit / delete).
final clientListProvider =
    StateNotifierProvider<ClientListNotifier, ClientListState>(
  (ref) => ClientListNotifier(ref.read(apiProvider)),
);
