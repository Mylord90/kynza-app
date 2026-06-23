enum UserRole {
  owner,
  manager,
  staff,
  client;

  static UserRole fromString(String v) =>
      values.firstWhere((r) => r.name == v, orElse: () => UserRole.client);

  bool get canViewWallet => this == owner;
  bool get canManageTeam => this == owner;
  bool get canViewAllRevenue => this == owner;
  bool get canViewMarketing => this == owner || this == manager;
  bool get canViewAllClients => this == owner || this == manager;
}
