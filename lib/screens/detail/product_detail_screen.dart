import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/vanity_item_model.dart';
import '../../providers/vanity_provider.dart';
import '../dashboard/widgets/expiry_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  final VanityItemModel item;

  const ProductDetailScreen({super.key, required this.item});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late VanityItemModel _currentItem;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  Future<void> _handleMarkOpenedToday() async {
    final provider = context.read<VanityProvider>();
    await provider.markAsOpened(_currentItem);
    if (!mounted) return;

    setState(() {
      final now = DateTime.now();
      _currentItem = _currentItem.copyWith(
        openedDate: now,
        expiryDate: now.add(Duration(days: _currentItem.paoMonths * 30)),
        status: VanityStatus.active,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as opened today! Expiry countdown started.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _handlePickOpenedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentItem.openedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final provider = context.read<VanityProvider>();
      await provider.markAsOpened(_currentItem, openedDate: picked);
      setState(() {
        _currentItem = _currentItem.copyWith(
          openedDate: picked,
          status: VanityStatus.active,
        );
      });
    }
  }

  Future<void> _handleMarkFinished() async {
    // Show Prompt: "Would you repurchase this?"
    final repurchase = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Emptied this product?',
            style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Congratulations on finishing your ${_currentItem.productName}!',
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Would you repurchase this product?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton.icon(
              icon: const Icon(Icons.thumb_down_outlined, size: 16, color: AppColors.statusRed),
              label: const Text('No', style: TextStyle(color: AppColors.statusRed)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.thumb_up_outlined, size: 16),
              label: const Text('Yes!'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    final provider = context.read<VanityProvider>();
    await provider.markAsFinished(_currentItem, wouldRepurchase: repurchase);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_currentItem.productName} moved to Empties history!'),
          backgroundColor: AppColors.secondary,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDeleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product?'),
        content: const Text('Are you sure you want to remove this item from your vanity?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<VanityProvider>();
      await provider.deleteItem(_currentItem.vanityItemId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.findById(_currentItem.categoryId);
    final days = _currentItem.daysUntilExpiry();
    final costPerDay = _currentItem.costPerDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Product Details',
          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.statusRed),
            onPressed: _handleDeleteItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Product Identity Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category.categoryName.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      ExpiryBadge(item: _currentItem),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _currentItem.brand.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentItem.productName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  if (_currentItem.volume != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Size: ${_currentItem.volume}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Expiry & PAO Analytics Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Period After Opening (PAO)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    label: 'PAO Lifespan',
                    value: '${_currentItem.paoMonths} Months',
                    icon: Icons.timelapse,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Date Opened',
                    value: _currentItem.formattedOpenedDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Expiry Date',
                    value: _currentItem.formattedExpiryDate,
                    icon: Icons.event_busy_outlined,
                    valueColor: _currentItem.computedStatus == VanityStatus.expired
                        ? AppColors.statusRed
                        : _currentItem.computedStatus == VanityStatus.expiring
                            ? AppColors.statusAmber
                            : AppColors.statusGreen,
                  ),
                  if (days != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      label: 'Countdown',
                      value: days < 0 ? '${days.abs()} days past expiry' : '$days days remaining',
                      icon: Icons.hourglass_bottom_rounded,
                      valueColor: days < 0 ? AppColors.statusRed : AppColors.textPrimary,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Budget / Cost Insights Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget & Cost Breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    label: 'Purchase Price',
                    value: _currentItem.price != null
                        ? '\$${_currentItem.price!.toStringAsFixed(2)}'
                        : 'Not specified',
                    icon: Icons.attach_money,
                  ),
                  if (_currentItem.openedDate != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      label: 'Days in Use',
                      value: '${_currentItem.daysInUse} days',
                      icon: Icons.date_range,
                    ),
                    if (costPerDay != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        label: 'Cost Per Day',
                        value: '\$${costPerDay.toStringAsFixed(2)} / day',
                        icon: Icons.trending_down,
                        valueColor: AppColors.primaryDark,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            if (_currentItem.openedDate == null) ...[
              ElevatedButton.icon(
                onPressed: _handleMarkOpenedToday,
                icon: const Icon(Icons.flash_on),
                label: const Text('Mark as Opened Today'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _handlePickOpenedDate,
                icon: const Icon(Icons.calendar_month),
                label: const Text('Pick Past Opening Date'),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _handleMarkFinished,
                icon: const Icon(Icons.recycling_rounded),
                label: const Text('Mark as Emptied / Finished'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _handlePickOpenedDate,
                icon: const Icon(Icons.edit_calendar),
                label: const Text('Change Opened Date'),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
