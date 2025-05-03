// lib/views/widgets/report_form/component_type_selector.dart
import 'package:flutter/material.dart';

/// A widget for selecting a component type with a more user-friendly UI
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
        color: Colors.blue.shade50,
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
          const SizedBox(height: 12.0),

          if (selectedType == null)
            ElevatedButton.icon(
              onPressed: () => _showComponentTypeDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                elevation: 2,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getComponentIcon(selectedType!),
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedType!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  _getComponentDescription(selectedType!),
                  style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Show a dialog to select a component type
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
