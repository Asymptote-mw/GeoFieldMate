import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/field_record.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../core/constants/colors.dart';
import '../field_entry/record_detail_screen.dart';

/// Screen for searching and filtering field records
class SearchFilterScreen extends StatefulWidget {
  final String? projectId; // Optional: search within specific project

  const SearchFilterScreen({super.key, this.projectId});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _searchController = TextEditingController();

  List<FieldRecord> _allRecords = [];
  List<FieldRecord> _filteredRecords = [];
  bool _isLoading = true;

  // Filter options
  String? _selectedRockType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _hasLocation = false;
  bool _hasMeasurements = false;
  String _sortBy = 'date_desc'; // date_desc, date_asc, rock_type

  final List<String> _rockTypes = [
    'All',
    'igneous',
    'sedimentary',
    'metamorphic'
  ];
  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Rock Type',
    'Dip Angle',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      List<FieldRecord> records;

      if (widget.projectId != null) {
        records = await _dbHelper.getFieldRecordsByProject(widget.projectId!);
      } else {
        // Load all records from all projects
        final projects = await _dbHelper.getAllProjects();
        final List<FieldRecord> allRecords = [];
        for (final project in projects) {
          final projectRecords =
              await _dbHelper.getFieldRecordsByProject(project.id);
          allRecords.addAll(projectRecords);
        }
        records = allRecords;
      }

      setState(() {
        _allRecords = records;
        _filteredRecords = records;
        _isLoading = false;
      });

      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading records: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<FieldRecord> filtered = List.from(_allRecords);

    // Text search
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      filtered = filtered.where((record) {
        return record.rockType.toLowerCase().contains(searchText) ||
            (record.specificRockName?.toLowerCase().contains(searchText) ??
                false) ||
            record.notes.toLowerCase().contains(searchText) ||
            (record.locationName?.toLowerCase().contains(searchText) ?? false);
      }).toList();
    }

    // Rock type filter
    if (_selectedRockType != null && _selectedRockType != 'All') {
      filtered = filtered
          .where((record) => record.rockType == _selectedRockType)
          .toList();
    }

    // Date range filter
    if (_startDate != null) {
      filtered = filtered.where((record) {
        return record.timestamp.isAfter(_startDate!) ||
            record.timestamp.isAtSameMomentAs(_startDate!);
      }).toList();
    }

    if (_endDate != null) {
      final endOfDay =
          DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      filtered = filtered.where((record) {
        return record.timestamp.isBefore(endOfDay) ||
            record.timestamp.isAtSameMomentAs(endOfDay);
      }).toList();
    }

    // Location filter
    if (_hasLocation) {
      filtered = filtered.where((record) {
        return record.latitude != null && record.longitude != null;
      }).toList();
    }

    // Measurements filter
    if (_hasMeasurements) {
      filtered = filtered.where((record) {
        return record.dip != null && record.strike != null;
      }).toList();
    }

    // Sort results
    switch (_sortBy) {
      case 'date_desc':
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case 'date_asc':
        filtered.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case 'rock_type':
        filtered.sort((a, b) => a.rockType.compareTo(b.rockType));
        break;
      case 'dip':
        filtered.sort((a, b) {
          final dipA = a.dip ?? -1;
          final dipB = b.dip ?? -1;
          return dipB.compareTo(dipA);
        });
        break;
    }

    setState(() {
      _filteredRecords = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRockType = null;
      _startDate = null;
      _endDate = null;
      _hasLocation = false;
      _hasMeasurements = false;
      _sortBy = 'date_desc';
      _filteredRecords = _allRecords;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Rock Type Filter
                const Text('Rock Type',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _rockTypes.map((type) {
                    final isSelected = _selectedRockType == type ||
                        (type == 'All' && _selectedRockType == null);
                    return ChoiceChip(
                      label: Text(type == 'All' ? type : type.toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setModalState(() {
                          setState(() {
                            _selectedRockType = type == 'All' ? null : type;
                            _applyFilters();
                          });
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Date Range
                const Text('Date Range',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectDate(context, true);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_startDate == null
                            ? 'Start Date'
                            : DateFormat('MMM d, yyyy').format(_startDate!)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('to'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _selectDate(context, false);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(_endDate == null
                            ? 'End Date'
                            : DateFormat('MMM d, yyyy').format(_endDate!)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Additional Filters
                const Text('Additional Filters',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SwitchListTile(
                  title: const Text('Has Location Data'),
                  value: _hasLocation,
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _hasLocation = value;
                        _applyFilters();
                      });
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Has Measurements'),
                  subtitle: const Text('Dip and Strike recorded'),
                  value: _hasMeasurements,
                  onChanged: (value) {
                    setModalState(() {
                      setState(() {
                        _hasMeasurements = value;
                        _applyFilters();
                      });
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Records'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by rock type, location, notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Filter button
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 4),
                        const Text('Filters'),
                        if (_hasActiveFilters())
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              _getActiveFilterCount().toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onSelected: (_) => _showFilterBottomSheet(),
                  ),
                  const SizedBox(width: 8),

                  // Sort dropdown
                  DropdownButton<String>(
                    value: _sortBy,
                    underline: Container(),
                    items: [
                      DropdownMenuItem(
                          value: 'date_desc', child: Text('Newest First')),
                      DropdownMenuItem(
                          value: 'date_asc', child: Text('Oldest First')),
                      DropdownMenuItem(
                          value: 'rock_type', child: Text('Rock Type')),
                      DropdownMenuItem(value: 'dip', child: Text('Dip Angle')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                          _applyFilters();
                        });
                      }
                    },
                  ),

                  // Active filter chips
                  if (_selectedRockType != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_selectedRockType!.toUpperCase()),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _selectedRockType = null;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                  if (_startDate != null || _endDate != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        _startDate != null && _endDate != null
                            ? 'Date Range'
                            : _startDate != null
                                ? 'After ${DateFormat('MMM d').format(_startDate!)}'
                                : 'Before ${DateFormat('MMM d').format(_endDate!)}',
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _applyFilters();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredRecords.length} result${_filteredRecords.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecords.length,
                          itemBuilder: (context, index) {
                            final record = _filteredRecords[index];
                            return _buildRecordCard(record);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedRockType != null ||
        _startDate != null ||
        _endDate != null ||
        _hasLocation ||
        _hasMeasurements;
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedRockType != null) count++;
    if (_startDate != null || _endDate != null) count++;
    if (_hasLocation) count++;
    if (_hasMeasurements) count++;
    return count;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No records found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(FieldRecord record) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');

    Color rockTypeColor;
    switch (record.rockType.toLowerCase()) {
      case 'igneous':
        rockTypeColor = AppColors.igneous;
        break;
      case 'sedimentary':
        rockTypeColor = AppColors.sedimentary;
        break;
      case 'metamorphic':
        rockTypeColor = AppColors.metamorphic;
        break;
      default:
        rockTypeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordDetailScreen(record: record),
            ),
          );
          if (result == true) {
            _loadRecords();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: rockTypeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      record.rockType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rockTypeColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dateFormat.format(record.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (record.specificRockName != null) ...[
                Text(
                  record.specificRockName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (record.dip != null || record.strike != null) ...[
                Row(
                  children: [
                    const Icon(Icons.architecture, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Dip: ${record.dip ?? 'N/A'}° | Strike: ${record.strike ?? 'N/A'}°',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (record.locationName != null ||
                  (record.latitude != null && record.longitude != null)) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.locationName ??
                            '${record.latitude!.toStringAsFixed(4)}, ${record.longitude!.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
