// lib/views/widgets/report_form/floor_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technical_visit_report_view_model.dart';
import '../../../models/floor.dart';

/// A widget that displays a selector for floors in the report form
class FloorSelector extends StatelessWidget {
  final bool showAddFloor;

  const FloorSelector({super.key, this.showAddFloor = true});

  @override
  Widget build(BuildContext context) {
    return Consumer<TechnicalVisitReportViewModel>(
      builder: (context, viewModel, _) {
        final floors = viewModel.floors;
        final currentFloorIndex = viewModel.currentFloorIndex;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Floor selection dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: currentFloorIndex,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          onChanged: (int? index) {
                            if (index != null) {
                              viewModel.setCurrentFloorIndex(index);
                            }
                          },
                          items:
                              floors.asMap().entries.map<DropdownMenuItem<int>>(
                                (entry) {
                                  return DropdownMenuItem<int>(
                                    value: entry.key,
                                    child: Text(
                                      entry.value.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                        ),
                      ),
                    ),
                    // Edit floor name button
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => _showEditFloorNameDialog(
                            context,
                            viewModel,
                            floors[currentFloorIndex],
                          ),
                      tooltip: 'Renommer l\'étage',
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    // Delete floor button (only if more than one floor)
                    if (floors.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed:
                            () => _showDeleteFloorConfirmation(
                              context,
                              viewModel,
                              currentFloorIndex,
                            ),
                        tooltip: 'Supprimer l\'étage',
                        visualDensity: VisualDensity.compact,
                        color: Colors.red.shade400,
                      ),
                  ],
                ),
              ),

              // Add floor button (if enabled)
              if (showAddFloor)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => viewModel.addFloor(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade500,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8.0),
                            bottomRight: Radius.circular(8.0),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter un étage',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
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
            title: const Text('Renommer l\'étage'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'étage',
                hintText: 'Ex: Rez-de-chaussée, Étage 1, Sous-sol, etc.',
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
