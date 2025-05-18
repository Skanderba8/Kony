// lib/views/screens/report_form/floor_components_form.dart
import 'package:flutter/material.dart';
import 'package:kony/models/report_sections/custom_component.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../models/floor.dart';
import '../../widgets/report_form/component_type_selector.dart';
import '../../widgets/report_form/dynamic_list_section.dart';
import '../../widgets/report_form/section_header.dart';
import '../../widgets/report_form/floor_selector.dart';

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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor selector with add floor button
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: FloorSelector(),
            ),

            // Floor title and description
            SectionHeader(
              title: 'Étage: ${currentFloor.name}',
              subtitle: 'Ajoutez les composants installés à cet étage.',
              icon: Icons.layers,
            ),

            // Component type selector
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: ComponentTypeSelector(
                componentTypes: viewModel.componentTypes,
                selectedType: viewModel.selectedComponentType,
                onTypeSelected: (type) {
                  viewModel.setSelectedComponentType(type);

                  // If selecting a new component type, add a new component
                  if (type != null) {
                    viewModel.addComponentByType(type);
                  }
                },
                label: 'Ajouter un composant',
              ),
            ),

            // Display components by type with proper constraints
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: _buildComponentSections(viewModel, currentFloor),
            ),
          ],
        );
      },
    );
  }

  /// Build sections for each component type that has components
  Widget _buildComponentSections(
    TechnicalVisitReportViewModel viewModel,
    Floor floor,
  ) {
    final List<Widget> sections = [];

    // Network cabinets
    if (floor.networkCabinets.isNotEmpty) {
      sections.add(
        DynamicListSection<NetworkCabinet>(
          title: 'Baies Informatiques',
          subtitle: 'Informations sur les baies informatiques à cet étage.',
          icon: Icons.dns_outlined,
          items: floor.networkCabinets,
          onAddItem: () {
            viewModel.addNetworkCabinet();
          },
          onRemoveItem: (index) {
            viewModel.removeNetworkCabinet(index);
          },
          addButtonLabel: 'Ajouter une baie',
          emptyStateMessage: 'Aucune baie informatique ajoutée',
          componentType: 'baie informatique',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (cabinet, index) {
            return _buildCabinetForm(cabinet, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Perforations
    if (floor.perforations.isNotEmpty) {
      sections.add(
        DynamicListSection<Perforation>(
          title: 'Percements',
          subtitle:
              'Points de passage des câbles à travers les murs et planchers.',
          icon: Icons.architecture,
          items: floor.perforations,
          onAddItem: () {
            viewModel.addPerforation();
          },
          onRemoveItem: (index) {
            viewModel.removePerforation(index);
          },
          addButtonLabel: 'Ajouter un percement',
          emptyStateMessage: 'Aucun percement ajouté',
          componentType: 'percement',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (perforation, index) {
            return _buildPerforationForm(perforation, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Access traps
    if (floor.accessTraps.isNotEmpty) {
      sections.add(
        DynamicListSection<AccessTrap>(
          title: 'Trappes d\'accès',
          subtitle: 'Informations sur les trappes d\'accès à cet étage.',
          icon: Icons.door_sliding_outlined,
          items: floor.accessTraps,
          onAddItem: () {
            viewModel.addAccessTrap();
          },
          onRemoveItem: (index) {
            viewModel.removeAccessTrap(index);
          },
          addButtonLabel: 'Ajouter une trappe',
          emptyStateMessage: 'Aucune trappe d\'accès ajoutée',
          componentType: 'trappe d\'accès',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (trap, index) {
            return _buildAccessTrapForm(trap, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Cable paths
    if (floor.cablePaths.isNotEmpty) {
      sections.add(
        DynamicListSection<CablePath>(
          title: 'Chemins de câbles',
          subtitle: 'Structures de support des câbles à cet étage.',
          icon: Icons.linear_scale,
          items: floor.cablePaths,
          onAddItem: () {
            viewModel.addCablePath();
          },
          onRemoveItem: (index) {
            viewModel.removeCablePath(index);
          },
          addButtonLabel: 'Ajouter un chemin',
          emptyStateMessage: 'Aucun chemin de câbles ajouté',
          componentType: 'chemin de câbles',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (path, index) {
            return _buildCablePathForm(path, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Cable trunkings
    if (floor.cableTrunkings.isNotEmpty) {
      sections.add(
        DynamicListSection<CableTrunking>(
          title: 'Goulottes',
          subtitle: 'Canaux de protection des câbles à cet étage.',
          icon: Icons.power_input,
          items: floor.cableTrunkings,
          onAddItem: () {
            viewModel.addCableTrunking();
          },
          onRemoveItem: (index) {
            viewModel.removeCableTrunking(index);
          },
          addButtonLabel: 'Ajouter une goulotte',
          emptyStateMessage: 'Aucune goulotte ajoutée',
          componentType: 'goulotte',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (trunking, index) {
            return _buildCableTrunkingForm(trunking, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Conduits
    if (floor.conduits.isNotEmpty) {
      sections.add(
        DynamicListSection<Conduit>(
          title: 'Conduits',
          subtitle: 'Tubes de protection des câbles à cet étage.',
          icon: Icons.rotate_90_degrees_ccw,
          items: floor.conduits,
          onAddItem: () {
            viewModel.addConduit();
          },
          onRemoveItem: (index) {
            viewModel.removeConduit(index);
          },
          addButtonLabel: 'Ajouter un conduit',
          emptyStateMessage: 'Aucun conduit ajouté',
          componentType: 'conduit',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (conduit, index) {
            return _buildConduitForm(conduit, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Copper cablings
    if (floor.copperCablings.isNotEmpty) {
      sections.add(
        DynamicListSection<CopperCabling>(
          title: 'Câblages cuivre',
          subtitle: 'Câbles réseau en cuivre à cet étage.',
          icon: Icons.cable,
          items: floor.copperCablings,
          onAddItem: () {
            viewModel.addCopperCabling();
          },
          onRemoveItem: (index) {
            viewModel.removeCopperCabling(index);
          },
          addButtonLabel: 'Ajouter un câblage cuivre',
          emptyStateMessage: 'Aucun câblage cuivre ajouté',
          componentType: 'câblage cuivre',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (cabling, index) {
            return _buildCopperCablingForm(cabling, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // Fiber optic cablings
    if (floor.fiberOpticCablings.isNotEmpty) {
      sections.add(
        DynamicListSection<FiberOpticCabling>(
          title: 'Câblages fibre optique',
          subtitle: 'Câbles à fibre optique à cet étage.',
          icon: Icons.fiber_manual_record,
          items: floor.fiberOpticCablings,
          onAddItem: () {
            viewModel.addFiberOpticCabling();
          },
          onRemoveItem: (index) {
            viewModel.removeFiberOpticCabling(index);
          },
          addButtonLabel: 'Ajouter un câblage fibre',
          emptyStateMessage: 'Aucun câblage fibre optique ajouté',
          componentType: 'câblage fibre optique',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (cabling, index) {
            return _buildFiberOpticCablingForm(cabling, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    // In lib/views/screens/report_form/floor_components_form.dart
    // In the _buildComponentSections method after other component sections

    // Custom components
    if (floor.customComponents.isNotEmpty) {
      sections.add(
        DynamicListSection<CustomComponent>(
          title: 'Composants Personnalisés',
          subtitle: 'Composants personnalisés ajoutés à cet étage.',
          icon: Icons.add_box,
          items: floor.customComponents,
          onAddItem: () {
            viewModel.addCustomComponent();
          },
          onRemoveItem: (index) {
            viewModel.removeCustomComponent(index);
          },
          addButtonLabel: 'Ajouter un composant personnalisé',
          emptyStateMessage: 'Aucun composant personnalisé ajouté',
          componentType: 'composant personnalisé',
          onAddOtherComponentType: () {
            viewModel.setSelectedComponentType(null);
            _showComponentTypeSelector(context, viewModel);
          },
          itemBuilder: (component, index) {
            return _buildCustomComponentForm(component, index, viewModel);
          },
        ),
      );
      sections.add(const SizedBox(height: 24));
    }

    if (sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucun composant ajouté à cet étage',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Utilisez le sélecteur ci-dessus pour ajouter des baies, percements, '
                'chemins de câbles et autres composants à cet étage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showComponentTypeSelector(context, viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un composant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(child: Column(children: sections));
  }

  /// Display a dialog to select a component type
  void _showComponentTypeSelector(
    BuildContext context,
    TechnicalVisitReportViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choisir un type de composant'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...viewModel.componentTypes.map(
                    (type) => ListTile(
                      title: Text(type),
                      leading: Icon(_getIconForComponentType(type)),
                      onTap: () {
                        viewModel.setSelectedComponentType(type);
                        viewModel.addComponentByType(type);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
          ),
    );
  }

  /// Get an icon for a component type
  IconData _getIconForComponentType(String type) {
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
      case 'Composant personnalisé': // Add this case
        return Icons.add_box;
      default:
        return Icons.device_unknown;
    }
  }

  /// Build form for network cabinet
  Widget _buildCabinetForm(
    NetworkCabinet cabinet,
    int index,
    TechnicalVisitReportViewModel viewModel,
  ) {
    // Reuse the existing NetworkCabinetForm but modify it to work with our floor-based approach
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
    // Create a form for perforation - simplified version for now
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
    // Simplified form for access trap
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
    // Form for cable path
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

        FormCheckbox(
          label: 'Visible',
          value: editingPath.isVisible,
          onChanged: (value) {
            if (value != null) {
              editingPath = editingPath.copyWith(isVisible: value);
              viewModel.updateCablePath(index, editingPath);
            }
          },
        ),

        FormCheckbox(
          label: 'Intérieur',
          value: editingPath.isInterior,
          onChanged: (value) {
            if (value != null) {
              editingPath = editingPath.copyWith(isInterior: value);
              viewModel.updateCablePath(index, editingPath);
            }
          },
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
    // Form for cable trunking
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

        FormNumberField(
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

        FormNumberField(
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

        FormNumberField(
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

        FormCheckbox(
          label: 'Intérieur',
          value: editingTrunking.isInterior,
          onChanged: (value) {
            if (value != null) {
              editingTrunking = editingTrunking.copyWith(isInterior: value);
              viewModel.updateCableTrunking(index, editingTrunking);
            }
          },
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
    // Form for conduit
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

        FormCheckbox(
          label: 'Intérieur',
          value: editingConduit.isInterior,
          onChanged: (value) {
            if (value != null) {
              editingConduit = editingConduit.copyWith(isInterior: value);
              viewModel.updateConduit(index, editingConduit);
            }
          },
        ),

        FormNumberField(
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
    // Form for copper cabling
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

        // Dropdown for category
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

        FormNumberField(
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

        FormCheckbox(
          label: 'Intérieur',
          value: editingCabling.isInterior,
          onChanged: (value) {
            if (value != null) {
              editingCabling = editingCabling.copyWith(isInterior: value);
              viewModel.updateCopperCabling(index, editingCabling);
            }
          },
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
    // Form for fiber optic cabling
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

        FormNumberField(
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

        FormTextField(
          label: 'Type de fibre',
          hintText: 'Ex: OM3, OM4, OS2, etc.',
          initialValue: editingCabling.fiberType,
          required: true,
          onChanged: (value) {
            editingCabling = editingCabling.copyWith(fiberType: value);
            viewModel.updateFiberOpticCabling(index, editingCabling);
          },
        ),

        FormNumberField(
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

        FormNumberField(
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

        FormCheckbox(
          label: 'Intérieur',
          value: editingCabling.isInterior,
          onChanged: (value) {
            if (value != null) {
              editingCabling = editingCabling.copyWith(isInterior: value);
              viewModel.updateFiberOpticCabling(index, editingCabling);
            }
          },
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
              viewModel.updateFiberOpticCabling(index, editingCabling);
            }
          },
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
}

// In lib/views/screens/report_form/floor_components_form.dart
// Add this as a new method alongside other component form methods

Widget _buildCustomComponentForm(
  CustomComponent component,
  int index,
  TechnicalVisitReportViewModel viewModel,
) {
  // Create a local copy for editing
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
    ],
  );
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
    // Create local state for editing
    NetworkCabinet editingCabinet = cabinet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name field
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

        // Location field
        // Location field
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

        // Cabinet state field
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

        // Powered checkbox
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

        // Number fields
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

        // Notes field
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
