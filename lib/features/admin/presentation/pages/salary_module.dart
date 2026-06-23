import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// ═══════════════════════════════════════════════════════════════════════════════
///                    HYBRID SALARY SYSTEM MODULE (AUTO + MANUAL)
///          INDUSTRIAL GRADE + OFFLINE-FIRST + CACHE-RESILIENT ARCHITECTURE
/// ═══════════════════════════════════════════════════════════════════════════════

class SalaryModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  final Function(String message, {bool isError}) showSnackBar;
  final VoidCallback onBackToDashboard;

  const SalaryModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
    required this.onBackToDashboard,
  });

  @override
  State<SalaryModule> createState() => _SalaryModuleState();
}

class _SalaryModuleState extends State<SalaryModule> {
  // ─── SALARY SYSTEM COLORS ─────────────────────────────────
  static const Color _salaryPrimary = Color(0xFF10B981);
  static const Color _salaryDark = Color(0xFF059669);
  static const Color _salaryLight = Color(0xFF34D399);

  // ─── INDUSTRIAL COLOR PALETTE ────────────────────────────
  static const Color _bgDark = Color(0xFF0B0F19);
  static const Color _bgCard = Color(0xFF151B2B);
  static const Color _bgElevated = Color(0xFF1E2538);
  static const Color _primary = Color(0xFF6366F1);
  static const Color _primaryLight = Color(0xFF818CF8);
  static const Color _accentSuccess = Color(0xFF22C55E);
  static const Color _accentWarning = Color(0xFFF59E0B);
  static const Color _accentDanger = Color(0xFFEF4444);
  static const Color _accentInfo = Color(0xFF3B82F6);
  static const Color _textPrimary = Color(0xFFF8FAFC);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _border = Color(0xFF2D3748);

  // ─── NETWORK & CACHE STATE ───────────────────────────────
  bool _isOnline = true;
  bool _isLoadingFromCache = false;
  String? _lastError;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  // Cache fallback data
  List<DocumentSnapshot>? _cachedSalaryRecords;
  List<DocumentSnapshot>? _cachedDraftRecords;
  List<DocumentSnapshot>? _cachedApprovedRecords;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Initialize connectivity monitoring
  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionState(result as ConnectivityResult);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      _updateConnectionState(result as ConnectivityResult);
    }) as StreamSubscription<ConnectivityResult>?;
  }

  void _updateConnectionState(ConnectivityResult result) {
    final wasOnline = _isOnline;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });

    // If came back online, refresh data
    if (!wasOnline && _isOnline) {
      widget.showSnackBar("🌐 Back online. Syncing data...", isError: false);
      setState(() {}); // Trigger rebuild to refresh streams
    }
  }

  // ─── HELPERS ──────────────────────────────────────────────
  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  String _getCurrentMonthName() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[now.month - 1]} ${now.year}";
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(2)}L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(0);
  }

  String _formatFullCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '₨',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return _salaryDashboard();
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                    MAIN SALARY DASHBOARD (CACHE-RESILIENT)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _salaryDashboard() {
    return SingleChildScrollView(
      child: StatefulBuilder(
        builder: (context, setInnerState) {
          return FutureBuilder<bool>(
            future: _initializeSalarySystem(),
            builder: (context, initSnapshot) {
              if (initSnapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState("Initializing Salary System...");
              }

              if (initSnapshot.hasError) {
                return _buildErrorState("Initialization failed: ${initSnapshot.error}");
              }

              return StreamBuilder<bool>(
                stream: _checkSalarySetup(),
                builder: (context, setupSnapshot) {
                  final isSetup = setupSnapshot.data ?? false;

                  if (!isSetup) {
                    return _buildSetupRequiredState(setInnerState);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSalaryHeader(setInnerState),
                      SizedBox(height: 16.h),
                      _buildNetworkStatusBar(),
                      SizedBox(height: 16.h),
                      _buildSalaryStats(),
                      SizedBox(height: 16.h),
                      _buildHybridPayrollActions(setInnerState),
                      SizedBox(height: 16.h),
                      Container(
                        height: widget.isMobile ? 400.h : 500.h,
                        child: _buildHybridSalaryRecordsList(setInnerState),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Network status indicator bar
  Widget _buildNetworkStatusBar() {
    if (_isOnline && _lastError == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      margin: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16.w : 0),
      decoration: BoxDecoration(
        color: _isOnline ? _accentWarning.withOpacity(0.1) : _accentDanger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: _isOnline ? _accentWarning.withOpacity(0.3) : _accentDanger.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isOnline ? Icons.warning_amber : Icons.cloud_off,
            color: _isOnline ? _accentWarning : _accentDanger,
            size: 18.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _isOnline
                  ? "⚠️ Showing cached data. Pull to refresh for latest."
                  : "📴 Offline mode. Using locally cached data.",
              style: TextStyle(
                color: _isOnline ? _accentWarning : _accentDanger,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_isOnline)
            Container(
              width: 8.w,
              height: 8.w,
              decoration: BoxDecoration(
                color: _accentDanger,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  // ─── CACHE-RESILIENT QUERIES ───────────────────────────────────────────────────

  /// Build a cache-resilient stream that falls back to cache on error
  Stream<QuerySnapshot> _buildResilientStream({
    required Query query,
    required String cacheKey,
    required int maxRetries,
  }) {
    // First try: Server with cache fallback
    // If online: prefer server, but fallback to cache on timeout/error
    // If offline: directly use cache

    if (!_isOnline) {
      // Offline: Force cache-only
      return query
          .get(const GetOptions(source: Source.cache))
          .asStream()
          .map((snapshot) => snapshot as QuerySnapshot);
    }

    // Online: Try server first with retry logic
    return _retryableStream(
      query: query,
      maxRetries: maxRetries,
      cacheKey: cacheKey,
    );
  }

  /// Retryable stream with exponential backoff and cache fallback
  Stream<QuerySnapshot> _retryableStream({
    required Query query,
    required int maxRetries,
    required String cacheKey,
  }) async* {
    int attempt = 0;
    Duration delay = const Duration(milliseconds: 500);

    while (attempt < maxRetries) {
      try {
        // Try server first
        final serverSnapshot = await query
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 10));

        // Success: yield and store in cache fallback
        _storeCacheFallback(cacheKey, serverSnapshot.docs);
        yield serverSnapshot;
        return;

      } on TimeoutException catch (_) {
        attempt++;
        if (attempt >= maxRetries) {
          // Max retries reached: fallback to cache
          yield* _fallbackToCache(query, cacheKey);
          return;
        }
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff

      } on FirebaseException catch (e) {
        // Check if it's an index error
        if (e.code == 'failed-precondition' ||
            e.message?.contains('index') == true) {
          _lastError = "Firestore index required. Please create composite index.";
          widget.showSnackBar(_lastError!, isError: true);
          // Try cache fallback immediately for index errors
          yield* _fallbackToCache(query, cacheKey);
          return;
        }

        attempt++;
        if (attempt >= maxRetries) {
          yield* _fallbackToCache(query, cacheKey);
          return;
        }
        await Future.delayed(delay);
        delay *= 2;

      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          yield* _fallbackToCache(query, cacheKey);
          return;
        }
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  /// Fallback to cache when server fails
  Stream<QuerySnapshot> _fallbackToCache(Query query, String cacheKey) async* {
    setState(() => _isLoadingFromCache = true);

    try {
      // Try cache first
      final cacheSnapshot = await query
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 5));

      if (cacheSnapshot.docs.isNotEmpty) {
        _storeCacheFallback(cacheKey, cacheSnapshot.docs);
        yield cacheSnapshot;
        return;
      }
    } catch (_) {
      // Cache also failed
    }

    // Final fallback: return empty snapshot
    yield await query.limit(0).get();
  }

  void _storeCacheFallback(String key, List<DocumentSnapshot> docs) {
    switch (key) {
      case 'salaryRecords':
        _cachedSalaryRecords = docs;
        break;
      case 'draftRecords':
        _cachedDraftRecords = docs;
        break;
      case 'approvedRecords':
        _cachedApprovedRecords = docs;
        break;
    }
  }

  List<DocumentSnapshot>? _getCacheFallback(String key) {
    switch (key) {
      case 'salaryRecords':
        return _cachedSalaryRecords;
      case 'draftRecords':
        return _cachedDraftRecords;
      case 'approvedRecords':
        return _cachedApprovedRecords;
      default:
        return null;
    }
  }

  // ─── AUTO-INITIALIZATION ───────────────────────────────────────────────────────

  Future<bool> _initializeSalarySystem() async {
    try {
      await _createDefaultSalaryStructure();
      await _createMissingSalaryProfiles();
      return true;
    } catch (e) {
      print("❌ Salary Init Error: $e");
      return false;
    }
  }

  Stream<bool> _checkSalarySetup() {
    return FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryStructures')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Future<void> _createDefaultSalaryStructure() async {
    final structureRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryStructures')
        .doc('default');

    final existing = await structureRef.get();
    if (existing.exists) return;

    await structureRef.set({
      'structureId': 'default',
      'name': 'Standard Teaching Staff',
      'description': 'Default structure for all teaching staff',
      'isDefault': true,
      'country': 'PK',
      'currency': 'PKR',

      'earnings': {
        'basic': {'type': 'percentage', 'value': 50, 'name': 'Basic Salary'},
        'hra': {'type': 'percentage', 'value': 20, 'name': 'House Rent Allowance'},
        'da': {'type': 'percentage', 'value': 15, 'name': 'Dearness Allowance'},
        'ta': {'type': 'fixed', 'value': 2000, 'name': 'Travel Allowance'},
        'medical': {'type': 'fixed', 'value': 1500, 'name': 'Medical Allowance'},
        'special': {'type': 'fixed', 'value': 0, 'name': 'Special Allowance'}
      },

      'deductions': {
        'pf': {'type': 'percentage', 'value': 12, 'name': 'Provident Fund', 'applicableOn': 'basic'},
        'professionalTax': {'type': 'fixed', 'value': 200, 'name': 'Professional Tax'},
        'incomeTax': {
          'type': 'slab',
          'name': 'Income Tax',
          'slabs': [
            {'limit': 600000, 'rate': 0},
            {'limit': 800000, 'rate': 5},
            {'limit': 1200000, 'rate': 10},
            {'limit': 2400000, 'rate': 15},
            {'limit': 3000000, 'rate': 20},
            {'limit': 999999999, 'rate': 25}
          ]
        }
      },

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
    });

    print("✅ Salary structure created");
  }

  Future<void> _createMissingSalaryProfiles() async {
    final teachersSnapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('teachers')
        .where('status', isEqualTo: 'active')
        .get();

    int createdCount = 0;

    for (var teacher in teachersSnapshot.docs) {
      final teacherData = teacher.data();
      final teacherId = teacher.id;

      final profileRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teacherSalaryProfiles')
          .doc(teacherId);

      final existing = await profileRef.get();
      if (existing.exists) continue;

      final defaultCTC = 600000;

      await profileRef.set({
        'teacherId': teacherId,
        'teacherName': teacherData['name'] ?? 'Unknown',
        'teacherEmail': teacherData['email'] ?? '',
        'salaryStructureId': 'default',
        'ctc': defaultCTC,
        'monthlyGross': (defaultCTC / 12).round(),

        'bankDetails': {
          'accountHolder': teacherData['name'] ?? '',
          'bankName': '',
          'accountNumber': '',
          'ifscCode': '',
          'branch': ''
        },

        'taxDetails': {'panNumber': '', 'taxRegime': 'new'},
        'joiningDate': teacherData['createdAt'] ?? FieldValue.serverTimestamp(),
        'effectiveFrom': FieldValue.serverTimestamp(),
        'isActive': true,

        'advanceBalance': 0,
        'totalAdvanceTaken': 0,
        'totalAdvanceRepaid': 0,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid ?? 'system',
      });

      createdCount++;
    }

    if (createdCount > 0) {
      print("✅ Created $createdCount salary profiles");
    }
  }

  // ─── SETUP UI ──────────────────────────────────────────────────────────────────

  Widget _buildSetupRequiredState(StateSetter setInnerState) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(48.w),
        margin: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _salaryPrimary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: _salaryPrimary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_salaryPrimary, _salaryLight],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings_suggest,
                color: Colors.white,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "Hybrid Salary System Setup",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "Auto-calculate + Manual override enabled",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 32.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  _buildSetupItem(Icons.auto_fix_high, "Auto-Calculation", "Default: System calculates all"),
                  SizedBox(height: 12.h),
                  _buildSetupItem(Icons.edit_note, "Manual Override", "Edit any field before payment"),
                  SizedBox(height: 12.h),
                  _buildSetupItem(Icons.track_changes, "Audit Trail", "Track auto vs manual changes"),
                ],
              ),
            ),
            SizedBox(height: 32.h),
            _industrialButton(
              "Initialize Hybrid System",
              icon: Icons.rocket_launch,
              onPressed: () async {
                await _initializeSalarySystem();
                setInnerState(() {});
                widget.showSnackBar("✅ Hybrid salary system ready!", isError: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _salaryPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: _salaryPrimary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_circle, color: _salaryPrimary, size: 20.sp),
      ],
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _salaryPrimary),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(color: _textSecondary, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: _accentDanger, size: 64.sp),
            SizedBox(height: 16.h),
            Text(
              "Setup Error",
              style: TextStyle(
                color: _accentDanger,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _industrialButton(
              "Retry",
              icon: Icons.refresh,
              onPressed: () {
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── DASHBOARD COMPONENTS ──────────────────────────────────────────────────────

  Widget _buildSalaryHeader(StateSetter setInnerState) {
    return widget.isMobile
        ? Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _salaryPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.auto_fix_high, color: _salaryPrimary, size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hybrid Salary System",
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Auto + Manual Override",
                    style: TextStyle(
                      color: _salaryPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _industrialButton(
                "Structure",
                icon: Icons.settings,
                onPressed: () => _showSalaryStructureDialog(),
                isSecondary: true,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _industrialButton(
                "Generate",
                icon: Icons.play_arrow,
                onPressed: () => _showHybridGenerateDialog(),
              ),
            ),
          ],
        ),
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _salaryPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.auto_fix_high, color: _salaryPrimary, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hybrid Salary System",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "Auto-calculate with manual override capability",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _industrialButton(
              "Structure",
              icon: Icons.settings,
              onPressed: () => _showSalaryStructureDialog(),
              isSecondary: true,
            ),
            SizedBox(width: 12.w),
            _industrialButton(
              "Generate Payroll",
              icon: Icons.play_arrow,
              onPressed: () => _showHybridGenerateDialog(),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                    CACHE-RESILIENT SALARY STATS
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildSalaryStats() {
    final monthYear = _getCurrentMonthYear();
    final query = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryRecords')
        .where('monthYear', isEqualTo: monthYear);

    return StreamBuilder<QuerySnapshot>(
      stream: _buildResilientStream(
        query: query,
        cacheKey: 'salaryRecords',
        maxRetries: 3,
      ),
      builder: (context, snapshot) {
        // Handle loading with cache fallback
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSalaryRecords == null) {
          return _buildStatsShimmer();
        }

        // Use cache fallback if stream has error
        final docs = snapshot.hasData
            ? snapshot.data!.docs
            : _cachedSalaryRecords ?? [];

        double totalGross = 0;
        double totalNet = 0;
        double totalPaid = 0;
        int draftCount = 0;
        int approvedCount = 0;
        int paidCount = 0;
        int pendingCount = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalGross += (data['totalEarnings'] ?? 0).toDouble();
          totalNet += (data['finalPayable'] ?? 0).toDouble();

          final status = data['status'] ?? 'pending';
          if (status == 'draft') draftCount++;
          else if (status == 'approved') approvedCount++;
          else if (status == 'paid') {
            totalPaid += (data['paidAmount'] ?? 0).toDouble();
            paidCount++;
          } else {
            pendingCount++;
          }
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: widget.isMobile ? 2 : 5,
          crossAxisSpacing: 16.w,
          mainAxisSpacing: 16.h,
          childAspectRatio: widget.isMobile ? 1.2 : 1.4,
          children: [
            _buildStatCard("Total Payroll", "₨${_formatCurrency(totalGross)}",
                Icons.account_balance_wallet, _salaryPrimary, "${docs.length} staff"),
            _buildStatCard("Net Payable", "₨${_formatCurrency(totalNet)}",
                Icons.calculate, _accentInfo, "After deductions"),
            _buildStatCard("Draft", "$draftCount",
                Icons.edit_note, _accentWarning, "Needs review"),
            _buildStatCard("Approved", "$approvedCount",
                Icons.check_circle_outline, _primaryLight, "Ready to pay"),
            _buildStatCard("Paid", "₨${_formatCurrency(totalPaid)}",
                Icons.check_circle, _accentSuccess, "$paidCount done"),
          ],
        );
      },
    );
  }

  Widget _buildStatsShimmer() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: widget.isMobile ? 2 : 5,
      crossAxisSpacing: 16.w,
      mainAxisSpacing: 16.h,
      childAspectRatio: widget.isMobile ? 1.2 : 1.4,
      children: List.generate(5, (index) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: _bgElevated,
        child: Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      )),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 16.w : 20.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: widget.isMobile ? 20.sp : 24.sp),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: widget.isMobile ? 18.sp : 22.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: color,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         HYBRID PAYROLL ACTIONS (CACHE-RESILIENT)
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildHybridPayrollActions(StateSetter setInnerState) {
    final monthYear = _getCurrentMonthYear();
    final baseQuery = FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('salaryRecords')
        .where('monthYear', isEqualTo: monthYear);

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_salaryPrimary.withOpacity(0.1), _bgCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _salaryPrimary.withOpacity(0.3)),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _buildResilientStream(
          query: baseQuery,
          cacheKey: 'salaryRecords',
          maxRetries: 3,
        ),
        builder: (context, snapshot) {
          final docs = snapshot.hasData
              ? snapshot.data!.docs
              : _cachedSalaryRecords ?? [];

          final draftRecords = docs.where((r) =>
          (r.data() as Map)['status'] == 'draft').toList();
          final approvedRecords = docs.where((r) =>
          (r.data() as Map)['status'] == 'approved').toList();
          final paidRecords = docs.where((r) =>
          (r.data() as Map)['status'] == 'paid').toList();

          return widget.isMobile
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPayrollHeader(),
              SizedBox(height: 12.h),
              _buildPayrollProgress(docs, paidRecords),
              SizedBox(height: 12.h),
              if (draftRecords.isNotEmpty)
                _buildActionButton(
                  "Review ${draftRecords.length} Drafts",
                  Icons.edit_note,
                  _accentWarning,
                      () => _showReviewDraftsDialog(setInnerState),
                ),
              if (approvedRecords.isNotEmpty) ...[
                SizedBox(height: 8.h),
                _buildActionButton(
                  "Pay ${approvedRecords.length} Approved",
                  Icons.payment,
                  _accentSuccess,
                      () => _showProcessPaymentsDialog(),
                ),
              ],
              if (docs.isEmpty)
                _buildActionButton(
                  "Generate Payroll",
                  Icons.play_arrow,
                  _salaryPrimary,
                      () => _showHybridGenerateDialog(),
                ),
            ],
          )
              : Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPayrollHeader(),
                    SizedBox(height: 8.h),
                    _buildPayrollProgress(docs, paidRecords),
                  ],
                ),
              ),
              SizedBox(width: 24.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (draftRecords.isNotEmpty)
                    _buildActionButton(
                      "Review Drafts (${draftRecords.length})",
                      Icons.edit_note,
                      _accentWarning,
                          () => _showReviewDraftsDialog(setInnerState),
                    ),
                  if (approvedRecords.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    _buildActionButton(
                      "Process Payments (${approvedRecords.length})",
                      Icons.payment,
                      _accentSuccess,
                          () => _showProcessPaymentsDialog(),
                    ),
                  ],
                  if (docs.isEmpty)
                    _buildActionButton(
                      "Generate Payroll",
                      Icons.play_arrow,
                      _salaryPrimary,
                          () => _showHybridGenerateDialog(),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPayrollHeader() {
    return Row(
      children: [
        Icon(Icons.calendar_today, color: _salaryPrimary, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          "Current Payroll: ${_getCurrentMonthName()}",
          style: TextStyle(
            color: _textPrimary,
            fontSize: widget.isMobile ? 16.sp : 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: _salaryPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            "HYBRID",
            style: TextStyle(
              color: _salaryPrimary,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayrollProgress(List<DocumentSnapshot> records, List<DocumentSnapshot> paidRecords) {
    final total = records.length;
    final paid = paidRecords.length;
    final progress = total > 0 ? (paid / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Progress: $paid/$total teachers paid",
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: _bgElevated,
            valueColor: AlwaysStoppedAnimation<Color>(_salaryPrimary),
            minHeight: 8.h,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: widget.isMobile ? double.infinity : null,
      child: _industrialButton(
        label,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                    CACHE-RESILIENT SALARY RECORDS LIST
  // ═══════════════════════════════════════════════════════════════════════════════

  Widget _buildHybridSalaryRecordsList(StateSetter setInnerState) {
    final monthYear = _getCurrentMonthYear();
    final query = FirebaseFirestore.instance
        .collection('schools').doc(widget.schoolId)
        .collection('salaryRecords')
        .where('monthYear', isEqualTo: monthYear)
        .orderBy('teacherName');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Salary Records",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                _industrialButton(
                  "Export",
                  icon: Icons.download,
                  onPressed: () => _exportSalaryData(),
                  isSecondary: true,
                ),
                SizedBox(width: 8.w),
                _industrialButton(
                  "Advances",
                  icon: Icons.money_off,
                  onPressed: () => _showAdvanceDialog(),
                  isSecondary: true,
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Force refresh from server
              setState(() {
                _cachedSalaryRecords = null;
                _lastError = null;
              });
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: _salaryPrimary,
            backgroundColor: _bgCard,
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildResilientStream(
                query: query,
                cacheKey: 'salaryRecords',
                maxRetries: 3,
              ),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _cachedSalaryRecords == null) {
                  return _buildShimmerList();
                }

                // Error with cache fallback
                if (snapshot.hasError && _cachedSalaryRecords != null) {
                  return _buildListWithData(_cachedSalaryRecords!, setInnerState);
                }

                // Use data from stream or cache
                final records = snapshot.hasData
                    ? snapshot.data!.docs
                    : _cachedSalaryRecords ?? [];

                if (records.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.payments_outlined,
                    title: "No salary records",
                    subtitle: "Generate payroll for this month",
                  );
                }

                return _buildListWithData(records, setInnerState);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListWithData(List<DocumentSnapshot> records, StateSetter setInnerState) {
    return widget.isMobile
        ? ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) =>
          _buildHybridSalaryCard(records[index], setInnerState),
    )
        : _buildHybridSalaryTable(records, setInnerState);
  }

  // ─── HYBRID SALARY CARD ────────────────────────────────────────────────────────

  Widget _buildHybridSalaryCard(DocumentSnapshot record, StateSetter setInnerState) {
    final data = record.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'draft';
    final isAutoCalculated = data['isAutoCalculated'] ?? true;
    final hasManualChanges = (data['manualChanges'] as Map<String, dynamic>?)?.isNotEmpty ?? false;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'draft':
        statusColor = _accentWarning;
        statusIcon = Icons.edit_note;
        statusText = 'DRAFT';
        break;
      case 'approved':
        statusColor = _primaryLight;
        statusIcon = Icons.check_circle_outline;
        statusText = 'APPROVED';
        break;
      case 'paid':
        statusColor = _accentSuccess;
        statusIcon = Icons.check_circle;
        statusText = 'PAID';
        break;
      default:
        statusColor = _textMuted;
        statusIcon = Icons.pending;
        statusText = 'PENDING';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: status == 'draft' ? _accentWarning.withOpacity(0.5) :
          status == 'approved' ? _primaryLight.withOpacity(0.5) :
          _salaryPrimary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Name + Status
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_salaryPrimary, _salaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    (data['teacherName'] ?? 'T')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['teacherName'] ?? 'Unknown',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Net: ${_formatFullCurrency((data['finalPayable'] ?? 0).toDouble())}",
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        if (hasManualChanges)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _accentInfo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 10.sp, color: _accentInfo),
                                SizedBox(width: 2.w),
                                Text(
                                  "EDITED",
                                  style: TextStyle(
                                    color: _accentInfo,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildHybridStatusChip(status, statusColor, statusIcon, statusText),
            ],
          ),

          SizedBox(height: 12.h),

          // Salary Breakdown
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSalaryInfoItem("Gross", (data['totalEarnings'] ?? 0).toDouble()),
                _buildSalaryInfoItem("Deductions", (data['totalDeductions'] ?? 0).toDouble()),
                _buildSalaryInfoItem("Payable", (data['finalPayable'] ?? 0).toDouble(), isHighlighted: true),
              ],
            ),
          ),

          SizedBox(height: 12.h),

          // Action Buttons based on status
          if (status == 'draft')
            Row(
              children: [
                Expanded(
                  child: _industrialButton(
                    "Review & Edit",
                    icon: Icons.edit_note,
                    onPressed: () => _showHybridEditDialog(record, setInnerState),
                    isSecondary: true,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _industrialButton(
                    "Approve",
                    icon: Icons.check_circle,
                    onPressed: () => _approveSalaryRecord(record),
                  ),
                ),
              ],
            )
          else if (status == 'approved')
            SizedBox(
              width: double.infinity,
              child: _industrialButton(
                "Pay Now",
                icon: Icons.payment,
                onPressed: () => _showPaymentDialog(record, setInnerState),
              ),
            )
          else if (status == 'paid')
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _accentSuccess.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: _accentSuccess, size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "Paid on ${_formatDate(data['paidDate'])}",
                      style: TextStyle(
                        color: _accentSuccess,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHybridStatusChip(String status, Color color, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return 'N/A';
  }

  // ─── HYBRID SALARY TABLE ───────────────────────────────────────────────────────

  Widget _buildHybridSalaryTable(List<DocumentSnapshot> records, StateSetter setInnerState) {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text("Teacher", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                Expanded(child: Text("Gross", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                Expanded(child: Text("Deductions", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                Expanded(child: Text("Net", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                Expanded(child: Text("Status", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                Expanded(child: Text("Type", style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600, fontSize: 13.sp))),
                SizedBox(width: 120.w),
              ],
            ),
          ),
          // Rows
          Expanded(
            child: ListView.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) => Divider(color: _border, height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                final data = record.data() as Map<String, dynamic>;
                final status = data['status'] ?? 'draft';
                final isAutoCalculated = data['isAutoCalculated'] ?? true;
                final hasManualChanges = (data['manualChanges'] as Map<String, dynamic>?)?.isNotEmpty ?? false;

                Color statusColor = status == 'draft' ? _accentWarning :
                status == 'approved' ? _primaryLight :
                status == 'paid' ? _accentSuccess : _textMuted;

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_salaryPrimary, _salaryLight]),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Center(
                                child: Text(
                                  (data['teacherName'] ?? 'T')[0].toUpperCase(),
                                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['teacherName'] ?? 'Unknown',
                                    style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 14.sp),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (hasManualChanges)
                                    Text(
                                      "Edited",
                                      style: TextStyle(color: _accentInfo, fontSize: 10.sp),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatFullCurrency((data['totalEarnings'] ?? 0).toDouble()),
                          style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatFullCurrency((data['totalDeductions'] ?? 0).toDouble()),
                          style: TextStyle(color: _accentDanger, fontSize: 13.sp),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatFullCurrency((data['finalPayable'] ?? 0).toDouble()),
                          style: TextStyle(color: _salaryPrimary, fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                      ),
                      Expanded(
                        child: _buildHybridStatusChip(
                            status,
                            statusColor,
                            status == 'draft' ? Icons.edit_note :
                            status == 'approved' ? Icons.check_circle_outline : Icons.check_circle,
                            status.toUpperCase()
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isAutoCalculated ? "Auto" : "Manual",
                          style: TextStyle(
                            color: isAutoCalculated ? _textSecondary : _accentInfo,
                            fontSize: 12.sp,
                            fontWeight: isAutoCalculated ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120.w,
                        child: _buildTableActionButton(record, status, setInnerState),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableActionButton(DocumentSnapshot record, String status, StateSetter setInnerState) {
    if (status == 'draft') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconButton(Icons.edit_note, _accentWarning, () => _showHybridEditDialog(record, setInnerState)),
          SizedBox(width: 4.w),
          _iconButton(Icons.check_circle, _accentSuccess, () => _approveSalaryRecord(record)),
        ],
      );
    } else if (status == 'approved') {
      return _industrialButton(
        "Pay",
        onPressed: () => _showPaymentDialog(record, setInnerState),
      );
    } else {
      return Text(
        "Completed",
        style: TextStyle(color: _accentSuccess, fontSize: 12.sp),
      );
    }
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          child: Icon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         HYBRID DIALOGS & ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════════

  void _showHybridGenerateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _salaryPrimary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_fix_high, color: _salaryPrimary, size: 32.sp),
              ),
              SizedBox(height: 20.h),
              Text(
                "Generate Payroll (Hybrid)",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Auto-calculate salaries for ${_getCurrentMonthName()}",
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _bgElevated,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    _buildHybridFeatureItem(Icons.check_circle, "Auto-calculate all components", true),
                    _buildHybridFeatureItem(Icons.edit_note, "Review as draft before approval", true),
                    _buildHybridFeatureItem(Icons.track_changes, "Edit any field if needed", true),
                    _buildHybridFeatureItem(Icons.history, "Full audit trail maintained", true),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _industrialButton(
                      "Cancel",
                      onPressed: () => Navigator.pop(context),
                      isSecondary: true,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _industrialButton(
                      "Generate Drafts",
                      icon: Icons.play_arrow,
                      onPressed: () async {
                        Navigator.pop(context);
                        await _generateHybridPayroll();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHybridFeatureItem(IconData icon, String text, bool isPositive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(icon, color: isPositive ? _accentSuccess : _accentWarning, size: 18.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateHybridPayroll() async {
    widget.showSnackBar("🤖 Auto-generating payroll drafts...", isError: false);

    try {
      final teachersSnapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
          .where('status', isEqualTo: 'active')
          .get();

      final structureDoc = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('salaryStructures')
          .doc('default')
          .get();

      if (!structureDoc.exists) {
        widget.showSnackBar("Salary structure not found!", isError: true);
        return;
      }

      final structure = structureDoc.data()!;
      final monthYear = _getCurrentMonthYear();

      int generated = 0;
      int skipped = 0;

      for (var teacher in teachersSnapshot.docs) {
        final teacherData = teacher.data();
        final teacherId = teacher.id;

        // Check if already exists
        final existing = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('salaryRecords')
            .where('teacherId', isEqualTo: teacherId)
            .where('monthYear', isEqualTo: monthYear)
            .get();

        if (existing.docs.isNotEmpty) {
          skipped++;
          continue;
        }

        final profileDoc = await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('teacherSalaryProfiles')
            .doc(teacherId)
            .get();

        if (!profileDoc.exists) continue;

        final profile = profileDoc.data()!;
        final ctc = (profile['ctc'] ?? 0).toDouble();
        final monthlyGross = ctc / 12;

        // Calculate based on structure (SAME LOGIC AS BEFORE)
        final earnings = structure['earnings'] as Map<String, dynamic>;
        final deductions = structure['deductions'] as Map<String, dynamic>;

        double basic = 0, hra = 0, da = 0, ta = 0, medical = 0, special = 0;

        // Basic (50% of monthly gross)
        if (earnings['basic'] != null) {
          final basicConfig = earnings['basic'] as Map<String, dynamic>;
          if (basicConfig['type'] == 'percentage') {
            basic = monthlyGross * (basicConfig['value'] ?? 50) / 100;
          }
        }

        // HRA (20% of basic)
        if (earnings['hra'] != null) {
          final hraConfig = earnings['hra'] as Map<String, dynamic>;
          if (hraConfig['type'] == 'percentage') {
            hra = basic * (hraConfig['value'] ?? 20) / 100;
          }
        }

        // DA (15% of basic)
        if (earnings['da'] != null) {
          final daConfig = earnings['da'] as Map<String, dynamic>;
          if (daConfig['type'] == 'percentage') {
            da = basic * (daConfig['value'] ?? 15) / 100;
          }
        }

        // Fixed allowances
        ta = (earnings['ta']?['value'] ?? 0).toDouble();
        medical = (earnings['medical']?['value'] ?? 0).toDouble();
        special = (earnings['special']?['value'] ?? 0).toDouble();

        final totalEarnings = basic + hra + da + ta + medical + special;

        // Deductions
        final pf = basic * ((deductions['pf']?['value'] ?? 12) / 100);
        final professionalTax = (deductions['professionalTax']?['value'] ?? 200).toDouble();

        // Simple income tax calculation
        double incomeTax = 0;
        final annualTaxable = (totalEarnings - pf) * 12;
        final taxSlabs = deductions['incomeTax']?['slabs'] as List<dynamic>?;
        if (taxSlabs != null) {
          for (var slab in taxSlabs) {
            final limit = (slab['limit'] ?? 0).toDouble();
            final rate = (slab['rate'] ?? 0).toDouble();
            if (annualTaxable <= limit) {
              incomeTax = (annualTaxable * rate / 100) / 12;
              break;
            }
          }
        }

        final totalDeductions = pf + professionalTax + incomeTax;
        final finalPayable = totalEarnings - totalDeductions;

        // HYBRID: Create as DRAFT with audit trail
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('salaryRecords')
            .add({
          'teacherId': teacherId,
          'teacherName': teacherData['name'] ?? 'Unknown',
          'monthYear': monthYear,
          'month': DateTime.now().month,
          'year': DateTime.now().year,

          // Earnings
          'earnings': {
            'basic': basic,
            'hra': hra,
            'da': da,
            'ta': ta,
            'medical': medical,
            'special': special,
          },
          'totalEarnings': totalEarnings,

          // Deductions
          'deductions': {
            'pf': pf,
            'professionalTax': professionalTax,
            'incomeTax': incomeTax,
          },
          'totalDeductions': totalDeductions,

          // Final calculations
          'finalPayable': finalPayable,
          'netPayable': finalPayable,

          // HYBRID FIELDS
          'status': 'draft', // draft → approved → paid
          'isAutoCalculated': true,
          'autoCalculatedAt': FieldValue.serverTimestamp(),
          'manualChanges': {}, // Empty initially
          'approvedAt': null,
          'approvedBy': null,

          // Payment fields
          'paidAmount': 0,
          'paidDate': null,
          'paymentMethod': null,
          'paymentReference': null,

          'advanceDeduction': 0,

          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        generated++;
      }

      widget.showSnackBar(
          "✅ Generated $generated drafts, skipped $skipped",
          isError: false
      );
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    }
  }

  void _showReviewDraftsDialog(StateSetter setInnerState) {
    final monthYear = _getCurrentMonthYear();
    final query = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryRecords')
        .where('monthYear', isEqualTo: monthYear)
        .where('status', isEqualTo: 'draft')
        .orderBy('teacherName');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 700.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note, color: _accentWarning, size: 28.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Review Draft Salaries",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                "Review auto-calculated salaries. Edit if needed, then approve.",
                style: TextStyle(color: _textSecondary, fontSize: 13.sp),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildResilientStream(
                    query: query,
                    cacheKey: 'draftRecords',
                    maxRetries: 3,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && _cachedDraftRecords == null) {
                      return _buildShimmerList();
                    }

                    final drafts = snapshot.hasData
                        ? snapshot.data!.docs
                        : _cachedDraftRecords ?? [];

                    if (drafts.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.check_circle,
                        title: "No drafts pending",
                        subtitle: "All salaries reviewed",
                      );
                    }

                    return ListView.builder(
                      itemCount: drafts.length,
                      itemBuilder: (context, index) {
                        final draft = drafts[index];
                        final data = draft.data() as Map<String, dynamic>;

                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _bgElevated,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['teacherName'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Net: ${_formatFullCurrency((data['finalPayable'] ?? 0).toDouble())}",
                                      style: TextStyle(
                                        color: _salaryPrimary,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _iconButton(
                                      Icons.edit_note,
                                      _accentWarning,
                                          () {
                                        Navigator.pop(context);
                                        _showHybridEditDialog(draft, setInnerState);
                                      }
                                  ),
                                  SizedBox(width: 8.w),
                                  _iconButton(
                                      Icons.check_circle,
                                      _accentSuccess,
                                          () => _approveSalaryRecord(draft)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              StreamBuilder<QuerySnapshot>(
                stream: _buildResilientStream(
                  query: query,
                  cacheKey: 'draftRecords',
                  maxRetries: 3,
                ),
                builder: (context, snapshot) {
                  final count = snapshot.hasData
                      ? snapshot.data!.docs.length
                      : _cachedDraftRecords?.length ?? 0;
                  return Row(
                    children: [
                      Expanded(
                        child: _industrialButton(
                          "Close",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                      if (count > 0) ...[
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _industrialButton(
                            "Approve All ($count)",
                            icon: Icons.check_circle,
                            onPressed: () => _approveAllDrafts(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  //                         HYBRID EDIT DIALOG (MANUAL OVERRIDE)
  // ═══════════════════════════════════════════════════════════════════════════════

  void _showHybridEditDialog(DocumentSnapshot record, StateSetter setInnerState) {
    final data = record.data() as Map<String, dynamic>;

    // Controllers for manual override
    final basicController = TextEditingController(text: (data['earnings']?['basic'] ?? 0).toStringAsFixed(0));
    final hraController = TextEditingController(text: (data['earnings']?['hra'] ?? 0).toStringAsFixed(0));
    final daController = TextEditingController(text: (data['earnings']?['da'] ?? 0).toStringAsFixed(0));
    final specialController = TextEditingController(text: (data['earnings']?['special'] ?? 0).toStringAsFixed(0));
    final bonusController = TextEditingController(text: "0");
    final deductionController = TextEditingController(text: "0");
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          // Calculate totals in real-time
          final basic = double.tryParse(basicController.text) ?? 0;
          final hra = double.tryParse(hraController.text) ?? 0;
          final da = double.tryParse(daController.text) ?? 0;
          final special = double.tryParse(specialController.text) ?? 0;
          final bonus = double.tryParse(bonusController.text) ?? 0;
          final manualDeduction = double.tryParse(deductionController.text) ?? 0;

          final originalEarnings = (data['totalEarnings'] ?? 0).toDouble();
          final originalDeductions = (data['totalDeductions'] ?? 0).toDouble();

          final newEarnings = basic + hra + da + special + bonus;
          final newDeductions = originalDeductions + manualDeduction;
          final newPayable = newEarnings - newDeductions;

          final earningsDiff = newEarnings - originalEarnings;
          final payableDiff = newPayable - (data['finalPayable'] ?? 0).toDouble();

          return Dialog(
            backgroundColor: _bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: Container(
              width: widget.isMobile ? double.infinity : 600.w,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: _accentWarning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.edit_note, color: _accentWarning, size: 24.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Edit Salary",
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              data['teacherName'] ?? 'Unknown',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _accentInfo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "MANUAL OVERRIDE",
                          style: TextStyle(
                            color: _accentInfo,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Original values indicator
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: _bgElevated,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: _textMuted, size: 16.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            "Original: ${_formatFullCurrency(originalEarnings)} - ${_formatFullCurrency(originalDeductions)} = ${_formatFullCurrency((data['finalPayable'] ?? 0).toDouble())}",
                            style: TextStyle(color: _textMuted, fontSize: 12.sp),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Editable fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "EARNINGS",
                            style: TextStyle(
                              color: _salaryPrimary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildEditField("Basic Salary", basicController, "Auto-calculated"),
                          SizedBox(height: 8.h),
                          _buildEditField("HRA", hraController, "20% of Basic"),
                          SizedBox(height: 8.h),
                          _buildEditField("DA", daController, "15% of Basic"),
                          SizedBox(height: 8.h),
                          _buildEditField("Special Allowance", specialController, "Fixed"),
                          SizedBox(height: 8.h),
                          _buildEditField("Bonus / Incentive", bonusController, "Add if any"),

                          SizedBox(height: 20.h),

                          Text(
                            "EXTRA DEDUCTIONS",
                            style: TextStyle(
                              color: _accentDanger,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildEditField("Additional Deduction", deductionController, "Fine, Loan, etc."),

                          SizedBox(height: 20.h),

                          Text(
                            "NOTES",
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          TextField(
                            controller: notesController,
                            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: "Reason for changes...",
                              hintStyle: TextStyle(color: _textMuted),
                              filled: true,
                              fillColor: _bgElevated,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: _border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(color: _salaryPrimary),
                              ),
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // New totals
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_salaryPrimary.withOpacity(0.1), _bgElevated],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: _salaryPrimary.withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                _buildComparisonRow("Total Earnings", originalEarnings, newEarnings, earningsDiff),
                                SizedBox(height: 8.h),
                                _buildComparisonRow("Total Deductions", originalDeductions, newDeductions, manualDeduction),
                                Divider(color: _border, height: 16.h),
                                _buildComparisonRow("NET PAYABLE", (data['finalPayable'] ?? 0).toDouble(), newPayable, payableDiff, isTotal: true),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _industrialButton(
                          "Cancel",
                          onPressed: () => Navigator.pop(context),
                          isSecondary: true,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _industrialButton(
                          "Save Changes",
                          icon: Icons.save,
                          onPressed: () async {
                            await _saveManualChanges(
                              record,
                              {
                                'basic': basic,
                                'hra': hra,
                                'da': da,
                                'special': special,
                                'bonus': bonus,
                              },
                              manualDeduction,
                              notesController.text,
                              newEarnings,
                              newDeductions,
                              newPayable,
                            );
                            Navigator.pop(context);
                            setInnerState(() {});
                            widget.showSnackBar("✅ Manual changes saved", isError: false);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, String hint) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: _textPrimary, fontSize: 13.sp, fontWeight: FontWeight.w500),
              ),
              Text(
                hint,
                style: TextStyle(color: _textMuted, fontSize: 10.sp),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: "₨ ",
              prefixStyle: TextStyle(color: _salaryPrimary, fontSize: 14.sp),
              filled: true,
              fillColor: _bgElevated,
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: _salaryPrimary),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(String label, double oldVal, double newVal, double diff, {bool isTotal = false}) {
    final isPositive = diff >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? _textPrimary : _textSecondary,
            fontSize: isTotal ? 14.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              _formatFullCurrency(oldVal),
              style: TextStyle(
                color: _textMuted,
                fontSize: 12.sp,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              _formatFullCurrency(newVal),
              style: TextStyle(
                color: isTotal ? _salaryPrimary : _textPrimary,
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (diff != 0) ...[
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isPositive ? _accentSuccess.withOpacity(0.1) : _accentDanger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  isPositive ? "+${diff.toStringAsFixed(0)}" : diff.toStringAsFixed(0),
                  style: TextStyle(
                    color: isPositive ? _accentSuccess : _accentDanger,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _saveManualChanges(
      DocumentSnapshot record,
      Map<String, double> newEarnings,
      double additionalDeduction,
      String notes,
      double totalEarnings,
      double totalDeductions,
      double finalPayable,
      ) async {
    try {
      final data = record.data() as Map<String, dynamic>;

      // Track what was changed
      final manualChanges = <String, dynamic>{
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'originalEarnings': data['earnings'],
        'originalDeductions': data['deductions'],
        'originalTotalEarnings': data['totalEarnings'],
        'originalTotalDeductions': data['totalDeductions'],
        'originalFinalPayable': data['finalPayable'],
        'newEarnings': newEarnings,
        'additionalDeduction': additionalDeduction,
        'notes': notes,
      };

      await record.reference.update({
        'earnings': newEarnings,
        'totalEarnings': totalEarnings,
        'totalDeductions': totalDeductions,
        'finalPayable': finalPayable,
        'netPayable': finalPayable,
        'isAutoCalculated': false,
        'manualChanges': manualChanges,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("✅ Manual changes saved for ${data['teacherName']}");
    } catch (e) {
      widget.showSnackBar("❌ Error saving changes: $e", isError: true);
    }
  }

  Future<void> _approveSalaryRecord(DocumentSnapshot record) async {
    try {
      await record.reference.update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      widget.showSnackBar("✅ Salary approved", isError: false);
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    }
  }

  Future<void> _approveAllDrafts() async {
    try {
      final drafts = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('salaryRecords')
          .where('monthYear', isEqualTo: _getCurrentMonthYear())
          .where('status', isEqualTo: 'draft')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();
      final approvedBy = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

      for (var doc in drafts.docs) {
        batch.update(doc.reference, {
          'status': 'approved',
          'approvedAt': now,
          'approvedBy': approvedBy,
          'updatedAt': now,
        });
      }

      await batch.commit();
      widget.showSnackBar("✅ ${drafts.docs.length} salaries approved", isError: false);
      Navigator.pop(context);
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    }
  }

  void _showProcessPaymentsDialog() {
    final monthYear = _getCurrentMonthYear();
    final query = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('salaryRecords')
        .where('monthYear', isEqualTo: monthYear)
        .where('status', isEqualTo: 'approved');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 600.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Process Payments",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _buildResilientStream(
                    query: query,
                    cacheKey: 'approvedRecords',
                    maxRetries: 3,
                  ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData && _cachedApprovedRecords == null) {
                      return _buildShimmerList();
                    }

                    final approved = snapshot.hasData
                        ? snapshot.data!.docs
                        : _cachedApprovedRecords ?? [];

                    if (approved.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.check_circle,
                        title: "No approved salaries",
                        subtitle: "Approve drafts first",
                      );
                    }

                    return ListView.builder(
                      itemCount: approved.length,
                      itemBuilder: (context, index) {
                        final record = approved[index];
                        final data = record.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _salaryPrimary,
                            child: Text(
                              (data['teacherName'] ?? 'T')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            data['teacherName'] ?? 'Unknown',
                            style: TextStyle(color: _textPrimary),
                          ),
                          subtitle: Text(
                            _formatFullCurrency((data['finalPayable'] ?? 0).toDouble()),
                            style: TextStyle(color: _salaryPrimary),
                          ),
                          trailing: _industrialButton(
                            "Pay",
                            onPressed: () => _processSinglePayment(record),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Close",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processSinglePayment(DocumentSnapshot record) async {
    try {
      await record.reference.update({
        'status': 'paid',
        'paidAmount': (record['finalPayable'] ?? 0).toDouble(),
        'paidDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      widget.showSnackBar("✅ Payment processed", isError: false);
    } catch (e) {
      widget.showSnackBar("❌ Error: $e", isError: true);
    }
  }

  void _showPaymentDialog(DocumentSnapshot record, StateSetter setInnerState) {
    final data = record.data() as Map<String, dynamic>;
    final amount = (data['finalPayable'] ?? 0).toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          "Confirm Payment",
          style: TextStyle(color: _textPrimary),
        ),
        content: Text(
          "Pay ${_formatFullCurrency(amount)} to ${data['teacherName']}?",
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          _industrialButton(
            "Cancel",
            onPressed: () => Navigator.pop(context),
            isSecondary: true,
          ),
          _industrialButton(
            "Confirm",
            onPressed: () async {
              Navigator.pop(context);
              await _processSinglePayment(record);
              setInnerState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _showSalaryStructureDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 800.w,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: _salaryPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.settings, color: _salaryPrimary, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      "Salary Structure",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(widget.schoolId)
                      .collection('salaryStructures')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return _buildShimmerList();

                    final structures = snapshot.data!.docs;
                    if (structures.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.settings_outlined,
                        title: "No salary structures",
                        subtitle: "Create your first structure",
                      );
                    }

                    return ListView.builder(
                      itemCount: structures.length,
                      itemBuilder: (context, index) {
                        final structure = structures[index];
                        final data = structure.data() as Map<String, dynamic>;

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: _bgElevated,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['name'] ?? 'Unnamed',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (data['isDefault'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: _salaryPrimary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        "DEFAULT",
                                        style: TextStyle(
                                          color: _salaryPrimary,
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                data['description'] ?? '',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "Currency: ${data['currency'] ?? 'PKR'}",
                                style: TextStyle(
                                  color: _textMuted,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Close",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvanceDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Container(
          width: widget.isMobile ? double.infinity : 500.w,
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Salary Advances",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('teacherSalaryProfiles')
                    .where('advanceBalance', isGreaterThan: 0)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();

                  final profiles = snapshot.data!.docs;
                  if (profiles.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.money_off,
                      title: "No active advances",
                      subtitle: "All teachers have cleared their advances",
                    );
                  }

                  return Container(
                    constraints: BoxConstraints(maxHeight: 300.h),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final data = profile.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(
                            data['teacherName'] ?? 'Unknown',
                            style: TextStyle(color: _textPrimary),
                          ),
                          subtitle: Text(
                            "Balance: ${_formatFullCurrency((data['advanceBalance'] ?? 0).toDouble())}",
                            style: TextStyle(color: _accentWarning),
                          ),
                          trailing: _industrialButton(
                            "Details",
                            onPressed: () {},
                            isSecondary: true,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: _industrialButton(
                  "Close",
                  onPressed: () => Navigator.pop(context),
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSalaryData() async {
    widget.showSnackBar("📊 Export feature coming soon!", isError: false);
  }

  // ─── SHARED UI COMPONENTS ─────────────────────────────────────────────────────

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
            : const LinearGradient(colors: [_primary, _primaryLight]),
        color: isSecondary ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(10.r),
        border: isSecondary ? Border.all(color: _border) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            child: isLoading
                ? SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isSecondary ? _textPrimary : Colors.white,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: isSecondary ? _textPrimary : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
              child: Icon(
                icon,
                color: _primary,
                size: compact ? 32.sp : 48.sp,
              ),
            ),
            SizedBox(height: compact ? 12.h : 20.h),
            Text(
              title,
              style: TextStyle(
                color: _textPrimary,
                fontSize: compact ? 16.sp : 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                color: _textSecondary,
                fontSize: compact ? 12.sp : 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
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
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
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
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 150.w,
                      height: 12.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalaryInfoItem(String label, double amount, {bool isHighlighted = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textMuted,
            fontSize: 11.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "₨${_formatCurrency(amount)}",
          style: TextStyle(
            color: isHighlighted ? _salaryPrimary : _textPrimary,
            fontSize: isHighlighted ? 14.sp : 12.sp,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}