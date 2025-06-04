// lib/views/widgets/report_form/component_type_selector.dart
import 'package:flutter/material.dart';

/// An improved component type selector with better UI that matches the app design
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
    this.label = 'Ajouter un composant',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
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
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Sélectionnez le type de composant à documenter',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Add component button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showImprovedComponentDialog(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Choisir un composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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

  void _showImprovedComponentDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
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
                                    'Choisir un Composant',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Sélectionnez le type d\'élément à ajouter',
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

                      const Divider(height: 1),

                      // Featured component (Custom component)
                      Container(
                        margin: const EdgeInsets.all(16),
                        child: _buildFeaturedComponentCard(
                          'Composant personnalisé',
                          'Créer un composant sur mesure selon vos besoins',
                          Icons.add_box,
                          Colors.pink,
                          context,
                        ),
                      ),

                      // Section title for standard components
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'COMPOSANTS STANDARDS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Standard components list
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount:
                              componentTypes.length -
                              1, // Exclude custom component
                          itemBuilder: (context, index) {
                            // Skip custom component as it's featured above
                            final componentType =
                                componentTypes
                                    .where(
                                      (type) =>
                                          type != 'Composant personnalise',
                                    )
                                    .toList()[index];

                            return _buildStandardComponentCard(
                              componentType,
                              _getComponentDescription(componentType),
                              _getComponentIcon(componentType),
                              _getComponentColor(componentType),
                              context,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildFeaturedComponentCard(
    String title,
    String description,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTypeSelected(title);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
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

  Widget _buildStandardComponentCard(
    String title,
    String description,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            onTypeSelected(title);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
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
}
