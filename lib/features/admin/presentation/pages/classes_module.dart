// Firestore Path:
//   schools/{schoolId}/classes/{classId}
//
// Document fields:
//   name         String   e.g. "10A"
//   grade        String   e.g. "10"
//   section      String   e.g. "A"
//   classTeacher String   teacher name (optional)
//   classTeacherId String teacher doc id (optional)
//   capacity     int      max students
//   room         String   room number/name
//   subjects     List     list of subject names
//   shift        String   "Morning" | "Afternoon" | "Evening"
//   createdAt    Timestamp
//   updatedAt    Timestamp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

// ─── COLOUR PALETTE (mirrors AdminDashboardPage exactly) ─────────────────────
const Color _bgDark      = Color(0xFF0F1117);
const Color _bgCard      = Color(0xFF161922);
const Color _bgElevated  = Color(0xFF1E212E);
const Color _border      = Color(0xFF2A2E3B);
const Color _borderLight = Color(0xFF353A4A);
const Color _primary     = Color(0xFF7C8CF0);
const Color _primaryLight= Color(0xFF9AA5F3);
const Color _accentGreen = Color(0xFF3DD68B);
const Color _accentAmber = Color(0xFFF2A93B);
const Color _accentRed   = Color(0xFFF2657A);
const Color _accentBlue  = Color(0xFF4DBEF7);
const Color _accentViolet= Color(0xFFB084F5);
const Color _textPrimary = Color(0xFFEEF1F8);
const Color _textSecondary=Color(0xFF8B92A8);
const Color _textMuted   = Color(0xFF5A6072);

// ─── GRADE COLOUR MAP ────────────────────────────────────────────────────────
Color _gradeColor(String grade) {
  final g = int.tryParse(grade) ?? 0;
  if (g <= 3)  return _accentGreen;
  if (g <= 6)  return _accentBlue;
  if (g <= 8)  return _accentAmber;
  if (g <= 10) return _accentRed;
  return _accentViolet;
}

// ─────────────────────────────────────────────────────────────────────────────
// ClassesModule — top-level widget
// ─────────────────────────────────────────────────────────────────────────────
class ClassesModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final void Function(String msg, {bool isError}) showSnackBar;

  const ClassesModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<ClassesModule> createState() => _ClassesModuleState();
}

class _ClassesModuleState extends State<ClassesModule>
    with SingleTickerProviderStateMixin {

  // ── View state ──────────────────────────────────────────────────────────────
  /// "grid" | "list"
  String _viewMode = 'grid';

  /// Search text
  String _searchQuery = '';

  /// Grade filter — null means all
  String? _filterGrade;

  /// Shift filter — null means all
  String? _filterShift;

  /// Sort field
  String _sortBy = 'name'; // 'name' | 'grade' | 'capacity' | 'students'

  // ── Tab controller for grade tabs ───────────────────────────────────────────
  late TabController _tabController;

  static const List<String> _grades = [
    'All', '1', '2', '3', '4', '5',
    '6', '7', '8', '9', '10',
  ];

  void _showBulkCreateDialog() {
    // Local state inside dialog
    String _bulkGrade      = '1';
    List<String> _sections = ['A'];
    String _bulkShift      = 'Morning';
    int _bulkCapacity      = 40;
    bool _isCreating       = false;
    String _status         = '';

    final _sectionOptions = ['A','B','C','D','E','F'];
    final _shiftOptions   = ['Morning','Afternoon','Evening'];
    final _gradeOptions   = List.generate(12, (i) => '${i + 1}');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          Future<void> _createAll() async {
            setDialog(() { _isCreating = true; _status = 'Creating classes…'; });
            int created = 0;
            int skipped = 0;

            for (final section in _sections) {
              final className = 'Grade $_bulkGrade$section';
              try {
                // Check if already exists
                final existing = await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('classes')
                    .where('name', isEqualTo: className)
                    .where('shift', isEqualTo: _bulkShift)
                    .get();

                if (existing.docs.isNotEmpty) {
                  skipped++;
                  setDialog(() => _status = '⚠️ $className already exists, skipping…');
                  continue;
                }

                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('classes')
                    .add({
                  'name':         className,
                  'grade':        _bulkGrade,
                  'section':      section,
                  'shift':        _bulkShift,
                  'capacity':     _bulkCapacity,
                  'classTeacher': '',
                  'teacherId':    '',
                  'subjects':     [],
                  'room':         '',
                  'createdAt':    FieldValue.serverTimestamp(),
                });

                created++;
                setDialog(() => _status = '✅ Created $className');
              } catch (e) {
                setDialog(() => _status = '❌ Error creating $className: $e');
              }
            }

            setDialog(() {
              _isCreating = false;
              _status = created > 0
                  ? '✅ Done! Created $created class${created > 1 ? 'es' : ''}'
                  '${skipped > 0 ? ', skipped $skipped existing' : ''}.'
                  : '⚠️ No classes created — all already exist.';
            });

            await Future.delayed(const Duration(seconds: 2));
            if (ctx.mounted) Navigator.pop(ctx);
          }

          return Dialog(
            backgroundColor: _bgCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            child: Container(
              width: 480.w,
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Row(children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [_primary, _primaryLight]),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 22.sp),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bulk Create Classes',
                              style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w800)),
                          Text(
                            'Create multiple sections at once',
                            style: TextStyle(
                                color: _textSecondary, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _isCreating ? null : () => Navigator.pop(ctx),
                      child: Icon(Icons.close_rounded,
                          color: _textMuted, size: 22.sp),
                    ),
                  ]),

                  SizedBox(height: 24.h),
                  Divider(color: _border, height: 1),
                  SizedBox(height: 20.h),

                  // ── Grade picker ─────────────────────────────────────────
                  Text('Grade',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: _bgElevated,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: _border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _bulkGrade,
                        isExpanded: true,
                        dropdownColor: _bgElevated,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: _textMuted),
                        items: _gradeOptions.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text('Grade $g',
                              style: TextStyle(
                                  color: _textPrimary, fontSize: 13.sp)),
                        )).toList(),
                        onChanged: _isCreating
                            ? null
                            : (v) => setDialog(() => _bulkGrade = v ?? '1'),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Section selector ─────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sections',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${_sections.length} selected',
                        style: TextStyle(color: _primary, fontSize: 12.sp),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _sectionOptions.map((s) {
                      final selected = _sections.contains(s);
                      return GestureDetector(
                        onTap: _isCreating
                            ? null
                            : () => setDialog(() {
                          if (selected) {
                            if (_sections.length > 1) _sections.remove(s);
                          } else {
                            _sections.add(s);
                            _sections.sort();
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44.w,
                          height: 44.w,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                                colors: [_primary, _primaryLight])
                                : null,
                            color: selected ? null : _bgElevated,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: selected
                                  ? Colors.transparent
                                  : _border,
                            ),
                            boxShadow: selected
                                ? [BoxShadow(
                                color: _primary.withOpacity(0.30),
                                blurRadius: 10,
                                offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              s,
                              style: TextStyle(
                                color: selected ? Colors.white : _textSecondary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 16.h),

                  // ── Shift ────────────────────────────────────────────────
                  Text('Shift',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  Row(
                    children: _shiftOptions.map((s) {
                      final sel = _bulkShift == s;
                      return Expanded(
                        child: GestureDetector(
                          onTap: _isCreating
                              ? null
                              : () => setDialog(() => _bulkShift = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: EdgeInsets.only(
                                right: s != 'Evening' ? 8.w : 0),
                            padding: EdgeInsets.symmetric(vertical: 11.h),
                            decoration: BoxDecoration(
                              gradient: sel
                                  ? const LinearGradient(
                                  colors: [_primary, _primaryLight])
                                  : null,
                              color: sel ? null : _bgElevated,
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                  color: sel ? Colors.transparent : _border),
                              boxShadow: sel
                                  ? [BoxShadow(
                                  color: _primary.withOpacity(0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3))]
                                  : [],
                            ),
                            child: Center(
                              child: Text(s,
                                  style: TextStyle(
                                    color: sel ? Colors.white : _textSecondary,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 16.h),

                  // ── Capacity ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Capacity per class',
                          style: TextStyle(
                              color: _textSecondary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600)),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '$_bulkCapacity students',
                          style: TextStyle(
                              color: _primary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: _primary,
                      inactiveTrackColor: _bgElevated,
                      thumbColor: _primaryLight,
                      overlayColor: _primary.withOpacity(0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _bulkCapacity.toDouble(),
                      min: 10, max: 80, divisions: 14,
                      onChanged: _isCreating
                          ? null
                          : (v) => setDialog(
                              () => _bulkCapacity = v.round()),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Preview ──────────────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: _bgElevated,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preview — ${_sections.length} class${_sections.length > 1 ? 'es' : ''} will be created',
                            style: TextStyle(
                                color: _textSecondary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600)),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: _sections.map((s) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                  color: _primary.withOpacity(0.25)),
                            ),
                            child: Text(
                              'Grade $_bulkGrade$s · $_bulkShift · $_bulkCapacity',
                              style: TextStyle(
                                  color: _primary,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600),
                            ),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── Status message ───────────────────────────────────────
                  if (_status.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _status.startsWith('✅')
                            ? _accentGreen.withOpacity(0.08)
                            : _status.startsWith('❌')
                            ? _accentRed.withOpacity(0.08)
                            : _accentAmber.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(_status,
                          style: TextStyle(
                              color: _status.startsWith('✅')
                                  ? _accentGreen
                                  : _status.startsWith('❌')
                                  ? _accentRed
                                  : _accentAmber,
                              fontSize: 12.sp)),
                    ),
                  ],

                  SizedBox(height: 20.h),

                  // ── Actions ──────────────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _isCreating ? null : () => Navigator.pop(ctx),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          decoration: BoxDecoration(
                            color: _bgElevated,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: _border),
                          ),
                          child: Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: _textSecondary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isCreating ? null : _createAll,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(vertical: 13.h),
                          decoration: BoxDecoration(
                            gradient: _isCreating
                                ? LinearGradient(colors: [
                              _primary.withOpacity(0.5),
                              _primaryLight.withOpacity(0.5)
                            ])
                                : const LinearGradient(
                                colors: [_primary, _primaryLight]),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: _isCreating
                                ? []
                                : [BoxShadow(
                                color: _primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5))],
                          ),
                          child: Center(
                            child: _isCreating
                                ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                                : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  'Create ${_sections.length} Class${_sections.length > 1 ? 'es' : ''}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _grades.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filterGrade = _grades[_tabController.index] == 'All'
              ? null
              : _grades[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Firestore stream ────────────────────────────────────────────────────────
  Stream<QuerySnapshot> get _classStream => FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('classes')
      .orderBy('createdAt', descending: false)
      .snapshots();

  // ── Filter + sort logic ─────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    var list = docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final name    = (d['name']    ?? '').toString().toLowerCase();
      final grade   = (d['grade']   ?? '').toString();
      final room    = (d['room']    ?? '').toString().toLowerCase();
      final teacher = (d['classTeacher'] ?? '').toString().toLowerCase();
      final shift   = (d['shift']   ?? '').toString();

      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          name.contains(q) || grade.contains(q) ||
          room.contains(q) || teacher.contains(q);

      final matchGrade = _filterGrade == null || grade == _filterGrade;
      final matchShift = _filterShift == null || shift == _filterShift;

      return matchSearch && matchGrade && matchShift;
    }).toList();

    list.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      switch (_sortBy) {
        case 'grade':
          final ga = int.tryParse(da['grade'] ?? '0') ?? 0;
          final gb = int.tryParse(db['grade'] ?? '0') ?? 0;
          return ga == gb
              ? (da['section'] ?? '').compareTo(db['section'] ?? '')
              : ga.compareTo(gb);
        case 'capacity':
          return (db['capacity'] ?? 0).compareTo(da['capacity'] ?? 0);
        default: // 'name'
          return (da['name'] ?? '').compareTo(db['name'] ?? '');
      }
    });
    return list;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 20.h),
        _buildGradeTabs(),
        SizedBox(height: 16.h),
        _buildSearchBar(),
        SizedBox(height: 16.h),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(widget.isMobile ? 18.w : 24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primary.withOpacity(0.15), _bgCard],
          ),
          border: Border.all(color: _primary.withOpacity(0.22)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -28.h, right: -16.w,
              child: Container(
                width: 120.w, height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(0.09),
                ),
              ),
            ),
            Positioned(
              bottom: -36.h, right: 60.w,
              child: Container(
                width: 90.w, height: 90.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentBlue.withOpacity(0.06),
                ),
              ),
            ),

            widget.isMobile
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _headerIconBadge(),
                  SizedBox(width: 14.w),
                  Expanded(child: _headerTitleBlock()),
                ]),
                SizedBox(height: 16.h),
                Row(children: [
                  Expanded(
                    child: _secondaryButton(
                        '⚡ Bulk', _showBulkCreateDialog),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: _primaryButton(
                        '+ Add Class', _openAddClassDialog),
                  ),
                ]),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _headerIconBadge(),
                SizedBox(width: 18.w),
                Expanded(child: _headerTitleBlock()),
                StreamBuilder<QuerySnapshot>(
                  stream: _classStream,
                  builder: (context, snap) {
                    final total = snap.data?.docs.length ?? 0;
                    return Row(children: [
                      _headerStatPill(Icons.class_outlined, '$total',
                          'Classes', _primary),
                      SizedBox(width: 8.w),
                    ]);
                  },
                ),
                SizedBox(width: 12.w),
                _viewToggle(),
                SizedBox(width: 10.w),
                _sortButton(),
                SizedBox(width: 10.w),
                // ✅ Bulk Create button added
                _secondaryButton('⚡ Bulk Create', _showBulkCreateDialog),
                SizedBox(width: 10.w),
                _primaryButton('+ Add Class', _openAddClassDialog),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _headerIconBadge() {
    return Container(
      padding: EdgeInsets.all(widget.isMobile ? 12.w : 14.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.38),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(Icons.class_rounded,
          color: Colors.white,
          size: widget.isMobile ? 24.sp : 28.sp),
    );
  }

  Widget _headerTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFEEF1F8), _primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'Class Management',
            style: TextStyle(
              color: Colors.white,
              fontSize: widget.isMobile ? 22.sp : 26.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Create, organise and manage school classes',
          style: TextStyle(color: _textSecondary, fontSize: 13.sp),
        ),
      ],
    );
  }

  Widget _headerStatPill(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 8.w),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(color: _textMuted, fontSize: 10.sp)),
        ]),
      ]),
    );
  }


  // ── Grade tabs ──────────────────────────────────────────────────────────────
  Widget _buildGradeTabs() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        physics: const BouncingScrollPhysics(),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(9.r),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _textSecondary,
        labelStyle:
        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
        TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
        tabs: _grades
            .map((g) => Tab(
          height: 36.h,
          text: g == 'All' ? 'All Grades' : 'Grade $g',
        ))
            .toList(),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Row(children: [
      Expanded(
        child: Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: _textPrimary, fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Search class name, room, teacher…',
              hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
              prefixIcon: Icon(Icons.search_rounded,
                  color: _textMuted, size: 20.sp),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                onTap: () => setState(() => _searchQuery = ''),
                child: Icon(Icons.clear_rounded,
                    color: _textMuted, size: 18.sp),
              )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 13.h),
            ),
          ),
        ),
      ),
      SizedBox(width: 10.w),
      _shiftFilterButton(),
      if (!widget.isMobile) ...[
        SizedBox(width: 10.w),
        _viewToggle(),
      ],
    ]);
  }

  Widget _shiftFilterButton() {
    return PopupMenuButton<String?>(
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: _border),
      ),
      onSelected: (v) => setState(() => _filterShift = v),
      itemBuilder: (_) => [
        _shiftItem(null, 'All Shifts'),
        _shiftItem('Morning', 'Morning'),
        _shiftItem('Afternoon', 'Afternoon'),
        _shiftItem('Evening', 'Evening'),
      ],
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: _filterShift != null ? _primary.withOpacity(0.15) : _bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: _filterShift != null ? _primary.withOpacity(0.5) : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wb_sunny_outlined,
                color: _filterShift != null ? _primary : _textSecondary,
                size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              _filterShift ?? 'Shift',
              style: TextStyle(
                color: _filterShift != null ? _primary : _textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String?> _shiftItem(String? value, String label) {
    final isSelected = _filterShift == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            color: isSelected ? _primary : _textMuted,
            size: 16.sp,
          ),
          SizedBox(width: 10.w),
          Text(label,
              style: TextStyle(
                  color: _textPrimary, fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _viewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleBtn(Icons.grid_view_rounded, 'grid'),
          _viewToggleBtn(Icons.format_list_bulleted_rounded, 'list'),
        ],
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, String mode) {
    final active = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38.w,
        height: 38.h,
        decoration: BoxDecoration(
          color: active ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon,
            color: active ? Colors.white : _textMuted, size: 18.sp),
      ),
    );
  }

  Widget _sortButton() {
    return PopupMenuButton<String>(
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: _border),
      ),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        _sortItem('name', 'Name (A–Z)'),
        _sortItem('grade', 'Grade'),
        _sortItem('capacity', 'Capacity'),
      ],
      child: Container(
        height: 44.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, color: _textSecondary, size: 16.sp),
            SizedBox(width: 6.w),
            Text('Sort',
                style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(label,
          style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: _classStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _shimmerGrid();
        }
        if (snapshot.hasError) {
          return _errorState(snapshot.error.toString());
        }

        final all = snapshot.data?.docs ?? [];
        final filtered = _applyFilters(all);

        if (all.isEmpty) {
          return _emptyState(
            icon: Icons.class_outlined,
            title: 'No classes yet',
            subtitle: 'Tap "+ Add Class" to create your first class.',
          );
        }

        if (filtered.isEmpty) {
          return _emptyState(
            icon: Icons.search_off_rounded,
            title: 'No results found',
            subtitle: 'Try a different search or filter.',
          );
        }

        return _viewMode == 'list'
            ? _buildListView(filtered)
            : _buildGridView(filtered);
      },
    );
  }

  // ── Grid view ───────────────────────────────────────────────────────────────
  Widget _buildGridView(List<QueryDocumentSnapshot> docs) {
    final crossCount = widget.isMobile ? 1 : (widget.isTablet ? 2 : 3);
    return GridView.builder(
      padding: EdgeInsets.only(bottom: 24.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: widget.isMobile ? 1.6 : 1.35,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _ClassCard(
        doc: docs[i],
        schoolId: widget.schoolId,
        onEdit: () => _openEditClassDialog(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
        onTap: () => _openClassDetail(docs[i]),
      ),
    );
  }

  // ── List view ───────────────────────────────────────────────────────────────
  Widget _buildListView(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: EdgeInsets.only(bottom: 24.h),
      itemCount: docs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) => _ClassListTile(
        doc: docs[i],
        schoolId: widget.schoolId,
        onEdit: () => _openEditClassDialog(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
        onTap: () => _openClassDetail(docs[i]),
      ),
    );
  }

  // ── Add / Edit dialog ────────────────────────────────────────────────────────
  void _openAddClassDialog() => _openClassDialog(null);
  void _openEditClassDialog(QueryDocumentSnapshot doc) =>
      _openClassDialog(doc);

  void _openClassDialog(QueryDocumentSnapshot? existing) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _ClassFormDialog(
        schoolId: widget.schoolId,
        existing: existing,
        showSnackBar: widget.showSnackBar,
      ),
    );
  }

  // ── Class detail bottom sheet ─────────────────────────────────────────────────
  void _openClassDetail(QueryDocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClassDetailSheet(
        doc: doc,
        schoolId: widget.schoolId,
        onEdit: () {
          Navigator.pop(context);
          _openEditClassDialog(doc);
        },
        showSnackBar: widget.showSnackBar,
      ),
    );
  }

  // ── Delete confirmation ───────────────────────────────────────────────────────
  void _confirmDelete(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.delete_outline,
                  color: _accentRed, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Text('Delete Class?',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete class "${d['name']}"? '
              'This cannot be undone.',
          style: TextStyle(color: _textSecondary, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: _textSecondary, fontSize: 13.sp)),
          ),
          _primaryButton('Delete', () async {
            Navigator.pop(context);
            try {
              await doc.reference.delete();
              widget.showSnackBar('Class deleted successfully');
            } catch (e) {
              widget.showSnackBar('Error: $e', isError: true);
            }
          }, color: _accentRed),
        ],
      ),
    );
  }

  // ── Empty / error / shimmer states ───────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(0.15),
                  _primaryLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _primary.withOpacity(0.2)),
            ),
            child: Icon(icon, color: _primary, size: 52.sp),
          ),
          SizedBox(height: 22.h),
          Text(
            title,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(color: _textSecondary, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 28.h),
          _primaryButton('+ Add First Class', _openAddClassDialog),
        ],
      ),
    );
  }


  Widget _errorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: _accentRed, size: 48.sp),
          SizedBox(height: 12.h),
          Text('Failed to load classes',
              style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(error,
              style: TextStyle(color: _textMuted, fontSize: 11.sp),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _shimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.only(bottom: 24.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.isMobile ? 1 : (widget.isTablet ? 2 : 3),
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 1.35,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: _bgElevated,
        child: Container(
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _primaryButton(String label, VoidCallback onPressed,
      {Color? color}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: color == null
              ? const LinearGradient(
            colors: [_primary, _primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: color,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: (color ?? _primary).withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClassCard — grid card for a single class
// ─────────────────────────────────────────────────────────────────────────────
class _ClassCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ClassCard({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<_ClassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d        = widget.doc.data() as Map<String, dynamic>;
    final name     = d['name']         as String? ?? '';
    final grade    = d['grade']        as String? ?? '';
    final section  = d['section']      as String? ?? '';
    final room     = d['room']         as String? ?? '';
    final teacher  = d['classTeacher'] as String? ?? '';
    final capacity = d['capacity']     as int?    ?? 0;
    final shift    = d['shift']        as String? ?? '';
    final subjects = (d['subjects'] as List?)?.length ?? 0;
    final color    = _gradeColor(grade);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.55) : _border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: _hovered
                ? [BoxShadow(
                color: color.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 8))]
                : [BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 12,
                offset: const Offset(0, 3))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              children: [
                // ── Gradient top accent bar ──
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 4.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.4)]),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,   // ✅ no more huge gap
                    children: [
                      // ── Top row: badge + actions ──
                      Row(children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.20),
                                color.withOpacity(0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13.r),
                            border: Border.all(
                                color: color.withOpacity(0.35), width: 1.5),
                          ),
                          child: Center(
                            // ✅ shows grade number only, not full "10A"
                            child: Text(
                              grade.isNotEmpty ? grade : name,
                              style: TextStyle(
                                color: color,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w900,
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
                                name,
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                shift.isNotEmpty ? shift : 'No shift set',
                                style: TextStyle(
                                  color: shift.isNotEmpty
                                      ? _accentAmber
                                      : _textMuted,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _iconBtn(Icons.edit_outlined, _primary, widget.onEdit),
                        SizedBox(width: 6.w),
                        _iconBtn(
                            Icons.delete_outline, _accentRed, widget.onDelete),
                      ]),

                      SizedBox(height: 12.h),

                      // ── Chips: section + subjects ──
                      Wrap(spacing: 6.w, runSpacing: 6.h, children: [
                        if (section.isNotEmpty)
                          _chip('Section $section', _textMuted),
                        _chip('$subjects subject${subjects == 1 ? '' : 's'}',
                            _accentBlue),
                      ]),

                      SizedBox(height: 10.h),

                      // ── Room & teacher — always show both, fallback text ──
                      _infoRow(
                        Icons.room_outlined,
                        room.isNotEmpty ? room : 'Room not assigned',
                        dimmed: room.isEmpty,
                      ),
                      SizedBox(height: 4.h),
                      _infoRow(
                        Icons.person_outline,
                        teacher.isNotEmpty ? teacher : 'No teacher assigned',
                        dimmed: teacher.isEmpty,
                      ),

                      SizedBox(height: 14.h),
                      Divider(color: _border, height: 1),
                      SizedBox(height: 12.h),

                      // ── Student count + progress ──
                      _buildStudentCountRow(capacity),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCountRow(int capacity) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .where('class',
          isEqualTo: (widget.doc.data() as Map<String, dynamic>)['name'])
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        final pct = capacity > 0 ? count / capacity : 0.0;
        final fillColor = pct > 0.9
            ? _accentRed
            : pct > 0.7
            ? _accentAmber
            : _accentGreen;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.people_outline, color: _textMuted, size: 13.sp),
              SizedBox(width: 5.w),
              Text(
                '$count${capacity > 0 ? ' / $capacity' : ''} students',
                style: TextStyle(color: _textSecondary, fontSize: 11.sp),
              ),
              const Spacer(),
              if (capacity > 0)
                Text(
                  '${(pct * 100).toStringAsFixed(0)}% full',
                  style: TextStyle(
                      color: fillColor,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700),
                ),
            ]),
            if (capacity > 0) ...[
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  backgroundColor: _bgElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(fillColor),
                  minHeight: 5.h,
                ),
              ),
            ],
          ],
        );
      },
    );
  }


  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(7.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 15.sp),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5.r),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10.sp, fontWeight: FontWeight.w700)),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool dimmed = false}) {
    return Row(children: [
      Icon(icon,
          color: dimmed ? _textMuted.withOpacity(0.5) : _textMuted,
          size: 13.sp),
      SizedBox(width: 6.w),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: dimmed ? _textMuted.withOpacity(0.6) : _textSecondary,
            fontSize: 12.sp,
            fontStyle: dimmed ? FontStyle.italic : FontStyle.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ]);
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// _ClassListTile — compact list row for list view
// ─────────────────────────────────────────────────────────────────────────────
class _ClassListTile extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ClassListTile({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  State<_ClassListTile> createState() => _ClassListTileState();
}

class _ClassListTileState extends State<_ClassListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final name    = d['name']    as String? ?? '';
    final grade   = d['grade']   as String? ?? '';
    final room    = d['room']    as String? ?? '';
    final teacher = d['classTeacher'] as String? ?? '';
    final capacity= d['capacity'] as int?    ?? 0;
    final shift   = d['shift']   as String? ?? '';
    final subjects= List<String>.from(d['subjects'] ?? []);
    final color   = _gradeColor(grade);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _hovered ? _bgElevated : _bgCard,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _hovered ? color.withOpacity(0.4) : _border,
            ),
          ),
          child: Row(
            children: [
              // Badge
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: name.length > 3 ? 10.sp : 14.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Class $name',
                            style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700)),
                        SizedBox(width: 8.w),
                        _tinyChip('Gr.$grade', color),
                        if (shift.isNotEmpty) ...[
                          SizedBox(width: 4.w),
                          _tinyChip(shift, _accentAmber),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        if (room.isNotEmpty) ...[
                          Icon(Icons.room_outlined,
                              color: _textMuted, size: 11.sp),
                          SizedBox(width: 3.w),
                          Text(room,
                              style: TextStyle(
                                  color: _textSecondary, fontSize: 11.sp)),
                          SizedBox(width: 10.w),
                        ],
                        if (teacher.isNotEmpty) ...[
                          Icon(Icons.person_outline,
                              color: _textMuted, size: 11.sp),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(teacher,
                                style: TextStyle(
                                    color: _textSecondary, fontSize: 11.sp),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                    if (subjects.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 4.w,
                        runSpacing: 4.h,
                        children: subjects.take(4).map((s) =>
                            _tinyChip(s, _primary)).toList()
                          ..addAll(subjects.length > 4
                              ? [_tinyChip('+${subjects.length - 4}', _textMuted)]
                              : []),
                      ),
                    ],
                  ],
                ),
              ),

              // Students + actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('schools')
                        .doc(widget.schoolId)
                        .collection('students')
                        .where('class', isEqualTo: name)
                        .snapshots(),
                    builder: (ctx, snap) {
                      final count =
                      snap.hasData ? snap.data!.docs.length : 0;
                      return Text(
                        '$count${capacity > 0 ? "/$capacity" : ""} students',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 11.sp),
                      );
                    },
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _iconBtn2(
                          Icons.edit_outlined, _primary, widget.onEdit),
                      SizedBox(width: 6.w),
                      _iconBtn2(
                          Icons.delete_outline, _accentRed, widget.onDelete),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tinyChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9.sp, fontWeight: FontWeight.w700)),
    );
  }

  Widget _iconBtn2(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(7.r),
        ),
        child: Icon(icon, color: color, size: 14.sp),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClassFormDialog — Add / Edit class
// ─────────────────────────────────────────────────────────────────────────────
class _ClassFormDialog extends StatefulWidget {
  final String schoolId;
  final QueryDocumentSnapshot? existing;
  final void Function(String, {bool isError}) showSnackBar;

  const _ClassFormDialog({
    required this.schoolId,
    required this.existing,
    required this.showSnackBar,
  });

  @override
  State<_ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<_ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl    = TextEditingController();
  final _roomCtrl    = TextEditingController();
  final _capacityCtrl= TextEditingController();

  String  _grade   = '1';
  String  _section = 'A';
  String  _shift   = 'Morning';
  String  _teacherName = '';
  String  _teacherId   = '';
  List<String> _subjects = [];
  bool _isSaving = false;

  // Dropdown values
  final List<String> _gradeOptions =
  List.generate(12, (i) => '${i + 1}');
  final List<String> _sectionOptions =
  ['A', 'B', 'C', 'D', 'E', 'F'];
  final List<String> _shiftOptions =
  ['Morning', 'Afternoon', 'Evening'];
  final List<String> _allSubjects = [
    'Mathematics', 'Physics', 'Chemistry', 'Biology',
    'Computer Science', 'English', 'Urdu', 'History',
    'Geography', 'Islamiat', 'Pakistan Studies',
    'Economics', 'Accounting', 'Art & Design', 'Physical Education',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!.data() as Map<String, dynamic>;
      _nameCtrl.text     = d['name']     ?? '';
      _roomCtrl.text     = d['room']     ?? '';
      _capacityCtrl.text = (d['capacity'] ?? '').toString();
      _grade    = d['grade']   ?? '1';
      _section  = d['section'] ?? 'A';
      _shift    = d['shift']   ?? 'Morning';
      _teacherName = d['classTeacher']   ?? '';
      _teacherId   = d['classTeacherId'] ?? '';
      _subjects    = List<String>.from(d['subjects'] ?? []);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  // Auto-generate class name
  void _autoName() {
    if (_nameCtrl.text.isEmpty ||
        _nameCtrl.text == '$_grade${_section}' ||
        _nameCtrl.text.startsWith(_grade)) {
      setState(() => _nameCtrl.text = '$_grade$_section');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'name'           : _nameCtrl.text.trim().toUpperCase(),
        'grade'          : _grade,
        'section'        : _section,
        'shift'          : _shift,
        'room'           : _roomCtrl.text.trim(),
        'capacity'       : int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'classTeacher'   : _teacherName,
        'classTeacherId' : _teacherId,
        'subjects'       : _subjects,
        'updatedAt'      : FieldValue.serverTimestamp(),
      };

      if (widget.existing == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('classes')
            .add(data);
        widget.showSnackBar('Class created successfully!');
      } else {
        await widget.existing!.reference.update(data);
        widget.showSnackBar('Class updated successfully!');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        width: 560.w,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildDialogHeader(isEdit),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Class Identity'),
                      SizedBox(height: 12.h),
                      _gradeAndSectionRow(),
                      SizedBox(height: 14.h),
                      _classNameField(),
                      SizedBox(height: 20.h),

                      _sectionLabel('Logistics'),
                      SizedBox(height: 12.h),
                      _roomAndCapacityRow(),
                      SizedBox(height: 14.h),
                      _shiftSelector(),
                      SizedBox(height: 20.h),

                      _sectionLabel('Class Teacher'),
                      SizedBox(height: 12.h),
                      _teacherPicker(),
                      SizedBox(height: 20.h),

                      _sectionLabel('Subjects Offered'),
                      SizedBox(height: 12.h),
                      _subjectSelector(),
                      SizedBox(height: 28.h),

                      _actionButtons(isEdit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(bool isEdit) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 16.w, 20.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_primary, _primaryLight]),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.class_outlined, color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Class' : 'Add New Class',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isEdit ? 'Update class details' : 'Fill in the details below',
                  style: TextStyle(color: _textSecondary, fontSize: 11.sp),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: _border),
              ),
              child: Icon(Icons.close, color: _textMuted, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 14.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_primary, _primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _gradeAndSectionRow() {
    return Row(
      children: [
        Expanded(
          child: _labeledField(
            'Grade *',
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: _border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _grade,
                  isExpanded: true,
                  dropdownColor: _bgElevated,
                  style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                  items: _gradeOptions
                      .map((g) => DropdownMenuItem(
                      value: g,
                      child: Text('Grade $g',
                          style: TextStyle(
                              color: _textPrimary, fontSize: 13.sp))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _grade = v!);
                    _autoName();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _labeledField(
            'Section *',
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: _border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _section,
                  isExpanded: true,
                  dropdownColor: _bgElevated,
                  style: TextStyle(color: _textPrimary, fontSize: 13.sp),
                  items: _sectionOptions
                      .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text('Section $s',
                          style: TextStyle(
                              color: _textPrimary, fontSize: 13.sp))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _section = v!);
                    _autoName();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _classNameField() {
    return _labeledField(
      'Class Name *',
      TextFormField(
        controller: _nameCtrl,
        style: TextStyle(color: _textPrimary, fontSize: 13.sp),
        textCapitalization: TextCapitalization.characters,
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Required' : null,
        decoration: _inputDecoration('e.g. 10A, KG-B'),
      ),
    );
  }

  Widget _roomAndCapacityRow() {
    return Row(
      children: [
        Expanded(
          child: _labeledField(
            'Room / Block',
            TextFormField(
              controller: _roomCtrl,
              style: TextStyle(color: _textPrimary, fontSize: 13.sp),
              decoration: _inputDecoration('e.g. Room 12, Block B'),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        SizedBox(
          width: 120.w,
          child: _labeledField(
            'Capacity',
            TextFormField(
              controller: _capacityCtrl,
              style: TextStyle(color: _textPrimary, fontSize: 13.sp),
              keyboardType: TextInputType.number,
              decoration: _inputDecoration('e.g. 40'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shiftSelector() {
    return _labeledField(
      'Shift',
      Row(
        children: _shiftOptions.map((s) {
          final selected = _shift == s;
          final icon = s == 'Morning'
              ? Icons.wb_sunny_outlined
              : s == 'Afternoon'
              ? Icons.wb_cloudy_outlined
              : Icons.nights_stay_outlined;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _shift = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(
                    right: s != _shiftOptions.last ? 8.w : 0),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: selected
                      ? _accentAmber.withOpacity(0.1)
                      : _bgElevated,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: selected
                        ? _accentAmber.withOpacity(0.6)
                        : _border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        color: selected ? _accentAmber : _textMuted,
                        size: 18.sp),
                    SizedBox(height: 4.h),
                    Text(s,
                        style: TextStyle(
                          color: selected ? _accentAmber : _textSecondary,
                          fontSize: 11.sp,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _teacherPicker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('teachers')
      // ✅ No status filter — shows all teachers regardless of status field
          .orderBy('name')
          .snapshots(),
      builder: (context, snap) {
        // Loading
        if (!snap.hasData) {
          return Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                    color: _primary, strokeWidth: 2),
              ),
            ),
          );
        }

        final teachers = snap.data!.docs;

        // Empty — but now shows helpful message with reason
        if (teachers.isEmpty) {
          return Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: _accentAmber.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _accentAmber.withOpacity(0.25)),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: _accentAmber, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'No teachers found — add teachers first to assign a class teacher.',
                  style: TextStyle(color: _accentAmber, fontSize: 12.sp),
                ),
              ),
            ]),
          );
        }

        // Dropdown
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          decoration: BoxDecoration(
            color: _bgElevated,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _teacherId.isEmpty ? null : _teacherId,
              isExpanded: true,
              dropdownColor: _bgElevated,
              menuMaxHeight: 280.h,
              hint: Text(
                'Select class teacher (optional)',
                style: TextStyle(color: _textMuted, fontSize: 13.sp),
              ),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: _textMuted, size: 20.sp),
              items: [
                // None option
                DropdownMenuItem<String>(
                  value: '',
                  child: Text('None — unassigned',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic)),
                ),
                ...teachers.map((t) {
                  final td = t.data() as Map<String, dynamic>;
                  final name       = td['name']       as String? ?? 'Unknown';
                  final subject    = td['subject']    as String? ?? '';
                  final hasStatus  = td.containsKey('status');
                  final isActive   = td['status'] == 'active';

                  return DropdownMenuItem<String>(
                    value: t.id,
                    child: Row(children: [
                      // Avatar circle
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                                color: _primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(name,
                                style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                            if (subject.isNotEmpty)
                              Text(subject,
                                  style: TextStyle(
                                      color: _textMuted, fontSize: 11.sp),
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      // Active/inactive dot (only if status field exists)
                      if (hasStatus)
                        Container(
                          width: 7.w,
                          height: 7.w,
                          decoration: BoxDecoration(
                            color: isActive ? _accentGreen : _textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ]),
                  );
                }),
              ],
              onChanged: (v) {
                setState(() {
                  _teacherId = v ?? '';
                  if (v == null || v.isEmpty) {
                    _teacherName = '';
                  } else {
                    final match = teachers.firstWhere(
                          (t) => t.id == v,
                      orElse: () => teachers.first,
                    );
                    final td = match.data() as Map<String, dynamic>;
                    _teacherName = td['name'] as String? ?? '';
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _subjectSelector() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _allSubjects.map((s) {
        final selected = _subjects.contains(s);
        return GestureDetector(
          onTap: () {
            setState(() {
              selected ? _subjects.remove(s) : _subjects.add(s);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                  colors: [_primary, _primaryLight])
                  : null,
              color: selected ? null : _bgElevated,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: selected ? Colors.transparent : _border,
              ),
            ),
            child: Text(
              s,
              style: TextStyle(
                color: selected ? Colors.white : _textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _actionButtons(bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: _bgElevated,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: _border),
              ),
              child: Center(
                child: Text('Cancel',
                    style: TextStyle(
                        color: _textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _isSaving ? null : _save,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                gradient: _isSaving
                    ? null
                    : const LinearGradient(
                  colors: [_primary, _primaryLight],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                color: _isSaving ? _bgElevated : null,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: _isSaving
                    ? []
                    : [
                  BoxShadow(
                    color: _primary.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isSaving
                    ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  isEdit ? 'Update Class' : 'Create Class',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: _textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 6.h),
        field,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
      filled: true,
      fillColor: _bgElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: _accentRed),
      ),
      contentPadding:
      EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ClassDetailSheet — full detail bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ClassDetailSheet extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;
  final void Function(String, {bool isError}) showSnackBar;

  const _ClassDetailSheet({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
    required this.showSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    final d    = doc.data() as Map<String, dynamic>;
    final name = d['name']  as String? ?? '';
    final grade= d['grade'] as String? ?? '';
    final color= _gradeColor(grade);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: _textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                Container(
                  width: 56.w,
                  height: 56.w,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: color,
                        fontSize: name.length > 3 ? 13.sp : 18.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class $name',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Grade ${d['grade']} · Section ${d['section']} · ${d['shift'] ?? ''}',
                        style: TextStyle(
                            color: _textSecondary, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_primary, _primaryLight]),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text('Edit',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),
          Divider(color: _border, height: 1),
          SizedBox(height: 16.h),

          // Details grid
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailGrid(d),
                  SizedBox(height: 20.h),
                  if ((d['subjects'] as List?)?.isNotEmpty == true) ...[
                    _sectionTitle('Subjects'),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: List<String>.from(d['subjects'] ?? [])
                          .map((s) => Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                              color: _primary.withOpacity(0.2)),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                color: _primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600)),
                      ))
                          .toList(),
                    ),
                    SizedBox(height: 20.h),
                  ],
                  _sectionTitle('Enrolled Students'),
                  SizedBox(height: 10.h),
                  _enrolledStudentsList(name),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailGrid(Map<String, dynamic> d) {
    final items = <_DetailItem>[
      _DetailItem(Icons.room_outlined, 'Room', d['room'] ?? '—'),
      _DetailItem(Icons.people_outline, 'Capacity',
          d['capacity'] != null ? '${d['capacity']} students' : '—'),
      _DetailItem(
          Icons.person_outline, 'Class Teacher', d['classTeacher'] ?? '—'),
      _DetailItem(Icons.wb_sunny_outlined, 'Shift', d['shift'] ?? '—'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 2.6,
      children: items
          .map((item) => Container(
        padding:
        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _bgElevated,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: _primary, size: 16.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.label,
                      style: TextStyle(
                          color: _textMuted, fontSize: 10.sp)),
                  Text(item.value,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ))
          .toList(),
    );
  }

  Widget _enrolledStudentsList(String className) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(schoolId)
          .collection('students')
          .where('class', isEqualTo: className)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
              child: CircularProgressIndicator(
                  color: _primary, strokeWidth: 2));
        }
        final students = snap.data!.docs;
        if (students.isEmpty) {
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _bgElevated,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline, color: _textMuted, size: 18.sp),
                SizedBox(width: 10.w),
                Text('No students enrolled yet',
                    style: TextStyle(
                        color: _textSecondary, fontSize: 12.sp)),
              ],
            ),
          );
        }
        return Column(
          children: students.take(8).map((s) {
            final sd = s.data() as Map<String, dynamic>;
            final sName = sd['name'] as String? ?? '';
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        sName.isNotEmpty ? sName[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: _primary,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(sName,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        )),
                  ),
                  Text(
                    sd['rollNumber'] ?? '',
                    style:
                    TextStyle(color: _textMuted, fontSize: 11.sp),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: TextStyle(
          color: _textPrimary,
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
        ));
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  const _DetailItem(this.icon, this.label, this.value);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models used by sidebar (defined here to avoid import issues)
// You can move these to a shared models file if preferred.
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Win11 sidebar row widgets (copied from dashboard to avoid import cycles)
// If you already export these from admin_dashboard_page.dart, remove below.
// ─────────────────────────────────────────────────────────────────────────────

class _Win11NavRow extends StatefulWidget {
  final bool isActive;
  final Color accentColor;
  final bool isExpanded;
  final Widget child;

  const _Win11NavRow({
    required this.isActive,
    required this.accentColor,
    required this.isExpanded,
    required this.child,
  });

  @override
  State<_Win11NavRow> createState() => _Win11NavRowState();
}

class _Win11NavRowState extends State<_Win11NavRow> {
  bool _hovered = false;

  static const _bg = Color(0xFF1A1A1A);
  static const _hover = Color(0xFF2C2C2C);
  static const _border = Color(0xFF3A3A3A);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? 10.w : 6.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: widget.isActive
              ? widget.accentColor.withOpacity(0.12)
              : _hovered
              ? _hover
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: widget.isActive
              ? Border.all(color: widget.accentColor.withOpacity(0.3))
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}

class _Win11HoverRow extends StatefulWidget {
  final bool isExpanded;
  final Widget child;
  const _Win11HoverRow({required this.isExpanded, required this.child});

  @override
  State<_Win11HoverRow> createState() => _Win11HoverRowState();
}

class _Win11HoverRowState extends State<_Win11HoverRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isExpanded ? 10.w : 6.w,
          vertical: 8.h,
        ),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFF2C2C2C) : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: widget.child,
      ),
    );
  }
}