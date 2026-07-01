// Firestore Path:
// schools/{schoolId}/subjects/{subjectId}
//
// Document fields:
// name     String  e.g. "Mathematics"
// code     String  e.g. "SUB-001" (auto-generated)
// category String  e.g. "Science", "Arts", "Languages"
// createdAt Timestamp
// updatedAt Timestamp
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

// ─── COLOUR PALETTE (mirrors ClassesModule exactly) ─────────────────────────
const Color _bgDark = Color(0xFF0F1117);
const Color _bgCard = Color(0xFF161922);
const Color _bgElevated = Color(0xFF1E212E);
const Color _border = Color(0xFF2A2E3B);
const Color _borderLight = Color(0xFF353A4A);
const Color _primary = Color(0xFF7C8CF0);
const Color _primaryLight = Color(0xFF9AA5F3);
const Color _accentGreen = Color(0xFF3DD68B);
const Color _accentAmber = Color(0xFFF2A93B);
const Color _accentRed = Color(0xFFF2657A);
const Color _accentBlue = Color(0xFF4DBEF7);
const Color _accentViolet = Color(0xFFB084F5);
const Color _textPrimary = Color(0xFFEEF1F8);
const Color _textSecondary = Color(0xFF8B92A8);
const Color _textMuted = Color(0xFF5A6072);

// ─── CATEGORY COLOUR MAP ────────────────────────────────────────────────────
Color _categoryColor(String category) {
  final c = category.toLowerCase();
  if (c.contains('science'))               return const Color(0xFF3DD68B);
  if (c.contains('math'))                  return const Color(0xFF4DBEF7);
  if (c.contains('art') || c.contains('music')) return const Color(0xFFB084F5);
  if (c.contains('lang') || c.contains('english') || c.contains('urdu'))
    return const Color(0xFFF2A93B);
  if (c.contains('comp') || c.contains('tech') || c.contains('ict'))
    return const Color(0xFF7C8CF0);
  if (c.contains('islam') || c.contains('relig') || c.contains('quran'))
    return const Color(0xFFF2657A);
  if (c.contains('social') || c.contains('history') || c.contains('geo'))
    return const Color(0xFF4DBEF7);
  return const Color(0xFF7C8CF0);
}
IconData _iconForCategory(String category, String name) {
  final c = (category + name).toLowerCase();
  if (c.contains('math'))                  return Icons.calculate_rounded;
  if (c.contains('physic'))                return Icons.bolt_rounded;
  if (c.contains('chem'))                  return Icons.science_rounded;
  if (c.contains('bio'))                   return Icons.eco_rounded;
  if (c.contains('science'))               return Icons.biotech_rounded;
  if (c.contains('english'))               return Icons.auto_stories_rounded;
  if (c.contains('urdu'))                  return Icons.translate_rounded;
  if (c.contains('lang'))                  return Icons.record_voice_over_rounded;
  if (c.contains('comp') || c.contains('ict') || c.contains('tech'))
    return Icons.computer_rounded;
  if (c.contains('islam') || c.contains('quran') || c.contains('relig'))
    return Icons.mosque_rounded;
  if (c.contains('art') || c.contains('draw'))
    return Icons.palette_rounded;
  if (c.contains('music'))                 return Icons.music_note_rounded;
  if (c.contains('sport') || c.contains('pt') || c.contains('physical'))
    return Icons.sports_soccer_rounded;
  if (c.contains('social') || c.contains('study'))
    return Icons.public_rounded;
  if (c.contains('history'))               return Icons.history_edu_rounded;
  if (c.contains('geo'))                   return Icons.map_rounded;
  if (c.contains('account') || c.contains('commerce'))
    return Icons.account_balance_rounded;
  return Icons.menu_book_rounded;
}
// ─── PREDEFINED CATEGORIES ────────────────────────────────────────────────────
const List<String> _categories = [
  'All', 'Science', 'Mathematics', 'Languages',
  'Computer', 'Arts', 'Islamiat', 'Social Studies', 'Other',
];





// ─────────────────────────────────────────────────────────────────────────────
// SubjectsModule — top-level widget
// ─────────────────────────────────────────────────────────────────────────────
class SubjectsModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final void Function(String msg, {bool isError}) showSnackBar;

  const SubjectsModule({
    super.key,
    required this.schoolId,
    required this.schoolName,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.showSnackBar,
  });

  @override
  State<SubjectsModule> createState() => _SubjectsModuleState();
}

class _SubjectsModuleState extends State<SubjectsModule>
    with SingleTickerProviderStateMixin {

  // ── View state ──────────────────────────────────────────────────────────────
  String _viewMode = 'grid';
  String _searchQuery = '';
  String? _filterCategory;
  String _sortBy = 'name'; // 'name' | 'code' | 'createdAt'

  // ── Tab controller for category tabs ────────────────────────────────────────
  late TabController _tabController;

  // ── Category list with "All" at index 0 ─────────────────────────────────────
  late final List<String> _categoryTabs;

  @override
  void initState() {
    super.initState();
    _categoryTabs = _categories;
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _filterCategory = _categoryTabs[_tabController.index] == 'All'
              ? null
              : _categoryTabs[_tabController.index];
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
  Stream<QuerySnapshot> get _subjectStream => FirebaseFirestore.instance
      .collection('schools')
      .doc(widget.schoolId)
      .collection('subjects')
      .orderBy('createdAt', descending: false)
      .snapshots();

  // ── Filter + sort logic ─────────────────────────────────────────────────────
  List<QueryDocumentSnapshot> _applyFilters(List<QueryDocumentSnapshot> docs) {
    var list = docs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final name = (d['name'] ?? '').toString().toLowerCase();
      final code = (d['code'] ?? '').toString().toLowerCase();
      final category = (d['category'] ?? 'Other').toString();

      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          name.contains(q) ||
          code.contains(q);

      final matchCategory = _filterCategory == null ||
          category == _filterCategory ||
          (_filterCategory == 'Other' && !_categories.sublist(1).contains(category));

      return matchSearch && matchCategory;
    }).toList();

    list.sort((a, b) {
      final da = a.data() as Map<String, dynamic>;
      final db = b.data() as Map<String, dynamic>;
      switch (_sortBy) {
        case 'code':
          return (da['code'] ?? '').toString().compareTo((db['code'] ?? '').toString());
        case 'createdAt':
          final ta = da['createdAt'] as Timestamp?;
          final tb = db['createdAt'] as Timestamp?;
          if (ta == null || tb == null) return 0;
          return tb.compareTo(ta); // newest first
        default: // 'name'
          return (da['name'] ?? '').toString().compareTo((db['name'] ?? '').toString());
      }
    });
    return list;
  }

  // ── Auto-generate subject code ──────────────────────────────────────────────
  Future<String> _generateSubjectCode() async {
    final subjectsRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects');

    final snapshot = await subjectsRef.get();
    final count = snapshot.docs.length + 1;
    final code = 'SUB-${count.toString().padLeft(3, '0')}';

    final existing = await subjectsRef.where('code', isEqualTo: code).get();
    if (existing.docs.isNotEmpty) {
      return 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    }
    return code;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 20.h),
        _buildCategoryTabs(),
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
                    flex: 2,
                    child: _primaryButton('+ Add Subject', _openAddSubjectDialog),
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
                StreamBuilder(
                  stream: _subjectStream,
                  builder: (context, snap) {
                    final total = snap.data?.docs.length ?? 0;
                    return Row(children: [
                      _headerStatPill(Icons.menu_book_outlined, '$total',
                          'Subjects', _primary),
                      SizedBox(width: 8.w),
                    ]);
                  },
                ),
                SizedBox(width: 12.w),
                _viewToggle(),
                SizedBox(width: 10.w),
                _sortButton(),
                SizedBox(width: 10.w),
                _primaryButton('+ Add Subject', _openAddSubjectDialog),
              ],
            ),
          ],
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
      child: Icon(Icons.menu_book_rounded,
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
            colors: [_textPrimary, _primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            'Subject Management',
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
          'Create, organise and manage school subjects',
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
          Text(label, style: TextStyle(color: _textMuted, fontSize: 10.sp)),
        ]),
      ]),
    );
  }

  // ── Category tabs ───────────────────────────────────────────────────────────
  Widget _buildCategoryTabs() {
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
        tabs: _categoryTabs
            .map((c) => Tab(
          height: 36.h,
          text: c,
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
              hintText: 'Search subject name, code…',
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
      if (!widget.isMobile) ...[
        SizedBox(width: 10.w),
        _viewToggle(),
      ],
    ]);
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
    return PopupMenuButton(
      color: _bgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        side: BorderSide(color: _border),
      ),
      onSelected: (v) => setState(() => _sortBy = v),
      itemBuilder: (_) => [
        _sortItem('name', 'Name (A–Z)'),
        _sortItem('code', 'Subject Code'),
        _sortItem('createdAt', 'Newest First'),
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

  PopupMenuItem _sortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Text(label,
          style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return StreamBuilder(
      stream: _subjectStream,
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
            icon: Icons.menu_book_outlined,
            title: 'No subjects yet',
            subtitle: 'Tap "+ Add Subject" to create your first subject.',
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
        childAspectRatio: widget.isMobile ? 1.4 : (widget.isTablet ? 1.35 : 1.55),

      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _SubjectCard(
        doc: docs[i],
        schoolId: widget.schoolId,
        onEdit: () => _openEditSubjectDialog(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
      ),
    );
  }

  // ── List view ───────────────────────────────────────────────────────────────
  Widget _buildListView(List<QueryDocumentSnapshot> docs) {
    return ListView.separated(
      padding: EdgeInsets.only(bottom: 24.h),
      itemCount: docs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) => _SubjectListTile(
        doc: docs[i],
        schoolId: widget.schoolId,
        onEdit: () => _openEditSubjectDialog(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
      ),
    );
  }

  // ── Add / Edit dialog ──────────────────────────────────────────────────────
  void _openAddSubjectDialog() => _openSubjectDialog(null);
  void _openEditSubjectDialog(QueryDocumentSnapshot doc) =>
      _openSubjectDialog(doc);

  void _openSubjectDialog(QueryDocumentSnapshot? existing) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _SubjectFormDialog(
        schoolId: widget.schoolId,
        existing: existing,
        showSnackBar: widget.showSnackBar,
      ),
    );
  }

  // ── Delete confirmation ─────────────────────────────────────────────────────
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
            Text('Delete Subject?',
                style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete subject "${d['name']}" (${d['code']})? '
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
              widget.showSnackBar('Subject deleted successfully');
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
          _primaryButton('+ Add First Subject', _openAddSubjectDialog),
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
          Text('Failed to load subjects',
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
        childAspectRatio: 1.25,
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
// _SubjectCard — grid card for a single subject
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d        = widget.doc.data() as Map<String, dynamic>;
    final name     = d['name'] as String? ?? '';
    final code     = d['code'] as String? ?? '';
    final category = d['category'] as String? ?? 'Other';
    final color    = _categoryColor(category);
    final icon     = _iconForCategory(category, name);
    final createdAt = d['createdAt'] as Timestamp?;
    final dateStr  = createdAt != null
        ? '${createdAt.toDate().day.toString().padLeft(2, '0')}/'
        '${createdAt.toDate().month.toString().padLeft(2, '0')}/'
        '${createdAt.toDate().year}'
        : '—';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
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
              ? [BoxShadow(color: color.withOpacity(0.22),
              blurRadius: 24, offset: const Offset(0, 8))]
              : [BoxShadow(color: Colors.black.withOpacity(0.18),
              blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(children: [
            // ── Top accent bar ──────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 3.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.35)]),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon + action buttons ───────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject icon badge
                      Container(
                        width: 50.w, height: 50.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.06),
                          ], begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(13.r),
                          border: Border.all(
                              color: color.withOpacity(0.3), width: 1.5),
                        ),
                        child: Center(
                          child: Icon(icon, color: color, size: 22.sp),
                        ),
                      ),
                      const Spacer(),
                      // Edit + delete
                      _iconBtn(Icons.edit_outlined, _primary, widget.onEdit),
                      SizedBox(width: 6.w),
                      _iconBtn(Icons.delete_outline, _accentRed, widget.onDelete),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // ── Name ────────────────────────────────────────
                  Text(
                    name,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),

                  // ── Category chip ────────────────────────────────
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, color: color, size: 10.sp),
                      SizedBox(width: 4.w),
                      Text(category,
                          style: TextStyle(
                              color: color, fontSize: 10.sp,
                              fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  SizedBox(height: 12.h),
                  Divider(color: _border, height: 1),
                  SizedBox(height: 10.h),

                  // ── Footer: code + date ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Code badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _accentGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                              color: _accentGreen.withOpacity(0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.qr_code_2_rounded,
                              color: _accentGreen, size: 11.sp),
                          SizedBox(width: 4.w),
                          Text(code,
                              style: TextStyle(
                                  color: _accentGreen,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ]),
                      ),
                      // Date added
                      Text(
                        'Added $dateStr',
                        style: TextStyle(
                            color: _textMuted, fontSize: 10.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStudentUsageRow(String subjectName) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('students')
          .snapshots(),
      builder: (context, snap) {
        // Count students who have this subject in their subjects list
        int count = 0;
        if (snap.hasData) {
          for (var doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final subjects = List.from(data['subjects'] ?? []);
            if (subjects.contains(subjectName)) count++;
          }
        }

        return Row(children: [
          Icon(Icons.people_outline, color: _textMuted, size: 13.sp),
          SizedBox(width: 5.w),
          Text(
            '$count students enrolled',
            style: TextStyle(color: _textSecondary, fontSize: 11.sp),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: count > 0 ? _accentGreen.withOpacity(0.1) : _bgElevated,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                  color: count > 0 ? _accentGreen.withOpacity(0.2) : _border),
            ),
            child: Text(
              count > 0 ? 'Active' : 'Unused',
              style: TextStyle(
                color: count > 0 ? _accentGreen : _textMuted,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ]);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// _SubjectListTile — compact list row for list view
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectListTile extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final String schoolId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectListTile({
    required this.doc,
    required this.schoolId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SubjectListTile> createState() => _SubjectListTileState();
}

class _SubjectListTileState extends State<_SubjectListTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    final name = d['name'] as String? ?? '';
    final code = d['code'] as String? ?? '';
    final category = d['category'] as String? ?? 'Other';
    final color = _categoryColor(category);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                  style: TextStyle(
                    color: color,
                    fontSize: 18.sp,
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
                      Text(name,
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 8.w),
                      _tinyChip(code, _textMuted),
                      SizedBox(width: 4.w),
                      _tinyChip(category, color),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Auto-generated code: $code',
                    style: TextStyle(color: _textSecondary, fontSize: 11.sp),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                _iconBtn2(Icons.edit_outlined, _primary, widget.onEdit),
                SizedBox(width: 6.w),
                _iconBtn2(
                    Icons.delete_outline, _accentRed, widget.onDelete),
              ],
            ),
          ],
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
// _SubjectFormDialog — Add / Edit subject
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectFormDialog extends StatefulWidget {
  final String schoolId;
  final QueryDocumentSnapshot? existing;
  final void Function(String, {bool isError}) showSnackBar;


  const _SubjectFormDialog({
    required this.schoolId,
    required this.existing,
    required this.showSnackBar,
  });

  @override
  State<_SubjectFormDialog> createState() => _SubjectFormDialogState();
}

class _SubjectFormDialogState extends State<_SubjectFormDialog> {
  final _formKey = GlobalKey<FormState>();




  final _nameCtrl = TextEditingController();
  String _category = 'Science';
  String _autoCode = '';
  bool _isSaving = false;
  final _descCtrl = TextEditingController(); // ← ADD THIS

  final List<String> _categoryOptions = [
    'Science', 'Mathematics', 'Languages', 'Computer',
    'Arts', 'Islamiat', 'Social Studies', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final d = widget.existing!.data() as Map<String, dynamic>;
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _category = d['category'] ?? 'Science';
      _autoCode = d['code'] ?? '';
    } else {
      _generateCode();
    }
  }

  Future<void> _generateCode() async {
    final subjectsRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects');

    // Extract letters only from category name (or subject name if category empty)
    final src = (_category.isNotEmpty && _category != 'Other')
        ? _category.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '')
        : (_nameCtrl.text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), ''));

    // Base = first 3 letters of category (e.g. SCI, MAT, ENG, COM, ISL)
    final base = src.length >= 3 ? src.substring(0, 3) : src.padRight(3, 'X');

    // Find all existing codes starting with same base
    final snapshot = await subjectsRef
        .where('code', isGreaterThanOrEqualTo: base)
        .where('code', isLessThan: '${base}z')
        .get();

    int maxSeq = 0;
    for (final doc in snapshot.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final code = (d['code'] ?? '').toString();
      if (code.startsWith(base)) {
        final seqStr = code.substring(base.length);
        final seq = int.tryParse(seqStr) ?? 0;
        if (seq > maxSeq) maxSeq = seq;
      }
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(2, '0');
    if (mounted) setState(() => _autoCode = '$base$nextSeq');
    // Examples: SCI01, SCI02, MAT01, ENG01, COM01, ISL01, ART01
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameCtrl.text.trim();

      // Check duplicate name
      final dupCheck = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .where('name', isEqualTo: name)
          .get();

      final isDuplicate = dupCheck.docs.any((doc) =>
      widget.existing == null || doc.id != widget.existing!.id);

      if (isDuplicate) {
        setState(() => _isSaving = false);
        widget.showSnackBar(
            'A subject named "$name" already exists.', isError: true);
        return;
      }

      final data = {
        'name':        name,
        'category':    _category,
        'description': _descCtrl.text.trim(),
        'updatedAt':   FieldValue.serverTimestamp(),
      };

      if (widget.existing == null) {
        data['code'] = _autoCode;
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('subjects')
            .add(data);
        widget.showSnackBar('Subject "$name" created with code $_autoCode!');
      } else {
        await widget.existing!.reference.update(data);
        widget.showSnackBar('Subject updated successfully!');
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      widget.showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        width: 480.w,
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
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
            _buildDialogHeader(isEdit),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Subject Details'),
                      SizedBox(height: 12.h),
                      _nameField(),
                      SizedBox(height: 16.h),
                      _categorySelector(),
                      SizedBox(height: 20.h),
                      SizedBox(height: 16.h),
                      _labeledField(
                        'Description (optional)',
                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          style: TextStyle(
                              color: _textPrimary, fontSize: 13.sp),
                          decoration: _inputDecoration(
                            'e.g. Covers algebra, geometry for Class 9–10',
                          ),
                        ),
                      ),
                      if (!isEdit) ...[
                        _sectionLabel('Auto-Generated Code'),
                        SizedBox(height: 12.h),
                        _codeDisplay(),
                        SizedBox(height: 4.h),
                        Text(
                          'Subject code is automatically generated and cannot be changed',
                          style: TextStyle(
                              color: _textMuted,
                              fontSize: 10.sp,
                              fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 20.h),
                      ],

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
            child: Icon(Icons.menu_book_outlined,
                color: Colors.white, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Subject' : 'Add New Subject',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isEdit ? 'Update subject details' : 'Fill in the details below',
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

  Widget _nameField() {
    return _labeledField(
      'Subject Name *',
      TextFormField(
        controller: _nameCtrl,
        style: TextStyle(color: _textPrimary, fontSize: 13.sp),
        textCapitalization: TextCapitalization.words,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Required';
          return null;
        },
        decoration: _inputDecoration('e.g. Mathematics, Physics, English'),
      ),
    );
  }

  Widget _categorySelector() {
    return _labeledField(
      'Category *',
      Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _categoryOptions.map((cat) {
          final isSelected = _category == cat;
          final color = _categoryColor(cat);
          return GestureDetector(
            onTap: () {
              setState(() => _category = cat);
              // Regenerate code when category changes (for new subjects)
              if (widget.existing == null) _generateCode();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : _bgElevated,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected ? color : _border,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                    color: color.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  _iconForCategory(cat, ''),
                  color: isSelected ? color : _textMuted,
                  size: 14.sp,
                ),
                SizedBox(width: 5.w),
                Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? color : _textSecondary,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _codeDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: _bgElevated,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_rounded, color: _accentGreen, size: 18.sp),
          SizedBox(width: 12.w),
          Text(
            _autoCode.isEmpty ? 'Generating...' : _autoCode,
            style: TextStyle(
              color: _accentGreen,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: _accentGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: _accentGreen.withOpacity(0.2)),
            ),
            child: Text(
              "AUTO",
              style: TextStyle(
                color: _accentGreen,
                fontSize: 9.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
                  isEdit ? 'Update Subject' : 'Create Subject',
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