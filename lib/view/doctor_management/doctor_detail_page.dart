import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../model/entities/profile.dart';

class DoctorDetailPage extends StatefulWidget {
  final String doctorId;
  final bool isSelfView;

  const DoctorDetailPage({
    super.key,
    required this.doctorId,
    this.isSelfView = false,
  });

  @override
  State<DoctorDetailPage> createState() => _DoctorDetailPageState();
}

class _DoctorDetailPageState extends State<DoctorDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
      }
    });
  }

  void _editProfile(DoctorDetail doctor) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editDoctorProfile,
      arguments: {
        'doctorDetail': doctor,
        'isSelfEdit': widget.isSelfView,
      },
    );
    if (result == true && mounted) {
      context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
    }
  }

  void _editAccount(DoctorDetail doctor) async {
    if (widget.isSelfView) {
      final profileArgs = Profile(
        id: doctor.id,
        fullName: doctor.fullName,
        email: doctor.email,
        role: doctor.role,
        phone: doctor.phone,
        isMale: doctor.isMale,
        dateOfBirth: doctor.dateOfBirth,
        createdAt: doctor.createdAt,
        updatedAt: doctor.updatedAt,
      );
      final result = await Navigator.pushNamed(
        context,
        Routes.editAccountDoctor,
        arguments: profileArgs,
      );
      if (result == true && mounted) {
        context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
      }
    } else {
      final doctorAsMap = {
        'id': doctor.id,
        'fullName': doctor.fullName,
        'email': doctor.email,
        'phone': doctor.phone,
        'isMale': doctor.isMale,
        'dateOfBirth': doctor.dateOfBirth?.toIso8601String(),
        'role': doctor.role,
      };
      final result = await Navigator.pushNamed(
        context,
        Routes.updateDoctor,
        arguments: doctorAsMap,
      );
      if (result == true && mounted) {
        context.read<DoctorVm>().fetchDoctorDetail(widget.doctorId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorVm = context.watch<DoctorVm>();
    final doctor = doctorVm.doctorDetail;
    final isOffline = doctorVm.isOffline;

    final reviews = doctorVm.reviews;
    final isLoadingReviews = doctorVm.isLoadingReviews;

    return Scaffold(
      backgroundColor: context.theme.bg,
      body: doctorVm.isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : doctor == null
          ? const Center(child: Text('Không thể tải dữ liệu bác sĩ'))
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(doctor, isOffline, context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    context,
                    title: "Thông tin tài khoản",
                    icon: Icons.person_pin_rounded,
                    onEdit: () => _editAccount(doctor),
                    isOffline: isOffline,
                    editKey: const ValueKey('profile_doctor_edit_button'),
                    children: [
                      _buildInfoRow(Icons.email, "Email",
                          doctor.email, context),
                      _buildInfoRow(
                          Icons.phone,
                          "Điện thoại",
                          doctor.phone ?? 'Chưa cập nhật',
                          context),
                      _buildInfoRow(
                          Icons.cake,
                          "Ngày sinh",
                          doctor.dateOfBirth
                              ?.toString()
                              .split(' ')[0] ??
                              'Chưa cập nhật',
                          context),
                      _buildInfoRow(
                          Icons.person,
                          "Giới tính",
                          (doctor.isMale ? 'Nam' : 'Nữ'),
                          context),
                    ],
                  ),
                  _buildInfoSection(
                    context,
                    title: "Hồ sơ chuyên môn",
                    icon: Icons.medical_information,
                    onEdit: () => _editProfile(doctor),
                    isOffline: isOffline,
                    children: [
                      if (doctor.specialties.isNotEmpty)
                        _buildTitledChipList(
                            "Chuyên khoa",
                            doctor.specialties.map((e) => e.name).toList(),
                            context),
                      if (doctor.workLocations.isNotEmpty)
                        _buildTitledChipList(
                            "Nơi công tác",
                            doctor.workLocations
                                .map((e) => e.name)
                                .toList(),
                            context),
                      _buildExpansionListSection(
                          "Chức vụ", doctor.position, context),
                      _buildExpansionListSection(
                          "Kinh nghiệm", doctor.experience, context),
                      _buildExpansionListSection("Quá trình đào tạo",
                          doctor.trainingProcess, context),
                      _buildExpansionListSection(
                          "Giải thưởng", doctor.awards, context),
                      _buildExpansionListSection(
                          "Thành viên hiệp hội", doctor.memberships, context),
                      if (doctor.introduction != null &&
                          doctor.introduction!.isNotEmpty)
                        _buildExpansionHtmlSection(
                            "Giới thiệu", doctor.introduction!, context),
                      if (doctor.research != null &&
                          doctor.research!.isNotEmpty)
                        _buildExpansionHtmlSection(
                            "Nghiên cứu khoa học",
                            doctor.research!,
                            context),
                    ],
                  ),
                  _buildInfoSection(
                    context,
                    title: "Đánh giá của bệnh nhân",
                    icon: Icons.reviews_outlined,
                    isOffline: isOffline,
                    children: [
                      if (isLoadingReviews && reviews.isEmpty)
                        const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ))
                      else if (reviews.isEmpty)
                        const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Chưa có đánh giá nào'),
                            ))
                      else
                        Column(
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                              const NeverScrollableScrollPhysics(),
                              itemCount: reviews.length,
                              itemBuilder: (ctx, index) {
                                final review = reviews[index];
                                return _buildReviewCard(
                                    context, review);
                              },
                            ),
                            const Divider(height: 1),
                            Center(
                              child: TextButton(
                                child: Text('Xem tất cả đánh giá',
                                    style: TextStyle(
                                        color: context.theme.primary)),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    Routes.doctorReviewPage,
                                    arguments: {
                                      'doctorId': doctor.id,
                                      'doctorName': doctor.fullName,
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.theme.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StarRating(
                        rating: review.rating, color: context.theme.yellow),
                    const SizedBox(height: 8),
                    Text(
                      review.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.body,
            style: TextStyle(color: context.theme.mutedForeground, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  style: TextStyle(
                      color: context.theme.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal()),
                style:
                TextStyle(color: context.theme.mutedForeground, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      DoctorDetail doctor, bool isOffline, BuildContext context) {
    bool isValidUrl(String? url) =>
        url != null && url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true;

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: context.theme.card,
      elevation: 2,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Text(
          doctor.fullName,
          style: TextStyle(
            color: context.theme.textColor,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (isValidUrl(doctor.portrait))
              CachedNetworkImage(
                imageUrl: doctor.portrait!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: context.theme.muted),
                errorWidget: (context, url, error) =>
                    Container(color: context.theme.muted),
              )
            else
              Container(color: context.theme.muted),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.theme.card.withOpacity(0.9),
                    context.theme.card.withOpacity(0.2)
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: context.theme.primary.withOpacity(0.1),
                    backgroundImage: isValidUrl(doctor.avatarUrl)
                        ? CachedNetworkImageProvider(doctor.avatarUrl!)
                        : null,
                    child: !isValidUrl(doctor.avatarUrl)
                        ? Text(
                      doctor.fullName.isNotEmpty
                          ? doctor.fullName[0].toUpperCase()
                          : 'D',
                      style: TextStyle(
                          fontSize: 40, color: context.theme.primary),
                    )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    doctor.degree ?? 'Chưa có thông tin học vị',
                    style: TextStyle(
                      fontSize: 18,
                      color: context.theme.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!widget.isSelfView)
                    _StatusBadge(
                      doctor: doctor,
                      isOffline: isOffline,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<Widget> children,
        VoidCallback? onEdit,
        bool isOffline = false,
        ValueKey? editKey,
      }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.theme.border, width: 1.5),
      ),
      color: context.theme.card.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.theme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!isOffline && onEdit != null)
                  IconButton(
                    key: editKey,
                    icon: Icon(Icons.edit_outlined,
                        color: context.theme.primary, size: 20),
                    onPressed: onEdit,
                    tooltip: 'Chỉnh sửa',
                  ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTitledChipList(
      String title, List<String> items, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items.map((item) => _buildChip(item, context)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionHtmlSection(
      String title, String content, BuildContext context) {
    String htmlContent;
    try {
      final deltaJson = jsonDecode(content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = content.replaceAll('\n', '<br>');
    }

    return ExpansionTile(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      iconColor: context.theme.primary,
      collapsedIconColor: context.theme.textColor,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Html(
            data: htmlContent,
            onLinkTap: (url, _, __) async {
              if (url != null && await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url));
              }
            },
            style: {
              "body": Style(
                fontSize: FontSize(15),
                color: context.theme.mutedForeground,
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                lineHeight: LineHeight.em(1.5),
              ),
              "h1,h2,h3,h4,h5,h6": Style(
                color: context.theme.textColor,
              ),
              "li": Style(padding: HtmlPaddings.only(left: 8)),
            },
          ),
        )
      ],
    );
  }

  Widget _buildExpansionListSection(
      String title, List<String>? items, BuildContext context) {
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      iconColor: context.theme.primary,
      collapsedIconColor: context.theme.textColor,
      children: items
          .map((item) => ListTile(
        leading: Icon(Icons.check_circle_outline,
            color: context.theme.green, size: 18),
        title: Text(
          item,
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      ))
          .toList(),
    );
  }

  Widget _buildInfoRow(
      IconData? icon, String label, String value, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.theme.primary, size: 20),
            const SizedBox(width: 16),
          ],
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Expanded(
            child: Text(
              value,
              style:
              TextStyle(color: context.theme.mutedForeground, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, BuildContext context) {
    return Chip(
      avatar: Icon(Icons.check_circle, color: context.theme.primary, size: 16),
      label: Text(label),
      backgroundColor: context.theme.primary.withOpacity(0.1),
      labelStyle:
      TextStyle(color: context.theme.primary, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DoctorDetail doctor;
  final bool isOffline;

  const _StatusBadge({
    required this.doctor,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = doctor.isActive;

    void handleTap() {
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể thay đổi trạng thái khi offline')),
        );
        return;
      }

        context
            .read<DoctorVm>()
            .toggleDoctorStatus(doctor.profileId, !isActive);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: handleTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isActive ? context.theme.green : context.theme.grey)
                .withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isActive ? context.theme.green : context.theme.grey),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.pause_circle,
                color: isActive ? context.theme.green : context.theme.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'Đang hoạt động' : 'Tạm ngưng',
                style: TextStyle(
                  color: isActive ? context.theme.green : context.theme.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final Color color;
  final double size;

  const _StarRating({
    required this.rating,
    this.color = Colors.amber,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: color,
          size: size,
        );
      }),
    );
  }
}