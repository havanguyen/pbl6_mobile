import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/services/local/profile_cache_service.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view/profile/my_permissions_page.dart';

class ProfileSuperadminPage extends StatefulWidget {
  const ProfileSuperadminPage({super.key});

  @override
  State<ProfileSuperadminPage> createState() => _ProfileSuperadminPageState();
}

class _ProfileSuperadminPageState extends State<ProfileSuperadminPage> {
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
    String? tempError;

    try {
      updatedProfile = await AuthService.getProfile();
    } catch (e) {
      if (!isConnected) {
        tempError = AppLocalizations.of(
          context,
        ).translate('offline_load_error');
      } else {
        tempError =
            "${AppLocalizations.of(context).translate('load_profile_error')}$e";
      }
    }

    if (!mounted) return;

    if (updatedProfile != null) {
      setState(() {
        _currentProfile = updatedProfile;
        _isLoading = false;
      });
    } else {
      if (!isConnected) {
        final cachedProfileMap = await ProfileCacheService.instance
            .getProfile();
        if (cachedProfileMap != null) {
          setState(() {
            _currentProfile = Profile.fromJson(cachedProfileMap);
            _isLoading = false;
            _isOffline = true;
            _error = AppLocalizations.of(context).translate('offline_banner');
          });
        } else {
          setState(() {
            _isLoading = false;
            _error = AppLocalizations.of(context).translate('offline_no_cache');
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _error =
              tempError ??
              AppLocalizations.of(context).translate('cannot_load_profile');
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
        backgroundColor: context.theme.blue,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('personal_information'),
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
                  Routes.editProfile,
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
      return const Center(child: CircularProgressIndicator());
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
        child: Text(AppLocalizations.of(context).translate('no_profile_data')),
      );
    }

    return Column(
      children: [
        if (_isOffline && _error != null)
          Container(
            width: double.infinity,
            color: context.theme.yellow,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.theme.popover),
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
                        AppLocalizations.of(
                          context,
                        ).translate('my_permissions_title'),
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
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: context.theme.primary.withOpacity(0.1),
          child: Text(
            _currentProfile!.fullName.isNotEmpty
                ? _currentProfile!.fullName[0].toUpperCase()
                : 'A',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: context.theme.primary,
            ),
          ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.theme.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoItem(
              context,
              icon: Icons.badge_outlined,
              label: AppLocalizations.of(context).translate('role'),
              value: _currentProfile!.role,
            ),
            _buildInfoItem(
              context,
              icon: Icons.transgender_outlined,
              label: AppLocalizations.of(context).translate('gender_label'),
              value: _currentProfile!.isMale != null
                  ? (_currentProfile!.isMale!
                        ? AppLocalizations.of(context).translate('male')
                        : AppLocalizations.of(context).translate('female'))
                  : AppLocalizations.of(context).translate('not_updated'),
            ),
            _buildInfoItem(
              context,
              icon: Icons.cake_outlined,
              label: AppLocalizations.of(context).translate('dob_label'),
              value:
                  _currentProfile!.dateOfBirth?.toLocal().toString().split(
                    ' ',
                  )[0] ??
                  AppLocalizations.of(context).translate('not_updated'),
            ),
            _buildInfoItem(
              context,
              icon: Icons.phone_outlined,
              label: AppLocalizations.of(context).translate('phone_label'),
              value:
                  _currentProfile!.phone ??
                  AppLocalizations.of(context).translate('not_updated'),
              isLast: true,
            ),
          ],
        ),
      ),
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
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.theme.textColor,
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 32),
      ],
    );
  }
}
