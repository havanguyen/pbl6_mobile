import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/question.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/shared/widgets/widget/question_delete_confirm.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class ListQuestionPage extends StatefulWidget {
  const ListQuestionPage({super.key});

  @override
  State<ListQuestionPage> createState() => _ListQuestionPageState();
}

class _ListQuestionPageState extends State<ListQuestionPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuestionVm>().fetchQuestions(forceRefresh: true);
        context.read<QuestionVm>().fetchSpecialties();
      }
    });

    _searchController.addListener(_debounceSearch);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUserRole() async {
    final role = await Store.getUserRole();
    if (mounted) {
      setState(() {
        _canDelete = (role == 'ADMIN' || role == 'SUPER_ADMIN');
      });
    }
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
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('question_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchSection(),
            Expanded(
              child: Consumer<QuestionVm>(
                builder: (context, questionVm, child) {
                  if (questionVm.isLoading) {
                    return _buildShimmerList();
                  }

                  if (questionVm.error != null) {
                    return Center(
                      child: Text(
                        questionVm.error!,
                        style: TextStyle(color: context.theme.destructive),
                      ),
                    );
                  }

                  if (questionVm.questions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.question_answer_outlined,
                            size: 64,
                            color: context.theme.mutedForeground,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('no_questions_found'),
                            style: TextStyle(
                              color: context.theme.mutedForeground,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await questionVm.fetchQuestions(forceRefresh: true);
                      await questionVm.fetchSpecialties();
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount:
                          questionVm.questions.length +
                          (questionVm.hasNextPage ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == questionVm.questions.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.theme.primary,
                              ),
                            ),
                          );
                        }
                        final question = questionVm.questions[index];
                        return _buildAnimatedQuestionCard(
                          question,
                          index,
                          false,
                        );
                      },
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
                hintText: AppLocalizations.of(
                  context,
                ).translate('search_question_hint'),
                hintStyle: TextStyle(
                  color: context.theme.mutedForeground.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.theme.primary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.border.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: context.theme.input,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.theme.mutedForeground,
                          size: 20,
                        ),
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
                  border: Border.all(
                    color: context.theme.border.withOpacity(0.5),
                  ),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: context.theme.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<QuestionVm>(
      builder: (context, questionVm, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('filter_sort_title'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: context.theme.mutedForeground,
                    ),
                    label: Text(
                      AppLocalizations.of(context).translate('reset'),
                      style: TextStyle(color: context.theme.mutedForeground),
                    ),
                    onPressed: () {
                      questionVm.resetFilters();
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 0.5),

              Text(
                AppLocalizations.of(context).translate('specialty_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              questionVm.isLoadingSpecialties
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : questionVm.specialtyError != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.theme.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        questionVm.specialtyError!,
                        style: TextStyle(color: context.theme.destructive),
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value:
                          questionVm.specialties.any(
                            (c) => c.id == questionVm.selectedSpecialtyId,
                          )
                          ? questionVm.selectedSpecialtyId
                          : null,
                      hint: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('all_specialties'),
                        style: TextStyle(color: context.theme.mutedForeground),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        color: context.theme.textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.primary),
                        ),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.medical_services_outlined,
                          size: 18,
                          color: context.theme.mutedForeground,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.theme.mutedForeground,
                      ),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('all_specialties'),
                            style: TextStyle(
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ),
                        ...questionVm.specialties.map((specialty) {
                          return DropdownMenuItem<String>(
                            value: specialty.id,
                            child: Text(
                              specialty.name,
                              style: TextStyle(
                                color: context.theme.popoverForeground,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        questionVm.updateSpecialtyFilter(value);
                      },
                    ),
              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context).translate('status'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: questionVm.selectedStatus,
                hint: Text(
                  AppLocalizations.of(context).translate('all_statuses'),
                  style: TextStyle(color: context.theme.mutedForeground),
                ),
                isExpanded: true,
                style: TextStyle(color: context.theme.textColor, fontSize: 15),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.theme.primary),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.toggle_on_outlined,
                    size: 18,
                    color: context.theme.mutedForeground,
                  ),
                ),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.theme.mutedForeground,
                ),
                dropdownColor: context.theme.popover,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      AppLocalizations.of(context).translate('all_statuses'),
                      style: TextStyle(color: context.theme.mutedForeground),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'PENDING',
                    child: Text(
                      '⏳ ${AppLocalizations.of(context).translate('status_pending')}',
                      style: TextStyle(color: context.theme.popoverForeground),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'ANSWERED',
                    child: Text(
                      '✅ ${AppLocalizations.of(context).translate('status_answered')}',
                      style: TextStyle(color: context.theme.popoverForeground),
                    ),
                  ),
                  DropdownMenuItem<String>(
                    value: 'CLOSED',
                    child: Text(
                      '🔒 ${AppLocalizations.of(context).translate('status_closed')}',
                      style: TextStyle(color: context.theme.popoverForeground),
                    ),
                  ),
                ],
                onChanged: (value) {
                  questionVm.updateStatusFilter(value);
                },
              ),
              const SizedBox(height: 24),

              Text(
                AppLocalizations.of(context).translate('sort'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: questionVm.sortBy,
                      style: TextStyle(
                        color: context.theme.textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.primary),
                        ),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.theme.mutedForeground,
                      ),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem(
                          value: 'createdAt',
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_created_at'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'updatedAt',
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_updated_at'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'title',
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_title'),
                          ),
                        ),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_created_at'),
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_updated_at'),
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('sort_title'),
                          ),
                        ].map<Widget>((Widget item) {
                          String value;
                          if ((item as Text).data ==
                              AppLocalizations.of(
                                context,
                              ).translate('sort_created_at')) {
                            value = 'createdAt';
                          } else if (item.data ==
                              AppLocalizations.of(
                                context,
                              ).translate('sort_updated_at')) {
                            value = 'updatedAt';
                          } else if (item.data ==
                              AppLocalizations.of(
                                context,
                              ).translate('sort_title')) {
                            value = 'title';
                          } else {
                            value = 'createdAt';
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
                          questionVm.updateSortFilter(sortBy: value),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: questionVm.sortOrder,
                      style: TextStyle(
                        color: context.theme.textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.primary),
                        ),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.theme.mutedForeground,
                      ),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem(
                          value: 'ASC',
                          child: Text(
                            AppLocalizations.of(context).translate('sort_asc'),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'DESC',
                          child: Text(
                            AppLocalizations.of(context).translate('sort_desc'),
                          ),
                        ),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          Text(
                            AppLocalizations.of(context).translate('sort_asc'),
                          ),
                          Text(
                            AppLocalizations.of(context).translate('sort_desc'),
                          ),
                        ].map<Widget>((Widget item) {
                          return DropdownMenuItem<String>(
                            value:
                                (item as Text).data ==
                                    AppLocalizations.of(
                                      context,
                                    ).translate('sort_asc')
                                ? 'ASC'
                                : 'DESC',
                            child: Text(
                              item.data!,
                              style: TextStyle(color: context.theme.textColor),
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (value) =>
                          questionVm.updateSortFilter(sortOrder: value),
                    ),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).translate('apply')),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 12.0,
                        decoration: BoxDecoration(
                          color: context.theme.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 60,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: context.theme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 10.0,
                            decoration: BoxDecoration(
                              color: context.theme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildAnimatedQuestionCard(
    Question question,
    int index,
    bool isOffline,
  ) {
    String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(question.createdAt.toLocal());

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (question.status) {
      case 'ANSWERED':
        statusColor = context.theme.green;
        statusText = AppLocalizations.of(context).translate('status_answered');
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'CLOSED':
        statusColor = context.theme.mutedForeground;
        statusText = AppLocalizations.of(context).translate('status_closed');
        statusIcon = Icons.lock_outline_rounded;
        break;
      case 'PENDING':
      default:
        statusColor = context.theme.yellow;
        statusText = AppLocalizations.of(context).translate('status_pending');
        statusIcon = Icons.hourglass_empty_rounded;
        break;
    }

    return Slidable(
      key: ValueKey('question_item_${question.id}'),
      endActionPane: (isOffline || !_canDelete)
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
                  label: AppLocalizations.of(context).translate('delete'),
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
          side: BorderSide(color: context.theme.border.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        color: context.theme.card,
        child: InkWell(
          onTap: () {
            // Navigate to detail
            Navigator.pushNamed(
              context,
              Routes.questionDetail,
              arguments: question.id,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: context.theme.primary.withOpacity(0.1),
                      child: Text(
                        question.authorName.isNotEmpty == true
                            ? question.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: context.theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.authorName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.theme.textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  question.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.theme.mutedForeground,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (question.specialtyId != null)
                      Consumer<QuestionVm>(
                        builder: (context, vm, _) {
                          final specialty = vm.specialties.firstWhere(
                            (s) => s.id == question.specialtyId,
                            orElse: () => Specialty(
                              id: '',
                              name: 'Unknown',
                              description: '',
                              infoSectionsCount: 0,
                            ),
                          );
                          if (specialty.name == 'Unknown')
                            return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.muted,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              specialty.name,
                              style: TextStyle(
                                color: context.theme.mutedForeground,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
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
}
