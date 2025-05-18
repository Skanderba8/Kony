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
      padding: const EdgeInsets.all(14.0), // Slightly smaller padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0), // Smaller radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Lighter shadow
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.blue.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.0, // Slightly smaller font
              color: Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 10.0), // Tighter spacing

          if (selectedType == null)
            ElevatedButton.icon(
              onPressed: () => _showComponentTypeDialog(context),
              icon: const Icon(
                Icons.add_circle_outline,
                size: 18,
              ), // Smaller icon
              label: const Text('Ajouter un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0, // Smaller button
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), // Smaller radius
                ),
                elevation: 1, // Less elevation
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Smaller padding
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10), // Smaller radius
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(
                          8,
                        ), // Smaller icon container
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(
                                0.15,
                              ), // Lighter shadow
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getComponentIcon(selectedType!),
                          color: Colors.blue.shade700,
                          size: 20, // Smaller icon
                        ),
                      ),
                      const SizedBox(width: 10), // Tighter spacing
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedType!,
                              style: TextStyle(
                                fontSize: 16, // Smaller font size
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 2), // Tighter spacing
                            Text(
                              _getComponentDescription(selectedType!),
                              style: TextStyle(
                                fontSize: 13.0, // Slightly larger description
                                fontWeight: FontWeight.normal, // Normal weight
                                color:
                                    Colors
                                        .blue
                                        .shade900, // Darker blue for better readability
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18), // Smaller icon
                        onPressed: () => _showComponentTypeDialog(context),
                        tooltip: 'Changer le type',
                        color: Colors.blue.shade600,
                        padding: EdgeInsets.zero, // Remove padding
                        constraints:
                            const BoxConstraints(), // Remove constraints
                        visualDensity: VisualDensity.compact, // Compact button
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // In lib/views/widgets/report_form/component_type_selector.dart

  Widget _buildComponentTypeCard(
    BuildContext context,
    String type,
    bool isHighlighted,
  ) {
    final Color cardColor =
        isHighlighted
            ? Colors.blue.withOpacity(0.05) // Lighter blue background
            : Colors.white; // White instead of gray for other options

    final Color textColor = isHighlighted ? Colors.blue : Colors.black87;

    final Color iconColor =
        isHighlighted
            ? Colors.blue
            : Colors.blue.shade700; // More consistent icon colors

    final Color descriptionColor =
        isHighlighted
            ? Colors.blue.shade700
            : Colors.grey.shade700; // Darker text for better readability

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ), // Smaller margins
      elevation: isHighlighted ? 1 : 0, // Less shadow
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Smaller radius
        side: BorderSide(
          color:
              isHighlighted
                  ? Colors.blue.shade200
                  : Colors.grey.shade100, // Lighter border
        ),
      ),
      child: InkWell(
        onTap: () {
          onTypeSelected(type);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ), // Smaller padding
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Smaller icon container
                decoration: BoxDecoration(
                  color:
                      isHighlighted
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.blue.withOpacity(
                            0.05,
                          ), // Lighter backgrounds
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getComponentIcon(type),
                  color: iconColor,
                  size: 20, // Smaller icon
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 15, // Slightly smaller text
                        fontWeight:
                            isHighlighted ? FontWeight.bold : FontWeight.w500,

                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3), // Tighter spacing
                    Text(
                      _getComponentDescription(type),
                      style: TextStyle(
                        fontSize: 13, // Increased font size for description
                        fontWeight: FontWeight.normal,
                        color:
                            descriptionColor, // Darker color for better contrast
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14, // Smaller arrow
                color:
                    isHighlighted ? Colors.blue.shade300 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComponentTypeDialog(BuildContext context) {
    // Create a sorted list with "Composant personnalisé" first
    final sortedTypes = List<String>.from(componentTypes);
    // Remove it from current position if it exists
    sortedTypes.remove('Composant personnalisé');
    // Add it to the beginning
    sortedTypes.insert(0, 'Composant personnalisé');

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                20,
              ), // Slightly smaller radius
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    6,
                  ), // Tighter padding
                  child: Row(
                    children: [
                      Text(
                        'Choisir un type de composant',
                        style: TextStyle(
                          fontSize: 17, // Slightly smaller title
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                    child: Column(
                      children: [
                        // Custom component highlighted at the top
                        _buildComponentTypeCard(
                          context,
                          'Composant personnalisé',
                          true,
                        ),

                        const Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            4,
                          ), // Tighter padding
                          child: Row(
                            children: [
                              Text(
                                'TYPES STANDARD',
                                style: TextStyle(
                                  fontSize: 11, // Smaller label
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Other component types
                        for (int i = 1; i < sortedTypes.length; i++)
                          _buildComponentTypeCard(
                            context,
                            sortedTypes[i],
                            false,
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0), // Smaller padding
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8, // Smaller button
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _getComponentDescription(String type) {
    switch (type) {
      case 'Baie Informatique':
        return 'Armoire contenant les équipements réseau';
      case 'Percement':
        return 'Passage pour câbles dans murs ou planchers';
      case 'Trappe d\'accès':
        return 'Ouverture pour accéder aux zones techniques';
      case 'Chemin de câbles':
        return 'Support pour acheminer les câbles';
      case 'Goulotte':
        return 'Canal pour protéger et dissimuler les câbles';
      case 'Conduit':
        return 'Tube pour protéger les câbles';
      case 'Câblage cuivre':
        return 'Câbles réseau en cuivre (Cat5e, Cat6, etc.)';
      case 'Câblage fibre optique':
        return 'Câbles à fibre optique haute performance';
      case 'Composant personnalisé':
        return 'Créer un composant sur mesure selon vos besoins';
      default:
        return 'Sélectionnez un type de composant';
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
      case 'Composant personnalisé':
        return Icons.add_box;
      default:
        return Icons.device_unknown;
    }
  }
}
