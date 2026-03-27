import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/backend_api.dart';

/// Single shared [BackendApi] instance for the entire app lifetime.
/// All feature providers read this instead of creating their own instance.
final apiProvider = Provider<BackendApi>((ref) => BackendApi());
