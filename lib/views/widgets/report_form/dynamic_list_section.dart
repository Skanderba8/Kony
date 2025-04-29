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
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: Text(addButtonLabel),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                    Divider(color: Colors.grey.shade200),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: itemBuilder(item, index),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
