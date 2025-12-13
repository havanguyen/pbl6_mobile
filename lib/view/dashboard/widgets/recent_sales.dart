import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../../shared/widgets/common/image_display.dart';
import '../../../../shared/localization/app_localizations.dart';

class RecentSales extends StatelessWidget {
  final List<RevenueByDoctorStats> data;

  const RecentSales({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_data'),
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = data[index];
        final revenue = item.total['VND'] ?? 0;
        final revenueStr = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        ).format(revenue);

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: context.theme.muted,
            child: CommonImage(
              imageUrl: item.doctor.avatarUrl.isNotEmpty
                  ? item.doctor.avatarUrl
                  : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(item.doctor.fullName)}&background=random',
              width: 40,
              height: 40,
              borderRadius: 20,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            item.doctor.fullName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: context.theme.textColor,
            ),
          ),
          trailing: Text(
            revenueStr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.theme.textColor,
            ),
          ),
        );
      },
    );
  }
}
