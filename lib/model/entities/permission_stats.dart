class PermissionStats {
  final int totalPermissions;
  final int totalGroups;
  final int totalUserPermissions;
  final int totalGroupPermissions;
  final int totalUserGroupMemberships;
  final List<MostUsedPermission> mostUsedPermissions;
  final List<LargestGroup> largestGroups;

  PermissionStats({
    required this.totalPermissions,
    required this.totalGroups,
    required this.totalUserPermissions,
    required this.totalGroupPermissions,
    required this.totalUserGroupMemberships,
    required this.mostUsedPermissions,
    required this.largestGroups,
  });

  factory PermissionStats.fromJson(Map<String, dynamic> json) {
    return PermissionStats(
      totalPermissions: json['totalPermissions'] ?? 0,
      totalGroups: json['totalGroups'] ?? 0,
      totalUserPermissions: json['totalUserPermissions'] ?? 0,
      totalGroupPermissions: json['totalGroupPermissions'] ?? 0,
      totalUserGroupMemberships: json['totalUserGroupMemberships'] ?? 0,
      mostUsedPermissions:
          (json['mostUsedPermissions'] as List?)
              ?.map((e) => MostUsedPermission.fromJson(e))
              .toList() ??
          [],
      largestGroups:
          (json['largestGroups'] as List?)
              ?.map((e) => LargestGroup.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class MostUsedPermission {
  final String permissionId;
  final String resource;
  final String action;
  final int usageCount;

  MostUsedPermission({
    required this.permissionId,
    required this.resource,
    required this.action,
    required this.usageCount,
  });

  factory MostUsedPermission.fromJson(Map<String, dynamic> json) {
    return MostUsedPermission(
      permissionId: json['permissionId'] ?? '',
      resource: json['resource'] ?? '',
      action: json['action'] ?? '',
      usageCount: json['usageCount'] ?? 0,
    );
  }
}

class LargestGroup {
  final String groupId;
  final String groupName;
  final int memberCount;

  LargestGroup({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  factory LargestGroup.fromJson(Map<String, dynamic> json) {
    return LargestGroup(
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      memberCount: json['memberCount'] ?? 0,
    );
  }
}
