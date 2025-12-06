class PermissionConstants {
  static const List<String> resources = [
    'doctors',
    'patients',
    'staff',
    'specialties',
    'work-locations',
    'blogs',
    'questions',
    'reviews',
    'permissions',
  ];

  static const List<String> actions = [
    'read',
    'create',
    'update',
    'delete',
    'manage',
  ];

  static String formatResourceName(String resource) {
    return resource
        .split('-')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }

  static String formatActionName(String action) {
    return action.isNotEmpty
        ? '${action[0].toUpperCase()}${action.substring(1)}'
        : action;
  }
}
