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
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8.0 : 12.0,
            horizontal: 16.0,
          ),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.layers_outlined,
                      size: isCompact ? 16 : 18,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentFloorIndex,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.blue.shade600,
                        ),
                        style: TextStyle(
                          fontSize: isCompact ? 14 : 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade800,
                        ),
                        onChanged: (int? index) {
                          if (index != null) {
                            viewModel.setCurrentFloorIndex(index);
                          }
                        },
                        items:
                            floors.asMap().entries.map<DropdownMenuItem<int>>((
                              entry,
                            ) {
                              return DropdownMenuItem<int>(
                                value: entry.key,
                                child: Text(entry.value.name),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit floor name button
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed:
                            () => _showEditFloorNameDialog(
                              context,
                              viewModel,
                              floors[currentFloorIndex],
                            ),
                        tooltip: 'Renommer l\'étage',
                        color: Colors.blue.shade600,
                      ),
                      // Delete floor button (only if more than one floor)
                      if (floors.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed:
                              () => _showDeleteFloorConfirmation(
                                context,
                                viewModel,
                                currentFloorIndex,
                              ),
                          tooltip: 'Supprimer l\'étage',
                          color: Colors.red.shade400,
                        ),
                    ],
                  ),
                ],
              ),

              // Add floor button (if enabled and not compact)
              if (showAddFloor && !isCompact) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => viewModel.addFloor(),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Ajouter un étage'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],

              // Compact add floor button
              if (showAddFloor && isCompact) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => viewModel.addFloor(),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Ajouter un étage',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
