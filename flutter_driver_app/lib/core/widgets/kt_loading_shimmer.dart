import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class KTLoadingShimmer extends StatelessWidget {
  final ShimmerVariant variant;

  const KTLoadingShimmer({super.key, this.variant = ShimmerVariant.list});

  const KTLoadingShimmer.card({super.key}) : variant = ShimmerVariant.card;
  const KTLoadingShimmer.list({super.key}) : variant = ShimmerVariant.list;
  const KTLoadingShimmer.stat({super.key}) : variant = ShimmerVariant.stat;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: _buildVariant(),
    );
  }

  Widget _buildVariant() {
    switch (variant) {
      case ShimmerVariant.card:
        return _buildCardShimmer();
      case ShimmerVariant.list:
        return _buildListShimmer();
      case ShimmerVariant.stat:
        return _buildStatShimmer();
    }
  }

  Widget _buildCardShimmer() {
    return Column(
      children: List.generate(3, (_) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildListShimmer() {
    return Column(
      children: List.generate(6, (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 160, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(2, (_) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum ShimmerVariant { card, list, stat }
