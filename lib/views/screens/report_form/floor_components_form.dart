// lib/views/screens/report_form/floor_components_form.dart
import 'package:flutter/material.dart';
import 'package:kony/models/report_sections/custom_component.dart';
import 'package:kony/views/widgets/report_form/component_photo_section.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../models/floor.dart';
import '../../widgets/report_form/collapsible_component_card.dart';

// Import all needed model and form components
import '../../../models/report_sections/network_cabinet.dart';
import '../../../models/report_sections/perforation.dart';
import '../../../models/report_sections/access_trap.dart';
import '../../../models/report_sections/cable_path.dart';
import '../../../models/report_sections/cable_trunking.dart';
import '../../../models/report_sections/conduit.dart';
import '../../../models/report_sections/copper_cabling.dart';
import '../../../models/report_sections/fiber_optic_cabling.dart';
import '../../widgets/report_form/form_text_field.dart';
import '../../widgets/report_form/form_number_field.dart';
import '../../widgets/report_form/form_checkbox.dart';
import '../../widgets/report_form/form_dropdown.dart';

/// Form for managing all components for a floor in the technical visit report
class FloorComponentsForm extends StatefulWidget {
  const FloorComponentsForm({super.key});

  @override
  _FloorComponentsFormState createState() => _FloorComponentsFormState();
}

class _FloorComponentsFormState extends State<FloorComponentsForm> {
  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, child) {
        final Floor? currentFloor = viewModel.currentFloor;

        if (currentFloor == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Check if floor has any components
        final hasComponents = currentFloor.totalComponentCount > 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Component selector - only show if no components exist
            if (!hasComponents) _buildComponentSelector(viewModel),

            // Display components by type with collapsible cards
            if (hasComponents) _buildComponentSections(viewModel, currentFloor),

            // If no components, show empty state
            if (!hasComponents) _buildEmptyFloorState(viewModel),
          ],
        );
      },
    );
  }

  Widget _buildComponentSelector(TechnicalVisitReportViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sélectionner un composant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choisissez le type de composant à documenter',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showComponentTypeDialog(viewModel),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Choisir un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build sections for each component type that has components using collapsible cards
  Widget _buildComponentSections(
    TechnicalVisitReportViewModel viewModel,
    Floor floor,
  ) {
    final List<Widget> sections = [];

    // Network cabinets
    if (floor.networkCabinets.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<NetworkCabinet>(
          title: 'Baies Informatiques',
          subtitle: 'Équipements réseau et serveurs',
          icon: Icons.dns_outlined,
          color: Colors.blue,
          items: floor.networkCabinets,
          onAddItem: () => viewModel.addNetworkCabinet(),
          onRemoveItem: (index) => viewModel.removeNetworkCabinet(index),
          addButtonLabel: 'Ajouter une baie',
          emptyStateMessage: 'Aucune baie informatique ajoutée',
          componentType: 'Baie Informatique',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (cabinet, index) => _buildCabinetForm(cabinet, index, viewModel),
        ),
      );
    }

    // Perforations
    if (floor.perforations.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<Perforation>(
          title: 'Percements',
          subtitle: 'Passages de câbles dans murs et planchers',
          icon: Icons.architecture,
          color: Colors.orange,
          items: floor.perforations,
          onAddItem: () => viewModel.addPerforation(),
          onRemoveItem: (index) => viewModel.removePerforation(index),
          addButtonLabel: 'Ajouter un percement',
          emptyStateMessage: 'Aucun percement ajouté',
          componentType: 'Percement',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (perforation, index) =>
                  _buildPerforationForm(perforation, index, viewModel),
        ),
      );
    }

    // Access traps
    if (floor.accessTraps.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<AccessTrap>(
          title: 'Trappes d\'accès',
          subtitle: 'Accès aux zones techniques',
          icon: Icons.door_sliding_outlined,
          color: Colors.purple,
          items: floor.accessTraps,
          onAddItem: () => viewModel.addAccessTrap(),
          onRemoveItem: (index) => viewModel.removeAccessTrap(index),
          addButtonLabel: 'Ajouter une trappe',
          emptyStateMessage: 'Aucune trappe d\'accès ajoutée',
          componentType: 'Trappe d\'accès',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (trap, index) => _buildAccessTrapForm(trap, index, viewModel),
        ),
      );
    }

    // Cable paths
    if (floor.cablePaths.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<CablePath>(
          title: 'Chemins de câbles',
          subtitle: 'Structures de support des câbles',
          icon: Icons.linear_scale,
          color: Colors.green,
          items: floor.cablePaths,
          onAddItem: () => viewModel.addCablePath(),
          onRemoveItem: (index) => viewModel.removeCablePath(index),
          addButtonLabel: 'Ajouter un chemin',
          emptyStateMessage: 'Aucun chemin de câbles ajouté',
          componentType: 'Chemin de câbles',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (path, index) => _buildCablePathForm(path, index, viewModel),
        ),
      );
    }

    // Cable trunkings
    if (floor.cableTrunkings.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<CableTrunking>(
          title: 'Goulottes',
          subtitle: 'Canaux de protection des câbles',
          icon: Icons.power_input,
          color: Colors.teal,
          items: floor.cableTrunkings,
          onAddItem: () => viewModel.addCableTrunking(),
          onRemoveItem: (index) => viewModel.removeCableTrunking(index),
          addButtonLabel: 'Ajouter une goulotte',
          emptyStateMessage: 'Aucune goulotte ajoutée',
          componentType: 'Goulotte',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (trunking, index) =>
                  _buildCableTrunkingForm(trunking, index, viewModel),
        ),
      );
    }

    // Conduits
    if (floor.conduits.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<Conduit>(
          title: 'Conduits',
          subtitle: 'Tubes de protection des câbles',
          icon: Icons.rotate_90_degrees_ccw,
          color: Colors.indigo,
          items: floor.conduits,
          onAddItem: () => viewModel.addConduit(),
          onRemoveItem: (index) => viewModel.removeConduit(index),
          addButtonLabel: 'Ajouter un conduit',
          emptyStateMessage: 'Aucun conduit ajouté',
          componentType: 'Conduit',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (conduit, index) => _buildConduitForm(conduit, index, viewModel),
        ),
      );
    }

    // Copper cablings
    if (floor.copperCablings.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<CopperCabling>(
          title: 'Câblages cuivre',
          subtitle: 'Câbles réseau en cuivre',
          icon: Icons.cable,
          color: Colors.amber,
          items: floor.copperCablings,
          onAddItem: () => viewModel.addCopperCabling(),
          onRemoveItem: (index) => viewModel.removeCopperCabling(index),
          addButtonLabel: 'Ajouter un câblage cuivre',
          emptyStateMessage: 'Aucun câblage cuivre ajouté',
          componentType: 'Câblage cuivre',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (cabling, index) =>
                  _buildCopperCablingForm(cabling, index, viewModel),
        ),
      );
    }

    // Fiber optic cablings
    if (floor.fiberOpticCablings.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<FiberOpticCabling>(
          title: 'Câblages fibre optique',
          subtitle: 'Câbles à fibre optique haute performance',
          icon: Icons.fiber_manual_record,
          color: Colors.red,
          items: floor.fiberOpticCablings,
          onAddItem: () => viewModel.addFiberOpticCabling(),
          onRemoveItem: (index) => viewModel.removeFiberOpticCabling(index),
          addButtonLabel: 'Ajouter un câblage fibre',
          emptyStateMessage: 'Aucun câblage fibre optique ajouté',
          componentType: 'Câblage fibre optique',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (cabling, index) =>
                  _buildFiberOpticCablingForm(cabling, index, viewModel),
        ),
      );
    }

    // Custom components
    if (floor.customComponents.isNotEmpty) {
      sections.add(
        CollapsibleComponentCard<CustomComponent>(
          title: 'Composants Personnalisés',
          subtitle: 'Composants sur mesure selon vos besoins',
          icon: Icons.add_box,
          color: Colors.pink,
          items: floor.customComponents,
          onAddItem: () => viewModel.addCustomComponent(),
          onRemoveItem: (index) => viewModel.removeCustomComponent(index),
          addButtonLabel: 'Ajouter un composant personnalisé',
          emptyStateMessage: 'Aucun composant personnalisé ajouté',
          componentType: 'Composant personnalisé',
          initiallyExpanded: true,
          onAddOtherComponentType: () => _showComponentTypeDialog(viewModel),
          itemBuilder:
              (component, index) =>
                  _buildCustomComponentForm(component, index, viewModel),
        ),
      );
    }

    return Column(children: sections);
  }

  Widget _buildEmptyFloorState(TechnicalVisitReportViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 48,
              color: Colors.blue.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun composant ajouté à cet étage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Utilisez le sélecteur ci-dessus pour ajouter des baies, percements,\nchemins de câbles et autres composants à cet étage.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Display a modern dialog to select a component type
  void _showComponentTypeDialog(TechnicalVisitReportViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choisir un composant',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sélectionnez le type de composant à ajouter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  ),
                ),

                // Component options
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Featured: Custom component
                        _buildFeaturedComponentOption(
                          'Composant personnalisé',
                          'Créer un composant sur mesure selon vos besoins',
                          Icons.add_box,
                          Colors.pink,
                          () => _addComponent(
                            viewModel,
                            'Composant personnalisé',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'COMPOSANTS STANDARD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Standard components grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                          children:
                              viewModel.componentTypes
                                  .where(
                                    (type) => type != 'Composant personnalisé',
                                  )
                                  .map(
                                    (type) => _buildComponentGridItem(
                                      type,
                                      _getComponentIcon(type),
                                      _getComponentColor(type),
                                      () => _addComponent(viewModel, type),
                                    ),
                                  )
                                  .toList(),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildFeaturedComponentOption(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RECOMMANDÉ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: color.withOpacity(0.8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComponentGridItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addComponent(TechnicalVisitReportViewModel viewModel, String type) {
    Navigator.pop(context);
    viewModel.addComponentByType(type);
  }

  // Helper methods for component properties
  IconData _getComponentIcon(String type) {
    switch (type) {
      case 'Baie Informatique':
        return Icons.dns_outlined;
      case 'Percement':
        return Icons.architecture;
      case 'Trappe d\'accès':
        return Icons.door_sliding_outlined;
      case 'Chemin de câbles':
        return Icons.linear_scale;
      case 'Goulotte':
        return Icons.power_input;
      case 'Conduit':
        return Icons.rotate_90_degrees_ccw;
      case 'Câblage cuivre':
        return Icons.cable;
      case 'Câblage fibre optique':
        return Icons.fiber_manual_record;
      case 'Composant personnalisé':
        return Icons.add_box;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getComponentColor(String type) {
    switch (type) {
      case 'Baie Informatique':
        return Colors.blue;
      case 'Percement':
        return Colors.orange;
      case 'Trappe d\'accès':
        return Colors.purple;
      case 'Chemin de câbles':
        return Colors.green;
      case 'Goulotte':
        return Colors.teal;
      case 'Conduit':
        return Colors.indigo;
      case 'Câblage cuivre':
        return Colors.amber;
      case 'Câblage fibre optique':
        return Colors.red;
      case 'Composant personnalisé':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  /// Build form for network cabinet
  Widget _buildCabinetForm(
    NetworkCabinet cabinet,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    return NetworkCabinetFormItem(
      cabinet: cabinet,
      index: index,
      onUpdate: (updatedCabinet) {
        viewModel.updateNetworkCabinet(index, updatedCabinet);
      },
    );
  }

  /// Build form for perforation
  Widget _buildPerforationForm(
    Perforation perforation,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    Perforation editingPerforation = perforation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Mur nord salle de réunion, Plancher technique, etc.',
          initialValue: editingPerforation.location,
          required: true,
          onChanged: (value) {
            editingPerforation = editingPerforation.copyWith(location: value);
            viewModel.updatePerforation(index, editingPerforation);
          },
        ),
        FormTextField(
          label: 'Type de mur/plancher',
          hintText: 'Ex: Béton, Plâtre, Cloison, etc.',
          initialValue: editingPerforation.wallType,
          required: true,
          onChanged: (value) {
            editingPerforation = editingPerforation.copyWith(wallType: value);
            viewModel.updatePerforation(index, editingPerforation);
          },
        ),
        FormNumberField(
          label: 'Épaisseur (cm)',
          value: editingPerforation.wallDepth,
          decimal: true,
          min: 0,
          max: 100,
          onChanged: (value) {
            if (value != null) {
              editingPerforation = editingPerforation.copyWith(
                wallDepth: value.toDouble(),
              );
              viewModel.updatePerforation(index, editingPerforation);
            }
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce percement',
          initialValue: editingPerforation.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingPerforation = editingPerforation.copyWith(notes: value);
            viewModel.updatePerforation(index, editingPerforation);
          },
        ),
      ],
    );
  }

  /// Build form for access trap
  Widget _buildAccessTrapForm(
    AccessTrap trap,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    AccessTrap editingTrap = trap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Faux-plafond couloir, Local technique, etc.',
          initialValue: editingTrap.location,
          required: true,
          onChanged: (value) {
            editingTrap = editingTrap.copyWith(location: value);
            viewModel.updateAccessTrap(index, editingTrap);
          },
        ),
        FormTextField(
          label: 'Dimensions',
          hintText: 'Ex: 60x60cm, 30x30cm, etc.',
          initialValue: editingTrap.trapSize,
          required: true,
          onChanged: (value) {
            editingTrap = editingTrap.copyWith(trapSize: value);
            viewModel.updateAccessTrap(index, editingTrap);
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur cette trappe',
          initialValue: editingTrap.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingTrap = editingTrap.copyWith(notes: value);
            viewModel.updateAccessTrap(index, editingTrap);
          },
        ),
      ],
    );
  }

  /// Build form for cable path
  Widget _buildCablePathForm(
    CablePath path,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    CablePath editingPath = path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Couloir principal, Local technique, etc.',
          initialValue: editingPath.location,
          required: true,
          onChanged: (value) {
            editingPath = editingPath.copyWith(location: value);
            viewModel.updateCablePath(index, editingPath);
          },
        ),
        FormTextField(
          label: 'Dimensions',
          hintText: 'Ex: 100x50mm, 200x60mm, etc.',
          initialValue: editingPath.size,
          required: true,
          onChanged: (value) {
            editingPath = editingPath.copyWith(size: value);
            viewModel.updateCablePath(index, editingPath);
          },
        ),
        FormNumberField(
          label: 'Longueur (m)',
          value: editingPath.lengthInMeters,
          decimal: true,
          min: 0,
          max: 1000,
          onChanged: (value) {
            if (value != null) {
              editingPath = editingPath.copyWith(
                lengthInMeters: value.toDouble(),
              );
              viewModel.updateCablePath(index, editingPath);
            }
          },
        ),
        FormTextField(
          label: 'Type de fixation',
          hintText: 'Ex: Suspendu, Mural, Sur dalle, etc.',
          initialValue: editingPath.fixationType,
          required: true,
          onChanged: (value) {
            editingPath = editingPath.copyWith(fixationType: value);
            viewModel.updateCablePath(index, editingPath);
          },
        ),
        Row(
          children: [
            Expanded(
              child: FormCheckbox(
                label: 'Visible',
                value: editingPath.isVisible,
                onChanged: (value) {
                  if (value != null) {
                    editingPath = editingPath.copyWith(isVisible: value);
                    viewModel.updateCablePath(index, editingPath);
                  }
                },
              ),
            ),
            Expanded(
              child: FormCheckbox(
                label: 'Intérieur',
                value: editingPath.isInterior,
                onChanged: (value) {
                  if (value != null) {
                    editingPath = editingPath.copyWith(isInterior: value);
                    viewModel.updateCablePath(index, editingPath);
                  }
                },
              ),
            ),
          ],
        ),
        FormNumberField(
          label: 'Hauteur d\'installation (m)',
          value: editingPath.heightInMeters,
          decimal: true,
          min: 0,
          max: 20,
          onChanged: (value) {
            if (value != null) {
              editingPath = editingPath.copyWith(
                heightInMeters: value.toDouble(),
              );
              viewModel.updateCablePath(index, editingPath);
            }
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce chemin de câbles',
          initialValue: editingPath.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingPath = editingPath.copyWith(notes: value);
            viewModel.updateCablePath(index, editingPath);
          },
        ),
      ],
    );
  }

  /// Build form for cable trunking
  Widget _buildCableTrunkingForm(
    CableTrunking trunking,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    CableTrunking editingTrunking = trunking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Mur bureau, Couloir, etc.',
          initialValue: editingTrunking.location,
          required: true,
          onChanged: (value) {
            editingTrunking = editingTrunking.copyWith(location: value);
            viewModel.updateCableTrunking(index, editingTrunking);
          },
        ),
        FormTextField(
          label: 'Dimensions',
          hintText: 'Ex: 40x25mm, 60x40mm, etc.',
          initialValue: editingTrunking.size,
          required: true,
          onChanged: (value) {
            editingTrunking = editingTrunking.copyWith(size: value);
            viewModel.updateCableTrunking(index, editingTrunking);
          },
        ),
        FormNumberField(
          label: 'Longueur (m)',
          value: editingTrunking.lengthInMeters,
          decimal: true,
          min: 0,
          max: 1000,
          onChanged: (value) {
            if (value != null) {
              editingTrunking = editingTrunking.copyWith(
                lengthInMeters: value.toDouble(),
              );
              viewModel.updateCableTrunking(index, editingTrunking);
            }
          },
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Angles intérieurs',
                value: editingTrunking.innerAngles,
                decimal: false,
                min: 0,
                max: 100,
                onChanged: (value) {
                  if (value != null) {
                    editingTrunking = editingTrunking.copyWith(
                      innerAngles: value.toInt(),
                    );
                    viewModel.updateCableTrunking(index, editingTrunking);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Angles extérieurs',
                value: editingTrunking.outerAngles,
                decimal: false,
                min: 0,
                max: 100,
                onChanged: (value) {
                  if (value != null) {
                    editingTrunking = editingTrunking.copyWith(
                      outerAngles: value.toInt(),
                    );
                    viewModel.updateCableTrunking(index, editingTrunking);
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Angles plats',
                value: editingTrunking.flatAngles,
                decimal: false,
                min: 0,
                max: 100,
                onChanged: (value) {
                  if (value != null) {
                    editingTrunking = editingTrunking.copyWith(
                      flatAngles: value.toInt(),
                    );
                    viewModel.updateCableTrunking(index, editingTrunking);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormCheckbox(
                label: 'Intérieur',
                value: editingTrunking.isInterior,
                onChanged: (value) {
                  if (value != null) {
                    editingTrunking = editingTrunking.copyWith(
                      isInterior: value,
                    );
                    viewModel.updateCableTrunking(index, editingTrunking);
                  }
                },
              ),
            ),
          ],
        ),
        FormNumberField(
          label: 'Hauteur d\'installation (m)',
          value: editingTrunking.workHeight,
          decimal: true,
          min: 0,
          max: 20,
          onChanged: (value) {
            if (value != null) {
              editingTrunking = editingTrunking.copyWith(
                workHeight: value.toDouble(),
              );
              viewModel.updateCableTrunking(index, editingTrunking);
            }
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur cette goulotte',
          initialValue: editingTrunking.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingTrunking = editingTrunking.copyWith(notes: value);
            viewModel.updateCableTrunking(index, editingTrunking);
          },
        ),
      ],
    );
  }

  /// Build form for conduit
  Widget _buildConduitForm(
    Conduit conduit,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    Conduit editingConduit = conduit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Mur extérieur, Sol, etc.',
          initialValue: editingConduit.location,
          required: true,
          onChanged: (value) {
            editingConduit = editingConduit.copyWith(location: value);
            viewModel.updateConduit(index, editingConduit);
          },
        ),
        FormTextField(
          label: 'Diamètre',
          hintText: 'Ex: 25mm, 40mm, etc.',
          initialValue: editingConduit.size,
          required: true,
          onChanged: (value) {
            editingConduit = editingConduit.copyWith(size: value);
            viewModel.updateConduit(index, editingConduit);
          },
        ),
        FormNumberField(
          label: 'Longueur (m)',
          value: editingConduit.lengthInMeters,
          decimal: true,
          min: 0,
          max: 1000,
          onChanged: (value) {
            if (value != null) {
              editingConduit = editingConduit.copyWith(
                lengthInMeters: value.toDouble(),
              );
              viewModel.updateConduit(index, editingConduit);
            }
          },
        ),
        Row(
          children: [
            Expanded(
              child: FormCheckbox(
                label: 'Intérieur',
                value: editingConduit.isInterior,
                onChanged: (value) {
                  if (value != null) {
                    editingConduit = editingConduit.copyWith(isInterior: value);
                    viewModel.updateConduit(index, editingConduit);
                  }
                },
              ),
            ),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur d\'installation (m)',
                value: editingConduit.workHeight,
                decimal: true,
                min: 0,
                max: 20,
                onChanged: (value) {
                  if (value != null) {
                    editingConduit = editingConduit.copyWith(
                      workHeight: value.toDouble(),
                    );
                    viewModel.updateConduit(index, editingConduit);
                  }
                },
              ),
            ),
          ],
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce conduit',
          initialValue: editingConduit.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingConduit = editingConduit.copyWith(notes: value);
            viewModel.updateConduit(index, editingConduit);
          },
        ),
      ],
    );
  }

  /// Build form for copper cabling
  Widget _buildCopperCablingForm(
    CopperCabling cabling,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    CopperCabling editingCabling = cabling;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Baie principale vers bureaux, etc.',
          initialValue: editingCabling.location,
          required: true,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(location: value);
            viewModel.updateCopperCabling(index, editingCabling);
          },
        ),
        FormTextField(
          label: 'Description du trajet',
          hintText: 'Ex: Chemin de câbles puis faux-plafond...',
          initialValue: editingCabling.pathDescription,
          required: true,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(pathDescription: value);
            viewModel.updateCopperCabling(index, editingCabling);
          },
        ),
        FormDropdown<String>(
          label: 'Catégorie',
          value: editingCabling.category,
          items: const [
            DropdownMenuItem(value: 'Cat5e', child: Text('Cat5e')),
            DropdownMenuItem(value: 'Cat6', child: Text('Cat6')),
            DropdownMenuItem(value: 'Cat6A', child: Text('Cat6A')),
            DropdownMenuItem(value: 'Cat7', child: Text('Cat7')),
            DropdownMenuItem(value: 'Cat8', child: Text('Cat8')),
          ],
          onChanged: (value) {
            if (value != null) {
              editingCabling = editingCabling.copyWith(category: value);
              viewModel.updateCopperCabling(index, editingCabling);
            }
          },
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: editingCabling.lengthInMeters,
                decimal: true,
                min: 0,
                max: 1000,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(
                      lengthInMeters: value.toDouble(),
                    );
                    viewModel.updateCopperCabling(index, editingCabling);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormCheckbox(
                label: 'Intérieur',
                value: editingCabling.isInterior,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(isInterior: value);
                    viewModel.updateCopperCabling(index, editingCabling);
                  }
                },
              ),
            ),
          ],
        ),
        FormNumberField(
          label: 'Hauteur d\'installation (m)',
          value: editingCabling.workHeight,
          decimal: true,
          min: 0,
          max: 20,
          onChanged: (value) {
            if (value != null) {
              editingCabling = editingCabling.copyWith(
                workHeight: value.toDouble(),
              );
              viewModel.updateCopperCabling(index, editingCabling);
            }
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce câblage',
          initialValue: editingCabling.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(notes: value);
            viewModel.updateCopperCabling(index, editingCabling);
          },
        ),
      ],
    );
  }

  /// Build form for fiber optic cabling
  Widget _buildFiberOpticCablingForm(
    FiberOpticCabling cabling,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    FiberOpticCabling editingCabling = cabling;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Emplacement',
          hintText: 'Ex: Entre local technique et datacenter, etc.',
          initialValue: editingCabling.location,
          required: true,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(location: value);
            viewModel.updateFiberOpticCabling(index, editingCabling);
          },
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Nombre de tiroirs',
                value: editingCabling.drawerCount,
                min: 0,
                max: 100,
                decimal: false,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(
                      drawerCount: value.toInt(),
                    );
                    viewModel.updateFiberOpticCabling(index, editingCabling);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormTextField(
                label: 'Type de fibre',
                hintText: 'Ex: OM3, OM4, OS2, etc.',
                initialValue: editingCabling.fiberType,
                required: true,
                onChanged: (value) {
                  editingCabling = editingCabling.copyWith(fiberType: value);
                  viewModel.updateFiberOpticCabling(index, editingCabling);
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Nombre de conduits',
                value: editingCabling.conduitCount,
                min: 0,
                max: 100,
                decimal: false,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(
                      conduitCount: value.toInt(),
                    );
                    viewModel.updateFiberOpticCabling(index, editingCabling);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'Longueur (m)',
                value: editingCabling.lengthInMeters,
                decimal: true,
                min: 0,
                max: 1000,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(
                      lengthInMeters: value.toDouble(),
                    );
                    viewModel.updateFiberOpticCabling(index, editingCabling);
                  }
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: FormCheckbox(
                label: 'Intérieur',
                value: editingCabling.isInterior,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(isInterior: value);
                    viewModel.updateFiberOpticCabling(index, editingCabling);
                  }
                },
              ),
            ),
            Expanded(
              child: FormNumberField(
                label: 'Hauteur d\'installation (m)',
                value: editingCabling.workHeight,
                decimal: true,
                min: 0,
                max: 20,
                onChanged: (value) {
                  if (value != null) {
                    editingCabling = editingCabling.copyWith(
                      workHeight: value.toDouble(),
                    );
                    viewModel.updateFiberOpticCabling(index, editingCabling);
                  }
                },
              ),
            ),
          ],
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce câblage fibre optique',
          initialValue: editingCabling.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(notes: value);
            viewModel.updateFiberOpticCabling(index, editingCabling);
          },
        ),
      ],
    );
  }

  /// Build form for custom component
  Widget _buildCustomComponentForm(
    CustomComponent component,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    CustomComponent editingComponent = component;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Nom du composant',
          hintText: 'Ex: Système d\'alarme, Tableau électrique, etc.',
          initialValue: editingComponent.name,
          required: true,
          onChanged: (value) {
            editingComponent = editingComponent.copyWith(name: value);
            viewModel.updateCustomComponent(index, editingComponent);
          },
        ),
        FormTextField(
          label: 'Description',
          hintText: 'Décrivez le composant et ses caractéristiques',
          initialValue: editingComponent.description,
          required: true,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingComponent = editingComponent.copyWith(description: value);
            viewModel.updateCustomComponent(index, editingComponent);
          },
        ),
        FormTextField(
          label: 'Emplacement',
          hintText: 'Indiquez où se trouve ce composant',
          initialValue: editingComponent.location,
          required: true,
          onChanged: (value) {
            editingComponent = editingComponent.copyWith(location: value);
            viewModel.updateCustomComponent(index, editingComponent);
          },
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur ce composant',
          initialValue: editingComponent.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingComponent = editingComponent.copyWith(notes: value);
            viewModel.updateCustomComponent(index, editingComponent);
          },
        ),
        // Add the photo section
        const Divider(height: 32),
        ComponentPhotoSection(
          componentIndex: index,
          photos: component.photos,
          componentType: 'Composant personnalisé',
        ),
      ],
    );
  }
}

/// Adapted form item for network cabinet specifically for the floor-based layout
class NetworkCabinetFormItem extends StatelessWidget {
  final NetworkCabinet cabinet;
  final int index;
  final Function(NetworkCabinet) onUpdate;

  const NetworkCabinetFormItem({
    super.key,
    required this.cabinet,
    required this.index,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    NetworkCabinet editingCabinet = cabinet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormTextField(
          label: 'Nom de la baie',
          hintText: 'Ex: Baie Principale, Switch Étage 2, etc.',
          initialValue: editingCabinet.name,
          required: true,
          onChanged: (value) {
            editingCabinet = editingCabinet.copyWith(name: value);
            onUpdate(editingCabinet);
          },
        ),
        FormTextField(
          label: 'Emplacement précis',
          hintText: 'Ex: Local technique 1er étage, Salle serveur, etc.',
          initialValue: editingCabinet.location,
          required: true,
          onChanged: (value) {
            editingCabinet = editingCabinet.copyWith(location: value);
            onUpdate(editingCabinet);
          },
        ),
        FormTextField(
          label: 'État de la baie',
          hintText: 'Ex: Bon état, Encombré, À remplacer, etc.',
          initialValue: editingCabinet.cabinetState,
          required: true,
          onChanged: (value) {
            editingCabinet = editingCabinet.copyWith(cabinetState: value);
            onUpdate(editingCabinet);
          },
        ),
        FormCheckbox(
          label: 'Baie alimentée',
          value: editingCabinet.isPowered,
          subtitle:
              'Indiquez si la baie dispose d\'une alimentation électrique fonctionnelle',
          onChanged: (value) {
            if (value != null) {
              editingCabinet = editingCabinet.copyWith(isPowered: value);
              onUpdate(editingCabinet);
            }
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormNumberField(
                label: 'Prises disponibles',
                value: editingCabinet.availableOutlets,
                min: 0,
                max: 100,
                onChanged: (value) {
                  editingCabinet = editingCabinet.copyWith(
                    availableOutlets: value as int? ?? 0,
                  );
                  onUpdate(editingCabinet);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormNumberField(
                label: 'U total',
                value: editingCabinet.totalRackUnits,
                min: 0,
                max: 100,
                onChanged: (value) {
                  editingCabinet = editingCabinet.copyWith(
                    totalRackUnits: value as int? ?? 0,
                  );
                  onUpdate(editingCabinet);
                },
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormNumberField(
                label: 'U disponibles',
                value: editingCabinet.availableRackUnits,
                min: 0,
                max: editingCabinet.totalRackUnits,
                onChanged: (value) {
                  editingCabinet = editingCabinet.copyWith(
                    availableRackUnits: value as int? ?? 0,
                  );
                  onUpdate(editingCabinet);
                },
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()), // Empty space for alignment
          ],
        ),
        FormTextField(
          label: 'Remarques',
          hintText: 'Notes additionnelles sur la baie',
          initialValue: editingCabinet.notes,
          multiline: true,
          maxLines: 3,
          onChanged: (value) {
            editingCabinet = editingCabinet.copyWith(notes: value);
            onUpdate(editingCabinet);
          },
        ),
      ],
    );
  }
}
