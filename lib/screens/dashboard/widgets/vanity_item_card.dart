import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/vanity_item_model.dart';
import '../../../models/category_model.dart';
import 'expiry_badge.dart';

class VanityItemCard extends StatelessWidget {
  final VanityItemModel item;
  final VoidCallback onTap;
  final VoidCallback onMarkOpenedToday;

  const VanityItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onMarkOpenedToday,
  });

  @override
  Widget build(BuildContext context) {
    final status = item.computedStatus;
    final category = CategoryModel.findById(item.categoryId);

    Color stripColor;
    switch (status) {
      case VanityStatus.expired:
        stripColor = AppColors.statusRed;
        break;
      case VanityStatus.expiring:
        stripColor = AppColors.statusAmber;
        break;
      case VanityStatus.active:
        stripColor = AppColors.statusGreen;
        break;
      case VanityStatus.unopened:
        stripColor = AppColors.statusUnopened;
        break;
      case VanityStatus.finished:
        stripColor = AppColors.statusFinished;
        break;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: status == VanityStatus.expired
              ? AppColors.statusRedBorder
              : status == VanityStatus.expiring
                  ? AppColors.statusAmberBorder
                  : AppColors.border,
          width: status == VanityStatus.expired || status == VanityStatus.expiring ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left urgency color strip
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: stripColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Main content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Category tag + Expiry Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.categoryName.toUpperCase(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ExpiryBadge(item: item),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Middle: Product Name & Brand
                      Text(
                        item.brand.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.productName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),

                      // Bottom Row: Date Details & Quick Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Opened Date / Expiry Date Text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.openedDate != null
                                    ? 'Opened: ${item.formattedOpenedDate}'
                                    : 'PAO: ${item.paoMonths} Months',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (item.expiryDate != null)
                                Text(
                                  'Expires: ${item.formattedExpiryDate}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: status == VanityStatus.expired
                                        ? AppColors.statusRed
                                        : status == VanityStatus.expiring
                                            ? AppColors.statusAmber
                                            : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),

                          // Quick Action Button
                          if (item.openedDate == null)
                            ElevatedButton.icon(
                              onPressed: onMarkOpenedToday,
                              icon: const Icon(Icons.flash_on, size: 14),
                              label: const Text('Opened Today'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                          else if (item.price != null && item.price! > 0)
                            Text(
                              '\$${item.price!.toStringAsFixed(2)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
