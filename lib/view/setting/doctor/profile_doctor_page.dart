import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/review_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class ProfileDoctorPage extends StatefulWidget {
  const ProfileDoctorPage({super.key});

  @override
  State<ProfileDoctorPage> createState() => _ProfileDoctorPageState();
}

class _ProfileDoctorPageState extends State<ProfileDoctorPage> {
  DoctorDetail? _doctorDetail;
  bool _isLoading = true;
  String? _error;

  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  String? _reviewError;

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetail();
  }

  Future<void> _fetchDoctorDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await AuthService.getProfile();
      if (profile != null) {
        final doctor = await DoctorService.getDoctorWithProfile(profile.id);
        if (doctor != null) {
          if (mounted) {
            setState(() {
              _doctorDetail = doctor;
              _isLoading = false;
            });
            // Use profileId instead of id for reviews
            _fetchReviews(doctor.profileId);
          }
        } else {
          if (mounted) {
            setState(() {
              _error = 'Unable to load doctor profile details.';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'User profile not found.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchReviews(String doctorId) async {
    setState(() {
      _isLoadingReviews = true;
      _reviewError = null;
    });

    try {
      final result = await ReviewService.getReviewsForDoctor(
        doctorId: doctorId,
        page: 1,
        limit: 3,
      );
      if (mounted) {
        setState(() {
          if (result.success) {
            _reviews = result.data;
          } else {
            _reviewError = result.message;
          }
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reviewError = e.toString();
          _isLoadingReviews = false;
        });
      }
    }
  }

  void _editAccount() async {
    if (_doctorDetail == null) return;
    final doctor = _doctorDetail!;
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
    if (result == true) {
      _fetchDoctorDetail();
    }
  }

  void _editProfessionalProfile() async {
    if (_doctorDetail == null) return;
    final result = await Navigator.pushNamed(
      context,
      Routes.editDoctorProfile,
      arguments: {'doctorDetail': _doctorDetail!, 'isSelfEdit': true},
    );
    if (result == true) {
      _fetchDoctorDetail();
    }
  }

  Widget _buildLoading() {
    return Scaffold(
      backgroundColor: context.theme.bg,
      body: Center(
        child: CircularProgressIndicator(color: context.theme.primary),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(title: const Text('Profile Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.theme.red),
            const SizedBox(height: 16),
            Text(_error ?? 'Unknown error occurred'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDoctorDetail,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_error != null || _doctorDetail == null) return _buildError();

    final doctor = _doctorDetail!;

    return Scaffold(
      backgroundColor: context.theme.bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(doctor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildQuickStats(doctor),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: AppLocalizations.of(
                      context,
                    ).translate('account_info'),
                    icon: Icons.person_outline,
                    onEdit: _editAccount,
                  ),
                  const SizedBox(height: 8),
                  _buildAccountInfoCard(doctor),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: AppLocalizations.of(
                      context,
                    ).translate('professional_profile'),
                    icon: Icons.medical_services_outlined,
                    onEdit: _editProfessionalProfile,
                  ),
                  const SizedBox(height: 8),
                  _buildProfessionalInfoCard(doctor),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    title: AppLocalizations.of(
                      context,
                    ).translate('patient_reviews'),
                    icon: Icons.reviews_outlined,
                  ),
                  const SizedBox(height: 8),
                  _buildReviewsSection(doctor),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(DoctorDetail doctor) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: context.theme.card,
      iconTheme: IconThemeData(color: context.theme.textColor),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (doctor.portrait != null && doctor.portrait!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: doctor.portrait!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: context.theme.primary.withAlpha(26),
                ), // 0.1 * 255
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.theme.primary.withAlpha(153), // 0.6 * 255
                      context.theme.bg,
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, context.theme.bg],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: context.theme.bg, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26), // 0.1 * 255
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: context.theme.card,
                        backgroundImage:
                            (doctor.avatarUrl != null &&
                                doctor.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImageProvider(doctor.avatarUrl!)
                            : null,
                        child:
                            (doctor.avatarUrl == null ||
                                doctor.avatarUrl!.isEmpty)
                            ? Text(
                                doctor.fullName.isNotEmpty
                                    ? doctor.fullName[0].toUpperCase()
                                    : 'D',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: context.theme.primary,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.theme.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (doctor.degree != null && doctor.degree!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          doctor.degree!,
                          style: TextStyle(
                            fontSize: 16,
                            color: context.theme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(DoctorDetail doctor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.theme.popover.withAlpha(13), // 0.05 * 255
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            AppLocalizations.of(context).translate('specialty_label'),
            '${doctor.specialties.length}',
            Icons.local_hospital_outlined,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            AppLocalizations.of(context).translate('work_location_label'),
            '${doctor.workLocations.length}',
            Icons.location_on_outlined,
          ),
          if (doctor.awards.isNotEmpty) ...[
            _buildVerticalDivider(),
            _buildStatItem(
              AppLocalizations.of(context).translate('awards_label'),
              '${doctor.awards.length}',
              Icons.emoji_events_outlined,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: context.theme.border);
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    final displayLabel = label.replaceAll(':', '');

    return Column(
      children: [
        Icon(icon, size: 20, color: context.theme.mutedForeground),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
        ),
        Text(
          displayLabel,
          style: TextStyle(fontSize: 12, color: context.theme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.theme.primary.withAlpha(26), // 0.1 * 255
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: context.theme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
            ),
          ],
        ),
        if (onEdit != null)
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.edit,
              color: context.theme.mutedForeground,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: context.theme.card,
              padding: const EdgeInsets.all(8),
            ),
          ),
      ],
    );
  }

  Widget _buildAccountInfoCard(DoctorDetail doctor) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: AppLocalizations.of(context).translate('email_label'),
            value: doctor.email.isNotEmpty
                ? doctor.email
                : AppLocalizations.of(context).translate('not_updated'),
            isLast: false,
          ),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: AppLocalizations.of(context).translate('phone_label'),
            value: doctor.phone != null && doctor.phone!.isNotEmpty
                ? doctor.phone!
                : AppLocalizations.of(context).translate('not_updated'),
            isLast: false,
          ),
          _buildInfoRow(
            icon: Icons.cake_outlined,
            label: AppLocalizations.of(context).translate('dob_label'),
            value: doctor.dateOfBirth != null
                ? DateFormat('dd/MM/yyyy').format(doctor.dateOfBirth!)
                : AppLocalizations.of(context).translate('not_updated'),
            isLast: false,
          ),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: AppLocalizations.of(context).translate('gender_label'),
            value: doctor.isMale
                ? AppLocalizations.of(context).translate('male')
                : AppLocalizations.of(context).translate('female'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoCard(DoctorDetail doctor) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        children: [
          if (doctor.specialties.isNotEmpty) ...[
            _buildContentPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('specialty_label'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: doctor.specialties
                        .map(
                          (e) => Chip(
                            label: Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.theme.primary,
                              ),
                            ),
                            backgroundColor: context.theme.primary.withAlpha(
                              26,
                            ), // 0.1 * 255
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.theme.border),
          ],
          if (doctor.workLocations.isNotEmpty) ...[
            _buildContentPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).translate('work_location_label'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...doctor.workLocations.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: context.theme.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.theme.textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: context.theme.border),
          ],
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('introduction_label'),
            content: doctor.introduction,
            isHtml: true,
          ),
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('position_label'),
            listItems: doctor.position,
          ),
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('experience_label'),
            listItems: doctor.experience,
          ),
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('training_label'),
            listItems: doctor.trainingProcess,
          ),
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('awards_label'),
            listItems: doctor.awards,
          ),
          _buildExpansionItem(
            title: AppLocalizations.of(context).translate('membership_label'),
            listItems: doctor.memberships,
            // Only hide divider if this is effectively the last item
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(DoctorDetail doctor) {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_reviewError != null) {
      return Center(child: Text(_reviewError!));
    }
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppLocalizations.of(context).translate('no_reviews_yet'),
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(_reviews[index]);
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
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
            child: Text(
              AppLocalizations.of(context).translate('view_all_reviews'),
              style: TextStyle(color: context.theme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      elevation: 0,
      color: context.theme.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.theme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: context.theme.primary.withAlpha(
                    26,
                  ), // 0.1 * 255
                  child: Text(
                    review.authorName.isNotEmpty
                        ? review.authorName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: context.theme.primary,
                      fontSize: 14,
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
                        review.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: context.theme.yellow,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(review.createdAt.toLocal()),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              review.body,
              style: TextStyle(
                fontSize: 13,
                color: context.theme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPadding({required Widget child}) {
    return Padding(padding: const EdgeInsets.all(16), child: child);
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: context.theme.mutedForeground, size: 22),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.theme.textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: context.theme.border),
      ],
    );
  }

  Widget _buildExpansionItem({
    required String title,
    String? content,
    List<String>? listItems,
    bool isHtml = false,
    bool isLast = false,
  }) {
    if ((content == null || content.isEmpty) &&
        (listItems == null || listItems.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.theme.textColor,
              ),
            ),
            iconColor: context.theme.primary,
            collapsedIconColor: context.theme.mutedForeground,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: isHtml
                    ? _buildHtmlContent(content!)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: listItems!
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: context.theme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          height: 1.5,
                                          fontSize: 14,
                                          color: context.theme.mutedForeground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: context.theme.border),
      ],
    );
  }

  Widget _buildHtmlContent(String content) {
    String htmlContent;
    try {
      final deltaJson = jsonDecode(content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = content.replaceAll('\n', '<br>');
    }

    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          fontSize: FontSize(14),
          color: context.theme.mutedForeground,
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
        ),
      },
      onLinkTap: (url, _, __) async {
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
    );
  }
}
