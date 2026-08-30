import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/vanity_item_model.dart';

class ExpiryBadge extends StatelessWidget {
  final VanityItemModel item;

  const ExpiryBadge({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final status = item.computedStatus;
    final days = item.daysUntilExpiry();

    Color bgColor;
    Color textColor;
    Color borderColor;
    IconData icon;
    String label;

    switch (status) {
      case VanityStatus.expired:
        bgColor = AppColors.statusRedBg;
        textColor = AppColors.statusRed;
        borderColor = AppColors.statusRedBorder;
        icon = Icons.cancel_outlined;
        final overdue = days != null ? days.abs() : 0;
        label = overdue == 0 ? 'Expired Today' : 'Expired $overdue d ago';
        break;

      case VanityStatus.expiring:
        bgColor = AppColors.statusAmberBg;
        textColor = AppColors.statusAmber;
        borderColor = AppColors.statusAmberBorder;
        icon = Icons.access_time_rounded;
        label = '$days d remaining';
        break;

      case VanityStatus.active:
        bgColor = AppColors.statusGreenBg;
        textColor = AppColors.statusGreen;
        borderColor = AppColors.statusGreenBorder;
        icon = Icons.check_circle_outline_rounded;
        label = '$days d remaining';
        break;

      case VanityStatus.unopened:
        bgColor = AppColors.statusUnopenedBg;
        textColor = AppColors.statusUnopened;
        borderColor = AppColors.statusUnopenedBorder;
        icon = Icons.inventory_2_outlined;
        label = 'Unopened (${item.paoMonths}M PAO)';
        break;

      case VanityStatus.finished:
        bgColor = AppColors.statusFinishedBg;
        textColor = AppColors.statusFinished;
        borderColor = AppColors.border;
        icon = Icons.task_alt_rounded;
        label = 'Emptied';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
