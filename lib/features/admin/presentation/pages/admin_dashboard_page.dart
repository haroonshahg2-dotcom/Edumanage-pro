import 'package:edumanage/features/admin/presentation/pages/salary_module.dart';
import 'package:edumanage/features/admin/presentation/pages/setting_module.dart';
import 'package:edumanage/features/admin/presentation/pages/teacher_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'package:edumanage/features/admin/presentation/pages/exam_results_module.dart';
import 'package:edumanage/features/admin/presentation/pages/student_module.dart';
import 'package:rxdart/rxdart.dart';
import 'attendance_module.dart';
import 'fee_module.dart';

class Win11Colors {
  static const Color bg           = Color(0xFF1A1A1A);
  static const Color hover        = Color(0xFF2C2C2C);
  static const Color active       = Color(0xFF2C2C2C);
  static const Color border       = Color(0xFF3A3A3A);
  static const Color text         = Color(0xFFD4D4D4);
  static const Color textActive   = Color(0xFFFFFFFF);
  static const Color textMuted    = Color(0xFF999999);
}

/// Hover scale + glow border card
class _HoverCard extends StatefulWidget {
  final Widget child;
  final double scaleUp;
  final Color? glowColor;
  final BorderRadius? borderRadius;
  final bool enableGlow;

  const _HoverCard({
    required this.child,
    this.scaleUp = 1.025,
    this.glowColor,
    this.borderRadius,
    this.enableGlow = true,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.scaleUp).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: widget.enableGlow && _hovered
                ? BoxDecoration(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (widget.glowColor ?? const Color(0xFF3B82F6))
                      .withOpacity(0.28),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            )
                : const BoxDecoration(),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Pulse ring animation (for notification badge, status dot)
class _PulseWidget extends StatefulWidget {
  final Widget child;
  final Color color;
  const _PulseWidget({required this.child, required this.color});

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(_opacity.value),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

/// Count-up animated number
class _AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle style;
  const _AnimatedCounter({required this.value, required this.style});

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(begin: 0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _anim = Tween<double>(
          begin: _prev.toDouble(), end: widget.value.toDouble())
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) =>
          Text(_anim.value.toInt().toString(), style: widget.style),
    );
  }
}

/// Staggered fade+slide-up item for lists
class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _StaggeredItem({required this.child, required this.index});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _opacity =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
        ));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
        );

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Hover action button (scale + color lift)
class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _HoverIconButton(
      {required this.icon, required this.color, required this.onPressed});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_hovered ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0.5 : 0.2)),
            boxShadow: _hovered
                ? [
              BoxShadow(
                  color: widget.color.withOpacity(0.25),
                  blurRadius: 10)
            ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated gradient border shimmer on hover for chart/info cards
class _GlowBorderCard extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  const _GlowBorderCard({required this.child, required this.baseColor});

  @override
  State<_GlowBorderCard> createState() => _GlowBorderCardState();
}

class _GlowBorderCardState extends State<_GlowBorderCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _glow = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _glow,
        builder: (_, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor.withOpacity(0.18 * _glow.value),
                blurRadius: 24 * _glow.value,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: widget.baseColor
                  .withOpacity(0.12 + 0.28 * _glow.value),
              width: 1.5,
            ),
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _KpiData {
  final String title;
  final int value;
  final String valueStr;
  final IconData icon;
  final Color color;
  final List<Color> bgGradient;
  final String trend;
  final bool trendUp;
  final String subtitle;
  final String route;

  const _KpiData({
    required this.title,
    required this.value,
    required this.valueStr,
    required this.icon,
    required this.color,
    required this.bgGradient,
    required this.trend,
    required this.trendUp,
    required this.subtitle,
    required this.route,
  });
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN DASHBOARD — all original code below, animations woven in
// ═══════════════════════════════════════════════════════════════════════════

class AdminDashboardPage extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final String? adminName;

  const AdminDashboardPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.adminName,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {

  // Add this map for section expansion state
  final Map<String, bool> _expandedSections = {
    'main': true,
    'academic': true,
    'examination': true,
    'finance': true,
    'communication': true,
    'analytics': true,
    'system': true,
  };

  String selectedMenu = "Dashboard";
  bool isSidebarOpen = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Search & filter state
  String searchQuery = "";
  String? selectedFilter;
  String? selectedClassFilter;

  // Pagination
  int currentPage = 1;
  final int itemsPerPage = 10;

  // ─── SIDEBAR — Darkest (background layer) ─────────────────
  static const Color _sidebarBg        = Color(0xFF0B0D14);   // ← Darkest (was 0F1117)
  static const Color _sidebarElevated  = Color(0xFF151821);   // Hover state
  static const Color _sidebarBorder    = Color(0xFF252836);   // Borders
  static const Color _sidebarText      = Color(0xFF8B92A8);   // Secondary text
  static const Color _sidebarTextActive = Color(0xFFEEF1F8);  // Primary text
  static const Color _sidebarMuted     = Color(0xFF5A6072);   // Disabled

  // ─── DASHBOARD — Lighter (content layer) ──────────────────
  static const Color _bgDark     = Color(0xFF0F1117);   // ← Lighter than sidebar (was same)
  static const Color _bgCard     = Color(0xFF161922);   // Cards
  static const Color _bgElevated = Color(0xFF1E212E);   // Elevated surfaces
  static const Color _border     = Color(0xFF2A2E3B);   // Borders
  static const Color _borderLight = Color(0xFF353A4A);  // Hover borders

  // ─── TEXT ─────────────────────────────────────────────────
  static const Color _textPrimary   = Color(0xFFEEF1F8);   // Headings
  static const Color _textSecondary = Color(0xFF8B92A8);   // Body
  static const Color _textMuted     = Color(0xFF5A6072);   // Hints

  // ─── ACCENTS (same for both) ──────────────────────────────
  static const Color _accentIndigo  = Color(0xFF7C8CF0);
  static const Color _accentEmerald = Color(0xFF3DD68B);
  static const Color _accentAmber   = Color(0xFFF2A93B);
  static const Color _accentSky     = Color(0xFF4DBEF7);
  static const Color _accentRose    = Color(0xFFF2657A);
  static const Color _accentViolet  = Color(0xFFB084F5);
  static const Color _accentSlate   = Color(0xFF8B92A8);

  // ─── PRIMARY ──────────────────────────────────────────────
  static const Color _primary      = Color(0xFF7C8CF0);
  static const Color _primaryLight = Color(0xFF9AA5F3);
  static const Color _primaryDark  = Color(0xFF5E6BE8);

  // ─── FUNCTIONAL ───────────────────────────────────────────
  static const Color _accentSuccess = Color(0xFF3DD68B);
  static const Color _accentWarning = Color(0xFFF2A93B);
  static const Color _accentDanger  = Color(0xFFF2657A);
  static const Color _accentInfo    = Color(0xFF4DBEF7);

  final List<String> availableClasses = [
    "1A","1B","1C","2A","2B","2C","3A","3B","3C",
    "4A","4B","4C","5A","5B","5C","6A","6B","6C",
    "7A","7B","7C","8A","8B","8C","9A","9B","9C",
    "10A","10B","10C",
  ];

  final Map<String, Color> _sectionAccentColors = {
    'main':          _accentIndigo,   // Soft Indigo
    'academic':      _accentEmerald,  // Success Green
    'examination':   _accentAmber,    // Warning Amber
    'finance':       _accentSky,      // Trust Blue
    'communication': _accentRose,     // Warm Pink
    'analytics':     _accentViolet,   // Deep Violet
    'system':        _accentSlate,    // Neutral Gray
  };

  final List<_SidebarSection> _sidebarSections = [
    _SidebarSection(
      key: 'main',
      title: 'Overview',
      icon: Icons.home_outlined,
      items: [
        _SidebarItem(title: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, route: 'Dashboard'),
      ],
    ),
    _SidebarSection(
      key: 'academic',
      title: 'Academic',
      icon: Icons.school_outlined,
      items: [
        _SidebarItem(title: 'Students', icon: Icons.people_outline, activeIcon: Icons.people, route: 'Students', collection: 'students'),
        _SidebarItem(title: 'Teachers', icon: Icons.person_outline, activeIcon: Icons.person, route: 'Teachers', collection: 'teachers'),
        _SidebarItem(title: 'Attendance', icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check, route: 'Attendance', collection: 'attendance'),
        _SidebarItem(title: 'Classes', icon: Icons.class_outlined, activeIcon: Icons.class_, route: 'Classes', collection: 'classes'),
        _SidebarItem(title: 'Subjects', icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, route: 'Subjects', collection: 'subjects'),
        _SidebarItem(title: 'Timetable', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, route: 'Timetable', collection: 'timetables'),
      ],
    ),
    _SidebarSection(
      key: 'examination',
      title: 'Examination',
      icon: Icons.quiz_outlined,
      items: [
        _SidebarItem(title: 'Exams', icon: Icons.assignment_outlined, activeIcon: Icons.assignment, route: 'Exams', collection: 'exams'),
        _SidebarItem(title: 'Results', icon: Icons.assessment_outlined, activeIcon: Icons.assessment, route: 'Results', collection: 'results'),
        _SidebarItem(title: 'Hall Tickets', icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number, route: 'Hall Tickets', collection: 'hallTickets'),
        _SidebarItem(title: 'Admit Cards', icon: Icons.badge_outlined, activeIcon: Icons.badge, route: 'Admit Cards', collection: 'admitCards'),
      ],
    ),
    _SidebarSection(
      key: 'finance',
      title: 'Finance',
      icon: Icons.account_balance_outlined,
      items: [
        _SidebarItem(title: 'Fees', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, route: 'Fees', collection: 'fees'),
        _SidebarItem(title: 'Salary', icon: Icons.payments_outlined, activeIcon: Icons.payments, route: 'Salary', collection: 'salaryRecords'),
        _SidebarItem(title: 'Expenses', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, route: 'Expenses', collection: 'expenses'),
      ],
    ),
    _SidebarSection(
      key: 'communication',
      title: 'Communication',
      icon: Icons.chat_outlined,
      items: [
        _SidebarItem(title: 'Announcements', icon: Icons.campaign_outlined, activeIcon: Icons.campaign, route: 'Announcements', collection: 'announcements'),
        _SidebarItem(title: 'Notices', icon: Icons.notifications_active_outlined, activeIcon: Icons.notifications_active, route: 'Notices', collection: 'notices'),
        _SidebarItem(title: 'Events', icon: Icons.event_outlined, activeIcon: Icons.event, route: 'Events', collection: 'events'),
        _SidebarItem(title: 'Messages', icon: Icons.message_outlined, activeIcon: Icons.message, route: 'Messages', collection: 'messages'),
      ],
    ),
    _SidebarSection(
      key: 'analytics',
      title: 'Analytics',
      icon: Icons.insights_outlined,
      items: [
        _SidebarItem(title: 'Analytics', icon: Icons.analytics_outlined, activeIcon: Icons.analytics, route: 'Analytics'),
        _SidebarItem(title: 'Reports', icon: Icons.summarize_outlined, activeIcon: Icons.summarize, route: 'Reports'),
      ],
    ),
    _SidebarSection(
      key: 'system',
      title: 'System',
      icon: Icons.settings_outlined,
      items: [
        _SidebarItem(title: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, route: 'Settings'),
      ],
    ),
  ];

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return "${months[now.month - 1]} ${now.year}";
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) return "${(amount / 100000).toStringAsFixed(2)}L";
    if (amount >= 1000)   return "${(amount / 1000).toStringAsFixed(1)}K";
    return amount.toStringAsFixed(0);
  }

  bool get isDesktop => ScreenUtil().screenWidth > 1200;
  bool get isTablet  => ScreenUtil().screenWidth > 768 && ScreenUtil().screenWidth <= 1200;
  bool get isMobile  => ScreenUtil().screenWidth <= 768;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(selectedMenu),
        child: _buildContent(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgDark,
      appBar: isDesktop ? null : _buildEnhancedAppBar(),
      body: Row(
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSidebarOpen ? 240.w : 48.w,
              child: _buildProfessionalSidebar(),
            ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(isMobile ? 12.w : 24.w),
              child: _buildAnimatedContent(),
            ),
          ),
        ],
      ),
      drawer: (isMobile || isTablet) ? _buildProfessionalDrawer() : null,
      bottomNavigationBar: isMobile ? _buildEnhancedMobileBottomNav() : null,
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar() {
    return AppBar(
      backgroundColor: _bgCard,
      elevation: 0,
      leading: (isMobile || isTablet)
          ? IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.menu, color: _textPrimary, size: 20.sp),
        ),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      )
          : null,
      title: Row(
        children: [
          // 🎨 PULSE on the online indicator dot
          _PulseWidget(
            color: _accentSuccess,
            child: Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: _accentSuccess,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _accentSuccess.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.schoolName,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 16.sp : 18.sp,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.adminName != null && !isMobile)
                  Text(
                    widget.adminName!.toUpperCase(),
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildNotificationBell(),
        SizedBox(width: 8.w),
        _buildQuickActionsMenu(),
        SizedBox(width: 8.w),
        _buildAdminProfile(),
        SizedBox(width: 16.w),
      ],
    );
  }

  Widget _buildNotificationBell() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          children: [
            _industrialIconButton(
              Icons.notifications_outlined,
              onPressed: () => _showNotificationsPanel(context),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8.w,
                top: 8.w,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  // 🎨 PULSE on notification badge
                  child: _PulseWidget(
                    color: _accentDanger,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: _accentDanger,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bgCard, width: 2),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 18.w,
                        minHeight: 18.w,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: _textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Notifications",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _industrialButton("Mark all read", onPressed: () {}, isSecondary: true),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('notifications')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return _buildShimmerList();
                  final notifications = snapshot.data!.docs;
                  if (notifications.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.notifications_none,
                      title: "No notifications",
                      subtitle: "You're all caught up!",
                    );
                  }
                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) =>
                    // 🎨 STAGGERED notification items
                    _StaggeredItem(
                      index: index,
                      child: _buildNotificationTile(notifications[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(DocumentSnapshot notif) {
    final bool isRead = notif['read'] ?? true;
    final Timestamp? timestamp = notif['timestamp'];
    final String timeAgo =
    timestamp != null ? _getTimeAgo(timestamp.toDate()) : "Unknown";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isRead ? _bgElevated : _primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isRead ? _border : _primary.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: _getNotificationColor(notif['type'] ?? 'info').withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            _getNotificationIcon(notif['type'] ?? 'info'),
            color: _getNotificationColor(notif['type'] ?? 'info'),
            size: 20.sp,
          ),
        ),
        title: Text(
          notif['title'] ?? 'Notification',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 14.sp,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Text(
          notif['message'] ?? '',
          style: TextStyle(color: _textSecondary, fontSize: 12.sp),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(timeAgo,
            style: TextStyle(color: _textMuted, fontSize: 11.sp)),
        onTap: () => notif.reference.update({'read': true}),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'success': return _accentSuccess;
      case 'warning': return _accentWarning;
      case 'error':   return _accentDanger;
      default:        return _accentInfo;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle;
      case 'warning': return Icons.warning;
      case 'error':   return Icons.error;
      default:        return Icons.info;
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  Widget _buildQuickActionsMenu() {
    return PopupMenuButton<String>(
      offset: Offset(0, 40.h),
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: _border),
      ),
      child: _industrialIconButton(Icons.add_circle_outline),
      itemBuilder: (context) => [
        _buildPopupItem('student',      Icons.person_add,            'Add Student',   _accentInfo),
        _buildPopupItem('teacher',      Icons.school,                'Add Teacher',   _accentSuccess),
        _buildPopupItem('announcement', Icons.campaign,              'Announcement',  _accentWarning),
        _buildPopupItem('Exam',         Icons.assignment_ind_outlined,'ManageExam',   _accentSuccess),
        _buildPopupItem('event',        Icons.event,                 'Schedule Event',_primary),
      ],
      onSelected: (value) {},
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Text(label, style: TextStyle(color: _textPrimary, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildAdminProfile() {
    return PopupMenuButton<String>(
      offset: Offset(0, 40.h),
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: _border),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_primary, _primaryLight]),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  widget.adminName?.substring(0, 1).toUpperCase() ?? "A",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            if (!isMobile) ...[
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.adminName ?? "Admin",
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600)),
                  Text("Super Admin",
                      style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                ],
              ),
              SizedBox(width: 8.w),
              Icon(Icons.keyboard_arrow_down, color: _textMuted, size: 18.sp),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildProfileMenuItem('profile',  Icons.person_outline,    'Profile'),
        _buildProfileMenuItem('settings', Icons.settings_outlined, 'Settings'),
        _buildProfileMenuItem('billing',  Icons.credit_card,       'Billing'),
        const PopupMenuDivider(),
        _buildProfileMenuItem('logout',   Icons.logout,            'Logout', color: _accentDanger),
      ],
      onSelected: (value) {
        if (value == 'logout'){
          Text("Are you sure to logout:");
          _handleLogout();
        }
      },
    );
  }

  PopupMenuItem<String> _buildProfileMenuItem(
      String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color ?? _textSecondary, size: 20.sp),
          SizedBox(width: 12.w),
          Text(label,
              style: TextStyle(color: color ?? _textPrimary, fontSize: 14.sp)),
        ],
      ),
    );
  }

  Widget _buildProfessionalSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: isSidebarOpen ? 240.w : 56.w,
      decoration: BoxDecoration(
        // Deep obsidian with a subtle blue undertone
        color: const Color(0xFF080B12),
        border: Border(
          right: BorderSide(
            color: const Color(0xFF1A1F2E),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarBrand(),
          _buildSidebarSearch(),
          Expanded(
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                itemCount: _sidebarSections.length,
                itemBuilder: (context, index) =>
                    _buildSidebarSection(_sidebarSections[index], index),
              ),
            ),
          ),
          _buildSidebarBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSidebarBrand() {
    return Container(
      height: 58.h,
      padding: EdgeInsets.symmetric(
        horizontal: isSidebarOpen ? 16.w : 10.w,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF141824), width: 1),
        ),
      ),
      child: isSidebarOpen
          ? Row(
        children: [
          // Logo mark with gradient shimmer effect
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C8CF0), Color(0xFF5A6BE8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C8CF0).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.school_rounded,
                color: Colors.white, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFEEF1F8), Color(0xFF9AA5F3)],
                  ).createShader(bounds),
                  child: Text(
                    'EduManage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Text(
                  'Pro Dashboard',
                  style: TextStyle(
                    color: const Color(0xFF4A5168),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Toggle chevron
          GestureDetector(
            onTap: () => setState(() => isSidebarOpen = !isSidebarOpen),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AnimatedRotation(
                turns: 0,
                duration: const Duration(milliseconds: 220),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141824),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(Icons.chevron_left_rounded,
                      color: const Color(0xFF4A5168), size: 16.sp),
                ),
              ),
            ),
          ),
        ],
      )
          : Center(
        child: GestureDetector(
          onTap: () => setState(() => isSidebarOpen = !isSidebarOpen),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C8CF0), Color(0xFF5A6BE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C8CF0).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(Icons.school_rounded,
                  color: Colors.white, size: 18.sp),
            ),
          ),
        ),
      ),
    );
  }
  // ── Collapsible search bar ──────────────────────────────────────────────
  Widget _buildSidebarSearch() {
    if (!isSidebarOpen) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 4.h),
      child: Container(
        height: 34.h,
        decoration: BoxDecoration(
          color: const Color(0xFF111521),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: const Color(0xFF1A2035), width: 1),
        ),
        child: Row(
          children: [
            SizedBox(width: 10.w),
            Icon(Icons.search_rounded,
                color: const Color(0xFF3A4055), size: 15.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: TextField(
                style: TextStyle(
                    color: const Color(0xFF8B92A8), fontSize: 12.sp),
                decoration: InputDecoration(
                  hintText: 'Quick find...',
                  hintStyle: TextStyle(
                      color: const Color(0xFF3A4055), fontSize: 12.sp),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 8.w),
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2035),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text('⌘K',
                  style: TextStyle(
                      color: const Color(0xFF3A4055), fontSize: 9.sp)),
            ),
          ],
        ),
      ),
    );
  }
  // ── Section block ───────────────────────────────────────────────────────
  Widget _buildSidebarSection(_SidebarSection section, int sectionIndex) {
    final accentColor = _sectionAccentColors[section.key] ?? _accentIndigo;

    return Padding(
      padding: EdgeInsets.only(
          bottom: sectionIndex == _sidebarSections.length - 1 ? 0 : 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Section label ──
          if (isSidebarOpen && section.title.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 12.w, 4.h),
              child: Row(
                children: [
                  Container(
                    width: 14.w,
                    height: 1,
                    color: accentColor.withOpacity(0.35),
                    margin: EdgeInsets.only(right: 6.w),
                  ),
                  Text(
                    section.title.toUpperCase(),
                    style: TextStyle(
                      color: accentColor.withOpacity(0.55),
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else if (!isSidebarOpen)
          // Collapsed: show section divider dot
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Center(
                child: Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

          // ── Items ──
          ...section.items.map((item) => _buildSidebarMenuItem(
            item: item,
            sectionColor: accentColor,
            isExpanded: isSidebarOpen,
          )),
        ],
      ),
    );
  }
  // ── Single menu item ────────────────────────────────────────────────────
  Widget _buildSidebarMenuItem({
    required _SidebarItem item,
    required Color sectionColor,
    required bool isExpanded,
  }) {
    final isActive = selectedMenu == item.route;

    return StreamBuilder<QuerySnapshot>(
      stream: item.collection != null
          ? FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(item.collection!)
          .snapshots()
          : null,
      builder: (context, snapshot) {
        final count =
        snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Tooltip(
          message: isExpanded ? '' : item.title,
          preferBelow: false,
          verticalOffset: 0,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(
                color: sectionColor.withOpacity(0.25), width: 1),
          ),
          textStyle: TextStyle(
              color: const Color(0xFFEEF1F8),
              fontSize: 12.sp,
              fontWeight: FontWeight.w500),
          child: GestureDetector(
            onTap: () => setState(() {
              selectedMenu = item.route;
              currentPage = 1;
            }),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: _buildNavRowWithPill(
                  item: item,
                  isActive: isActive,
                  sectionColor: sectionColor,
                  isExpanded: isExpanded,
                  count: count),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavRowWithPill({
    required _SidebarItem item,
    required bool isActive,
    required Color sectionColor,
    required bool isExpanded,
    required int count,
  }) {
    return _Win11NavRow(
      isActive: isActive,
      accentColor: sectionColor,
      isExpanded: isExpanded,
      child: Row(
        mainAxisAlignment:
        isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          // Active pill indicator (left edge)
          if (isExpanded) ...[
            _ActivePill(isActive: isActive, color: sectionColor),
            SizedBox(width: isActive ? 10.w : 4.w),
          ],

          // Icon with glow when active
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.all(isActive ? 7.w : 6.w),
            decoration: isActive
                ? BoxDecoration(
              color: sectionColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: sectionColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            )
                : BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              color: isActive ? sectionColor : const Color(0xFF4A5168),
              size: isExpanded ? 16.sp : 20.sp,
            ),
          ),

          if (isExpanded) ...[
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFFEEF1F8)
                      : const Color(0xFF6B7385),
                  fontSize: 13.sp,
                  fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: isActive ? 0.1 : 0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Count badge
            if (item.collection != null && count > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? sectionColor.withOpacity(0.2)
                      : const Color(0xFF141824),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isActive
                        ? sectionColor.withOpacity(0.4)
                        : const Color(0xFF1E2538),
                    width: 1,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: TextStyle(
                    color: isActive
                        ? sectionColor
                        : const Color(0xFF4A5168),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Bottom profile + logout ─────────────────────────────────────────────
  Widget _buildSidebarBottomActions() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFF141824), width: 1),
        ),
        // Subtle upward gradient
        gradient: LinearGradient(
          colors: [
            const Color(0xFF080B12).withOpacity(0),
            const Color(0xFF080B12),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logout button
          Padding(
            padding: EdgeInsets.fromLTRB(
                isSidebarOpen ? 10.w : 8.w,
                8.h,
                isSidebarOpen ? 10.w : 8.w,
                4.h),
            child: GestureDetector(
              onTap: _handleLogout,
              child: _Win11HoverRow(
                isExpanded: isSidebarOpen,
                child: isSidebarOpen
                    ? Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: const Color(0xFFF2657A), size: 16.sp),
                    SizedBox(width: 10.w),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: const Color(0xFFF2657A),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
                    : Icon(Icons.logout_rounded,
                    color: const Color(0xFFF2657A), size: 18.sp),
              ),
            ),
          ),

          // Profile strip
          Container(
            margin: EdgeInsets.fromLTRB(
                isSidebarOpen ? 10.w : 6.w,
                0,
                isSidebarOpen ? 10.w : 6.w,
                10.h),
            padding: EdgeInsets.symmetric(
                horizontal: isSidebarOpen ? 10.w : 6.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1220),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: const Color(0xFF1A2035), width: 1),
            ),
            child: isSidebarOpen
                ? Row(
              children: [
                // Avatar with gradient ring
                Container(
                  padding: const EdgeInsets.all(1.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C8CF0), Color(0xFF3DD68B)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C8CF0),
                      borderRadius: BorderRadius.circular(6.5.r),
                    ),
                    child: Center(
                      child: Text(
                        widget.adminName
                            ?.substring(0, 1)
                            .toUpperCase() ??
                            'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.adminName ?? 'Admin',
                        style: TextStyle(
                          color: const Color(0xFFCDD2E0),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 5.w,
                            height: 5.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3DD68B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: const Color(0xFF4A5168),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.more_horiz_rounded,
                    color: const Color(0xFF3A4055), size: 16.sp),
              ],
            )
                : Center(
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C8CF0), Color(0xFF3DD68B)],
                  ),
                  borderRadius: BorderRadius.circular(7.r),
                ),
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C8CF0),
                    borderRadius: BorderRadius.circular(5.5.r),
                  ),
                  child: Center(
                    child: Text(
                      widget.adminName
                          ?.substring(0, 1)
                          .toUpperCase() ??
                          'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalDrawer() {
    return Drawer(
      backgroundColor: _bgDark,
      width: 300.w,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: _sidebarSections.length,
              itemBuilder: (context, index) => _buildDrawerSection(
                _sidebarSections[index], index,
              ),
            ),
          ),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        bottom: 20.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(bottom: BorderSide(color: _sidebarBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_primary, _primaryLight]),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.school, color: Colors.white, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EduManage',
                        style: TextStyle(color: _sidebarTextActive, fontSize: 16.sp, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.schoolName,
                        style: TextStyle(color: _sidebarMuted, fontSize: 11.sp, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: _sidebarElevated,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: _sidebarBorder),
                  ),
                  child: Icon(Icons.close, color: _sidebarText, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _sidebarElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _sidebarBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_primary, _primaryLight]),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      widget.adminName?.substring(0, 1).toUpperCase() ?? 'A',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.adminName ?? 'Admin',
                        style: TextStyle(color: _sidebarTextActive, fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Super Admin',
                        style: TextStyle(color: _sidebarMuted, fontSize: 11.sp, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: _accentSuccess,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: _accentSuccess.withOpacity(0.4), blurRadius: 6)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(_SidebarSection section, int sectionIndex) {
    final accentColor = _sectionAccentColors[section.key] ?? _accentIndigo;
    final isExpanded = _expandedSections[section.key] ?? true;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expandedSections[section.key] = !isExpanded),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
              child: Row(
                children: [
                  Icon(section.icon, color: accentColor, size: 16.sp),
                  SizedBox(width: 10.w),
                  Text(
                    section.title.toUpperCase(),
                    style: TextStyle(
                      color: _sidebarMuted,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, color: _sidebarMuted, size: 16.sp),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: isExpanded
                ? Column(
              children: section.items.asMap().entries.map((entry) {
                return _buildDrawerMenuItem(
                  item: entry.value,
                  sectionColor: accentColor,
                  index: entry.key,
                );
              }).toList(),
            )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required _SidebarItem item,
    required Color sectionColor,
    required int index,
  }) {
    final isActive = selectedMenu == item.route;

    return StreamBuilder<QuerySnapshot>(
      stream: item.collection != null
          ? FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(item.collection!)
          .snapshots()
          : null,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return GestureDetector(
          onTap: () {
            setState(() => selectedMenu = item.route);
            Navigator.pop(context);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(bottom: 2.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isActive ? sectionColor.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
              border: isActive
                  ? Border.all(color: sectionColor.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: isActive
                      ? BoxDecoration(
                    color: sectionColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  )
                      : null,
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    color: isActive ? sectionColor : _sidebarText,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: isActive ? _sidebarTextActive : _sidebarText,
                      fontSize: 14.sp,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.collection != null && count > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isActive ? sectionColor.withOpacity(0.15) : _sidebarElevated,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: isActive ? sectionColor : _sidebarText,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isActive)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    margin: EdgeInsets.only(left: 10.w),
                    decoration: BoxDecoration(
                      color: sectionColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _sidebarBg,
        border: Border(top: BorderSide(color: _sidebarBorder)),
      ),
      child: GestureDetector(
        onTap: _handleLogout,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: _accentDanger.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _accentDanger.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: _accentDanger, size: 18.sp),
              SizedBox(width: 10.w),
              Text(
                'Logout',
                style: TextStyle(color: _accentDanger, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ─── DASHBOARD CONTENT ───────────────────────────────────
  Widget _dashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting header ─────────────────────────────────────────────
          _buildDashboardHeader(),
          SizedBox(height: isMobile ? 16.h : 20.h),

          _buildSectionLabel('At a Glance', Icons.bar_chart_rounded,
              const Color(0xFF7C8CF0)),
          SizedBox(height: 12.h),

          // ── KPI cards ────────────────────────────────────────────────────
          _buildKpiCards(),
          SizedBox(height: isMobile ? 16.h : 20.h),

          _buildSectionLabel(
              'Analytics', Icons.insights_rounded, const Color(0xFF4DBEF7)),
          SizedBox(height: 12.h),

          // ── Charts ───────────────────────────────────────────────────────
          _buildChartsRow(),
          SizedBox(height: isMobile ? 16.h : 20.h),

          _buildSectionLabel(
              'Activity', Icons.access_time_rounded, const Color(0xFF3DD68B)),
          SizedBox(height: 12.h),

          // ── Recent students + Quick actions ────────────────────────────
          _buildBottomRow(),
          SizedBox(height: 24.h),

          Center(
            child: Text(
              'EduManage Pro · ${widget.schoolName}',
              style: TextStyle(
                color: const Color(0xFF2A2E3B),
                fontSize: 11.sp,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final greetingIcon = hour < 12 ? '☀️' : hour < 17 ? '🌤' : '🌙';
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(greetingIcon, style: TextStyle(fontSize: 20.sp)),
                    SizedBox(width: 8.w),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFEEF1F8), Color(0xFF7C8CF0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        '$greeting, ${widget.adminName?.split(' ').first ?? 'Admin'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: const Color(0xFF5A6072), size: 12.sp),
                    SizedBox(width: 6.w),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: const Color(0xFF5A6072),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    _PulseWidget(
                      color: const Color(0xFF3DD68B),
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3DD68B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: const Color(0xFF3DD68B),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            _buildHeaderChip(
              icon: Icons.add_rounded,
              label: 'Add Student',
              color: const Color(0xFF7C8CF0),
              onTap: () => setState(() => selectedMenu = 'Students'),
            ),
            SizedBox(width: 8.w),
            _buildHeaderChip(
              icon: Icons.download_outlined,
              label: 'Export',
              color: const Color(0xFF3DD68B),
              onTap: () {},
            ),
            SizedBox(width: 8.w),
          ],
          _buildHeaderChip(
            icon: Icons.refresh_rounded,
            label: '',
            color: const Color(0xFF4DBEF7),
            onTap: () => setState(() {}),
            iconOnly: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.0),
          duration: const Duration(milliseconds: 150),
          builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
          child: Container(
            padding: iconOnly
                ? EdgeInsets.all(10.w)
                : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16.sp),
                if (!iconOnly && label.isNotEmpty) ...[
                  SizedBox(width: 6.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
// 🔧 EXACT FIX — Replace _buildKpiCards() in your file
//
// Find this method (around line 2305) and replace the WHOLE method with this.
// Two bugs fixed:
//   1. Fee: was reading 'fees' collection → now reads 'feePayments'
//   2. Attendance: was querying date field on wrong level → now reads
//      attendance/{today}/summaries subcollection correctly
// ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKpiCards() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      // ── Students ──────────────────────────────────────────────────────────
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .snapshots(),
      builder: (context, studentSnap) {
        return StreamBuilder<QuerySnapshot>(
          // ── Teachers ────────────────────────────────────────────────────
          stream: FirebaseFirestore.instance
              .collection('schools')
              .doc(widget.schoolId)
              .collection('teachers')
              .snapshots(),
          builder: (context, teacherSnap) {
            return StreamBuilder<QuerySnapshot>(
              // ── FIX 1: was 'fees' → correct path is 'feePayments' ────────
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('feePayments')   // ✅ FIXED
                  .snapshots(),
              builder: (context, feeSnap) {
                return StreamBuilder<QuerySnapshot>(
                  // ── FIX 2: was querying wrong level → now reads
                  //    attendance/{today}/summaries subcollection ────────────
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('attendance')
                      .doc(today)               // ✅ FIXED: today's date doc
                      .collection('summaries')  // ✅ FIXED: subcollection
                      .snapshots(),
                  builder: (context, attSnap) {

                    final students = studentSnap.data?.docs.length ?? 0;
                    final teachers = teacherSnap.data?.docs.length ?? 0;

                    // ── Fee calculation ──────────────────────────────────
                    double totalFees = 0;
                    double paidFees  = 0;
                    if (feeSnap.hasData) {
                      for (var doc in feeSnap.data!.docs) {
                        final d      = doc.data() as Map<String, dynamic>;
                        final amount = ((d['amount']      ?? d['totalAmount'] ?? d['feeAmount'] ?? 0) as num).toDouble();
                        final paid   = ((d['paidAmount']  ?? d['amountPaid']  ?? 0) as num).toDouble();
                        final status = (d['status'] ?? d['paymentStatus'] ?? '').toString().toLowerCase();

                        totalFees += amount;

                        if (status == 'paid' || status == 'complete' || status == 'completed') {
                          paidFees += amount;
                        } else if (status == 'partial') {
                          paidFees += paid;
                        } else if (status == 'pending' || status == 'unpaid') {
                          // don't add to paid
                        } else {
                          // no status — use paidAmount if present
                          paidFees += paid > 0 ? paid : amount;
                        }
                      }
                    }

                    // ── Attendance calculation ───────────────────────────
                    // Reads exact field names from your Firestore:
                    // { totalStudents, present, absent, late, leave }
                    int totalStudents = 0;
                    int presentCount  = 0;
                    if (attSnap.hasData) {
                      for (var doc in attSnap.data!.docs) {
                        final d = doc.data() as Map<String, dynamic>;
                        totalStudents += ((d['totalStudents'] ?? 0) as num).toInt();
                        presentCount  += ((d['present']       ?? 0) as num).toInt();
                      }
                    }
                    final attPct = totalStudents > 0
                        ? ((presentCount / totalStudents) * 100).toStringAsFixed(1)
                        : '0.0';
                    final attDouble = double.tryParse(attPct) ?? 0.0;

                    final cards = [
                      _KpiData(
                        title: 'Total Students',
                        value: students,
                        valueStr: students.toString(),
                        icon: Icons.people_alt_rounded,
                        color: const Color(0xFF7C8CF0),
                        bgGradient: [const Color(0xFF1A1D2E), const Color(0xFF161922)],
                        trend: '+12',
                        trendUp: true,
                        subtitle: 'enrolled this term',
                        route: 'Students',
                      ),
                      _KpiData(
                        title: 'Teachers',
                        value: teachers,
                        valueStr: teachers.toString(),
                        icon: Icons.school_rounded,
                        color: const Color(0xFF3DD68B),
                        bgGradient: [const Color(0xFF162A22), const Color(0xFF161922)],
                        trend: '+2',
                        trendUp: true,
                        subtitle: 'active faculty',
                        route: 'Teachers',
                      ),
                      _KpiData(
                        title: 'Fee Collection',
                        value: paidFees.toInt(),
                        valueStr: '₨${_formatCurrency(paidFees)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: const Color(0xFF4DBEF7),
                        bgGradient: [const Color(0xFF152030), const Color(0xFF161922)],
                        trend: totalFees > 0
                            ? '${((paidFees / totalFees) * 100).toStringAsFixed(0)}%'
                            : '0%',
                        trendUp: paidFees >= (totalFees * 0.5),
                        subtitle: 'of ₨${_formatCurrency(totalFees)} total',
                        route: 'Fees',
                      ),
                      _KpiData(
                        title: 'Attendance',
                        value: 0,
                        valueStr: totalStudents > 0 ? '$attPct%' : '--',
                        icon: Icons.fact_check_rounded,
                        color: const Color(0xFFF2A93B),
                        bgGradient: [const Color(0xFF2A2010), const Color(0xFF161922)],
                        trend: totalStudents > 0
                            ? '$attPct%'
                            : 'No data',
                        trendUp: attDouble >= 75,
                        subtitle: totalStudents > 0
                            ? '$presentCount / $totalStudents today'
                            : 'No records today',
                        route: 'Attendance',
                      ),
                    ];

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossCount = constraints.maxWidth < 600 ? 2 : 4;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossCount,
                            crossAxisSpacing: 14.w,
                            mainAxisSpacing: 14.h,
                            childAspectRatio: constraints.maxWidth < 600 ? 1.35 : 1.7,
                          ),
                          itemCount: cards.length,
                          itemBuilder: (_, i) => _StaggeredItem(
                            index: i,
                            child: _buildKpiCard(cards[i]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildKpiCard(_KpiData data) {
    return _HoverCard(
      glowColor: data.color,
      scaleUp: 1.02,
      child: GestureDetector(
        onTap: () => setState(() => selectedMenu = data.route),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: data.bgGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: data.color.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top row: icon + trend chip ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: data.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: data.color.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(data.icon, color: data.color, size: 20.sp),
                    ),
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: (data.trendUp
                            ? const Color(0xFF3DD68B)
                            : const Color(0xFFF2657A))
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            data.trendUp
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: data.trendUp
                                ? const Color(0xFF3DD68B)
                                : const Color(0xFFF2657A),
                            size: 10.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            data.trend,
                            style: TextStyle(
                              color: data.trendUp
                                  ? const Color(0xFF3DD68B)
                                  : const Color(0xFFF2657A),
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Value ──────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.valueStr,
                      style: TextStyle(
                        color: const Color(0xFFEEF1F8),
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      data.title,
                      style: TextStyle(
                        color: data.color.withOpacity(0.9),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        color: const Color(0xFF5A6072),
                        fontSize: 10.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return Flex(
          direction: isNarrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Attendance bar chart ──────────────────────────────────
            Flexible(
              flex: 3,
              child: _buildAttendanceChartCard(),
            ),
            SizedBox(width: isNarrow ? 0 : 14.w, height: isNarrow ? 14.h : 0),
            // ── Fee donut chart ────────────────────────────────────────
            Flexible(
              flex: 2,
              child: _buildFeeDonutChart(),
            ),
          ],
        );
      },
    );
  }
// ── ATTENDANCE BAR CHART ──────────────────────────────────────────────────
  Widget _buildAttendanceChartCard() {
    final now   = DateTime.now();
    final days  = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final ids   = days.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    final labels= days.map((d) => DateFormat('E').format(d)).toList();

    return _GlowBorderCard(
      baseColor: _primary,
      child: _industrialChartCard(
        title: 'Attendance Overview',
        subtitle: 'Last 7 days · Live',
        child: SizedBox(
          height: isMobile ? 200.h : 260.h,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            // Fetch all 7 days once, then each StreamBuilder handles live updates.
            // For simplicity we use a single-pass async fetch here.
            future: _fetchWeekAttendance(ids),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Center(child: CircularProgressIndicator(
                    color: _primary, strokeWidth: 2));
              }
              final data = snap.data!;
              final hasAny = data.any((d) => (d['total'] as int) > 0);
              if (!hasAny) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: _textMuted, size: 36.sp),
                    SizedBox(height: 8.h),
                    Text('No attendance data yet',
                        style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
                  ],
                ));
              }
              return BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
                      '${r.toY.toStringAsFixed(0)}%',
                      TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, interval: 25, reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                        style: TextStyle(color: _textMuted, fontSize: 10.sp)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: Text(labels[i],
                            style: TextStyle(color: _textMuted, fontSize: 10.sp)),
                      );
                    },
                  )),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final pct = (data[i]['pct'] as double).clamp(0.0, 100.0);
                  final col = pct >= 90 ? _accentSuccess
                      : pct >= 75 ? _accentWarning : _accentDanger;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: pct,
                      width: isMobile ? 14.w : 20.w,
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(6.r)),
                      gradient: LinearGradient(
                        colors: [col.withOpacity(0.6), col],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ]);
                }),
              ));
            },
          ),
        ),
      ),
    );
  }

// Fetches last 7 days attendance data
  Future<List<Map<String, dynamic>>> _fetchWeekAttendance(
      List<String> ids) async {
    final results = <Map<String, dynamic>>[];
    for (final dateId in ids) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('attendance')
            .doc(dateId)
            .collection('summaries')
            .get();
        int total = 0, present = 0;
        for (final d in snap.docs) {
          final m = d.data();
          total   += (m['totalStudents'] ?? 0) as int;
          present += (m['present']       ?? 0) as int;
        }
        results.add({
          'dateId':  dateId,
          'total':   total,
          'present': present,
          'pct':     total > 0 ? present / total * 100.0 : 0.0,
        });
      } catch (_) {
        results.add({'dateId': dateId, 'total': 0, 'present': 0, 'pct': 0.0});
      }
    }
    return results;
  }


  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 5.w),
        Text(label,
            style:
            TextStyle(color: const Color(0xFF8B92A8), fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildShimmerChart() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E212E),
      highlightColor: const Color(0xFF2A2E3B),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E212E),
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
// ── FEE DONUT CHART ───────────────────────────────────────────────────────
  Widget _buildFeeDonutChart() {
    return _GlowBorderCard(
      baseColor: const Color(0xFF4DBEF7),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee Collection',
              style: TextStyle(
                color: const Color(0xFFEEF1F8),
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _getCurrentMonthName(),
              style: TextStyle(
                  color: const Color(0xFF5A6072), fontSize: 11.sp),
            ),
            SizedBox(height: 16.h),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('fees')
                  .snapshots(),
              builder: (context, snapshot) {
                double totalFees = 0, paidFees = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    totalFees += (d['totalAmount'] ?? 0).toDouble();
                    paidFees  += (d['paidAmount']  ?? 0).toDouble();
                  }
                } else {
                  totalFees = 100;
                  paidFees  = 72;
                }
                final unpaid = (totalFees - paidFees).clamp(0, double.infinity).toDouble();
                final pct = totalFees > 0 ? (paidFees / totalFees * 100) : 0;

                return Column(
                  children: [
                    SizedBox(
                      height: 140.h,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 44.r,
                              sections: [
                                PieChartSectionData(
                                  value: paidFees > 0 ? paidFees : 1,
                                  color: const Color(0xFF4DBEF7),
                                  radius: 26.r,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: unpaid > 0 ? unpaid : 0.001,
                                  color: const Color(0xFF2A2E3B),
                                  radius: 22.r,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: const Color(0xFFEEF1F8),
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Collected',
                                style: TextStyle(
                                  color: const Color(0xFF5A6072),
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _feeStatChip(
                            label: 'Collected',
                            value: '₨${_formatCurrency(paidFees)}',
                            color: const Color(0xFF4DBEF7),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _feeStatChip(
                            label: 'Pending',
                            value: '₨${_formatCurrency(unpaid)}',
                            color: const Color(0xFFF2657A),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _feeStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700)),
          SizedBox(height: 2.h),
          Text(label,
              style: TextStyle(
                  color: const Color(0xFF5A6072), fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        return Flex(
          direction: isNarrow ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Recent students ─────────────────────────────────────────
            Flexible(
              flex: 3,
              child: _buildRecentStudentsCard(),
            ),
            SizedBox(width: isNarrow ? 0 : 14.w, height: isNarrow ? 14.h : 0),
            // ── Quick actions ───────────────────────────────────────────
            Flexible(
              flex: 2,
              child: _buildQuickActionsCard(),
            ),
          ],
        );
      },
    );
  }

// ── RECENT STUDENTS ───────────────────────────────────────────────────────
  Widget _buildRecentStudentsCard() {
    return _GlowBorderCard(
      baseColor: const Color(0xFF3DD68B),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Enrollments',
                      style: TextStyle(
                        color: const Color(0xFFEEF1F8),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text('Latest students added',
                        style: TextStyle(
                            color: const Color(0xFF5A6072), fontSize: 11.sp)),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => selectedMenu = 'Students'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3DD68B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                            color: const Color(0xFF3DD68B).withOpacity(0.25)),
                      ),
                      child: Text(
                        'View all →',
                        style: TextStyle(
                          color: const Color(0xFF3DD68B),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            // List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schools')
                  .doc(widget.schoolId)
                  .collection('students')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return _buildShimmerList();
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.people_outline,
                    title: 'No students yet',
                    subtitle: 'Add your first student to get started',
                  );
                }
                return Column(
                  children: docs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value.data() as Map<String, dynamic>;
                    return _StaggeredItem(
                      index: i,
                      child: _buildStudentTile(d, i),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTile(Map<String, dynamic> d, int index) {
    final avatarColors = [
      const Color(0xFF7C8CF0),
      const Color(0xFF3DD68B),
      const Color(0xFF4DBEF7),
      const Color(0xFFF2A93B),
      const Color(0xFFB084F5),
    ];
    final color = avatarColors[index % avatarColors.length];
    final name = d['name'] ?? d['studentName'] ?? 'Student';
    final cls  = d['class'] ?? d['className'] ?? '—';
    final roll = d['rollNo'] ?? d['rollNumber'] ?? '#';

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E212E),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF2A2E3B), width: 1),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Name + class
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: const Color(0xFFEEF1F8),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Class $cls',
                  style: TextStyle(
                      color: const Color(0xFF5A6072), fontSize: 11.sp),
                ),
              ],
            ),
          ),
          // Roll badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              '#$roll',
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
// ── QUICK ACTIONS ─────────────────────────────────────────────────────────
  Widget _buildQuickActionsCard() {
    final actions = [
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Add Student',
        sublabel: 'Enroll new student',
        color: const Color(0xFF7C8CF0),
        onTap: () => setState(() => selectedMenu = 'Students'),
      ),
      _QuickAction(
        icon: Icons.school_rounded,
        label: 'Add Teacher',
        sublabel: 'Register new teacher',
        color: const Color(0xFF3DD68B),
        onTap: () => setState(() => selectedMenu = 'Teachers'),
      ),
      _QuickAction(
        icon: Icons.fact_check_rounded,
        label: 'Take Attendance',
        sublabel: "Mark today's attendance",
        color: const Color(0xFFF2A93B),
        onTap: () => setState(() => selectedMenu = 'Attendance'),
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Collect Fee',
        sublabel: 'Record fee payment',
        color: const Color(0xFF4DBEF7),
        onTap: () => setState(() => selectedMenu = 'Fees'),
      ),
      _QuickAction(
        icon: Icons.campaign_rounded,
        label: 'Announcement',
        sublabel: 'Broadcast to all',
        color: const Color(0xFFB084F5),
        onTap: () => setState(() => selectedMenu = 'Announcements'),
      ),
    ];

    return _GlowBorderCard(
      baseColor: const Color(0xFF7C8CF0),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                color: const Color(0xFFEEF1F8),
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2.h),
            Text('Jump to common tasks',
                style:
                TextStyle(color: const Color(0xFF5A6072), fontSize: 11.sp)),
            SizedBox(height: 14.h),
            ...actions.asMap().entries.map((entry) => _StaggeredItem(
              index: entry.key,
              child: _buildQuickActionTile(entry.value),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(_QuickAction action) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: _HoverCard(
        glowColor: action.color,
        scaleUp: 1.01,
        child: GestureDetector(
          onTap: action.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E212E),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFF2A2E3B), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: action.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(action.icon, color: action.color, size: 16.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.label,
                          style: TextStyle(
                            color: const Color(0xFFEEF1F8),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          action.sublabel,
                          style: TextStyle(
                              color: const Color(0xFF5A6072), fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: const Color(0xFF3A4055), size: 12.sp),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        SizedBox(width: 10.w),
        Icon(icon, color: color, size: 15.sp),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF8B92A8),
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }



  Widget _attPill(String label, int value, Color color) => Column(
    children: [
      Text('$value',
          style: TextStyle(
              color: color, fontSize: 13.sp, fontWeight: FontWeight.w700)),
      Text(label,
          style: TextStyle(color: _textMuted, fontSize: 10.sp)),
    ],
  );

  Widget _buildEnhancedStatsGrid() {
    final stats = [
      {
        'title': 'Total Students', 'collection': 'students',
        'icon': Icons.people,     'color': _primary,
        'trend': '+12%',          'subtitle': 'enrolled this term',
      },
      {
        'title': 'Teachers',      'collection': 'teachers',
        'icon': Icons.school,     'color': _accentSuccess,
        'trend': '+5%',           'subtitle': 'active faculty',
      },
    ];

    if (isMobile) {
      return Column(children: [
        _StaggeredItem(index: 0, child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildEnhancedStatCard(stats[0]))),
        _StaggeredItem(index: 1, child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildEnhancedStatCard(stats[1]))),
        _StaggeredItem(index: 2, child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildFeeStat())),          // ✅ real-time fee
        _StaggeredItem(index: 3, child: Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildAttendanceStat())),   // ✅ real-time attendance
      ]);
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isTablet ? 2 : 4,
      crossAxisSpacing: 20.w,
      mainAxisSpacing: 20.h,
      childAspectRatio: 1.5,
      children: [
        _StaggeredItem(index: 0, child: _buildEnhancedStatCard(stats[0])),
        _StaggeredItem(index: 1, child: _buildEnhancedStatCard(stats[1])),
        _StaggeredItem(index: 2, child: _buildFeeStat()),         // ✅ real-time
        _StaggeredItem(index: 3, child: _buildAttendanceStat()),  // ✅ real-time
      ],
    );
  }



  Widget _buildEnhancedStatCard(Map<String, dynamic> stat) {
    final collection = stat['collection'] as String;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection(collection)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final isLoading = !snapshot.hasData;

        // 🎨 HOVER glow on stat cards
        return _HoverCard(
          scaleUp: 1.025,
          glowColor: stat['color'] as Color,
          enableGlow: true,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 4))
              ],
            ),
            child: isLoading
                ? _buildStatShimmer()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(stat['icon'] as IconData,
                          color: stat['color'] as Color, size: 24.sp),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _accentSuccess.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward,
                              color: _accentSuccess, size: 12.sp),
                          SizedBox(width: 4.w),
                          Text(stat['trend'] as String,
                              style: TextStyle(
                                  color: _accentSuccess,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎨 ANIMATED COUNTER for stat numbers
                    _AnimatedCounter(
                      value: count,
                      style: TextStyle(
                          color: _textPrimary,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 4.h),
                    Text(stat['title'] as String,
                        style: TextStyle(
                            color: _textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _feePill(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700)),
      Text(label,
          style: TextStyle(color: _textMuted, fontSize: 10.sp)),
    ],
  );

  Widget _buildStatShimmer() {
    return Shimmer.fromColors(
      baseColor: _bgElevated,
      highlightColor: _bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r))),
              Container(
                  width: 60.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r))),
            ],
          ),
          Container(
              width: 80.w,
              height: 32.h,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r))),
        ],
      ),
    );
  }


  Widget _buildAttendanceStat() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('attendance')
          .doc(today)
          .collection('summaries')
          .snapshots(),
      builder: (context, snap) {
        int total = 0, present = 0, absent = 0;
        if (snap.hasData) {
          for (final d in snap.data!.docs) {
            final m = d.data() as Map<String, dynamic>;
            total   += (m['totalStudents'] ?? 0) as int;
            present += (m['present']       ?? 0) as int;
            absent  += (m['absent']        ?? 0) as int;
          }
        }
        final pct    = total > 0 ? present / total * 100 : 0.0;
        final pctStr = total > 0 ? '${pct.toStringAsFixed(1)}%' : '--';
        final pctCol = pct >= 90 ? _accentSuccess
            : pct >= 75 ? _accentWarning : _accentDanger;
        final loading = snap.connectionState == ConnectionState.waiting;

        return _HoverCard(
          scaleUp: 1.025,
          glowColor: _accentWarning,
          enableGlow: true,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20, offset: const Offset(0, 4),
              )],
            ),
            child: loading
                ? _buildStatShimmer()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: _accentWarning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.fact_check,
                          color: _accentWarning, size: 22.sp),
                    ),
                    Row(children: [
                      _PulseWidget(
                        color: pctCol,
                        child: Container(
                          width: 7.w, height: 7.w,
                          decoration: BoxDecoration(
                              color: pctCol, shape: BoxShape.circle),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: pctCol.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(pctStr,
                            style: TextStyle(color: pctCol,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ],
                ),
                SizedBox(height: 10.h),
                total > 0
                    ? _AnimatedCounter(
                    value: present,
                    style: TextStyle(color: _textPrimary,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800))
                    : Text('--', style: TextStyle(color: _textPrimary,
                    fontSize: 26.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 4.h),
                Text('Attendance Today',
                    style: TextStyle(color: _textSecondary,
                        fontSize: 13.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 8.h),
                if (total > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _miniPill('P', present, _accentSuccess),
                      _miniPill('A', absent,  _accentDanger),
                      _miniPill('/', total,   _textMuted),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniPill(String label, int val, Color col) => Column(
    children: [
      Text('$val', style: TextStyle(
          color: col, fontSize: 13.sp, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(color: _textMuted, fontSize: 10.sp)),
    ],
  );

  Widget _buildFeeStat() {
    final currentMonth = _getCurrentMonthYear(); // "2026-06"
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('feePayments') // ✅ your real collection
          .snapshots(),
      builder: (context, snap) {
        double total = 0, month = 0;
        int count = 0;
        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final amt = ((d['amount'] ?? 0) as num).toDouble();
            total += amt;
            count++;
            final ts = d['paymentDate'] as Timestamp?;
            if (ts != null) {
              final dt = ts.toDate();
              final mk = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
              if (mk == currentMonth) month += amt;
            }
          }
        }
        final loading = snap.connectionState == ConnectionState.waiting;

        return _HoverCard(
          scaleUp: 1.025,
          glowColor: _accentInfo,
          enableGlow: true,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _bgCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _border),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20, offset: const Offset(0, 4),
              )],
            ),
            child: loading
                ? _buildStatShimmer()
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: _accentInfo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.account_balance_wallet,
                          color: _accentInfo, size: 22.sp),
                    ),
                    Row(children: [
                      _PulseWidget(
                        color: _accentSuccess,
                        child: Container(
                          width: 7.w, height: 7.w,
                          decoration: const BoxDecoration(
                              color: _accentSuccess,
                              shape: BoxShape.circle),
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _accentSuccess.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(_getCurrentMonthName(),
                            style: TextStyle(color: _accentSuccess,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ],
                ),
                SizedBox(height: 10.h),
                Text('Rs ${_formatCurrency(total)}',
                    style: TextStyle(color: _textPrimary,
                        fontSize: 22.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 4.h),
                Text('Fee Collection',
                    style: TextStyle(color: _textSecondary,
                        fontSize: 13.sp, fontWeight: FontWeight.w500)),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('This month: Rs ${_formatCurrency(month)}',
                        style: TextStyle(
                            color: _accentSuccess, fontSize: 11.sp)),
                    Text('$count receipts',
                        style: TextStyle(
                            color: _textMuted, fontSize: 11.sp)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealAttendanceChart() {
    final now     = DateTime.now();
    final last6   = List.generate(6, (i) => now.subtract(Duration(days: 5 - i)));
    final dayIds  = last6.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();

    // ✅ Use collectionGroup to stream all summaries docs across all date docs
    // If collectionGroup has index issues, fall back to individual streams below.
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _attendanceChartStream(dayIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
              child: CircularProgressIndicator(color: _primary, strokeWidth: 2));
        }

        final dataPoints = snapshot.data!;
        final hasData    = dataPoints.any((d) => (d['total'] as int) > 0);

        if (!hasData) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.bar_chart, color: _textMuted, size: 40.sp),
              SizedBox(height: 8.h),
              Text('No attendance data yet',
                  style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
            ]),
          );
        }

        return LineChart(LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: _border, strokeWidth: 1, dashArray: [5, 5]),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, interval: 20, reservedSize: 40,
              getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                  style: TextStyle(color: _textMuted, fontSize: 11.sp)),
            )),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= last6.length) return const SizedBox();
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(DateFormat('E').format(last6[i]),
                      style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                );
              },
            )),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: 0, maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: dataPoints.asMap().entries.map((e) =>
                  FlSpot(e.key.toDouble(), e.value['percentage'] as double)).toList(),
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: const LinearGradient(colors: [_primary, _primaryLight]),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) {
                  final c = spot.y >= 90 ? _accentSuccess
                      : spot.y >= 75 ? _accentWarning : _accentDanger;
                  return FlDotCirclePainter(
                      radius: 5, color: _bgCard,
                      strokeWidth: 2.5, strokeColor: c);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [_primary.withOpacity(0.3), _primary.withOpacity(0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ));
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _attendanceChartStream(List<String> dayIds) {
    // Create one stream per day and combine them
    final streams = dayIds.map((dateId) =>
        FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('attendance')
            .doc(dateId)
            .collection('summaries')
            .snapshots()
            .map((snap) {
          int total = 0, present = 0;
          for (final doc in snap.docs) {
            final d = doc.data();
            total   += (d['totalStudents'] ?? 0) as int;
            present += (d['present']       ?? 0) as int;
          }
          return {
            'dateId':     dateId,
            'total':      total,
            'present':    present,
            'percentage': total > 0 ? present / total * 100.0 : 0.0,
          };
        }),
    ).toList();


    return Rx.combineLatestList<Map<String, dynamic>>(streams);

  }

  Widget _buildPeriodSelector(List<String> periods) {
    return Container(
      decoration: BoxDecoration(
          color: _bgElevated, borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        children: periods.map((period) {
          final isSelected = period == 'Week';
          return GestureDetector(
            onTap: () {},
            child: Container(
              padding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: isSelected ? _primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(period,
                  style: TextStyle(
                      color: isSelected ? Colors.white : _textSecondary,
                      fontSize: 12.sp,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnhancedAttendanceChart() {
    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: _border, strokeWidth: 1, dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text("${value.toInt()}%",
                style: TextStyle(color: _textMuted, fontSize: 11.sp)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              if (value.toInt() < labels.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(labels[value.toInt()],
                      style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 92), FlSpot(1, 88), FlSpot(2, 95),
            FlSpot(3, 90), FlSpot(4, 94), FlSpot(5, 85),
          ],
          isCurved: true,
          curveSmoothness: 0.3,
          gradient: const LinearGradient(colors: [_primary, _primaryLight]),
          barWidth: 3,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) =>
                FlDotCirclePainter(
                    radius: 5,
                    color: _bgCard,
                    strokeWidth: 2.5,
                    strokeColor: _primary),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _primary.withOpacity(0.3),
                _primary.withOpacity(0.0)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildRevenueChartCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('feePayments')
          .snapshots(),
      builder: (context, snap) {
        // Group by month — last 6 months
        final Map<String, double> monthly = {};
        final now = DateTime.now();
        for (int i = 5; i >= 0; i--) {
          final d  = DateTime(now.year, now.month - i, 1);
          final mk = '${d.year}-${d.month.toString().padLeft(2,'0')}';
          monthly[mk] = 0;
        }

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d   = doc.data() as Map<String, dynamic>;
            final amt = ((d['amount'] ?? 0) as num).toDouble();
            final ts  = d['paymentDate'] as Timestamp?;
            if (ts != null) {
              final dt = ts.toDate();
              final mk = '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
              if (monthly.containsKey(mk)) monthly[mk] = monthly[mk]! + amt;
            }
          }
        }

        final keys   = monthly.keys.toList();
        final values = monthly.values.toList();
        final maxVal = values.isEmpty ? 1.0
            : values.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);

        final loading = snap.connectionState == ConnectionState.waiting;
        final totalThisMonth = monthly[_getCurrentMonthYear()] ?? 0.0;

        return _GlowBorderCard(
          baseColor: _accentSky,
          child: _industrialChartCard(
            title: 'Fee Collection',
            subtitle: '${_getCurrentMonthName()} · Live',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary row
                Row(children: [
                  Text('Rs ${_formatCurrency(totalThisMonth)}',
                      style: TextStyle(color: _textPrimary,
                          fontSize: 20.sp, fontWeight: FontWeight.w800)),
                  SizedBox(width: 8.w),
                  _PulseWidget(
                    color: _accentSuccess,
                    child: Container(
                      width: 7.w, height: 7.w,
                      decoration: const BoxDecoration(
                          color: _accentSuccess, shape: BoxShape.circle),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text('this month',
                      style: TextStyle(color: _textMuted, fontSize: 12.sp)),
                ]),
                SizedBox(height: 16.h),
                // Bar chart
                loading
                    ? _buildStatShimmer()
                    : SizedBox(
                  height: isMobile ? 140.h : 180.h,
                  child: BarChart(BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (g, gi, r, ri) => BarTooltipItem(
                          'Rs ${_formatCurrency(r.toY)}',
                          TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp),
                        ),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= keys.length)
                            return const SizedBox();
                          final parts = keys[i].split('-');
                          final months = ['','Jan','Feb','Mar','Apr','May',
                            'Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
                          final mNum = int.tryParse(parts[1]) ?? 0;
                          return Padding(
                            padding: EdgeInsets.only(top: 5.h),
                            child: Text(
                              mNum > 0 && mNum <= 12 ? months[mNum] : '',
                              style: TextStyle(
                                  color: _textMuted, fontSize: 10.sp),
                            ),
                          );
                        },
                      )),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: _border, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(keys.length, (i) {
                      final isCurrentMonth = keys[i] == _getCurrentMonthYear();
                      return BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: isMobile ? 16.w : 22.w,
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6.r)),
                          gradient: LinearGradient(
                            colors: isCurrentMonth
                                ? [_accentSky.withOpacity(0.5), _accentSky]
                                : [_primary.withOpacity(0.3), _primary.withOpacity(0.6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ]);
                    }),
                  )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedRevenueChart() {
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100000,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25000,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: _border, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25000,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(
                "₨${(value / 1000).toInt()}k",
                style: TextStyle(color: _textMuted, fontSize: 10.sp)),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
              if (value.toInt() < labels.length) {
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(labels[value.toInt()],
                      style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        _makeBarData(0, 45000, _primary),
        _makeBarData(1, 68000, _primary),
        _makeBarData(2, 55000, _primary),
        _makeBarData(3, 82000, _accentSuccess),
        _makeBarData(4, 75000, _primary),
        _makeBarData(5, 92000, _accentSuccess),
      ],
    ));
  }

  BarChartGroupData _makeBarData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: isMobile ? 20.w : 28.w,
          borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final activities = snapshot.hasData ? snapshot.data!.docs : [];

        return _industrialChartCard(
          title: "Recent Activity",
          subtitle: "Latest updates from your school",
          actions: [
            TextButton(
              onPressed: () {},
              child: Text("View All",
                  style: TextStyle(
                      color: _primary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          child: activities.isEmpty
              ? _buildEmptyState(
              icon: Icons.history,
              title: "No recent activity",
              subtitle: "Activities will appear here",
              compact: true)
              : Column(
            children: activities.asMap().entries.map((entry) {
              // 🎨 STAGGERED activity items
              return _StaggeredItem(
                index: entry.key,
                child: _buildActivityItem(
                  activity: entry.value,
                  isLast: entry.key == activities.length - 1,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActivityItem(
      {required DocumentSnapshot activity, required bool isLast}) {
    final String type = activity['type'] ?? 'info';
    final Timestamp? timestamp = activity['timestamp'];
    final String time =
    timestamp != null ? _getTimeAgo(timestamp.toDate()) : "Unknown";

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: _getActivityColor(type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(_getActivityIcon(type),
                    color: _getActivityColor(type), size: 18.sp),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    color: _border,
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['title'] ?? 'Activity',
                    style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(activity['description'] ?? '',
                    style:
                    TextStyle(color: _textSecondary, fontSize: 12.sp),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4.h),
                Text(time,
                    style: TextStyle(color: _textMuted, fontSize: 11.sp)),
                if (!isLast) SizedBox(height: 16.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'student':    return _accentInfo;
      case 'teacher':    return _accentSuccess;
      case 'fee':        return _accentWarning;
      case 'attendance': return _primary;
      default:           return _textSecondary;
    }
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'student':    return Icons.person_add;
      case 'teacher':    return Icons.school;
      case 'fee':        return Icons.payments;
      case 'attendance': return Icons.fact_check;
      default:           return Icons.info;
    }
  }

  Widget _buildQuickStatsCard() {
    return _industrialChartCard(
      title: "Quick Stats",
      subtitle: "This month's overview",
      child: Column(
        children: [
          _buildQuickStatRow("New Admissions",  "24", _accentInfo),
          SizedBox(height: 16.h),
          _buildQuickStatRow("Fee Defaulters",  "8",  _accentDanger),
          SizedBox(height: 16.h),
          _buildQuickStatRow("Upcoming Events", "3",  _accentWarning),
          SizedBox(height: 16.h),
          _buildQuickStatRow("Staff on Leave",  "2",  _textSecondary),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 8.w,
                height: 8.w,
                decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
            SizedBox(width: 12.w),
            Text(label,
                style:
                TextStyle(color: _textSecondary, fontSize: 14.sp)),
          ],
        ),
        Text(value,
            style: TextStyle(
                color: _textPrimary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  // ─── PLACEHOLDER MODULES ─────────────────────────────────
  Widget _analyticsModule()     => _comingSoon("Analytics");
  Widget _announcementsModule() => _comingSoon("Announcements");

  Widget _comingSoon(String title) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 32.w : 48.w),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch,
                color: _primary,
                size: isMobile ? 48.sp : 64.sp),
            SizedBox(height: isMobile ? 16.h : 24.h),
            Text("$title Module",
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: isMobile ? 20.sp : 24.sp,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text("Coming Soon",
                style: TextStyle(
                    color: _textMuted,
                    fontSize: isMobile ? 14.sp : 16.sp)),
            SizedBox(height: 24.h),
            _industrialButton("Back to Dashboard",
                onPressed: () =>
                    setState(() => selectedMenu = "Dashboard"),
                isSecondary: true),
          ],
        ),
      ),
    );
  }

  // ─── UI COMPONENTS ───────────────────────────────────────
  Widget _industrialChartCard({
    required String title,
    required String subtitle,
    required Widget child,
    List<Widget>? actions,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16.w : 24.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: isMobile ? 16.sp : 18.sp,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4.h),
                    Text(subtitle,
                        style: TextStyle(
                            color: _textMuted,
                            fontSize: isMobile ? 11.sp : 12.sp)),
                  ],
                ),
              ),
              if (actions != null) ...actions,
            ],
          ),
          SizedBox(height: isMobile ? 16.h : 24.h),
          child,
        ],
      ),
    );
  }

  Widget _industrialButton(
      String label, {
        IconData? icon,
        VoidCallback? onPressed,
        bool isSecondary = false,
        bool isLoading = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSecondary || onPressed == null
            ? null
            : const LinearGradient(
            colors: [_primary, _primaryLight]),
        color: isSecondary ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(10.r),
        border: isSecondary
            ? Border.all(color: _border)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: 20.w, vertical: 12.h),
            child: isLoading
                ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon,
                      color: isSecondary
                          ? _textPrimary
                          : Colors.white,
                      size: 18.sp),
                  SizedBox(width: 8.w),
                ],
                Text(label,
                    style: TextStyle(
                        color: isSecondary
                            ? _textPrimary
                            : Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _industrialIconButton(
      IconData icon, {
        Color? color,
        VoidCallback? onPressed,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.all(10.w),
            child: Icon(icon,
                color: color ?? _textSecondary, size: 20.sp),
          ),
        ),
      ),
    );
  }

  void _showIndustrialSnackBar(String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(isMobile ? 16.w : 24.w),
        content: Container(
          padding:
          EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isError ? _accentDanger : _bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
                color: isError ? _accentDanger : _border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20)
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: isError ? Colors.white : _accentSuccess,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: isError ? Colors.white : _textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool compact = false,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24.w : 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 16.w : 24.w),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: _primary,
                  size: compact ? 32.sp : 48.sp),
            ),
            SizedBox(height: compact ? 12.h : 20.h),
            Text(title,
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: compact ? 16.sp : 20.sp,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),
            Text(subtitle,
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: compact ? 12.sp : 14.sp),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: _bgElevated,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle)),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(4.r))),
                    SizedBox(height: 8.h),
                    Container(
                        width: 150.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(4.r))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // 🎨 PROFESSIONAL DRAWER — with Sections, Active Indicators & Animations
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEnhancedMobileBottomNav() {
    final items = [
      ("Dashboard", Icons.dashboard_outlined, Icons.dashboard),
      ("Students",  Icons.people_outline,     Icons.people),
      ("Teachers",  Icons.person_outline,     Icons.person),
      ("More",      Icons.menu,               Icons.menu),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.map((item) {
              final (label, icon, activeIcon) = item;
              final isActive = selectedMenu == label ||
                  (label == "More" &&
                      [
                        "Attendance","Fees","Analytics",
                        "Announcements","Settings"
                      ].contains(selectedMenu));

              // 🎨 ANIMATED scale on bottom nav tap
              return GestureDetector(
                onTap: () {
                  if (label == "More") {
                    _scaffoldKey.currentState?.openDrawer();
                  } else {
                    setState(() => selectedMenu = label);
                  }
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: isActive ? 1.12 : 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _primary.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? activeIcon : icon,
                          color: isActive ? _primary : _textMuted,
                          size: 24.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(label,
                            style: TextStyle(
                                color:
                                isActive ? _primary : _textMuted,
                                fontSize: 11.sp,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(
            preselectedRole: 'admin', userType: ''),
      ),
          (route) => false,
    );
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case "Teachers":
        return TeacherModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Students":
        return StudentModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Attendance":
        return AttendanceModule(
          schoolId: widget.schoolId,
          isMobile: isMobile,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Fees":
        return FeeModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Analytics":
        return _analyticsModule();
      case "Announcements":
        return _announcementsModule();
      case "Settings":
        return SettingsModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Salary":
        return SalaryModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
          onBackToDashboard: () =>
              setState(() => selectedMenu = "Dashboard"),
        );
      case "Exams":
        return ExamResultsModule(
          schoolId: widget.schoolId,
          schoolName: widget.schoolName,
          isMobile: isMobile,
          isTablet: isTablet,
          isDesktop: isDesktop,
          showSnackBar: _showIndustrialSnackBar,
        );
      case "Dashboard":
      default:
        return _dashboardContent();
    }
  }
}
// ═══════════════════════════════════════════════════════════════════════════
// 📋 SIDEBAR DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════
class _SidebarSection {
  final String key;
  final String title;
  final IconData icon;
  final List<_SidebarItem> items;

  const _SidebarSection({
    required this.key,
    required this.title,
    required this.icon,
    required this.items,
  });
}

class _SidebarItem {
  final String title;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final String? collection;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.collection,
  });
}
class _Win11NavRow extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color accentColor;
  final bool isExpanded;

  const _Win11NavRow({
    required this.child,
    required this.isActive,
    required this.accentColor,
    required this.isExpanded,
  });

  @override
  State<_Win11NavRow> createState() => _Win11NavRowState();
}

class _Win11NavRowState extends State<_Win11NavRow>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _ctrl;
  late Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _bgAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _ctrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, child) => Container(
          margin: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 8.w : 4.w,
            vertical: 1.5.h,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 12.w : 0,
            vertical: 10.h,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.accentColor.withOpacity(0.13)
                : Color.lerp(Colors.transparent,
                const Color(0xFF1E2130), _bgAnim.value),
            borderRadius: BorderRadius.circular(10.r),
            border: widget.isActive
                ? Border.all(
                color: widget.accentColor.withOpacity(0.25), width: 1)
                : null,
          ),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Win11HoverRow extends StatefulWidget {
  final Widget child;
  final bool isExpanded;

  const _Win11HoverRow({
    required this.child,
    required this.isExpanded,
  });

  @override
  State<_Win11HoverRow> createState() => _Win11HoverRowState();
}

class _Win11HoverRowState extends State<_Win11HoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? 10.w : 0,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF1E2130)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: widget.isExpanded
            ? widget.child
            : Center(child: widget.child),
      ),
    );
  }
}
class _ActivePill extends StatelessWidget {
  final bool isActive;
  final Color color;
  const _ActivePill({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isActive ? 3.w : 0,
      height: isActive ? 20.h : 0,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2.r),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
            : [],
      ),
    );
  }
}
