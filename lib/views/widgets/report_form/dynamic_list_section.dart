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
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: Colors.blue.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items list or empty state
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: items.isEmpty ? _buildEmptyState() : _buildItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        // Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder:
              (context, index) =>
                  Divider(color: Colors.grey.shade200, height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item header with name and delete button
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Text(
                          '${_getComponentShortName(componentType)} ${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 20,
                        ),
                        onPressed: () => onRemoveItem(index),
                        tooltip: 'Supprimer',
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: const EdgeInsets.all(8),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Item content
                  itemBuilder(item, index),
                ],
              ),
            );
          },
        ),

        // Action buttons at bottom
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Add same component type button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add, size: 18),
            label: Text(
              'Ajouter un autre ${_getComponentShortName(componentType)}',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade700,
              side: BorderSide(color: Colors.blue.shade300),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (onAddOtherComponentType != null) ...[
          const SizedBox(height: 8),
          // Add different component type button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddOtherComponentType,
              icon: const Icon(Icons.category_outlined, size: 18),
              label: const Text('Ajouter un autre composant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getComponentShortName(String componentType) {
    switch (componentType) {
      case 'Baie Informatique':
        return 'Baie';
      case 'Percement':
        return 'Percement';
      case 'Trappe d\'accès':
        return 'Trappe';
      case 'Chemin de câbles':
        return 'Chemin';
      case 'Goulotte':
        return 'Goulotte';
      case 'Conduit':
        return 'Conduit';
      case 'Câblage cuivre':
        return 'Câblage Cu';
      case 'Câblage fibre optique':
        return 'Câblage FO';
      case 'Composant personnalisé':
        return 'Composant';
      default:
        return 'Élément';
    }
  }
}
