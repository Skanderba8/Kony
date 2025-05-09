// lib/views/widgets/report_form/dynamic_list_section.dart
import 'package:flutter/material.dart';

/// A component for managing a dynamic list of items in the report form
///
/// This widget allows users to add, edit, and remove items from a list,
/// with each item rendered using a custom item builder function.
class DynamicListSection<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<T> items;
  final Widget Function(T item, int index) itemBuilder;
  final VoidCallback onAddItem;
  final Function(int index) onRemoveItem;
  final String addButtonLabel;
  final String emptyStateMessage;
  final VoidCallback? onAddOtherComponentType;
  final String componentType;

  const DynamicListSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.items,
    required this.itemBuilder,
    required this.onAddItem,
    required this.onRemoveItem,
    this.addButtonLabel = 'Ajouter',
    this.emptyStateMessage = 'Aucun élément ajouté',
    this.onAddOtherComponentType,
    this.componentType = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 36.0),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyStateMessage,
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 1,
                color: Colors.blue.shade50, // Light blue background
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Élément ${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                            ),
                            onPressed: () => onRemoveItem(index),
                            tooltip: 'Supprimer',
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.blue.shade200),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: itemBuilder(item, index),
                    ),

                    // Only show the buttons at the bottom of the last item
                    // In lib/views/widgets/report_form/dynamic_list_section.dart
                    // Update the Add Component buttons to use the blue theme

                    // Update the buttons at the bottom of the list
                    // Only show the buttons at the bottom of the last item
                    if (index == items.length - 1) ...[
                      Divider(color: Colors.blue.shade200),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Add same component type button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onAddItem,
                                icon: const Icon(Icons.add),
                                label: Text('Ajouter un autre $componentType'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  side: const BorderSide(
                                    color: Colors.blue,
                                  ), // Use solid blue color
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Add different component type button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: onAddOtherComponentType,
                                icon: const Icon(Icons.category_outlined),
                                label: const Text('Ajouter un autre composant'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.blue, // Use solid blue color
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                    horizontal: 16.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.0),
                                  ),
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
          ),
      ],
    );
  }
}
