import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';

class SubjectsModule extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final void Function(String message, {bool isError}) showSnackBar;

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

class _SubjectsModuleState extends State<SubjectsModule> {
  // ─── COLORS (matching your dashboard) ─────────────────────
  static const Color _bgDark = Color(0xFF0F1117);
  static const Color _bgCard = Color(0xFF161922);
  static const Color _bgElevated = Color(0xFF1E212E);
  static const Color _border = Color(0xFF2A2E3B);
  static const Color _borderLight = Color(0xFF353A4A);
  static const Color _textPrimary = Color(0xFFEEF1F8);
  static const Color _textSecondary = Color(0xFF8B92A8);
  static const Color _textMuted = Color(0xFF5A6072);
  static const Color _primary = Color(0xFF7C8CF0);
  static const Color _primaryLight = Color(0xFF9AA5F3);
  static const Color _accentSuccess = Color(0xFF3DD68B);
  static const Color _accentDanger = Color(0xFFF2657A);
  static const Color _accentWarning = Color(0xFFF2A93B);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── AUTO-GENERATE SUBJECT CODE ───────────────────────────
  /// Generates a unique subject code like: SUB-001, SUB-002, etc.
  Future<String> _generateSubjectCode() async {
    final subjectsRef = FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.schoolId)
        .collection('subjects');

    // Get total count to determine next number
    final snapshot = await subjectsRef.get();
    final count = snapshot.docs.length + 1;
    final code = 'SUB-${count.toString().padLeft(3, '0')}';

    // Double-check uniqueness (edge case: deletions)
    final existing = await subjectsRef.where('code', isEqualTo: code).get();
    if (existing.docs.isNotEmpty) {
      // Fallback: use timestamp
      return 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    }
    return code;
  }

  // ─── ADD SUBJECT ──────────────────────────────────────────
  Future<void> _addSubject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      widget.showSnackBar("Please enter a subject name", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = await _generateSubjectCode();

      await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .add({
        'name': name,
        'code': code,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _codeController.clear();
      widget.showSnackBar("Subject '$name' added with code $code");
      Navigator.pop(context); // Close dialog
    } catch (e) {
      widget.showSnackBar("Error: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── DELETE SUBJECT ─────────────────────────────────────
  Future<void> _deleteSubject(String docId, String subjectName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: _border),
        ),
        title: Text(
          "Delete Subject?",
          style: TextStyle(color: _textPrimary, fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          "Are you sure you want to delete '$subjectName'? This action cannot be undone.",
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: TextStyle(color: _textSecondary, fontSize: 14.sp)),
          ),
          Container(
            decoration: BoxDecoration(
              color: _accentDanger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: _accentDanger.withOpacity(0.3)),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text("Delete", style: TextStyle(color: _accentDanger, fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('schools')
            .doc(widget.schoolId)
            .collection('subjects')
            .doc(docId)
            .delete();
        widget.showSnackBar("Subject deleted successfully");
      } catch (e) {
        widget.showSnackBar("Error deleting subject: $e", isError: true);
      }
    }
  }

  // ─── SHOW ADD SUBJECT DIALOG ──────────────────────────────
  void _showAddSubjectDialog() {
    // Pre-generate code for display
    _generateSubjectCode().then((code) {
      _codeController.text = code;
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => _buildSubjectDialog(ctx, code),
        );
      }
    });
  }

  Widget _buildSubjectDialog(BuildContext ctx, String preGeneratedCode) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: _bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
            side: BorderSide(color: _border),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.menu_book_rounded, color: _primary, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                "Add New Subject",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Container(
            width: 400.w,
            constraints: BoxConstraints(maxWidth: 450.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Name
                Text(
                  "Subject Name",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: _textPrimary, fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: "e.g. Mathematics, Physics, English",
                    hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
                    filled: true,
                    fillColor: _bgElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _primary, width: 1.5),
                    ),
                    prefixIcon: Icon(Icons.book_outlined, color: _textMuted, size: 18.sp),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _addSubject(),
                ),
                SizedBox(height: 20.h),

                // Auto-generated Code Display
                Text(
                  "Subject Code (Auto-Generated)",
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: _bgElevated,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_rounded, color: _accentSuccess, size: 18.sp),
                      SizedBox(width: 12.w),
                      Text(
                        preGeneratedCode,
                        style: TextStyle(
                          color: _accentSuccess,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _accentSuccess.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: _accentSuccess.withOpacity(0.2)),
                        ),
                        child: Text(
                          "AUTO",
                          style: TextStyle(
                            color: _accentSuccess,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _nameController.clear();
                Navigator.pop(ctx);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: _textSecondary, fontSize: 14.sp),
              ),
            ),
            GestureDetector(
              onTap: _isLoading ? null : _addSubject,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primary, _primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  "Add Subject",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ─────────────────────────────────────────
          _buildHeader(),
          SizedBox(height: 20.h),

          // ─── SEARCH + STATS ───────────────────────────────
          _buildSearchAndStats(),
          SizedBox(height: 20.h),

          // ─── SUBJECTS LIST ────────────────────────────────
          Expanded(child: _buildSubjectsList()),
        ],
      ),
    );
  }

  // ─── HEADER ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subjects Management",
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.schoolName,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!widget.isMobile) ...[
          _buildHeaderAction(
            icon: Icons.download_outlined,
            label: "Export",
            color: _accentSuccess,
            onTap: () => widget.showSnackBar("Export feature coming soon"),
          ),
          SizedBox(width: 10.w),
        ],
        _buildAddButton(),
      ],
    );
  }

  Widget _buildHeaderAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16.sp),
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
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _showAddSubjectDialog,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryLight],
          ),
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              "Add Subject",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH + STATS ─────────────────────────────────────
  Widget _buildSearchAndStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .snapshots(),
      builder: (context, snapshot) {
        final totalSubjects = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Row(
          children: [
            // Search
            Expanded(
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: _bgCard,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 14.w),
                    Icon(Icons.search_rounded, color: _textMuted, size: 18.sp),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: _textPrimary, fontSize: 14.sp),
                        decoration: InputDecoration(
                          hintText: "Search subjects...",
                          hintStyle: TextStyle(color: _textMuted, fontSize: 13.sp),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 12.w),
                          child: Icon(Icons.close_rounded, color: _textMuted, size: 16.sp),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (!widget.isMobile) ...[
              SizedBox(width: 16.w),
              _buildStatCard("Total Subjects", totalSubjects.toString(), _primary),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.menu_book_rounded, color: color, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SUBJECTS LIST ──────────────────────────────────────
  Widget _buildSubjectsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId)
          .collection('subjects')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _buildShimmerList();
        }

        var docs = snapshot.data!.docs;

        // Filter by search
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final code = (data['code'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || code.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 20.h),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildSubjectCard(doc.id, data, index);
          },
        );
      },
    );
  }

  Widget _buildSubjectCard(String docId, Map<String, dynamic> data, int index) {
    final name = data['name'] ?? 'Unnamed Subject';
    final code = data['code'] ?? 'N/A';
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? "${createdAt.toDate().day.toString().padLeft(2, '0')}/${createdAt.toDate().month.toString().padLeft(2, '0')}/${createdAt.toDate().year}"
        : 'Unknown';

    // Color cycling for visual variety
    final colors = [
      _primary,
      _accentSuccess,
      const Color(0xFF4DBEF7),
      _accentWarning,
      const Color(0xFFB084F5),
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon / Avatar
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _bgElevated,
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        code,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Icon(Icons.access_time_rounded, color: _textMuted, size: 12.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Added on $dateStr",
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (!widget.isMobile)
            Row(
              children: [
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  color: _primary,
                  onTap: () => _showEditDialog(docId, data),
                ),
                SizedBox(width: 8.w),
                _buildActionButton(
                  icon: Icons.delete_outline,
                  color: _accentDanger,
                  onTap: () => _deleteSubject(docId, name),
                ),
              ],
            )
          else
            PopupMenuButton<String>(
              color: _bgElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
                side: BorderSide(color: _border),
              ),
              icon: Icon(Icons.more_vert_rounded, color: _textMuted, size: 18.sp),
              onSelected: (value) {
                if (value == 'edit') _showEditDialog(docId, data);
                if (value == 'delete') _deleteSubject(docId, name);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, color: _primary, size: 18.sp),
                      SizedBox(width: 10.w),
                      Text("Edit", style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: _accentDanger, size: 18.sp),
                      SizedBox(width: 10.w),
                      Text("Delete", style: TextStyle(color: _accentDanger, fontSize: 13.sp)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Icon(icon, color: color, size: 16.sp),
      ),
    );
  }

  // ─── EDIT SUBJECT ───────────────────────────────────────
  void _showEditDialog(String docId, Map<String, dynamic> data) {
    final editNameController = TextEditingController(text: data['name'] ?? '');
    final editCodeController = TextEditingController(text: data['code'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: _border),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.edit_rounded, color: _primary, size: 22.sp),
            ),
            SizedBox(width: 12.w),
            Text(
              "Edit Subject",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Container(
          width: 400.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Subject Name",
                style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: editNameController,
                style: TextStyle(color: _textPrimary, fontSize: 14.sp),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _bgElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _primary, width: 1.5),
                  ),
                  prefixIcon: Icon(Icons.book_outlined, color: _textMuted, size: 18.sp),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Subject Code",
                style: TextStyle(color: _textSecondary, fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: editCodeController,
                enabled: false, // Code is auto-generated, not editable
                style: TextStyle(color: _textMuted, fontSize: 14.sp),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _bgDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _border),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: _border),
                  ),
                  prefixIcon: Icon(Icons.qr_code_rounded, color: _textMuted, size: 18.sp),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                "Subject code cannot be changed",
                style: TextStyle(color: _textMuted, fontSize: 10.sp, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: _textSecondary, fontSize: 14.sp)),
          ),
          GestureDetector(
            onTap: () async {
              final newName = editNameController.text.trim();
              if (newName.isEmpty) {
                widget.showSnackBar("Subject name cannot be empty", isError: true);
                return;
              }
              try {
                await FirebaseFirestore.instance
                    .collection('schools')
                    .doc(widget.schoolId)
                    .collection('subjects')
                    .doc(docId)
                    .update({
                  'name': newName,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                widget.showSnackBar("Subject updated successfully");
                Navigator.pop(ctx);
              } catch (e) {
                widget.showSnackBar("Error: $e", isError: true);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_primary, _primaryLight]),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                "Save Changes",
                style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      ),
    );
  }

  // ─── EMPTY STATE ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: _primary,
                size: 48.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "No Subjects Yet",
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Add your first subject to get started",
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            _buildAddButton(),
          ],
        ),
      ),
    );
  }

  // ─── SHIMMER LOADING ────────────────────────────────────
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: _bgCard,
        highlightColor: _bgElevated,
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: _bgCard,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 150.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
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
}