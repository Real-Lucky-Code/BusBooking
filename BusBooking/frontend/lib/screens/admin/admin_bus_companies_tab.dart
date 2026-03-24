import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/admin_service.dart';

class AdminBusCompaniesTab extends StatefulWidget {
  const AdminBusCompaniesTab({super.key});

  @override
  State<AdminBusCompaniesTab> createState() => _AdminBusCompaniesTabState();
}

class _AdminBusCompaniesTabState extends State<AdminBusCompaniesTab> {
  late Future<List<BusCompanyInfo>> _companiesFuture;
  bool _isRefreshing = false;
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, approved, pending, rejected
  String _activeFilter = 'All'; // All, Active, Inactive
  String _sortBy = 'name'; // name, status, date
  
  // Pagination variables
  late ScrollController _scrollController;
  List<BusCompanyInfo> _allCompanies = [];
  List<BusCompanyInfo> _displayedCompanies = [];
  int _currentPage = 0;
  static const int _itemsPerPage = 10;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _companiesFuture = _loadCompanies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreCompanies();
      }
    }
  }

  void _loadMoreCompanies() {
    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        final filtered = _filterAndSort(_allCompanies);
        final newPage = _currentPage + 1;
        final startIndex = newPage * _itemsPerPage;
        
        if (startIndex < filtered.length) {
          final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
          setState(() {
            _displayedCompanies.addAll(filtered.sublist(startIndex, endIndex));
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

  Future<List<BusCompanyInfo>> _loadCompanies() async {
    try {
      return await AdminService.instance.getAllBusCompanies();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _companiesFuture = _loadCompanies();
    });
    try {
      final companies = await _companiesFuture;
      setState(() {
        _allCompanies = companies;
        _currentPage = 0;
        _displayedCompanies.clear();
        _isLoadingMore = false;
        _hasMoreData = true;
        
        // Load first page
        final filtered = _filterAndSort(_allCompanies);
        final endIndex = (_itemsPerPage).clamp(0, filtered.length);
        if (filtered.isNotEmpty) {
          _displayedCompanies = filtered.sublist(0, endIndex);
          _hasMoreData = endIndex < filtered.length;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _deactivateCompany(int companyId, String companyName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vô hiệu hóa nhà xe?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhà xe "$companyName" sẽ không thể quản lý chuyến đi.'),
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
      await AdminService.instance.deactivateCompany(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã vô hiệu hóa nhà xe "$companyName"'),
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

  Future<void> _reactivateCompany(int companyId, String companyName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kích hoạt lại nhà xe?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nhà xe "$companyName" sẽ có thể quản lý chuyến đi lại.'),
            const SizedBox(height: 8),
            const Text(
              'Lưu ý: Tất cả dữ liệu của nhà xe sẽ được khôi phục.',
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
      await AdminService.instance.reactivateCompany(companyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã kích hoạt lại nhà xe "$companyName"'),
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

  List<BusCompanyInfo> _filterAndSort(List<BusCompanyInfo> companies) {
    var filtered = companies
        .where((c) =>
            (_searchQuery.isEmpty || c.name.toLowerCase().contains(_searchQuery)) &&
            (_statusFilter == 'All' || c.status.toLowerCase() == _statusFilter.toLowerCase()) &&
            (_activeFilter == 'All' ||
                (_activeFilter == 'Active' && c.isActive) ||
                (_activeFilter == 'Inactive' && !c.isActive)))
        .toList();

    // Sort
    switch (_sortBy) {
      case 'status':
        filtered.sort((a, b) => a.status.compareTo(b.status));
        break;
      case 'active':
        filtered.sort((a, b) => b.isActive == a.isActive ? 0 : (b.isActive ? -1 : 1));
        break;
      default: // name
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Quản lý nhà xe'),
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
        child: FutureBuilder<List<BusCompanyInfo>>(
          future: _companiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data != null) {
              _allCompanies = snapshot.data!;
              if (_displayedCompanies.isEmpty) {
                final filtered = _filterAndSort(_allCompanies);
                final endIndex = (_itemsPerPage).clamp(0, filtered.length);
                if (filtered.isNotEmpty) {
                  _displayedCompanies = filtered.sublist(0, endIndex);
                  _hasMoreData = endIndex < filtered.length;
                }
              }
            }

            final filtered = _filterAndSort(_allCompanies);

            // Calculate stats
            final approvedCount = _allCompanies.where((c) => c.status.toLowerCase() == 'approved').length;
            final pendingCount = _allCompanies.where((c) => c.status.toLowerCase() == 'pending').length;
            final rejectedCount = _allCompanies.where((c) => c.status.toLowerCase() == 'rejected').length;
            final activeCount = _allCompanies.where((c) => c.isActive).length;
            final inactiveCount = _allCompanies.length - activeCount;

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
                            icon: Icons.business,
                            label: 'Tổng',
                            value: _allCompanies.length.toString(),
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.check_circle,
                            label: 'Phê duyệt',
                            value: approvedCount.toString(),
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.schedule,
                            label: 'Chờ duyệt',
                            value: pendingCount.toString(),
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status breakdown
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
                          _StatusBreakdown(
                            label: 'Hoạt động',
                            count: activeCount,
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                          _StatusBreakdown(
                            label: 'Vô hiệu',
                            count: inactiveCount,
                            color: Colors.red,
                            icon: Icons.cancel,
                          ),
                          _StatusBreakdown(
                            label: 'Từ chối',
                            count: rejectedCount,
                            color: Colors.grey,
                            icon: Icons.block,
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
                              _displayedCompanies.clear();
                            });
                            Future.delayed(const Duration(milliseconds: 100), () {
                              if (mounted) {
                                final newFiltered = _filterAndSort(_allCompanies);
                                final endIndex = (_itemsPerPage).clamp(0, newFiltered.length);
                                setState(() {
                                  if (newFiltered.isNotEmpty) {
                                    _displayedCompanies = newFiltered.sublist(0, endIndex);
                                    _hasMoreData = endIndex < newFiltered.length;
                                  }
                                });
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên nhà xe...',
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
                                label: _statusFilter == 'All' ? 'Trạng thái' : _statusFilter,
                                onTap: () => _showStatusFilter(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _FilterButton(
                                label: _activeFilter == 'All' ? 'Hoạt động' : _activeFilter,
                                onTap: () => _showActiveFilter(),
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

                  // Companies list
                  if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.business_center, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy nhà xe',
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
                          // Displayed companies list
                          ..._displayedCompanies.map((company) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CompanyCard(
                              company: company,
                              onDeactivate: () => _deactivateCompany(company.id, company.name),
                              onReactivate: () => _reactivateCompany(company.id, company.name),
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
                          if (!_hasMoreData && _displayedCompanies.isNotEmpty)
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
                                    'Đã hiển thị tất cả ${_displayedCompanies.length}/${filtered.length} nhà xe',
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

  void _showStatusFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Lọc theo trạng thái phê duyệt',
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
                trailing: _statusFilter == 'All' ? const Icon(Icons.check, color: Colors.blue) : null,
                selected: _statusFilter == 'All',
                onTap: () {
                  setState(() {
                    _statusFilter = 'All';
                    _currentPage = 0;
                    _displayedCompanies.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredCompanies();
                },
              ),
              ListTile(
                title: const Text('Đã phê duyệt'),
                trailing: _statusFilter == 'approved' ? const Icon(Icons.check, color: Colors.green) : null,
                selected: _statusFilter == 'approved',
                onTap: () {
                  setState(() {
                    _statusFilter = 'approved';
                    _currentPage = 0;
                    _displayedCompanies.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredCompanies();
                },
              ),
              ListTile(
                title: const Text('Chờ phê duyệt'),
                trailing: _statusFilter == 'pending' ? const Icon(Icons.check, color: Colors.orange) : null,
                selected: _statusFilter == 'pending',
                onTap: () {
                  setState(() {
                    _statusFilter = 'pending';
                    _currentPage = 0;
                    _displayedCompanies.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredCompanies();
                },
              ),
              ListTile(
                title: const Text('Bị từ chối'),
                trailing: _statusFilter == 'rejected' ? const Icon(Icons.check, color: Colors.red) : null,
                selected: _statusFilter == 'rejected',
                onTap: () {
                  setState(() {
                    _statusFilter = 'rejected';
                    _currentPage = 0;
                    _displayedCompanies.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredCompanies();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showActiveFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('Tất cả'),
            trailing: _activeFilter == 'All' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _activeFilter = 'All';
                _currentPage = 0;
                _displayedCompanies.clear();
              });
              Navigator.pop(context);
              _reloadFilteredCompanies();
            },
          ),
          ListTile(
            title: const Text('Hoạt động'),
            trailing: _activeFilter == 'Active' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _activeFilter = 'Active';
                _currentPage = 0;
                _displayedCompanies.clear();
              });
              Navigator.pop(context);
              _reloadFilteredCompanies();
            },
          ),
          ListTile(
            title: const Text('Vô hiệu hóa'),
            trailing: _activeFilter == 'Inactive' ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() {
                _activeFilter = 'Inactive';
                _currentPage = 0;
                _displayedCompanies.clear();
              });
              Navigator.pop(context);
              _reloadFilteredCompanies();
            },
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
          ('status', 'Theo trạng thái'),
          ('active', 'Theo hoạt động'),
        ]
            .map(
              (item) => ListTile(
                title: Text(item.$2),
                trailing: _sortBy == item.$1 ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _sortBy = item.$1;
                    _currentPage = 0;
                    _displayedCompanies.clear();
                  });
                  Navigator.pop(context);
                  _reloadFilteredCompanies();
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _reloadFilteredCompanies() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final filtered = _filterAndSort(_allCompanies);
        final endIndex = (_itemsPerPage).clamp(0, filtered.length);
        setState(() {
          if (filtered.isNotEmpty) {
            _displayedCompanies = filtered.sublist(0, endIndex);
            _hasMoreData = endIndex < filtered.length;
          } else {
            _displayedCompanies.clear();
            _hasMoreData = false;
          }
        });
      }
    });
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.onDeactivate,
    required this.onReactivate,
  });

  final BusCompanyInfo company;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;

  Color _getStatusColor() {
    switch (company.status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel() {
    switch (company.status.toLowerCase()) {
      case 'approved':
        return 'Đã phê duyệt';
      case 'pending':
        return 'Chờ duyệt';
      case 'rejected':
        return 'Bị từ chối';
      default:
        return 'Không xác định';
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
          color: company.isActive ? Colors.transparent : Colors.red.shade200,
          width: company.isActive ? 0 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: AppRadius.medium,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with avatar, info and status
                Row(
                  children: [
                    // Avatar with status background
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor().withOpacity(0.8),
                            _getStatusColor().withOpacity(0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.business,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Company info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            company.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Status indicator
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: company.isActive ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  company.isActive ? 'Hoạt động' : 'Bị vô hiệu hóa',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: company.isActive ? Colors.green.shade700 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Status badge and menu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor().withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _getStatusLabel(),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (company.isActive)
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

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({
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
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
