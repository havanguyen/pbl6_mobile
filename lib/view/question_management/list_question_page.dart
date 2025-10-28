import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/question.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/shared/widgets/widget/question_delete_confirm.dart';

class ListQuestionPage extends StatefulWidget {
  const ListQuestionPage({super.key});

  @override
  State<ListQuestionPage> createState() => _ListQuestionPageState();
}

class _ListQuestionPageState extends State<ListQuestionPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuestionVm>().fetchQuestions(forceRefresh: true);
        context.read<QuestionVm>().fetchSpecialties();
      }
    });

    _searchController.addListener(_debounceSearch);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_debounceSearch);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<QuestionVm>().loadMore();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        context.read<QuestionVm>().updateSearchQuery(_searchController.text);
      }
    });
  }

  void _showDeleteDialog(Question question) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final questionVm = Provider.of<QuestionVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: questionVm,
        child: QuestionDeleteConfirmationDialog(
          question: question.toJson(),
          onDeleteSuccess: () {},
          snackbarService: snackbarService,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final questionVm = context.read<QuestionVm>();
    if (questionVm.specialties.isEmpty &&
        !questionVm.isLoadingSpecialties &&
        questionVm.specialtyError == null) {
      questionVm.fetchSpecialties(forceRefresh: true);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: _buildFilterSection(),
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                hintText: 'Tìm theo tiêu đề, nội dung...',
                hintStyle: TextStyle(
                    color: context.theme.mutedForeground.withOpacity(0.7)),
                prefixIcon:
                Icon(Icons.search, color: context.theme.primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.border.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                  BorderSide(color: context.theme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: context.theme.input,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: context.theme.mutedForeground, size: 20),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: context.theme.input,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showFilterSheet,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.theme.border.withOpacity(0.5))),
                child: Icon(Icons.filter_list_rounded,
                    color: context.theme.primary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<QuestionVm>(builder: (context, questionVm, child) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bộ lọc & Sắp xếp',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.theme.textColor)),
                TextButton.icon(
                  icon: Icon(Icons.refresh,
                      size: 18, color: context.theme.mutedForeground),
                  label: Text('Đặt lại',
                      style: TextStyle(color: context.theme.mutedForeground)),
                  onPressed: () {
                    questionVm.resetFilters();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                )
              ],
            ),
            const Divider(height: 30, thickness: 0.5),

            Text('Chuyên khoa',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            questionVm.isLoadingSpecialties
                ? const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
                : questionVm.specialtyError != null
                ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.theme.destructive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Text(questionVm.specialtyError!, style: TextStyle(color: context.theme.destructive)),
            )
                : DropdownButtonFormField<String>(
              value: questionVm.specialties
                  .any((c) => c.id == questionVm.selectedSpecialtyId)
                  ? questionVm.selectedSpecialtyId
                  : null,
              hint: Text('Tất cả chuyên khoa',
                  style: TextStyle(color: context.theme.mutedForeground)),
              isExpanded: true,
              style:
              TextStyle(color: context.theme.textColor, fontSize: 15),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: context.theme.primary)),
                  filled: true,
                  fillColor: context.theme.input,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: context.theme.mutedForeground,
                  )),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.theme.mutedForeground),
              dropdownColor: context.theme.popover,
              items: [
                DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả chuyên khoa',
                        style: TextStyle(
                            color: context.theme.mutedForeground))),
                ...questionVm.specialties.map((specialty) {
                  return DropdownMenuItem<String>(
                    value: specialty.id,
                    child: Text(specialty.name,
                        style: TextStyle(
                            color: context.theme.popoverForeground)),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                questionVm.updateSpecialtyFilter(value);
              },
            ),
            const SizedBox(height: 24),

            Text('Trạng thái',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: questionVm.selectedStatus,
              hint: Text('Tất cả trạng thái',
                  style: TextStyle(color: context.theme.mutedForeground)),
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor, fontSize: 15),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.theme.primary)),
                  filled: true,
                  fillColor: context.theme.input,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: Icon(
                    Icons.toggle_on_outlined,
                    size: 18,
                    color: context.theme.mutedForeground,
                  )),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.theme.mutedForeground),
              dropdownColor: context.theme.popover,
              items: [
                DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả trạng thái',
                        style:
                        TextStyle(color: context.theme.mutedForeground))),
                DropdownMenuItem<String>(
                    value: 'PENDING',
                    child: Text('⏳ Đang chờ',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
                DropdownMenuItem<String>(
                    value: 'ANSWERED',
                    child: Text('✅ Đã trả lời',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
                DropdownMenuItem<String>(
                    value: 'CLOSED',
                    child: Text('🔒 Đã đóng',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
              ],
              onChanged: (value) {
                questionVm.updateStatusFilter(value);
              },
            ),
            const SizedBox(height: 24),

            Text('Sắp xếp',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: questionVm.sortBy,
                      style: TextStyle(
                          color: context.theme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.primary)),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: context.theme.mutedForeground),
                      dropdownColor: context.theme.popover,
                      items: const [
                        DropdownMenuItem(
                            value: 'createdAt',
                            child: Text('Ngày tạo')),
                        DropdownMenuItem(
                            value: 'updatedAt',
                            child: Text('Ngày cập nhật')),
                        DropdownMenuItem(
                            value: 'title',
                            child: Text('Tiêu đề')),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return const [
                          Text('Ngày tạo'),
                          Text('Ngày cập nhật'),
                          Text('Tiêu đề'),
                        ].map<Widget>((Widget item) {
                          String value;
                          switch ((item as Text).data) {
                            case 'Ngày tạo': value = 'createdAt'; break;
                            case 'Ngày cập nhật': value = 'updatedAt'; break;
                            case 'Tiêu đề': value = 'title'; break;
                            default: value = 'createdAt';
                          }
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              item.data!,
                              style: TextStyle(color: context.theme.textColor),
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) =>
                          questionVm.updateSortFilter(sortBy: value)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: questionVm.sortOrder,
                      style: TextStyle(
                          color: context.theme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.primary)),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: context.theme.mutedForeground),
                      dropdownColor: context.theme.popover,
                      items: const [
                        DropdownMenuItem(
                            value: 'ASC',
                            child: Text('Tăng dần')),
                        DropdownMenuItem(
                            value: 'DESC',
                            child: Text('Giảm dần')),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return const [
                          Text('Tăng dần'),
                          Text('Giảm dần'),
                        ].map<Widget>((Widget item) {
                          return DropdownMenuItem<String>(
                            value: (item as Text).data == 'Tăng dần' ? 'ASC' : 'DESC',
                            child: Text(
                              item.data!,
                              style: TextStyle(color: context.theme.textColor),
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) =>
                          questionVm.updateSortFilter(sortOrder: value)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Áp dụng')),
            )
          ],
        ),
      );
    });
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: context.theme.muted.withOpacity(0.5),
      highlightColor: context.theme.input,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 8,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(radius: 24, backgroundColor: context.theme.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                          width: double.infinity,
                          height: 16.0,
                          decoration: BoxDecoration(
                              color: context.theme.muted,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 12.0,
                          decoration: BoxDecoration(
                              color: context.theme.muted,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 60,
                              height: 10.0,
                              decoration: BoxDecoration(
                                  color: context.theme.muted,
                                  borderRadius: BorderRadius.circular(4))),
                          Container(
                              width: 100,
                              height: 10.0,
                              decoration: BoxDecoration(
                                  color: context.theme.muted,
                                  borderRadius: BorderRadius.circular(4))),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedQuestionCard(
      Question question, int index, bool isOffline) {
    String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(question.createdAt.toLocal());

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (question.status) {
      case 'ANSWERED':
        statusColor = context.theme.green;
        statusText = 'Đã trả lời';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'CLOSED':
        statusColor = context.theme.mutedForeground;
        statusText = 'Đã đóng';
        statusIcon = Icons.lock_outline_rounded;
        break;
      case 'PENDING':
      default:
        statusColor = context.theme.yellow;
        statusText = 'Đang chờ';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    return Slidable(
      key: ValueKey(question.id),
      endActionPane: isOffline
          ? null
          : ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (context) => _showDeleteDialog(question),
            backgroundColor: context.theme.destructive,
            foregroundColor: context.theme.white,
            icon: Icons.delete_outline_rounded,
            label: 'Xóa',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.theme.border.withOpacity(0.5))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: isOffline
                ? null
                : () async {
              Navigator.pushNamed(context, Routes.questionDetail,
                  arguments: question.id);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.title,
                          style: TextStyle(
                              color: context.theme.cardForeground,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 14,
                                color: context.theme.mutedForeground),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                question.authorName,
                                style: TextStyle(
                                    color: context.theme.mutedForeground,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText.toUpperCase(),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  color: context.theme.mutedForeground
                                      .withOpacity(0.8),
                                  fontSize: 11),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildEmptyState() {
    final provider = context.read<QuestionVm>();
    final bool isSearchingOrFiltering = _searchController.text.isNotEmpty ||
        provider.selectedStatus != null ||
        provider.selectedSpecialtyId != null;

    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchingOrFiltering ? Icons.search_off_rounded : Icons.question_answer_outlined,
              size: 60,
              color: context.theme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchingOrFiltering
                  ? 'Không tìm thấy câu hỏi'
                  : 'Chưa có câu hỏi nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                isSearchingOrFiltering
                    ? 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.'
                    : 'Hiện tại không có câu hỏi nào trong hệ thống.',
                style:
                TextStyle(color: context.theme.mutedForeground, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            if (isSearchingOrFiltering)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tải lại danh sách'),
                  onPressed: () {
                    _searchController.clear();
                    provider.resetFilters();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    final provider = context.read<QuestionVm>();
    final bool isNetworkError = errorMessage.contains('Lỗi kết nối') || errorMessage.contains('offline');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 60,
              color: context.theme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              isNetworkError ? 'Lỗi kết nối mạng' : 'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.destructive, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (isNetworkError || !errorMessage.contains('cache'))
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
                onPressed: () => provider.fetchQuestions(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                ),
              )
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Mục Hỏi Đáp'),
        elevation: 0.5,
        backgroundColor: context.theme.card,
        titleTextStyle: TextStyle(
          color: context.theme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: context.theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.mutedForeground),
            tooltip: "Làm mới",
            onPressed: context.watch<QuestionVm>().isLoading
                ? null
                : () => context.read<QuestionVm>().fetchQuestions(forceRefresh: true),
          )
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Consumer<QuestionVm>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchSection(),

              if (provider.error != null && !provider.isLoading && provider.questions.isNotEmpty)
                _buildOfflineErrorBanner(provider.error!, provider.isOffline),
              if ((provider.isLoadingMore || (provider.isLoading && provider.questions.isNotEmpty)) && provider.error == null)
                LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: context.theme.primary.withOpacity(0.5)),

              Expanded(
                child: Builder(
                  builder: (innerContext) {
                    if (provider.isLoading && provider.questions.isEmpty && provider.error == null) {
                      return _buildShimmerList();
                    }
                    else if (provider.error != null && provider.questions.isEmpty && !provider.isLoading) {
                      return _buildErrorState(provider.error!);
                    }
                    else if (provider.questions.isEmpty && !provider.isLoading && provider.error == null) {
                      return _buildEmptyState();
                    }
                    else {
                      return RefreshIndicator(
                        color: context.theme.primary,
                        backgroundColor: context.theme.card,
                        onRefresh: () async => context
                            .read<QuestionVm>()
                            .fetchQuestions(forceRefresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, top: 8),
                          controller: _scrollController,
                          itemCount: provider.questions.length +
                              (provider.isLoadingMore && provider.hasNextPage ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.questions.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                ),
                              );
                            }
                            final question = provider.questions[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 30.0,
                                child: FadeInAnimation(
                                  delay: const Duration(milliseconds: 50),
                                  child: _buildAnimatedQuestionCard(
                                      question, index, provider.isOffline),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineErrorBanner(String message, bool isActuallyOffline) {
    final bool isOfflineError = isActuallyOffline || message.contains('Lỗi kết nối') || message.contains('offline');
    final Color bannerColor = isOfflineError ? context.theme.yellow.withOpacity(0.15) : context.theme.destructive.withOpacity(0.15);
    final Color textColor = isOfflineError ? context.theme.yellow : context.theme.destructive;
    final IconData icon = isOfflineError ? Icons.wifi_off_rounded : Icons.error_outline_rounded;

    String displayMessage = message;
    if (message.contains(':') && message.contains('Lỗi')) {
      displayMessage = message.substring(0, message.indexOf(':'));
    }
    if (message.contains('offline') && message.contains('dữ liệu cũ')) {
      displayMessage = 'Bạn đang offline. Hiển thị dữ liệu cũ.';
    } else if (message.contains('offline') && message.contains('không có dữ liệu')) {
      displayMessage = 'Bạn đang offline và không có dữ liệu cache.';
    } else if (message.contains('offline')) {
      displayMessage = 'Bạn đang offline.';
    } else if (message.contains('Lỗi kết nối')) {
      displayMessage = 'Lỗi kết nối mạng.';
    }


    return Container(
      width: double.infinity,
      color: bannerColor,
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 13),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

}