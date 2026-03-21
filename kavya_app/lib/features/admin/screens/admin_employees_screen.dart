import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/kt_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell_screen.dart';

class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState
    extends ConsumerState<AdminEmployeesScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const _roles = [null, 'MANAGER', 'PROJECT_ASSOCIATE', 'FLEET_MANAGER', 'ACCOUNTANT', 'DRIVER'];
  static const _labels = ['All', 'Manager', 'PA', 'Fleet', 'Accountant', 'Driver'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminEmployeeSearchProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(adminEmployeesProvider);
    final activeRole = ref.watch(adminEmployeeRoleFilter);

    return Scaffold(
      backgroundColor: KTColors.darkBg,
      appBar: AppBar(
        backgroundColor: KTColors.darkSurface,
        title: Row(
          children: [
            const Text('Employees',
                style: TextStyle(color: KTColors.darkTextPrimary)),
            const SizedBox(width: 8),
            employees.when(
              data: (list) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: KTColors.info.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${list.length}',
                    style:
                        const TextStyle(color: KTColors.info, fontSize: 12)),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => context.push('/admin/employees/create'),
          ),
          const ComplianceBellButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminEmployeesProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Search ──
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              style: const TextStyle(color: KTColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: 'Search employees…',
                hintStyle: const TextStyle(color: KTColors.darkTextSecondary),
                prefixIcon:
                    const Icon(Icons.search, color: KTColors.darkTextSecondary),
                filled: true,
                fillColor: KTColors.darkSurface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            // ── Role chips ──
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(_roles.length, (i) {
                final active = activeRole == _roles[i];
                return ChoiceChip(
                  label: Text(_labels[i]),
                  selected: active,
                  selectedColor: KTColors.amber600,
                  backgroundColor: KTColors.darkSurface,
                  labelStyle: TextStyle(
                    color:
                        active ? Colors.white : KTColors.darkTextSecondary,
                    fontSize: 12,
                  ),
                  onSelected: (_) =>
                      ref.read(adminEmployeeRoleFilter.notifier).state =
                          _roles[i],
                );
              }),
            ),
            const SizedBox(height: 14),

            // ── Employee list ──
            employees.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(
                        child: Text('No employees found',
                            style: TextStyle(
                                color: KTColors.darkTextSecondary))),
                  );
                }
                return Column(
                  children: list.map<Widget>((e) {
                    final m = e as Map<String, dynamic>;
                    return _employeeTile(context, m);
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                  height: 120,
                  child: Center(
                      child: CircularProgressIndicator(
                          color: KTColors.amber600))),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: KTColors.danger)),
            ),

            // ── Add employee button ──
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/admin/employees/create'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: KTColors.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: KTColors.darkBorder, width: 0.5),
                ),
                child: const Center(
                    child: Text('+ Add employee',
                        style: TextStyle(
                            color: KTColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15))),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _employeeTile(BuildContext context, Map<String, dynamic> m) {
    final name = '${m['first_name'] ?? ''} ${(m['last_name'] ?? '').toString().isNotEmpty ? '${(m['last_name'] as String).substring(0, 1)}.' : ''}'.trim();
    final role = m['role'] as String? ?? m['primary_role'] as String? ?? '';
    final roleDisplay = _roleLabel(role);
    final isActive = m['is_active'] == true;
    final roleColor = _roleColor(role);

    return GestureDetector(
      onTap: () => context.push('/admin/employees/${m['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KTColors.darkSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: roleColor.withAlpha(30),
              child: Text(
                name.isNotEmpty
                    ? name.substring(0, name.length.clamp(0, 2)).toUpperCase()
                    : '?',
                style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isNotEmpty ? name : 'Unknown',
                      style: const TextStyle(
                          color: KTColors.darkTextPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(roleDisplay,
                      style: const TextStyle(
                          color: KTColors.darkTextSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isActive
                    ? KTColors.success.withAlpha(20)
                    : Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                    color: isActive ? KTColors.success : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role.toUpperCase()) {
      case 'MANAGER':
        return 'Manager';
      case 'PROJECT_ASSOCIATE':
        return 'Project Associate';
      case 'FLEET_MANAGER':
        return 'Fleet Manager';
      case 'ACCOUNTANT':
        return 'Accountant';
      case 'DRIVER':
        return 'Driver';
      case 'ADMIN':
        return 'Admin';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'MANAGER':
        return KTColors.info;
      case 'PROJECT_ASSOCIATE':
        return KTColors.amber600;
      case 'FLEET_MANAGER':
        return KTColors.success;
      case 'ACCOUNTANT':
        return const Color(0xFF7C3AED);
      case 'DRIVER':
        return const Color(0xFF0D9488);
      default:
        return KTColors.info;
    }
  }
}
