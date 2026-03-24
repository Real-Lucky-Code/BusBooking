import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  late Future<List<UserInfo>> _usersFuture;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _statusFilter = 'All';
  String _sortBy = 'name'; // name, email, role, status
  
  // Pagination variables
  late ScrollController _scrollController;
  List<UserInfo> _allUsers = [];
  List<UserInfo> _displayedUsers = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _usersFuture = _loadUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreUsers();
      }
    }
  }

  void _loadMoreUsers() {
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final filtered = _filterAndSort(_allUsers);
        final newPage = _currentPage + 1;
        final startIndex = newPage * _itemsPerPage;
        
        if (startIndex < filtered.length) {
          final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
          setState(() {
            _displayedUsers.addAll(filtered.sublist(startIndex, endIndex));
            _currentPage = newPage;
            _hasMoreData = endIndex < filtered.length;
            _isLoadingMore = false;
          });
        } else {
          setState(() {
            _hasMoreData = false;
            _isLoadingMore = false;
          });
        }
      }
    });
  }

  Future<List<UserInfo>> _loadUsers() async {
    try {
      return await AdminService.instance.getAllUsers();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _usersFuture = _loadUsers();
    });
    try {
      final users = await _usersFuture;
      setState(() {
        _allUsers = users;
        _currentPage = 0;
        _displayedUsers.clear();
        _isLoadingMore = false;
        _hasMoreData = true;
        
        // Load first page
        final filtered = _filterAndSort(_allUsers);
        final endIndex = (_itemsPerPage).clamp(0, filtered.length);
        if (filtered.isNotEmpty) {
          _displayedUsers = filtered.sublist(0, endIndex);
          _hasMoreData = endIndex < filtered.length;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _deactivateUser(int userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vô hiệu hóa người dùng?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người dùng "$userName" sẽ không thể đăng nhập vào hệ thống.'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Hành động này không thể hoàn tác trực tiếp.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.instance.deactivateUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã vô hiệu hóa người dùng "$userName"'),
            backgroundColor: Colors.red.shade600,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _reactivateUser(int userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kích hoạt lại người dùng?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người dùng "$userName" sẽ có thể đăng nhập lại vào hệ thống.'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Tất cả dữ liệu của người dùng sẽ được khôi phục.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Kích hoạt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AdminService.instance.reactivateUser(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã kích hoạt lại người dùng "$userName"'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<UserInfo> _filterAndSort(List<UserInfo> users) {
    var filtered = users
        .where((u) =>
            (_searchQuery.isEmpty ||
                u.email.toLowerCase().contains(_searchQuery) ||
                u.fullName.toLowerCase().contains(_searchQuery)) &&
            (_roleFilter == 'All' || u.role == _roleFilter) &&
            (_statusFilter == 'All' ||
                (_statusFilter == 'Active' && u.isActive) ||
                (_statusFilter == 'Inactive' && !u.isActive)))
        .toList();

    // Sort
    switch (_sortBy) {
      case 'email':
        filtered.sort((a, b) => a.email.compareTo(b.email));
        break;
      case 'role':
        filtered.sort((a, b) => a.role.compareTo(b.role));
        break;
      case 'status':
        filtered.sort((a, b) => b.isActive == a.isActive ? 0 : (b.isActive ? -1 : 1));
        break;
      default: // name
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản lý người dùng'),
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<UserInfo>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data != null) {
              _allUsers = snapshot.data!;
              if (_displayedUsers.isEmpty) {
                final filtered = _filterAndSort(_allUsers);
                final endIndex = (_itemsPerPage).clamp(0, filtered.length);
                if (filtered.isNotEmpty) {
                  _displayedUsers = filtered.sublist(0, endIndex);
                  _hasMoreData = endIndex < filtered.length;
                }
              }
            }

            final filtered = _filterAndSort(_allUsers);

            // Calculate stats
            final activeCount = _allUsers.where((u) => u.isActive).length;
            final inactiveCount = _allUsers.length - activeCount;
            final userCount = _allUsers.where((u) => u.role == 'User').length;
            final providerCount = _allUsers.where((u) => u.role == 'Provider').length;
            final adminCount = _allUsers.where((u) => u.role == 'Admin').length;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              child: Column(
                children: [
                  // Statistics cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.people,
                            label: 'Tổng',
                            value: _allUsers.length.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.check_circle,
                            label: 'Hoạt động',
                            value: activeCount.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.remove_circle,
                            label: 'Bị vô hiệu',
                            value: inactiveCount.toString(),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Role breakdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.medium,
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoleBreakdown(
                            label: 'Khách hàng',
                            count: userCount,
                            color: Colors.blue,
                            icon: Icons.person,
                          ),
                          _RoleBreakdown(
                            label: 'Nhà xe',
                            count: providerCount,
                            color: Colors.orange,
                            icon: Icons.business,
                          ),
                          _RoleBreakdown(
                            label: 'Quản trị',
                            count: adminCount,
                            color: Colors.red,
                            icon: Icons.admin_panel_settings,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search and filters
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Search
                        TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                              _currentPage = 0;
                              _displayedUsers.clear();
                            });
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                final newFiltered = _filterAndSort(_allUsers);
                                final endIndex = (_itemsPerPage).clamp(0, newFiltered.length);
                                setState(() {
                                  if (newFiltered.isNotEmpty) {
                                    _displayedUsers = newFiltered.sublist(0, endIndex);
                                    _hasMoreData = endIndex < newFiltered.length;
                                  }
                                });
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm theo email hoặc tên...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => setState(() => _searchQuery = ''),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filter and sort row
                        Row(
                          children: [
                            Expanded(
                              child: _FilterButton(
                                label: _roleFilter == 'All' ? 'Vai trò' : _roleFilter,
                                onTap: () => _showRoleFilter(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _statusFilter != 'All' ? Colors.red : Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  color: _statusFilter != 'All' ? Colors.red.shade50 : Colors.white,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showStatusFilter(),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _statusFilter == 'All' ? 'Trạng thái' : _statusFilter,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _statusFilter != 'All' ? Colors.red : Colors.black87,
                                              fontWeight: _statusFilter != 'All' ? FontWeight.bold : FontWeight.normal,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_drop_down,
                                            size: 18,
                                            color: _statusFilter != 'All' ? Colors.red : Colors.grey.shade600,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FilterButton(
                                label: 'Sắp xếp',
                                onTap: () => _showSortOptions(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Users list
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Displayed users list
                          ..._displayedUsers.map((user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserCard(
                              user: user,
                              onDeactivate: () => _deactivateUser(user.id, user.fullName),
                              onReactivate: () => _reactivateUser(user.id, user.fullName),
                            ),
                          )),

                          // Loading indicator
                          if (_isLoadingMore)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Đang tải thêm...',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),

                          // End of list indicator
                          if (!_hasMoreData && _displayedUsers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 32,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Đã hiển thị tất cả ${_displayedUsers.length}/${filtered.length} người dùng',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showRoleFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: ['All', 'User', 'Provider', 'Admin']
            .map(
              (role) => ListTile(
                title: Text(role),
                trailing: _roleFilter == role ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _roleFilter = role;
                    _currentPage = 0;
                    _displayedUsers.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredUsers();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Lọc theo trạng thái',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('Tất cả'),
                subtitle: const Text('Hiển thị tất cả người dùng'),
                trailing: _statusFilter == 'All' ? const Icon(Icons.check, color: Colors.blue) : null,
                selected: _statusFilter == 'All',
                onTap: () {
                  setState(() {
                    _statusFilter = 'All';
                    _currentPage = 0;
                    _displayedUsers.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredUsers();
                },
              ),
              ListTile(
                title: const Text('Hoạt động'),
                subtitle: const Text('Chỉ người dùng hoạt động'),
                trailing: _statusFilter == 'Active' ? const Icon(Icons.check, color: Colors.green) : null,
                selected: _statusFilter == 'Active',
                onTap: () {
                  setState(() {
                    _statusFilter = 'Active';
                    _currentPage = 0;
                    _displayedUsers.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredUsers();
                },
              ),
              ListTile(
                title: const Text('Bị vô hiệu hóa'),
                subtitle: const Text('Chỉ người dùng bị vô hiệu hóa'),
                trailing: _statusFilter == 'Inactive' ? const Icon(Icons.check, color: Colors.red) : null,
                selected: _statusFilter == 'Inactive',
                onTap: () {
                  setState(() {
                    _statusFilter = 'Inactive';
                    _currentPage = 0;
                    _displayedUsers.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredUsers();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ('name', 'Theo tên'),
          ('email', 'Theo email'),
          ('role', 'Theo vai trò'),
          ('status', 'Theo trạng thái'),
        ]
            .map(
              (item) => ListTile(
                title: Text(item.$2),
                trailing: _sortBy == item.$1 ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortBy = item.$1;
                    _currentPage = 0;
                    _displayedUsers.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredUsers();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _reloadFilteredUsers() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final filtered = _filterAndSort(_allUsers);
        final endIndex = (_itemsPerPage).clamp(0, filtered.length);
        setState(() {
          if (filtered.isNotEmpty) {
            _displayedUsers = filtered.sublist(0, endIndex);
            _hasMoreData = endIndex < filtered.length;
          } else {
            _displayedUsers.clear();
            _hasMoreData = false;
          }
        });
      }
    });
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final UserInfo user;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  Color _getRoleColor() {
    switch (user.role) {
      case 'Admin':
        return Colors.red;
      case 'Provider':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon() {
    switch (user.role) {
      case 'Admin':
        return Icons.admin_panel_settings;
      case 'Provider':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.medium,
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: user.isActive ? Colors.transparent : Colors.red.shade200,
          width: user.isActive ? 0 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Can add user detail page here
          borderRadius: AppRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with avatar, info and status
                Row(
                  children: [
                    // Avatar with role background
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRoleColor().withOpacity(0.8),
                            _getRoleColor().withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getRoleColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getRoleIcon(),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Status indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: user.isActive ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.isActive ? 'Hoạt động' : 'Bị vô hiệu hóa',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: user.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Role badge and menu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getRoleColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getRoleColor().withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            user.role == 'User'
                                ? 'Khách hàng'
                                : user.role == 'Provider'
                                    ? 'Nhà xe'
                                    : 'Quản trị',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getRoleColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (user.isActive)
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.block, size: 18, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('Vô hiệu hóa'),
                                  ],
                                ),
                                onTap: onDeactivate,
                              ),
                            ],
                          )
                        else
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text('Kích hoạt lại'),
                                  ],
                                ),
                                onTap: onReactivate,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RoleBreakdown extends StatelessWidget {
  const _RoleBreakdown({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

