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
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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
        context.read<DoctorVm>().fetchDoctorDetail(
          widget.doctorId,
          isSelf: widget.isSelfView,
        );
      }
    });
  }

  void _editProfile(DoctorDetail doctor) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.editDoctorProfile,
      arguments: {'doctorDetail': doctor, 'isSelfEdit': widget.isSelfView},
    );
    if (result == true && mounted) {
      context.read<DoctorVm>().fetchDoctorDetail(
        widget.doctorId,
        isSelf: widget.isSelfView,
      );
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
        context.read<DoctorVm>().fetchDoctorDetail(
          widget.doctorId,
          isSelf: widget.isSelfView,
        );
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
      body: doctorVm.isLoadingDetail && doctor == null
          ? const Center(child: CircularProgressIndicator())
          : doctor == null
          ? Center(
              child: Text(
                AppLocalizations.of(context).translate('doctor_detail_error'),
              ),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(doctor, isOffline, context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderSection(doctor, isOffline, context),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                          context,
                          title: AppLocalizations.of(
                            context,
                          ).translate('account_info'),
                          icon: Icons.person_pin_rounded,
                          onEdit: () => _editAccount(doctor),
                          isOffline: isOffline,
                          editKey: const ValueKey('profile_doctor_edit_button'),
                          children: [
                            _buildInfoRow(
                              Icons.email,
                              AppLocalizations.of(
                                context,
                              ).translate('email_label'),
                              doctor.email,
                              context,
                            ),
                            _buildInfoRow(
                              Icons.phone,
                              AppLocalizations.of(
                                context,
                              ).translate('phone_label'),
                              doctor.phone ??
                                  AppLocalizations.of(
                                    context,
                                  ).translate('not_updated'),
                              context,
                            ),
                            _buildInfoRow(
                              Icons.cake,
                              AppLocalizations.of(
                                context,
                              ).translate('dob_label'),
                              doctor.dateOfBirth != null
                                  ? DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(doctor.dateOfBirth!)
                                  : AppLocalizations.of(
                                      context,
                                    ).translate('not_updated'),
                              context,
                            ),
                            _buildInfoRow(
                              Icons.person,
                              AppLocalizations.of(
                                context,
                              ).translate('gender_label'),
                              (doctor.isMale
                                  ? AppLocalizations.of(
                                      context,
                                    ).translate('male')
                                  : AppLocalizations.of(
                                      context,
                                    ).translate('female')),
                              context,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                          context,
                          title: AppLocalizations.of(
                            context,
                          ).translate('professional_profile'),
                          icon: Icons.medical_information,
                          onEdit: () => _editProfile(doctor),
                          isOffline: isOffline,
                          children: [
                            if (doctor.specialties.isNotEmpty)
                              _buildTitledChipList(
                                AppLocalizations.of(
                                  context,
                                ).translate('specialty_label'),
                                doctor.specialties.map((e) => e.name).toList(),
                                context,
                              ),
                            if (doctor.workLocations.isNotEmpty)
                              _buildTitledChipList(
                                AppLocalizations.of(
                                  context,
                                ).translate('work_location_label'),
                                doctor.workLocations
                                    .map((e) => e.name)
                                    .toList(),
                                context,
                              ),
                            _buildExpansionListSection(
                              AppLocalizations.of(
                                context,
                              ).translate('position_label'),
                              doctor.position,
                              context,
                            ),
                            _buildExpansionListSection(
                              AppLocalizations.of(
                                context,
                              ).translate('experience_label'),
                              doctor.experience,
                              context,
                            ),
                            _buildExpansionListSection(
                              AppLocalizations.of(
                                context,
                              ).translate('training_label'),
                              doctor.trainingProcess,
                              context,
                            ),
                            _buildExpansionListSection(
                              AppLocalizations.of(
                                context,
                              ).translate('awards_label'),
                              doctor.awards,
                              context,
                            ),
                            _buildExpansionListSection(
                              AppLocalizations.of(
                                context,
                              ).translate('membership_label'),
                              doctor.memberships,
                              context,
                            ),
                            if (doctor.introduction != null &&
                                doctor.introduction!.isNotEmpty)
                              _buildExpansionHtmlSection(
                                AppLocalizations.of(
                                  context,
                                ).translate('introduction_label'),
                                doctor.introduction!,
                                context,
                              ),
                            if (doctor.research != null &&
                                doctor.research!.isNotEmpty)
                              _buildExpansionHtmlSection(
                                AppLocalizations.of(
                                  context,
                                ).translate('research_label'),
                                doctor.research!,
                                context,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoSection(
                          context,
                          title: AppLocalizations.of(
                            context,
                          ).translate('patient_reviews'),
                          icon: Icons.reviews_outlined,
                          isOffline: isOffline,
                          children: [
                            if (isLoadingReviews && reviews.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (reviews.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    AppLocalizations.of(
                                      context,
                                    ).translate('no_reviews_yet'),
                                  ),
                                ),
                              )
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
                                      return _buildReviewCard(context, review);
                                    },
                                  ),
                                  const Divider(height: 1),
                                  Center(
                                    child: TextButton(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('view_all_reviews'),
                                        style: TextStyle(
                                          color: context.theme.primary,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          Routes.doctorReviewPage,
                                          arguments: {
                                            'doctorId': doctor.profileId,
                                            'doctorName': doctor.fullName,
                                          },
                                        );
                                      },
                                    ),
                                  ),
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.theme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.theme.primary.withOpacity(0.1),
                child: Text(
                  review.authorName.isNotEmpty
                      ? review.authorName[0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    color: context.theme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _StarRating(
                      rating: review.rating,
                      color: context.theme.yellow,
                      size: 16,
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal()),
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            review.body,
            style: TextStyle(
              color: context.theme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
    DoctorDetail doctor,
    bool isOffline,
    BuildContext context,
  ) {
    bool isValidUrl(String? url) =>
        url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true;

    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: context.theme.card,
      elevation: 1,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: context.theme.textColor),
        onPressed: () => Navigator.of(context).pop(),
      ),
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
          textAlign: TextAlign.center,
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
                    context.theme.card.withOpacity(0.1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    DoctorDetail doctor,
    bool isOffline,
    BuildContext context,
  ) {
    bool isValidUrl(String? url) =>
        url != null &&
        url.isNotEmpty &&
        Uri.tryParse(url)?.hasAbsolutePath == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'avatar_${doctor.id}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.primary.withOpacity(0.2),
                      width: 3,
                    ),
                    image: isValidUrl(doctor.avatarUrl)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              doctor.avatarUrl!,
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: !isValidUrl(doctor.avatarUrl)
                      ? Text(
                          doctor.fullName.isNotEmpty
                              ? doctor.fullName[0].toUpperCase()
                              : 'D',
                          style: TextStyle(
                            fontSize: 32,
                            color: context.theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'name_${doctor.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          doctor.fullName,
                          style: TextStyle(
                            fontSize: 22,
                            color: context.theme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doctor.degree ??
                            AppLocalizations.of(
                              context,
                            ).translate('no_degree_info'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!widget.isSelfView)
                      _StatusBadge(doctor: doctor, isOffline: isOffline),
                  ],
                ),
              ),
            ],
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: context.theme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isOffline && onEdit != null)
                InkWell(
                  key: editKey,
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.edit_outlined,
                      color: context.theme.primary,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // const Divider(height: 24), // Removed divider for cleaner look
          ...children,
        ],
      ),
    );
  }

  Widget _buildTitledChipList(
    String title,
    List<String> items,
    BuildContext context,
  ) {
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
            children: items
                .map(
                  (item) => Chip(
                    label: Text(item),
                    backgroundColor: context.theme.primary.withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: context.theme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionHtmlSection(
    String title,
    String content,
    BuildContext context,
  ) {
    String htmlContent;
    try {
      final deltaJson = jsonDecode(content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = content.replaceAll('\n', '<br>');
    }

    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      iconColor: context.theme.primary,
      collapsedIconColor: context.theme.textColor,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      shape: const Border(),
      children: [
        Html(
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
            "h1,h2,h3,h4,h5,h6": Style(color: context.theme.textColor),
            "li": Style(padding: HtmlPaddings.only(left: 8)),
          },
        ),
      ],
    );
  }

  Widget _buildExpansionListSection(
    String title,
    List<String>? items,
    BuildContext context,
  ) {
    if (items == null || items.isEmpty) {
      return const SizedBox.shrink();
    }
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      iconColor: context.theme.primary,
      collapsedIconColor: context.theme.textColor,
      tilePadding: const EdgeInsets.symmetric(horizontal: 0),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      shape: const Border(),
      children: items
          .map(
            (item) => ListTile(
              leading: Icon(
                Icons.check_circle_outline,
                color: context.theme.green,
                size: 18,
              ),
              title: Text(
                item,
                style: TextStyle(color: context.theme.mutedForeground),
              ),
              minLeadingWidth: 0,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              dense: true,
            ),
          )
          .toList(),
    );
  }

  Widget _buildInfoRow(
    IconData? icon,
    String label,
    String value,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: context.theme.mutedForeground, size: 20),
            const SizedBox(width: 16),
          ] else
            const SizedBox(width: 36),
          SizedBox(
            width: 90,
            child: Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.theme.mutedForeground,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DoctorDetail doctor;
  final bool isOffline;

  const _StatusBadge({required this.doctor, required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final bool isActive = doctor.isActive;

    void handleTap() {
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('offline_status_change_error'),
            ),
          ),
        );
        return;
      }

      context.read<DoctorVm>().toggleDoctorStatus(doctor.profileId, !isActive);
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
                isActive
                    ? AppLocalizations.of(context).translate('active_status')
                    : AppLocalizations.of(context).translate('inactive_status'),
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
    required this.size,
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
