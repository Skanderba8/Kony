import 'dart:io';
import 'package:flutter/services.dart';
import 'package:kony/models/photo.dart' show Photo;
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
import 'package:http/http.dart' as http;

class PdfGenerationService {
  Future<Map<String, Uint8List>> _downloadImages(
    TechnicalVisitReport report,
  ) async {
    final Map<String, Uint8List> imageCache = {};

    Future<void> downloadImage(String url, String id) async {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          imageCache[id] = response.bodyBytes;
        }
      } catch (e) {
        print('Error downloading image $id: $e');
      }
    }

    for (final floor in report.floors) {
      // Network Cabinets
      for (final component in floor.networkCabinets) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Perforations
      for (final component in floor.perforations) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Access Traps
      for (final component in floor.accessTraps) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Cable Paths
      for (final component in floor.cablePaths) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Cable Trunkings
      for (final component in floor.cableTrunkings) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Conduits
      for (final component in floor.conduits) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Copper Cablings
      for (final component in floor.copperCablings) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Fiber Optic Cablings
      for (final component in floor.fiberOpticCablings) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }

      // Custom Components
      for (final component in floor.customComponents) {
        for (final photo in component.photos) {
          if (photo.url.isNotEmpty) {
            await downloadImage(photo.url, photo.id);
          }
        }
      }
    }

    print('Downloaded ${imageCache.length} images total');
    return imageCache;
  }

  Future<File> generateTechnicalReportPdf(TechnicalVisitReport report) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);

    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      regularFont = pw.Font.ttf(regularData);
      boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      print('Could not load custom fonts: $e');
    }

    final imageCache = await _downloadImages(report);
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(report, regularFont, boldFont),
        footer: (context) => _buildFooter(regularFont),
        build:
            (context) => [
              _buildTitleSection(report, regularFont, boldFont, dateFormat),
              pw.SizedBox(height: 30),
              _buildBasicInfoSection(report, regularFont, boldFont, dateFormat),
              pw.SizedBox(height: 25),
              _buildProjectContextSection(report, regularFont, boldFont),
              pw.SizedBox(height: 25),
              ..._buildComponentSections(
                report,
                regularFont,
                boldFont,
                imageCache,
              ),
              _buildConclusionSection(report, regularFont, boldFont),
            ],
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName =
        'Rapport_Technique_${report.clientName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await _uploadPdfToFirestore(report, file);
    return file;
  }

  pw.Widget _buildHeader(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 20),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue, width: 3),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KONY',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.Text(
                'Solutions Réseaux Professionnelles',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Text(
            report.clientName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Font? regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 15),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Document confidentiel',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTitleSection(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'RAPPORT DE VISITE TECHNIQUE',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            report.clientName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.location,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date de visite: ${dateFormat.format(report.date)}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 13,
              color: PdfColors.black,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBasicInfoSection(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
    DateFormat dateFormat,
  ) {
    return _buildSection(
      'INFORMATIONS GÉNÉRALES',
      [
        _buildInfoGrid(
          [
            ['Client', report.clientName],
            ['Lieu d\'intervention', report.location],
            ['Date de visite', dateFormat.format(report.date)],
            ['Chef de projet', report.projectManager],
            ['Techniciens', report.technicians.join(', ')],
            if (report.accompanyingPerson.isNotEmpty)
              ['Personne accompagnatrice', report.accompanyingPerson],
          ],
          regularFont,
          boldFont,
        ),
      ],
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildProjectContextSection(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
  ) {
    return _buildSection(
      'CONTEXTE DU PROJET',
      [
        pw.Text(
          report.projectContext,
          style: pw.TextStyle(font: regularFont, fontSize: 12, height: 1.5),
          textAlign: pw.TextAlign.justify,
        ),
      ],
      regularFont,
      boldFont,
    );
  }

  List<pw.Widget> _buildComponentSections(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    final sections = <pw.Widget>[];

    // Network Cabinets
    final allCabinets = _collectAllComponentsOfType<NetworkCabinet>(
      report.floors,
      (floor) => floor.networkCabinets,
    );
    if (allCabinets.isNotEmpty) {
      sections.add(
        _buildNetworkCabinetSection(
          allCabinets,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Perforations
    final allPerforations = _collectAllComponentsOfType<Perforation>(
      report.floors,
      (floor) => floor.perforations,
    );
    if (allPerforations.isNotEmpty) {
      sections.add(
        _buildPerforationSection(
          allPerforations,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Access Traps
    final allAccessTraps = _collectAllComponentsOfType<AccessTrap>(
      report.floors,
      (floor) => floor.accessTraps,
    );
    if (allAccessTraps.isNotEmpty) {
      sections.add(
        _buildAccessTrapSection(
          allAccessTraps,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Cable Paths
    final allCablePaths = _collectAllComponentsOfType<CablePath>(
      report.floors,
      (floor) => floor.cablePaths,
    );
    if (allCablePaths.isNotEmpty) {
      sections.add(
        _buildCablePathSection(
          allCablePaths,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Cable Trunkings
    final allCableTrunkings = _collectAllComponentsOfType<CableTrunking>(
      report.floors,
      (floor) => floor.cableTrunkings,
    );
    if (allCableTrunkings.isNotEmpty) {
      sections.add(
        _buildCableTrunkingSection(
          allCableTrunkings,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Conduits
    final allConduits = _collectAllComponentsOfType<Conduit>(
      report.floors,
      (floor) => floor.conduits,
    );
    if (allConduits.isNotEmpty) {
      sections.add(
        _buildConduitSection(allConduits, regularFont, boldFont, imageCache),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Copper Cablings
    final allCopperCablings = _collectAllComponentsOfType<CopperCabling>(
      report.floors,
      (floor) => floor.copperCablings,
    );
    if (allCopperCablings.isNotEmpty) {
      sections.add(
        _buildCopperCablingSection(
          allCopperCablings,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Fiber Optic Cablings
    final allFiberOpticCablings =
        _collectAllComponentsOfType<FiberOpticCabling>(
          report.floors,
          (floor) => floor.fiberOpticCablings,
        );
    if (allFiberOpticCablings.isNotEmpty) {
      sections.add(
        _buildFiberOpticCablingSection(
          allFiberOpticCablings,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    // Custom Components
    final allCustomComponents = _collectAllComponentsOfType<CustomComponent>(
      report.floors,
      (floor) => floor.customComponents,
    );
    if (allCustomComponents.isNotEmpty) {
      sections.add(
        _buildCustomComponentSection(
          allCustomComponents,
          regularFont,
          boldFont,
          imageCache,
        ),
      );
      sections.add(pw.SizedBox(height: 25));
    }

    return sections;
  }

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
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'BAIES INFORMATIQUES',
      cabinets.asMap().entries.map((entry) {
        final index = entry.key;
        final cabinetData = entry.value;
        final cabinet = cabinetData['component'] as NetworkCabinet;
        final floorName = cabinetData['floor'] as String;

        return _buildComponentCard(
          'Baie ${index + 1}: ${cabinet.name}',
          floorName,
          [
            ['Emplacement', cabinet.location],
            ['État', cabinet.cabinetState],
            ['Alimentation', cabinet.isPowered ? 'Oui' : 'Non'],
            ['Prises disponibles', cabinet.availableOutlets.toString()],
            ['Unités rack total', cabinet.totalRackUnits.toString()],
            ['Unités rack disponibles', cabinet.availableRackUnits.toString()],
            if (cabinet.notes.isNotEmpty) ['Remarques', cabinet.notes],
          ],
          cabinet.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildPerforationSection(
    List<Map<String, dynamic>> perforations,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'PERCEMENTS',
      perforations.asMap().entries.map((entry) {
        final index = entry.key;
        final perforationData = entry.value;
        final perforation = perforationData['component'] as Perforation;
        final floorName = perforationData['floor'] as String;

        return _buildComponentCard(
          'Percement ${index + 1}',
          floorName,
          [
            ['Emplacement', perforation.location],
            ['Type de mur/plancher', perforation.wallType],
            ['Épaisseur (cm)', perforation.wallDepth.toString()],
            if (perforation.notes.isNotEmpty) ['Remarques', perforation.notes],
          ],
          perforation.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildAccessTrapSection(
    List<Map<String, dynamic>> accessTraps,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'TRAPPES D\'ACCÈS',
      accessTraps.asMap().entries.map((entry) {
        final index = entry.key;
        final trapData = entry.value;
        final trap = trapData['component'] as AccessTrap;
        final floorName = trapData['floor'] as String;

        return _buildComponentCard(
          'Trappe d\'accès ${index + 1}',
          floorName,
          [
            ['Emplacement', trap.location],
            ['Dimensions', trap.trapSize],
            if (trap.notes.isNotEmpty) ['Remarques', trap.notes],
          ],
          trap.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildCablePathSection(
    List<Map<String, dynamic>> cablePaths,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'CHEMINS DE CÂBLES',
      cablePaths.asMap().entries.map((entry) {
        final index = entry.key;
        final pathData = entry.value;
        final path = pathData['component'] as CablePath;
        final floorName = pathData['floor'] as String;

        return _buildComponentCard(
          'Chemin de câbles ${index + 1}',
          floorName,
          [
            ['Emplacement', path.location],
            ['Dimensions', path.size],
            ['Longueur (m)', path.lengthInMeters.toString()],
            ['Type de fixation', path.fixationType],
            ['Visible', path.isVisible ? 'Oui' : 'Non'],
            ['Intérieur', path.isInterior ? 'Oui' : 'Non'],
            ['Hauteur (m)', path.heightInMeters.toString()],
            if (path.notes.isNotEmpty) ['Remarques', path.notes],
          ],
          path.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildCableTrunkingSection(
    List<Map<String, dynamic>> cableTrunkings,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'GOULOTTES',
      cableTrunkings.asMap().entries.map((entry) {
        final index = entry.key;
        final trunkingData = entry.value;
        final trunking = trunkingData['component'] as CableTrunking;
        final floorName = trunkingData['floor'] as String;

        return _buildComponentCard(
          'Goulotte ${index + 1}',
          floorName,
          [
            ['Emplacement', trunking.location],
            ['Dimensions', trunking.size],
            ['Longueur (m)', trunking.lengthInMeters.toString()],
            ['Angles intérieurs', trunking.innerAngles.toString()],
            ['Angles extérieurs', trunking.outerAngles.toString()],
            ['Angles plats', trunking.flatAngles.toString()],
            ['Intérieur', trunking.isInterior ? 'Oui' : 'Non'],
            ['Hauteur (m)', trunking.workHeight.toString()],
            if (trunking.notes.isNotEmpty) ['Remarques', trunking.notes],
          ],
          trunking.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildConduitSection(
    List<Map<String, dynamic>> conduits,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'CONDUITS',
      conduits.asMap().entries.map((entry) {
        final index = entry.key;
        final conduitData = entry.value;
        final conduit = conduitData['component'] as Conduit;
        final floorName = conduitData['floor'] as String;

        return _buildComponentCard(
          'Conduit ${index + 1}',
          floorName,
          [
            ['Emplacement', conduit.location],
            ['Diamètre', conduit.size],
            ['Longueur (m)', conduit.lengthInMeters.toString()],
            ['Intérieur', conduit.isInterior ? 'Oui' : 'Non'],
            ['Hauteur (m)', conduit.workHeight.toString()],
            if (conduit.notes.isNotEmpty) ['Remarques', conduit.notes],
          ],
          conduit.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildCopperCablingSection(
    List<Map<String, dynamic>> copperCablings,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'CÂBLAGES CUIVRE',
      copperCablings.asMap().entries.map((entry) {
        final index = entry.key;
        final cablingData = entry.value;
        final cabling = cablingData['component'] as CopperCabling;
        final floorName = cablingData['floor'] as String;

        return _buildComponentCard(
          'Câblage cuivre ${index + 1}',
          floorName,
          [
            ['Emplacement', cabling.location],
            ['Description du trajet', cabling.pathDescription],
            ['Catégorie', cabling.category],
            ['Longueur (m)', cabling.lengthInMeters.toString()],
            ['Intérieur', cabling.isInterior ? 'Oui' : 'Non'],
            ['Hauteur (m)', cabling.workHeight.toString()],
            if (cabling.notes.isNotEmpty) ['Remarques', cabling.notes],
          ],
          cabling.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildFiberOpticCablingSection(
    List<Map<String, dynamic>> fiberOpticCablings,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'CÂBLAGES FIBRE OPTIQUE',
      fiberOpticCablings.asMap().entries.map((entry) {
        final index = entry.key;
        final cablingData = entry.value;
        final cabling = cablingData['component'] as FiberOpticCabling;
        final floorName = cablingData['floor'] as String;

        return _buildComponentCard(
          'Câblage fibre optique ${index + 1}',
          floorName,
          [
            ['Emplacement', cabling.location],
            ['Type de fibre', cabling.fiberType],
            ['Nombre de tiroirs', cabling.drawerCount.toString()],
            ['Nombre de conduits', cabling.conduitCount.toString()],
            ['Longueur (m)', cabling.lengthInMeters.toString()],
            ['Intérieur', cabling.isInterior ? 'Oui' : 'Non'],
            ['Hauteur (m)', cabling.workHeight.toString()],
            if (cabling.notes.isNotEmpty) ['Remarques', cabling.notes],
          ],
          cabling.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildCustomComponentSection(
    List<Map<String, dynamic>> components,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return _buildSection(
      'COMPOSANTS PERSONNALISÉS',
      components.asMap().entries.map((entry) {
        final index = entry.key;
        final componentData = entry.value;
        final component = componentData['component'] as CustomComponent;
        final floorName = componentData['floor'] as String;

        return _buildComponentCard(
          'Composant ${index + 1}: ${component.name}',
          floorName,
          [
            ['Description', component.description],
            ['Emplacement', component.location],
            if (component.notes.isNotEmpty) ['Remarques', component.notes],
          ],
          component.photos,
          regularFont,
          boldFont,
          imageCache,
        );
      }).toList(),
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildConclusionSection(
    TechnicalVisitReport report,
    pw.Font? regularFont,
    pw.Font? boldFont,
  ) {
    return _buildSection(
      'CONCLUSIONS ET RECOMMANDATIONS',
      [
        pw.Text(
          report.conclusion,
          style: pw.TextStyle(font: regularFont, fontSize: 12, height: 1.5),
          textAlign: pw.TextAlign.justify,
        ),
        if (report.assumptions.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text(
            'Hypothèses et prérequis :',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          ...report.assumptions.map(
            (assumption) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(font: regularFont, fontSize: 12),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      assumption,
                      style: pw.TextStyle(font: regularFont, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'DURÉE ESTIMÉE DU PROJET',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${report.estimatedDurationDays} JOUR${report.estimatedDurationDays > 1 ? 'S' : ''}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
      regularFont,
      boldFont,
    );
  }

  pw.Widget _buildSection(
    String title,
    List<pw.Widget> children,
    pw.Font? regularFont,
    pw.Font? boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey800,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildComponentCard(
    String title,
    String floorName,
    List<List<String>> properties,
    List<Photo> photos,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 15),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$title - $floorName',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoGrid(properties, regularFont, boldFont),
          if (photos.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Text(
              'PHOTOS (${photos.length})',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildPhotosGrid(
                photos,
                regularFont,
                boldFont,
                imageCache,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoGrid(
    List<List<String>> properties,
    pw.Font? regularFont,
    pw.Font? boldFont,
  ) {
    return pw.Column(
      children:
          properties
              .map(
                (property) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 130,
                        child: pw.Text(
                          '${property[0]} :',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          property[1],
                          style: pw.TextStyle(font: regularFont, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  List<pw.Widget> _buildPhotosGrid(
    List<Photo> photos,
    pw.Font? regularFont,
    pw.Font? boldFont,
    Map<String, Uint8List> imageCache,
  ) {
    return photos.asMap().entries.map((entry) {
      final index = entry.key;
      final photo = entry.value;

      pw.Widget imageWidget;
      if (imageCache.containsKey(photo.id)) {
        try {
          final imageData = imageCache[photo.id]!;
          imageWidget = pw.Container(
            height: 60,
            width: 100,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Image(
              pw.MemoryImage(imageData),
              height: 60,
              width: 100,
              fit: pw.BoxFit.cover,
            ),
          );
        } catch (e) {
          print('Error displaying image ${photo.id}: $e');
          imageWidget = _buildImagePlaceholder(index, regularFont);
        }
      } else {
        print('Image not found in cache: ${photo.id}');
        imageWidget = _buildImagePlaceholder(index, regularFont);
      }

      return pw.Container(
        width: 100,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            imageWidget,
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Photo ${index + 1}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (photo.comment.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      photo.comment,
                      style: pw.TextStyle(
                        font: regularFont,
                        fontSize: 6,
                        height: 1.2,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _buildImagePlaceholder(int index, pw.Font? regularFont) {
    return pw.Container(
      height: 60,
      width: 100,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'Photo ${index + 1}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '(voir numérique)',
            style: pw.TextStyle(font: regularFont, fontSize: 6),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _uploadPdfToFirestore(
    TechnicalVisitReport report,
    File pdfFile,
  ) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await FirebaseFirestore.instance
          .collection('technical_visit_reports')
          .doc(report.id)
          .update({
            'pdfGenerated': true,
            'pdfGeneratedAt': DateTime.now().toIso8601String(),
            'pdfSizeInBytes': bytes.length,
          });
      print('PDF metadata updated in Firestore for report: ${report.id}');
    } catch (e) {
      print('Error updating PDF metadata in Firestore: $e');
    }
  }
}
