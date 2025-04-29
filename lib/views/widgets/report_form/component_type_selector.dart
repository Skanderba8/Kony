// lib/views/widgets/report_form/component_type_selector.dart
import 'package:flutter/material.dart';

/// A widget for selecting a component type from a dropdown
class ComponentTypeSelector extends StatelessWidget {
  final List<String> componentTypes;
  final String? selectedType;
  final Function(String?) onTypeSelected;
  final String label;

  const ComponentTypeSelector({
    super.key,
    required this.componentTypes,
    required this.selectedType,
    required this.onTypeSelected,
    this.label = 'Type de composant',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          const SizedBox(height: 8.0),
          // Using an InkWell to open a modal dialog instead of a dropdown
          // This avoids overflow issues with long component type names
          InkWell(
            onTap: () => _showComponentTypeDialog(context),
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedType ?? 'Sélectionner un type de composant',
                      style: TextStyle(
                        color:
                            selectedType == null
                                ? Colors.grey.shade600
                                : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (selectedType != null) ...[
            const SizedBox(height: 16.0),
            Text(
              _getComponentDescription(selectedType!),
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Show a dialog to select a component type
  /// This avoids overflow issues with the dropdown
  void _showComponentTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(label),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    componentTypes.map((type) {
                      final bool isSelected = type == selectedType;
                      return ListTile(
                        title: Text(type),
                        leading: Icon(_getComponentIcon(type)),
                        selected: isSelected,
                        selectedTileColor: Colors.blue.shade50,
                        onTap: () {
                          onTypeSelected(type);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
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

  /// Get a description for the selected component type
  String _getComponentDescription(String type) {
    switch (type) {
      case 'Baie Informatique':
        return 'Armoire contenant les équipements réseau et serveurs';
      case 'Percement':
        return 'Trou dans un mur, plafond ou plancher pour le passage des câbles';
      case 'Trappe d\'accès':
        return 'Ouverture permettant d\'accéder à des zones techniques';
      case 'Chemin de câbles':
        return 'Support métallique pour supporter et acheminer les câbles';
      case 'Goulotte':
        return 'Canal en plastique ou métal pour protéger et dissimuler les câbles';
      case 'Conduit':
        return 'Tube pour protéger les câbles dans les murs ou sous terre';
      case 'Câblage cuivre':
        return 'Câbles réseau en cuivre (Cat5e, Cat6, Cat6A, etc.)';
      case 'Câblage fibre optique':
        return 'Câbles à fibre optique pour transmissions haut débit';
      default:
        return 'Sélectionnez un type de composant à ajouter';
    }
  }

  /// Get an icon for a component type
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
      default:
        return Icons.device_unknown;
    }
  }
}
