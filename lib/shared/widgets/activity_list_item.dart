import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:edumanage/core/theme/app_theme.dart';

class ActivityListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final int index;

  const ActivityListItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      delay: (index * 100).ms,
      effects: [
        FadeEffect(duration: 500.ms),
        SlideEffect(
          begin: const Offset(-30, 0),
          end: Offset.zero,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          leading: Hero(
            tag: 'activity_icon_$index',
            child: Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 24.w),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.greyColor,
              ),
            ),
          ),
          trailing: Text(
            timeago.format(timestamp),
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.lightGreyColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}