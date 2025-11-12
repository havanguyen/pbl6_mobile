import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/answer.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/services/store.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:provider/provider.dart';

class QuestionDetailPage extends StatefulWidget {
  final String questionId;
  const QuestionDetailPage({super.key, required this.questionId});

  @override
  State<QuestionDetailPage> createState() => _QuestionDetailPageState();
}

class _QuestionDetailPageState extends State<QuestionDetailPage> {
  String? _userRole;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserRoleAndId();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadUserRoleAndId() async {
    final role = await Store.getUserRole();
    final profile = await AuthService.getProfile();
    if (mounted) {
      setState(() {
        _userRole = role;
        _currentUserId = profile?.id;
      });
      if (role == 'ADMIN' || role == 'SUPER_ADMIN') {
        final vm = context.read<QuestionVm>();
        if (vm.specialties.isEmpty) {
          vm.fetchSpecialties();
        }
      }
    }
  }

  void _loadData() {
    final vm = context.read<QuestionVm>();
    vm.currentQuestion = null;
    vm.currentAnswers.clear();
    vm.error = null;
    vm.isLoading = true;


    vm.fetchQuestionDetail(widget.questionId).then((_) {

      if (vm.currentQuestion != null && !vm.isOffline) {
        vm.fetchAnswers(widget.questionId);
      } else {

        if (vm.isLoading) {
          vm.isLoading = false;

        }
      }
    });
  }

  void _showDeleteAnswerDialog(Answer answer) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final questionVm = Provider.of<QuestionVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: context.theme.destructive),
            const SizedBox(width: 10),
            Text(
              'Xác nhận xóa',
              style: TextStyle(color: context.theme.textColor),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa câu trả lời này không?',
          style: TextStyle(color: context.theme.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await questionVm.deleteAnswer(answer.id);
              if (mounted) {
                if (success) {
                  snackbarService.showSuccess('Đã xóa câu trả lời');
                } else {
                  snackbarService.showError(
                      questionVm.error ?? 'Xóa câu trả lời thất bại');
                }
              }
            },
            child:
            Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  void _acceptAnswer(Answer answer) async {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final questionVm = Provider.of<QuestionVm>(context, listen: false);

    final success = await questionVm.acceptAnswer(answer.id);
    if (mounted) {
      if (success) {
        snackbarService.showSuccess('Đã duyệt câu trả lời');
      } else {
        snackbarService
            .showError(questionVm.error ?? 'Duyệt câu trả lời thất bại');
      }
    }

  }

  void _showPostAnswerDialog() {
    final questionVm = Provider.of<QuestionVm>(context, listen: false);
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final TextEditingController answerController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.theme.card,
          title: Text('Gửi câu trả lời', style: TextStyle(color: context.theme.textColor)),
          content: Form(
            key: formKey,
            child: TextFormField(
              key: const ValueKey('answer_quill_editor'),
              controller: answerController,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời của bạn...',
                hintStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: context.theme.textColor),
              maxLines: 5,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nội dung không được để trống'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
            ),
            ElevatedButton(
              key: const ValueKey('submit_answer_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor: context.theme.primaryForeground,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  final success = await questionVm.postAnswer(
                    widget.questionId,
                    answerController.text,
                  );
                  if (mounted) {
                    if (success) {
                      snackbarService.showSuccess('Đã gửi câu trả lời');
                    } else {
                      snackbarService.showError(
                          questionVm.error ?? 'Gửi câu trả lời thất bại');
                    }
                  }
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        );
      },
    );
  }

  void _showEditAnswerDialog(Answer answer) {
    final questionVm = Provider.of<QuestionVm>(context, listen: false);
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final TextEditingController answerController =
    TextEditingController(text: answer.body);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.theme.card,
          title: Text('Chỉnh sửa câu trả lời', style: TextStyle(color: context.theme.textColor)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: answerController,
              decoration: InputDecoration(
                hintText: 'Nhập câu trả lời của bạn...',
                hintStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: TextStyle(color: context.theme.textColor),
              maxLines: 5,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Nội dung không được để trống'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.theme.primary,
                foregroundColor: context.theme.primaryForeground,
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  final success = await questionVm.updateAnswer(
                    answer.id,
                    answerController.text,
                  );
                  if (mounted) {
                    if (success) {
                      snackbarService.showSuccess('Đã cập nhật câu trả lời');
                    } else {
                      snackbarService.showError(
                          questionVm.error ?? 'Cập nhật thất bại');
                    }
                  }
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  void _showEditQuestionDialog(QuestionVm vm) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final question = vm.currentQuestion;
    if (question == null) return;

    String? selectedSpecialtyId = question.specialtyId;
    String? selectedStatus = question.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.theme.card,
              title: Text('Chỉnh sửa câu hỏi', style: TextStyle(color: context.theme.textColor)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chuyên khoa', style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedSpecialtyId,
                    hint: Text('Chọn chuyên khoa', style: TextStyle(color: context.theme.mutedForeground)),
                    isExpanded: true,
                    style: TextStyle(color: context.theme.textColor, fontSize: 15),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: context.theme.input,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    dropdownColor: context.theme.popover,
                    items: vm.specialties.map((Specialty specialty) {
                      return DropdownMenuItem<String>(
                        value: specialty.id,
                        child: Text(specialty.name, style: TextStyle(color: context.theme.popoverForeground)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedSpecialtyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Trạng thái', style: TextStyle(color: context.theme.textColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    hint: Text('Chọn trạng thái', style: TextStyle(color: context.theme.mutedForeground)),
                    isExpanded: true,
                    style: TextStyle(color: context.theme.textColor, fontSize: 15),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: context.theme.input,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    dropdownColor: context.theme.popover,
                    items: const [
                      DropdownMenuItem(value: 'PENDING', child: Text('⏳ Đang chờ')),
                      DropdownMenuItem(value: 'ANSWERED', child: Text('✅ Đã trả lời')),
                      DropdownMenuItem(value: 'CLOSED', child: Text('🔒 Đã đóng')),
                    ],
                    selectedItemBuilder: (context) {
                      return [
                        Text('⏳ Đang chờ', style: TextStyle(color: context.theme.textColor)),
                        Text('✅ Đã trả lời', style: TextStyle(color: context.theme.textColor)),
                        Text('🔒 Đã đóng', style: TextStyle(color: context.theme.textColor)),
                      ];
                    },
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                  ),
                  onPressed: (selectedSpecialtyId == null || selectedStatus == null) ? null : () async {
                    Navigator.pop(context);
                    final data = {
                      'specialtyId': selectedSpecialtyId,
                      'status': selectedStatus,
                    };
                    final success = await vm.updateQuestion(question.id, data);
                    if (mounted) {
                      if (success) {
                        snackbarService.showSuccess('Đã cập nhật câu hỏi');
                      } else {
                        snackbarService.showError(
                            vm.error ?? 'Cập nhật thất bại');
                      }
                    }
                  },
                  child: const Text('Cập nhật'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {

    return Consumer<QuestionVm>(
      builder: (context, vm, child) {
        Widget bodyContent;

        if (vm.isLoading && vm.currentQuestion == null) {
          bodyContent = const Center(child: CircularProgressIndicator());
        }
        else if (vm.error != null && vm.currentQuestion == null) {
          bodyContent = Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vm.isOffline || (vm.error ?? '').contains('Lỗi kết nối')
                        ? Icons.wifi_off_rounded
                        : Icons.error_outline_rounded,
                    size: 60,
                    color: context.theme.mutedForeground,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    vm.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.theme.destructive,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    onPressed: _loadData,
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
        else if (vm.currentQuestion == null) {

          bodyContent = const Center(child: Text("Không tìm thấy câu hỏi"));
        }
        else {
          final question = vm.currentQuestion!;
          bodyContent = RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    question.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.5),
                        child: Icon(Icons.person_outline,
                            size: 16, color: context.theme.mutedForeground),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${question.authorName} (${question.authorEmail})',
                          style: TextStyle(
                              fontSize: 14,
                              color: context.theme.mutedForeground),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: context.theme.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm')
                            .format(question.createdAt.toLocal()),
                        style: TextStyle(
                            fontSize: 14,
                            color: context.theme.mutedForeground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.theme.input,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.theme.border),
                    ),
                    child: Text(
                      'Trạng thái: ${question.status}',
                      style: TextStyle(
                          color: context.theme.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.body,
                    style: TextStyle(
                        fontSize: 16,
                        color: context.theme.textColor.withOpacity(0.9),
                        height: 1.5),
                  ),
                  const Divider(height: 32, thickness: 0.5),


                  Text(
                    'Câu trả lời (${vm.currentAnswers.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),

                  if (vm.error != null && vm.error!.contains('câu trả lời'))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(vm.error!, style: TextStyle(color: context.theme.destructive)),
                    ),
                  const SizedBox(height: 12),

                  _buildAnswersList(vm),
                ],
              ),
            ),
          );
        }

        final bool canPostAnswer = _userRole == 'DOCTOR';
        final bool isAdminRole = (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết câu hỏi'),
            backgroundColor: context.theme.appBar,
            titleTextStyle: TextStyle(
              color: context.theme.primaryForeground,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: context.theme.primaryForeground),
            actions: [
              if (isAdminRole && vm.currentQuestion != null)
                IconButton(
                  icon: const Icon(Icons.edit_note_outlined),
                  onPressed: () => _showEditQuestionDialog(vm),
                  tooltip: 'Chỉnh sửa câu hỏi',
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: vm.isLoading ? null : _loadData,
              )
            ],
          ),
          backgroundColor: context.theme.bg,
          body: bodyContent,
          floatingActionButton: canPostAnswer
              ? FloatingActionButton(
            onPressed: _showPostAnswerDialog,
            backgroundColor: context.theme.primary,
            child: Icon(Icons.add_comment_outlined, color: context.theme.primaryForeground),
            tooltip: 'Gửi câu trả lời',
          )
              : null,
        );
      },
    );
  }

  Widget _buildAnswersList(QuestionVm vm) {

    if (vm.isLoading && vm.currentQuestion != null && vm.currentAnswers.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
    }


    if (!vm.isLoading && vm.currentAnswers.isEmpty && (vm.error == null || !vm.error!.contains('câu trả lời'))) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Chưa có câu trả lời nào', style: TextStyle(color: context.theme.mutedForeground)),
        ),
      );
    }


    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vm.currentAnswers.length,
      itemBuilder: (context, index) {
        final answer = vm.currentAnswers[index];
        return _buildAnswerCard(answer);
      },
    );
  }


  Widget _buildAnswerCard(Answer answer) {
    final bool isAccepted = answer.isAccepted;
    final bool isAdminRole = (_userRole == 'ADMIN' || _userRole == 'SUPER_ADMIN');
    final bool isDoctorRole = (_userRole == 'DOCTOR');
    final bool isOwner = (isDoctorRole && answer.authorId == _currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      color: context.theme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAccepted
              ? context.theme.green.withOpacity(0.7)
              : context.theme.border.withOpacity(0.5),
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (isAccepted)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.theme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle,
                        size: 14, color: context.theme.green),
                    const SizedBox(width: 4),
                    Text(
                      'ĐÃ DUYỆT',
                      style: TextStyle(
                        color: context.theme.green,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

            Text(
              answer.body,
              style: TextStyle(color: context.theme.textColor, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 8),

            Text(
              'Bác sĩ ID: ${answer.authorId}',
              style:
              TextStyle(color: context.theme.mutedForeground, fontSize: 12),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1, color: context.theme.border.withOpacity(0.5)),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isAdminRole && !isAccepted)
                  _buildAdminButton(
                    icon: Icons.check_circle_outline,
                    label: 'Duyệt',
                    color: context.theme.green,
                    onPressed: () => _acceptAnswer(answer),
                  ),
                if (isAdminRole) const SizedBox(width: 8),

                if (isAdminRole)
                  _buildAdminButton(
                    icon: Icons.delete_outline,
                    label: 'Xóa',
                    color: context.theme.destructive,
                    onPressed: () => _showDeleteAnswerDialog(answer),
                  ),

                if (isOwner)
                  _buildAdminButton(
                    icon: Icons.edit_outlined,
                    label: 'Sửa',
                    color: context.theme.primary,
                    onPressed: () => _showEditAnswerDialog(answer),
                  ),

                if (isOwner) const SizedBox(width: 8),

                if (isOwner)
                  _buildAdminButton(
                    icon: Icons.delete_outline,
                    label: 'Xóa',
                    color: context.theme.destructive,
                    onPressed: () => _showDeleteAnswerDialog(answer),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAdminButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
      icon: Icon(icon, size: 18, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      onPressed: onPressed,
    );
  }
}