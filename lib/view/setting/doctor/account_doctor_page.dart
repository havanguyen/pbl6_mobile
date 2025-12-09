import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/services/local/profile_cache_service.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view/profile/my_permissions_page.dart';

class AccountDoctorPage extends StatefulWidget {
  const AccountDoctorPage({super.key});

  @override
  State<AccountDoctorPage> createState() => _AccountDoctorPageState();
}

class _AccountDoctorPageState extends State<AccountDoctorPage> {
  Profile? _currentProfile;
  bool _isLoading = true;
  bool _isOffline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _isOffline = false;
      _error = null;
    });

    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = !connectivityResult.contains(ConnectivityResult.none);

    Profile? updatedProfile;
    try {
      updatedProfile = await AuthService.getProfile();
    } catch (e) {
      if (!isConnected) {
        if (mounted) {
          _error = AppLocalizations.of(
            context,
          ).translate('connection_error_loading_cache');
        }
      } else {
        if (mounted) {
          _error =
              "${AppLocalizations.of(context).translate('load_profile_error')}$e";
        }
      }
    }

    if (!mounted) return;

    if (updatedProfile != null) {
      if (updatedProfile.role == 'DOCTOR') {
        setState(() {
          _currentProfile = updatedProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = AppLocalizations.of(
            context,
          ).translate('error_not_doctor_account');
        });
      }
    } else {
      if (!isConnected) {
        final cachedProfileMap = await ProfileCacheService.instance
            .getProfile();
        if (cachedProfileMap != null) {
          if (cachedProfileMap['role'] == 'DOCTOR') {
            setState(() {
              _currentProfile = Profile.fromJson(cachedProfileMap);
              _isLoading = false;
              _isOffline = true;
              _error = AppLocalizations.of(context).translate('offline_banner');
            });
          } else {
            setState(() {
              _isLoading = false;
              _error = AppLocalizations.of(
                context,
              ).translate('cache_error_not_doctor');
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _error = AppLocalizations.of(context).translate('offline_no_cache');
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _error ??= AppLocalizations.of(
            context,
          ).translate('cannot_load_profile');
        });
      }
    }
  }

  Future<void> _reloadProfile() async {
    await _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.primary,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('account_info_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_currentProfile != null && !_isOffline)
            IconButton(
              icon: Icon(Icons.edit, color: context.theme.white),
              onPressed: () async {
                final shouldReload = await Navigator.pushNamed(
                  context,
                  Routes.editAccountDoctor,
                  arguments: _currentProfile,
                );
                if (shouldReload == true) {
                  _reloadProfile();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            color: context.theme.white,
            onPressed: _isLoading ? null : _reloadProfile,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.theme.primary),
      );
    }

    if (_error != null && _currentProfile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.theme.destructive, fontSize: 16),
          ),
        ),
      );
    }

    if (_currentProfile == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_profile_data'),
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      );
    }

    return Column(
      children: [
        if (_isOffline && _error != null)
          Container(
            width: double.infinity,
            color: Colors.amber.shade100, // Keep warning yellow
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reloadProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileHeader(context),
                  const SizedBox(height: 24),
                  _buildInfoCard(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final String? avatarUrl = _currentProfile?.avatarUrl;

    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: context.theme.primary.withOpacity(0.1),
          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
              ? CachedNetworkImageProvider(avatarUrl)
              : null,
          child: (avatarUrl == null || avatarUrl.isEmpty)
              ? Text(
                  _currentProfile!.fullName.isNotEmpty
                      ? _currentProfile!.fullName[0].toUpperCase()
                      : 'D',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: context.theme.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          _currentProfile!.fullName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentProfile!.email,
          style: TextStyle(fontSize: 16, color: context.theme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final genderText = _currentProfile!.isMale != null
        ? (_currentProfile!.isMale!
              ? AppLocalizations.of(context).translate('male')
              : AppLocalizations.of(context).translate('female'))
        : AppLocalizations.of(context).translate('not_updated');

    final dobText = _currentProfile!.dateOfBirth != null
        ? _currentProfile!.dateOfBirth!.toLocal().toIso8601String().split(
            'T',
          )[0]
        : AppLocalizations.of(context).translate('not_updated');

    final phoneText =
        _currentProfile!.phone ??
        AppLocalizations.of(context).translate('not_updated');

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: context.theme.card,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoItem(
                  context,
                  icon: Icons.transgender_outlined,
                  label: AppLocalizations.of(context).translate('gender'),
                  value: genderText,
                ),
                _buildInfoItem(
                  context,
                  icon: Icons.cake_outlined,
                  label: AppLocalizations.of(
                    context,
                  ).translate('date_of_birth'),
                  value: dobText,
                ),
                _buildInfoItem(
                  context,
                  icon: Icons.phone_outlined,
                  label: AppLocalizations.of(context).translate('phone_label'),
                  value: phoneText,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: context.theme.card,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.theme.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.security, color: context.theme.blue),
            ),
            title: Text(
              AppLocalizations.of(context).translate('my_permissions_title'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.theme.textColor,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.theme.grey,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyPermissionsPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: context.theme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.theme.mutedForeground,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.theme.textColor,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 32),
      ],
    );
  }
}
