import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edumanage/core/theme/app_theme.dart';

class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? change;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final Duration delay;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    required this.color,
    this.onTap,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change != null && !change!.contains('-');

    return Animate(
      delay: delay,
      effects: [
        FadeEffect(duration: 600.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 30),
          end: Offset.zero,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // YEH ADD KIYA
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: color, size: 24.w),
                  ),

                  SizedBox(height: 12.h), // Kam kiya

                  // Value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26.sp, // Thora chota kiya
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkColor,
                    ),
                  ),

                  SizedBox(height: 6.h), // Kam kiya

                  // Title and Change
                  Row(
                    mainAxisSize: MainAxisSize.min, // YEH ADD KIYA
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 12.sp, // Chota kiya
                            color: AppTheme.greyColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (change != null)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: isPositive
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.dangerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            change!,
                            style: TextStyle(
                              fontSize: 10.sp, // Chota kiya
                              fontWeight: FontWeight.w600,
                              color: isPositive
                                  ? AppTheme.successColor
                                  : AppTheme.dangerColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}