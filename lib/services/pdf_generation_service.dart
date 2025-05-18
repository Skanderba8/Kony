import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kony/models/report_sections/custom_component.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_sections/network_cabinet.dart';
import '../models/report_sections/perforation.dart';
import '../models/report_sections/access_trap.dart';
import '../models/report_sections/cable_path.dart';
import '../models/report_sections/cable_trunking.dart';
import '../models/report_sections/conduit.dart';
import '../models/report_sections/copper_cabling.dart';
import '../models/report_sections/fiber_optic_cabling.dart';
import '../models/floor.dart';
import '../models/technical_visit_report.dart';
import 'package:intl/intl.dart';

class PdfGenerationService {
  Future<File> generateTechnicalReportPdf(TechnicalVisitReport report) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    // Try to load custom font (fallback to default if not available)
    pw.Font? font;
    try {
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      font = pw.Font.ttf(fontData);
    } catch (e) {
      print('Could not load custom font: $e');
    }

    // Format dates
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader(report, font, context),
        footer: (context) => _buildFooter(context, font),
        build:
            (pw.Context context) => [
              // Title and Header
              pw.SizedBox(height: 40),

              // Basic Information Section
              _buildBasicInfoSection(report, font, dateFormat),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Project Context Section
              _buildProjectContextSection(report, font),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 20),

              // Technical Components by Type (not by floor)
              ..._buildComponentSectionsByType(report, font),

              // Conclusion Section
              _buildConclusionSection(report, font),
            ],
      ),
    );

    // Save PDF to device storage
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/rapport_visite_technique_${report.id}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    // Optional: Upload PDF to Firestore
    await _uploadPdfToFirestore(report, file);

    return file;
  }

  pw.Widget _buildReportHeader(
    TechnicalVisitReport report,
    pw.Font? font,
    pw.Context context,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RAPPORT DE VISITE TECHNIQUE',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Kony - Solutions Réseaux Professionnelles',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context, pw.Font? font) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700),
      ),
    );
  }

  pw.Widget _buildBasicInfoSection(
    TechnicalVisitReport report,
    pw.Font? font,
    DateFormat dateFormat,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Informations Générales',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            children: [
              _buildInfoRow('Client', report.clientName, font),
              _buildInfoRow('Lieu', report.location, font),
              _buildInfoRow(
                'Date de visite',
                dateFormat.format(report.date),
                font,
              ),
              _buildInfoRow(
                'Responsable de projet',
                report.projectManager,
                font,
              ),
              _buildInfoRow('Techniciens', report.technicians.join(", "), font),
              if (report.accompanyingPerson.isNotEmpty)
                _buildInfoRow('Accompagnant', report.accompanyingPerson, font),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInfoRow(String label, String value, pw.Font? font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value, style: pw.TextStyle(font: font))),
        ],
      ),
    );
  }

  pw.Widget _buildProjectContextSection(
    TechnicalVisitReport report,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Contexte du Projet',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Text(
            report.projectContext,
            style: pw.TextStyle(font: font),
            textAlign: pw.TextAlign.justify,
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildComponentSectionsByType(
    TechnicalVisitReport report,
    pw.Font? font,
  ) {
    final List<pw.Widget> sections = [];

    // Network Cabinets section
    final allCabinets = _collectAllComponentsOfType<NetworkCabinet>(
      report.floors,
      (floor) => floor.networkCabinets,
    );

    if (allCabinets.isNotEmpty) {
      sections.add(_buildNetworkCabinetSection(allCabinets, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Perforations section
    final allPerforations = _collectAllComponentsOfType<Perforation>(
      report.floors,
      (floor) => floor.perforations,
    );

    if (allPerforations.isNotEmpty) {
      sections.add(_buildPerforationSection(allPerforations, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Access Traps section
    final allAccessTraps = _collectAllComponentsOfType<AccessTrap>(
      report.floors,
      (floor) => floor.accessTraps,
    );

    if (allAccessTraps.isNotEmpty) {
      sections.add(_buildAccessTrapSection(allAccessTraps, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Cable Paths section
    final allCablePaths = _collectAllComponentsOfType<CablePath>(
      report.floors,
      (floor) => floor.cablePaths,
    );

    if (allCablePaths.isNotEmpty) {
      sections.add(_buildCablePathSection(allCablePaths, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Cable Trunkings section
    final allCableTrunkings = _collectAllComponentsOfType<CableTrunking>(
      report.floors,
      (floor) => floor.cableTrunkings,
    );

    if (allCableTrunkings.isNotEmpty) {
      sections.add(_buildCableTrunkingSection(allCableTrunkings, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Conduits section
    final allConduits = _collectAllComponentsOfType<Conduit>(
      report.floors,
      (floor) => floor.conduits,
    );

    if (allConduits.isNotEmpty) {
      sections.add(_buildConduitSection(allConduits, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Copper Cablings section
    final allCopperCablings = _collectAllComponentsOfType<CopperCabling>(
      report.floors,
      (floor) => floor.copperCablings,
    );

    if (allCopperCablings.isNotEmpty) {
      sections.add(_buildCopperCablingSection(allCopperCablings, font));
      sections.add(pw.SizedBox(height: 20));
    }

    // Fiber Optic Cablings section
    final allFiberOpticCablings =
        _collectAllComponentsOfType<FiberOpticCabling>(
          report.floors,
          (floor) => floor.fiberOpticCablings,
        );

    if (allFiberOpticCablings.isNotEmpty) {
      sections.add(_buildFiberOpticCablingSection(allFiberOpticCablings, font));
      sections.add(pw.SizedBox(height: 20));
    }
    final allCustomComponents = _collectAllComponentsOfType<CustomComponent>(
      report.floors,
      (floor) => floor.customComponents,
    );

    if (allCustomComponents.isNotEmpty) {
      sections.add(_buildCustomComponentSection(allCustomComponents, font));
      sections.add(pw.SizedBox(height: 20));
    }

    return sections;
  }

  /// Helper method to collect all components of a specific type from all floors
  List<Map<String, dynamic>> _collectAllComponentsOfType<T>(
    List<Floor> floors,
    List<T> Function(Floor) getComponents,
  ) {
    final List<Map<String, dynamic>> allComponents = [];

    for (final floor in floors) {
      final components = getComponents(floor);
      for (final component in components) {
        allComponents.add({'floor': floor.name, 'component': component});
      }
    }

    return allComponents;
  }

  pw.Widget _buildNetworkCabinetSection(
    List<Map<String, dynamic>> cabinets,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Baies Informatiques',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...cabinets.asMap().entries.map((entry) {
          final index = entry.key;
          final cabinetData = entry.value;
          final cabinet = cabinetData['component'] as NetworkCabinet;
          final floorName = cabinetData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Baie ${index + 1}: ${cabinet.name} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', cabinet.location, font),
                    _buildTableRow('État', cabinet.cabinetState, font),
                    _buildTableRow(
                      'Alimentation',
                      cabinet.isPowered ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Prises disponibles',
                      cabinet.availableOutlets.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Unités rack total',
                      cabinet.totalRackUnits.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Unités rack disponibles',
                      cabinet.availableRackUnits.toString(),
                      font,
                    ),
                    if (cabinet.notes.isNotEmpty)
                      _buildTableRow('Remarques', cabinet.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildPerforationSection(
    List<Map<String, dynamic>> perforations,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Percements',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...perforations.asMap().entries.map((entry) {
          final index = entry.key;
          final perforationData = entry.value;
          final perforation = perforationData['component'] as Perforation;
          final floorName = perforationData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Percement ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', perforation.location, font),
                    _buildTableRow(
                      'Type de mur/plancher',
                      perforation.wallType,
                      font,
                    ),
                    _buildTableRow(
                      'Épaisseur (cm)',
                      perforation.wallDepth.toString(),
                      font,
                    ),
                    if (perforation.notes.isNotEmpty)
                      _buildTableRow('Remarques', perforation.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildAccessTrapSection(
    List<Map<String, dynamic>> accessTraps,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Trappes d\'accès',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...accessTraps.asMap().entries.map((entry) {
          final index = entry.key;
          final trapData = entry.value;
          final trap = trapData['component'] as AccessTrap;
          final floorName = trapData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Trappe ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', trap.location, font),
                    _buildTableRow('Dimensions', trap.trapSize, font),
                    if (trap.notes.isNotEmpty)
                      _buildTableRow('Remarques', trap.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildCablePathSection(
    List<Map<String, dynamic>> cablePaths,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Chemins de câbles',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...cablePaths.asMap().entries.map((entry) {
          final index = entry.key;
          final pathData = entry.value;
          final path = pathData['component'] as CablePath;
          final floorName = pathData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Chemin de câbles ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', path.location, font),
                    _buildTableRow('Dimensions', path.size, font),
                    _buildTableRow(
                      'Longueur (m)',
                      path.lengthInMeters.toString(),
                      font,
                    ),
                    _buildTableRow('Type de fixation', path.fixationType, font),
                    _buildTableRow(
                      'Visible',
                      path.isVisible ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Intérieur',
                      path.isInterior ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Hauteur (m)',
                      path.heightInMeters.toString(),
                      font,
                    ),
                    if (path.notes.isNotEmpty)
                      _buildTableRow('Remarques', path.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildCableTrunkingSection(
    List<Map<String, dynamic>> cableTrunkings,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Goulottes',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...cableTrunkings.asMap().entries.map((entry) {
          final index = entry.key;
          final trunkingData = entry.value;
          final trunking = trunkingData['component'] as CableTrunking;
          final floorName = trunkingData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Goulotte ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', trunking.location, font),
                    _buildTableRow('Dimensions', trunking.size, font),
                    _buildTableRow(
                      'Longueur (m)',
                      trunking.lengthInMeters.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Angles intérieurs',
                      trunking.innerAngles.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Angles extérieurs',
                      trunking.outerAngles.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Angles plats',
                      trunking.flatAngles.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Intérieur',
                      trunking.isInterior ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Hauteur (m)',
                      trunking.workHeight.toString(),
                      font,
                    ),
                    if (trunking.notes.isNotEmpty)
                      _buildTableRow('Remarques', trunking.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildConduitSection(
    List<Map<String, dynamic>> conduits,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Conduits',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...conduits.asMap().entries.map((entry) {
          final index = entry.key;
          final conduitData = entry.value;
          final conduit = conduitData['component'] as Conduit;
          final floorName = conduitData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Conduit ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', conduit.location, font),
                    _buildTableRow('Diamètre', conduit.size, font),
                    _buildTableRow(
                      'Longueur (m)',
                      conduit.lengthInMeters.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Intérieur',
                      conduit.isInterior ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Hauteur (m)',
                      conduit.workHeight.toString(),
                      font,
                    ),
                    if (conduit.notes.isNotEmpty)
                      _buildTableRow('Remarques', conduit.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildCopperCablingSection(
    List<Map<String, dynamic>> copperCablings,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Câblages cuivre',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...copperCablings.asMap().entries.map((entry) {
          final index = entry.key;
          final cablingData = entry.value;
          final cabling = cablingData['component'] as CopperCabling;
          final floorName = cablingData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Câblage cuivre ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', cabling.location, font),
                    _buildTableRow(
                      'Description du trajet',
                      cabling.pathDescription,
                      font,
                    ),
                    _buildTableRow('Catégorie', cabling.category, font),
                    _buildTableRow(
                      'Longueur (m)',
                      cabling.lengthInMeters.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Intérieur',
                      cabling.isInterior ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Hauteur (m)',
                      cabling.workHeight.toString(),
                      font,
                    ),
                    if (cabling.notes.isNotEmpty)
                      _buildTableRow('Remarques', cabling.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildFiberOpticCablingSection(
    List<Map<String, dynamic>> fiberOpticCablings,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Câblages fibre optique',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...fiberOpticCablings.asMap().entries.map((entry) {
          final index = entry.key;
          final cablingData = entry.value;
          final cabling = cablingData['component'] as FiberOpticCabling;
          final floorName = cablingData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Câblage fibre optique ${index + 1} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Emplacement', cabling.location, font),
                    _buildTableRow('Type de fibre', cabling.fiberType, font),
                    _buildTableRow(
                      'Nombre de tiroirs',
                      cabling.drawerCount.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Nombre de conduits',
                      cabling.conduitCount.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Longueur (m)',
                      cabling.lengthInMeters.toString(),
                      font,
                    ),
                    _buildTableRow(
                      'Intérieur',
                      cabling.isInterior ? 'Oui' : 'Non',
                      font,
                    ),
                    _buildTableRow(
                      'Hauteur (m)',
                      cabling.workHeight.toString(),
                      font,
                    ),
                    if (cabling.notes.isNotEmpty)
                      _buildTableRow('Remarques', cabling.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildCustomComponentSection(
    List<Map<String, dynamic>> components,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Composants Personnalisés',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        ...components.asMap().entries.map((entry) {
          final index = entry.key;
          final componentData = entry.value;
          final component = componentData['component'] as CustomComponent;
          final floorName = componentData['floor'] as String;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Composant ${index + 1}: ${component.name} ($floorName)',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Table(
                  columnWidths: {
                    0: const pw.FixedColumnWidth(140),
                    1: const pw.FlexColumnWidth(),
                  },
                  children: [
                    _buildTableRow('Description', component.description, font),
                    _buildTableRow('Emplacement', component.location, font),
                    if (component.notes.isNotEmpty)
                      _buildTableRow('Remarques', component.notes, font),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildConclusionSection(
    TechnicalVisitReport report,
    pw.Font? font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Conclusion',
          style: pw.TextStyle(
            font: font,
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                report.conclusion,
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.justify,
              ),

              if (report.assumptions.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Hypothèses et prérequis:',
                  style: pw.TextStyle(
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children:
                      report.assumptions.map((assumption) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                margin: const pw.EdgeInsets.only(
                                  top: 3,
                                  right: 5,
                                ),
                                width: 5,
                                height: 5,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.black,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  assumption,
                                  style: pw.TextStyle(font: font, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ],

              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Durée estimée du déploiement:',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    '${report.estimatedDurationDays} jours',
                    style: pw.TextStyle(
                      font: font,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build table rows
  pw.TableRow _buildTableRow(String label, String value, pw.Font? font) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
        ),
      ],
    );
  }

  // Upload PDF to Firestore
  Future<void> _uploadPdfToFirestore(
    TechnicalVisitReport report,
    File pdfFile,
  ) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      // Store metadata only - not the actual PDF content as it would exceed Firestore limits
      await FirebaseFirestore.instance
          .collection('technical_visit_reports')
          .doc(report.id)
          .update({
            'pdfGenerated': true,
            'pdfGeneratedAt': DateTime.now().toIso8601String(),
            'pdfSizeInBytes': bytes.length,
          });

      // Note: In a production app, you would upload the actual PDF to Firebase Storage
      // and then store the download URL in Firestore

      print('PDF metadata updated in Firestore for report: ${report.id}');
    } catch (e) {
      print('Error updating PDF metadata in Firestore: $e');
    }
  }
}
