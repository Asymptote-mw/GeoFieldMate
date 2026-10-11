import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/field_record.dart';

/// Service for AI-powered geological interpretation using Google Gemini
class InterpretationService {
  // TODO: Replace with your NEW Gemini API key (after revoking the old one!)
  static const String _apiKey = 'AIzaSyDs8eREfgbAosNK86MLG-faqFN9TVcWONo';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  /// Generate geological interpretation from field recordflutts
  static Future<GeologicalInterpretation> analyzeRecords(
    List<FieldRecord> records,
  ) async {
    if (records.isEmpty) {
      throw Exception('No records provided for analysis');
    }

    // Prepare field data summary
    final String fieldDataSummary = _prepareFieldDataSummary(records);

    final String prompt =
        '''You are a geological interpretation assistant designed to support field-based reasoning, not replace it.

Using structural measurements, lithology, spatial relationships, and elevation data:
1. Identify patterns in strike, dip, and dip direction across multiple observations.
2. Recognize geological scenarios such as fold limbs and hinge zones, faults and offsets, stratigraphic repetition, and bedding younging trends.
3. Suggest possible geological interpretations based on established geological principles.
4. Clearly state the level of confidence and uncertainty for each suggestion.

All interpretations must be conservative, based only on provided field data, and presented as possibilities, not conclusions.

Analyze these field geological observations:

$fieldDataSummary

Respond ONLY with valid JSON in this exact format (no markdown, no code blocks):
{
  "interpretations": [
    {
      "title": "Brief interpretation title",
      "confidence": "low|medium|high",
      "description": "Detailed explanation",
      "reasoning": "Geological principles and data supporting this",
      "evidence": ["Data point 1", "Data point 2"],
      "recommendations": ["Additional data needed 1", "Additional data needed 2"]
    }
  ],
  "summary": "Overall geological context summary",
  "dataQuality": "Assessment of available data quality",
  "fieldVerificationNeeded": ["Specific things to verify in the field"]
}''';

    try {
      // Call Gemini API
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Extract text from Gemini response
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Clean JSON response
        final cleanedJson =
            text.replaceAll('```json', '').replaceAll('```', '').trim();

        final interpretationData = jsonDecode(cleanedJson);
        return GeologicalInterpretation.fromJson(interpretationData);
      } else {
        // Fallback to mock if API fails
        print('API Error: ${response.statusCode} - ${response.body}');
        return _generateMockInterpretation(records);
      }
    } catch (e) {
      // Fallback to mock interpretation if API call fails
      print('API call failed, using mock interpretation: $e');
      return _generateMockInterpretation(records);
    }
  }

  /// Generate mock interpretation for demo/offline mode
  static Future<GeologicalInterpretation> _generateMockInterpretation(
    List<FieldRecord> records,
  ) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Analyze the actual data
    final dipValues =
        records.where((r) => r.dip != null).map((r) => r.dip!).toList();
    final strikeValues =
        records.where((r) => r.strike != null).map((r) => r.strike!).toList();

    double avgDip = 0;
    double dipVariation = 0;
    if (dipValues.isNotEmpty) {
      avgDip = dipValues.reduce((a, b) => a + b) / dipValues.length;
      final minDip = dipValues.reduce((a, b) => a < b ? a : b);
      final maxDip = dipValues.reduce((a, b) => a > b ? a : b);
      dipVariation = (maxDip - minDip).toDouble();
    }

    final interpretations = <Interpretation>[];

    // Check for fold patterns
    if (dipVariation > 20 && dipValues.length >= 3) {
      interpretations.add(Interpretation(
        title: 'Possible Fold Structure',
        confidence: dipVariation > 30 ? 'medium' : 'low',
        description:
            'The observed variation in dip angles (${dipVariation.toStringAsFixed(0)}°) across measurements suggests potential folding. The dip values range from ${dipValues.reduce((a, b) => a < b ? a : b)}° to ${dipValues.reduce((a, b) => a > b ? a : b)}°, which could indicate fold limbs with different orientations.',
        reasoning:
            'In folded terrains, systematic changes in dip direction and magnitude are characteristic. The ${records.length} measurements show dip variation consistent with fold geometry.',
        evidence: [
          'Dip variation of ${dipVariation.toStringAsFixed(0)}° across ${records.length} measurements',
          'Average dip of ${avgDip.toStringAsFixed(0)}°',
          if (strikeValues.isNotEmpty)
            'Strike values: ${strikeValues.join(", ")}°',
        ],
        recommendations: [
          'Measure additional strike/dip on both sides of suspected fold axis',
          'Look for vergence indicators (e.g., parasitic folds, cleavage)',
          'Document any changes in rock type across the structure',
          'Map the spatial distribution of measurements to identify fold axis',
        ],
      ));
    }

    // Check for consistent bedding
    if (dipVariation < 15 && dipValues.length >= 2) {
      interpretations.add(Interpretation(
        title: 'Consistent Bedding Orientation',
        confidence: dipVariation < 10 ? 'high' : 'medium',
        description:
            'Measurements show relatively uniform dip angles (variation only ${dipVariation.toStringAsFixed(0)}°), suggesting a consistent bedding orientation across the study area.',
        reasoning:
            'Consistent structural measurements typically indicate either undeformed or gently tilted strata, a single fold limb, or measurements taken over a limited area.',
        evidence: [
          'Low dip variation (${dipVariation.toStringAsFixed(0)}°)',
          'Average dip: ${avgDip.toStringAsFixed(0)}°',
          'Number of consistent measurements: ${dipValues.length}',
        ],
        recommendations: [
          'Extend measurements over a wider area to test for larger-scale structures',
          'Document stratigraphic younging direction if possible',
          'Look for any minor variations that might indicate local deformation',
        ],
      ));
    }

    // Check for structural features
    final hasStructures = records.any((r) => r.structuralFeatures.isNotEmpty);
    if (hasStructures) {
      final allFeatures =
          records.expand((r) => r.structuralFeatures).toSet().toList();

      interpretations.add(Interpretation(
        title: 'Observed Structural Features',
        confidence: 'medium',
        description:
            'Field observations document structural features including: ${allFeatures.join(", ")}. These provide important constraints on deformation history.',
        reasoning:
            'The presence of ${allFeatures.join(", ")} indicates deformation beyond simple tilting and can indicate fault zones, fold axes, or zones of concentrated strain.',
        evidence: allFeatures.map((f) => 'Observed: $f').toList(),
        recommendations: [
          'Document orientation and kinematics of observed structures',
          'Look for cross-cutting relationships to establish relative timing',
          'Measure any associated foliation or cleavage',
        ],
      ));
    }

    if (interpretations.isEmpty) {
      interpretations.add(Interpretation(
        title: 'Limited Structural Data',
        confidence: 'low',
        description:
            'Current dataset contains ${records.length} measurement(s). More data points needed to establish reliable structural patterns.',
        reasoning:
            'Geological interpretation requires sufficient data density to distinguish between different structural scenarios.',
        evidence: [
          '${records.length} measurement(s) recorded',
          if (dipValues.isNotEmpty) 'Dip: ${dipValues.join(", ")}°',
        ],
        recommendations: [
          'Collect additional measurements across a wider area',
          'Space measurements to capture potential structural variation',
          'Document lithological changes and their relationships to structure',
        ],
      ));
    }

    return GeologicalInterpretation(
      interpretations: interpretations,
      summary:
          'Analysis based on ${records.length} field measurement(s) with ${dipValues.length} dip/strike readings. ${dipVariation > 20 ? "Significant structural variation observed." : "Relatively consistent structural orientation."}',
      dataQuality: dipValues.length >= 5
          ? 'Good: Sufficient measurements for preliminary interpretation'
          : dipValues.length >= 3
              ? 'Moderate: Additional measurements recommended'
              : 'Limited: More data needed for confident interpretation',
      fieldVerificationNeeded: [
        'Verify strike and dip measurements at additional locations',
        'Document stratigraphic relationships and rock types',
        'Look for kinematic indicators',
        'Map the spatial distribution of measurements',
      ],
    );
  }

  /// Prepare field data summary for analysis
  static String _prepareFieldDataSummary(List<FieldRecord> records) {
    final buffer = StringBuffer();

    buffer.writeln('FIELD OBSERVATIONS (${records.length} measurements):');
    buffer.writeln('');

    final sortedRecords = List<FieldRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      buffer.writeln('--- Observation ${i + 1} ---');
      buffer
          .writeln('Lithology: ${record.specificRockName ?? record.rockType}');

      if (record.dip != null && record.strike != null) {
        buffer.writeln('Strike/Dip: ${record.strike}°/${record.dip}°');
      }

      if (record.latitude != null && record.longitude != null) {
        buffer.writeln(
            'Location: ${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}');
      }
      if (record.elevation != null) {
        buffer.writeln('Elevation: ${record.elevation!.toStringAsFixed(1)}m');
      }

      if (record.structuralFeatures.isNotEmpty) {
        buffer.writeln('Structures: ${record.structuralFeatures.join(", ")}');
      }

      if (record.notes.isNotEmpty) {
        buffer.writeln('Notes: ${record.notes}');
      }

      buffer.writeln('');
    }

    return buffer.toString();
  }
}

/// Model for geological interpretation
class GeologicalInterpretation {
  final List<Interpretation> interpretations;
  final String summary;
  final String dataQuality;
  final List<String> fieldVerificationNeeded;

  GeologicalInterpretation({
    required this.interpretations,
    required this.summary,
    required this.dataQuality,
    required this.fieldVerificationNeeded,
  });

  factory GeologicalInterpretation.fromJson(Map<String, dynamic> json) {
    return GeologicalInterpretation(
      interpretations: (json['interpretations'] as List)
          .map((i) => Interpretation.fromJson(i))
          .toList(),
      summary: json['summary'] as String,
      dataQuality: json['dataQuality'] as String,
      fieldVerificationNeeded:
          List<String>.from(json['fieldVerificationNeeded']),
    );
  }
}

/// Individual interpretation
class Interpretation {
  final String title;
  final String confidence;
  final String description;
  final String reasoning;
  final List<String> evidence;
  final List<String> recommendations;

  Interpretation({
    required this.title,
    required this.confidence,
    required this.description,
    required this.reasoning,
    required this.evidence,
    required this.recommendations,
  });

  factory Interpretation.fromJson(Map<String, dynamic> json) {
    return Interpretation(
      title: json['title'] as String,
      confidence: json['confidence'] as String,
      description: json['description'] as String,
      reasoning: json['reasoning'] as String,
      evidence: List<String>.from(json['evidence']),
      recommendations: List<String>.from(json['recommendations']),
    );
  }

  Color getConfidenceColor() {
    switch (confidence.toLowerCase()) {
      case 'high':
        return Color(0xFF4CAF50);
      case 'medium':
        return Color(0xFFFFA726);
      case 'low':
        return Color(0xFFEF5350);
      default:
        return Color(0xFF9E9E9E);
    }
  }
}
