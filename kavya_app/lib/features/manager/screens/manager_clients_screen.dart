import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../../../core/theme/kt_text_styles.dart';
import '../../../core/widgets/kt_loading_shimmer.dart';
import '../../../core/widgets/kt_error_state.dart';
import '../providers/manager_providers.dart';
import '../widgets/client_card_widget.dart';

class ManagerClientsScreen extends ConsumerWidget {
  const ManagerClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(managerClientSearchProvider);
    final clientsAsync = ref.watch(managerClientListProvider);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Text('Clients', style: KTTextStyles.h2.copyWith(color: KTColors.darkTextPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: KTColors.primary),
            onPressed: () => context.push('/manager/clients/create'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => ref.read(managerClientSearchProvider.notifier).state = v,
              style: KTTextStyles.body.copyWith(color: KTColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search clients...',
                hintStyle: TextStyle(color: KTColors.darkTextSecondary),
                prefixIcon: const Icon(Icons.search, color: KTColors.darkTextSecondary),
                filled: true,
                fillColor: KTColors.darkElevated,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),

          // ── Client list ──────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: KTColors.primary,
              backgroundColor: KTColors.darkSurface,
              onRefresh: () async => ref.invalidate(managerClientListProvider),
              child: clientsAsync.when(
                loading: () => const KTLoadingShimmer(type: ShimmerType.list),
                error: (e, _) => KTErrorState(message: e.toString(), onRetry: () => ref.invalidate(managerClientListProvider)),
                data: (clients) {
                  if (clients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, color: KTColors.darkTextSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text(search.isEmpty ? 'No clients yet' : 'No results for "$search"',
                              style: KTTextStyles.body.copyWith(color: KTColors.darkTextSecondary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: clients.length,
                    itemBuilder: (_, i) => ClientCardWidget(client: Map<String, dynamic>.from(clients[i] as Map)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
