// lib/views/widgets/report_form/floor_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../models/floor.dart';

/// A widget that displays a selector for floors in the report form
class FloorSelector extends StatelessWidget {
  final bool showAddFloor;
  final bool isCompact;

  const FloorSelector({
    super.key,
    this.showAddFloor = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, _) {
        final floors = viewModel.floors;
        final currentFloorIndex = viewModel.currentFloorIndex;

        return Container(
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floor selection dropdown
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.layers_outlined,
                      size: isCompact ? 16 : 20,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étage actuel',
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: currentFloorIndex,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: Colors.blue.shade600,
                              size: isCompact ? 18 : 20,
                            ),
                            style: TextStyle(
                              fontSize: isCompact ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                            onChanged: (int? index) {
                              if (index != null) {
                                viewModel.setCurrentFloorIndex(index);
                              }
                            },
                            items:
                                floors
                                    .asMap()
                                    .entries
                                    .map<DropdownMenuItem<int>>((entry) {
                                      return DropdownMenuItem<int>(
                                        value: entry.key,
                                        child: Text(entry.value.name),
                                      );
                                    })
                                    .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons - more compact
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add floor button
                      if (showAddFloor)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.add,
                              size: isCompact ? 16 : 18,
                              color: Colors.green.shade600,
                            ),
                            padding: EdgeInsets.all(isCompact ? 6 : 8),
                            constraints: BoxConstraints(
                              minWidth: isCompact ? 28 : 32,
                              minHeight: isCompact ? 28 : 32,
                            ),
                            onPressed: () => viewModel.addFloor(),
                            tooltip: 'Ajouter un étage',
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Edit floor name button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: isCompact ? 14 : 16,
                            color: Colors.blue.shade600,
                          ),
                          padding: EdgeInsets.all(isCompact ? 6 : 8),
                          constraints: BoxConstraints(
                            minWidth: isCompact ? 28 : 32,
                            minHeight: isCompact ? 28 : 32,
                          ),
                          onPressed:
                              () => _showEditFloorNameDialog(
                                context,
                                viewModel,
                                floors[currentFloorIndex],
                              ),
                          tooltip: 'Renommer l\'étage',
                        ),
                      ),
                      // Delete floor button (only if more than one floor)
                      if (floors.length > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: isCompact ? 14 : 16,
                              color: Colors.red.shade600,
                            ),
                            padding: EdgeInsets.all(isCompact ? 6 : 8),
                            constraints: BoxConstraints(
                              minWidth: isCompact ? 28 : 32,
                              minHeight: isCompact ? 28 : 32,
                            ),
                            onPressed:
                                () => _showDeleteFloorConfirmation(
                                  context,
                                  viewModel,
                                  currentFloorIndex,
                                ),
                            tooltip: 'Supprimer l\'étage',
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Floor info summary (only when not compact)
              if (!isCompact) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFloorSummary(floors[currentFloorIndex]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _getFloorSummary(Floor floor) {
    final componentCount = floor.totalComponentCount;
    if (componentCount == 0) {
      return 'Aucun composant ajouté à cet étage';
    } else if (componentCount == 1) {
      return '1 composant documenté';
    } else {
      return '$componentCount composants documentés';
    }
  }

  /// Show a dialog to edit the floor name
  void _showEditFloorNameDialog(
    BuildContext context,
    TechnicalVisitReportViewModel viewModel,
    Floor floor,
  ) {
    final TextEditingController controller = TextEditingController(
      text: floor.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Renommer l\'étage'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'étage',
                hintText: 'Ex: Rez-de-chaussée, Étage 1, Sous-sol, etc.',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    viewModel.updateFloorName(
                      viewModel.currentFloorIndex,
                      name,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  /// Show a confirmation dialog before deleting a floor
  void _showDeleteFloorConfirmation(
    BuildContext context,
    TechnicalVisitReportViewModel viewModel,
    int floorIndex,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Supprimer l\'étage ?'),
            content: const Text(
              'Cette action est irréversible et supprimera tous les éléments associés à cet étage. '
              'Voulez-vous vraiment supprimer cet étage ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.deleteFloor(floorIndex);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
