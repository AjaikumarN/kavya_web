import 'package:flutter/material.dart';

class KTColors {
  KTColors._();

  // Brand
  static const primary = Color(0xFFE65100);
  static const primaryDark = Color(0xFFBF360C);
  static const primaryLight = Color(0xFFFFCCBC);

  // Role accent colors
  static const roleAdmin = Color(0xFFB71C1C);
  static const roleManager = Color(0xFF0D47A1);
  static const roleFleet = Color(0xFF1B5E20);
  static const roleAccountant = Color(0xFFF57F17);
  static const roleAssociate = Color(0xFF4A148C);
  static const roleDriver = Color(0xFF006064);
  static const roleAuditor = Color(0xFF37474F);

  // Semantic
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF9A825);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF01579B);

  // Surface
  static const cardSurface = Color(0xFFFAFAFA);
  static const cardSurfaceDark = Color(0xFF1E1E1E);
  static const background = Color(0xFFF5F5F5);

  // Text
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);

  // Divider
  static const divider = Color(0xFFE0E0E0);

  static Color roleColor(String role) {
    switch (role) {
      case 'admin':
        return roleAdmin;
      case 'manager':
        return roleManager;
      case 'fleet_manager':
        return roleFleet;
      case 'accountant':
        return roleAccountant;
      case 'project_associate':
        return roleAssociate;
      case 'driver':
        return roleDriver;
      case 'auditor':
        return roleAuditor;
      default:
        return primary;
    }
  }

  static String roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'fleet_manager':
        return 'Fleet Manager';
      case 'accountant':
        return 'Accountant';
      case 'project_associate':
        return 'Project Associate';
      case 'driver':
        return 'Driver';
      case 'auditor':
        return 'Auditor';
      default:
        return role;
    }
  }
}
