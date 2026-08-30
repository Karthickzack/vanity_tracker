import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../providers/vanity_provider.dart';
import '../../core/services/auth_service.dart';
import '../add_product/add_product_screen.dart';
import '../detail/product_detail_screen.dart';
import '../history/history_screen.dart';
import '../stats/stats_screen.dart';
import 'widgets/vanity_item_card.dart';

class VanityDashboardScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onSignOut;

  const VanityDashboardScreen({
    super.key,
    required this.authService,
    required this.onSignOut,
  });

  @override
  State<VanityDashboardScreen> createState() => _VanityDashboardScreenState();
}

class _VanityDashboardScreenState extends State<VanityDashboardScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Vanity',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Freshness & PAO Inventory',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.primaryDark),
            tooltip: 'Vanity Analytics',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textPrimary),
            tooltip: 'Empties History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () async {
              await widget.authService.signOut();
              widget.onSignOut();
            },
          ),
        ],
      ),
      body: Consumer<VanityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final items = provider.activeItems;

          return CustomScrollView(
            slivers: [
              // Summary Urgency Banner Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildSummaryCards(provider),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: provider.setSearchQuery,
                    decoration: InputDecoration(
                      hintText: 'Search by brand or product name...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Category Filter Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Products'),
                          selected: provider.selectedCategory == null,
                          onSelected: (_) => provider.setSelectedCategory(null),
                        ),
                      ),
                      ...CategoryModel.defaultCategories.map((cat) {
                        final isSelected = provider.selectedCategory == cat.categoryId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat.categoryName),
                            selected: isSelected,
                            onSelected: (_) {
                              provider.setSelectedCategory(
                                isSelected ? null : cat.categoryId,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Product Cards List
              if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(context, provider),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return VanityItemCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(item: item),
                            ),
                          );
                        },
                        onMarkOpenedToday: () async {
                          await provider.markAsOpened(item);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opened today! Expiry set for ${item.formattedExpiryDate}'),
                                backgroundColor: AppColors.secondary,
                              ),
                            );
                          }
                        },
                      );
                    },
                    childCount: items.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Product',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HistoryScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa_rounded),
            label: 'Vanity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.recycling_outlined),
            activeIcon: Icon(Icons.recycling_rounded),
            label: 'Empties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics_rounded),
            label: 'Budget',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(VanityProvider provider) {
    return Row(
      children: [
        // Fresh (>30d)
        Expanded(
          child: _buildMetricTile(
            title: 'Fresh',
            count: provider.totalActiveCount,
            color: AppColors.statusGreen,
            bgColor: AppColors.statusGreenBg,
            borderColor: AppColors.statusGreenBorder,
          ),
        ),
        const SizedBox(width: 8),

        // Expiring (0-30d)
        Expanded(
          child: _buildMetricTile(
            title: 'Expiring',
            count: provider.totalExpiringCount,
            color: AppColors.statusAmber,
            bgColor: AppColors.statusAmberBg,
            borderColor: AppColors.statusAmberBorder,
          ),
        ),
        const SizedBox(width: 8),

        // Expired (<0d)
        Expanded(
          child: _buildMetricTile(
            title: 'Expired',
            count: provider.totalExpiredCount,
            color: AppColors.statusRed,
            bgColor: AppColors.statusRedBg,
            borderColor: AppColors.statusRedBorder,
          ),
        ),
        const SizedBox(width: 8),

        // Unopened
        Expanded(
          child: _buildMetricTile(
            title: 'Unopened',
            count: provider.totalUnopenedCount,
            color: AppColors.statusUnopened,
            bgColor: AppColors.statusUnopenedBg,
            borderColor: AppColors.statusUnopenedBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required int count,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, VanityProvider provider) {
    final isFiltering = provider.selectedCategory != null || provider.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering ? 'No matching products' : 'Your Vanity is Empty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? 'Try clearing filters or search terms.'
                  : 'Scan a barcode or add skincare manually to start tracking expiration and PAO.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (isFiltering)
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                  provider.setSelectedCategory(null);
                },
                child: const Text('Reset Filters'),
              )
            else
              ElevatedButton.icon(
                onPressed: _openAddProduct,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Add First Product'),
              ),
          ],
        ),
      ),
    );
  }
}
