import 'package:flutter/material.dart';
import '../../../data/models/field_record.dart';
import '../../../data/models/project.dart';
import '../../../data/repositories/database_helper.dart';
import '../../../data/services/interpretation_service.dart';
import '../../../core/constants/colors.dart';

/// Screen for AI-powered geological interpretation
class InterpretationScreen extends StatefulWidget {
  final String projectId;

  const InterpretationScreen({super.key, required this.projectId});

  @override
  State<InterpretationScreen> createState() => _InterpretationScreenState();
}

class _InterpretationScreenState extends State<InterpretationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Project? _project;
  List<FieldRecord> _records = [];
  GeologicalInterpretation? _interpretation;
  bool _isLoading = true;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      _project = await _dbHelper.getProject(widget.projectId);
      _records = await _dbHelper.getFieldRecordsByProject(widget.projectId);

      // Filter records with measurements
      _records =
          _records.where((r) => r.dip != null && r.strike != null).toList();
    } catch (e) {
      setState(() => _error = 'Failed to load data: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _analyzeData() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No structural measurements available for analysis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _error = null;
    });

    try {
      final interpretation =
          await InterpretationService.analyzeRecords(_records);
      setState(() {
        _interpretation = interpretation;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Analysis failed: $e';
        _isAnalyzing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to analyze data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geological Interpretation'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _project?.name ?? 'Unknown Project',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.description, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                  '${_records.length} measurements with dip/strike data'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Disclaimer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.warning.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology, color: AppColors.warning),
                            const SizedBox(width: 8),
                            const Text(
                              'AI Interpretation Assistant',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '⚠️ This tool provides suggestions based on field data patterns. '
                          'All interpretations should be verified in the field and are not definitive conclusions. '
                          'Use as a supplementary analysis tool only.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Analyze button
                  if (_interpretation == null)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ready to analyze ${_records.length} field observations',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _isAnalyzing ? null : _analyzeData,
                            icon: _isAnalyzing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(_isAnalyzing
                                ? 'Analyzing...'
                                : 'Generate Interpretation'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Interpretation results
                  if (_interpretation != null) ...[
                    _buildInterpretationResults(),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _analyzeData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Re-analyze'),
                      ),
                    ),
                  ],

                  // Error display
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInterpretationResults() {
    if (_interpretation == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        Card(
          color: AppColors.primaryGreen.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.summarize, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text(
                      'Geological Context',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _interpretation!.summary,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Data Quality
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.data_usage, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Data Quality Assessment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_interpretation!.dataQuality),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Interpretations
        const Text(
          'Possible Interpretations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        ...(_interpretation!.interpretations.asMap().entries.map((entry) {
          final index = entry.key;
          final interp = entry.value;
          return _buildInterpretationCard(interp, index + 1);
        })),

        const SizedBox(height: 16),

        // Field verification needed
        Card(
          color: AppColors.info.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user, color: AppColors.info),
                    SizedBox(width: 8),
                    Text(
                      'Field Verification Needed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...(_interpretation!.fieldVerificationNeeded.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 16, color: AppColors.info),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterpretationCard(Interpretation interp, int number) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with confidence
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: interp.getConfidenceColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${interp.confidence.toUpperCase()} CONFIDENCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: interp.getConfidenceColor(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$number. ${interp.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              interp.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),

            // Reasoning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geological Reasoning:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    interp.reasoning,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Evidence
            const Text(
              'Supporting Evidence:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ...(interp.evidence.map((ev) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                        child: Text(ev, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              );
            })),
            const SizedBox(height: 12),

            // Recommendations
            const Text(
              'Additional Data Needed:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            ...(interp.recommendations.map((rec) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_right,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(rec, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }
}
