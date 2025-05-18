// lib/views/widgets/report_form/component_photo_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../models/photo.dart';
import '../../../view_models/technical_visit_report_view_model.dart';

class ComponentPhotoSection extends StatefulWidget {
  final int componentIndex;
  final List<Photo> photos;
  final String componentType;

  const ComponentPhotoSection({
    super.key,
    required this.componentIndex,
    required this.photos,
    required this.componentType,
  });

  @override
  _ComponentPhotoSectionState createState() => _ComponentPhotoSectionState();
}

class _ComponentPhotoSectionState extends State<ComponentPhotoSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingPhoto = false;
  File? _selectedImage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    // Show a dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choisir la source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Appareil photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galerie'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isAddingPhoto = true;
          _commentController.text = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
      );
    }
  }

  Future<void> _addPhoto() async {
    if (_selectedImage == null) return;

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter un commentaire à la photo'),
        ),
      );
      return;
    }

    final viewModel = Provider.of<TechnicalVisitReportViewModel>(
      context,
      listen: false,
    );

    // Based on the component type, call the appropriate method
    if (widget.componentType == 'Composant personnalisé') {
      await viewModel.addPhotoToCustomComponent(
        widget.componentIndex,
        _selectedImage!,
        _commentController.text.trim(),
      );
    }
    // Add similar conditions for other component types

    setState(() {
      _selectedImage = null;
      _isAddingPhoto = false;
    });
  }

  Future<void> _cancelAddPhoto() async {
    setState(() {
      _selectedImage = null;
      _isAddingPhoto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Photos ${widget.photos.isEmpty ? '' : '(${widget.photos.length})'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!_isAddingPhoto)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Ajouter une photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),

        // Add new photo section
        if (_isAddingPhoto && _selectedImage != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouvelle photo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),

                // Display the selected image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),

                // Comment field
                TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire *',
                    hintText:
                        'Ajoutez un commentaire descriptif pour cette photo',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _cancelAddPhoto,
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addPhoto,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Display existing photos
        if (widget.photos.isNotEmpty) ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.photos.length,
            itemBuilder: (context, index) {
              final photo = widget.photos[index];
              return _buildPhotoItem(photo, index);
            },
          ),
        ] else if (!_isAddingPhoto) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune photo ajoutée',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des photos pour documenter visuellement ce composant',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoItem(Photo photo, int index) {
    // Controller for editing comment
    final commentController = TextEditingController(text: photo.comment);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo with index number in corner
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: Image.network(
                  photo.url,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Photo ${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Comment section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment header
                const Text(
                  'Commentaire',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Comment text with edit option
                InkWell(
                  onTap: () {
                    // Show dialog to edit comment
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Modifier le commentaire'),
                            content: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                labelText: 'Commentaire',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final viewModel = Provider.of<
                                    TechnicalVisitReportViewModel
                                  >(context, listen: false);

                                  if (widget.componentType ==
                                      'Composant personnalisé') {
                                    viewModel.updatePhotoComment(
                                      widget.componentIndex,
                                      index,
                                      commentController.text.trim(),
                                    );
                                  }
                                  // Add similar conditions for other component types

                                  Navigator.pop(context);
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(photo.comment)),
                        const Icon(Icons.edit, size: 16, color: Colors.blue),
                      ],
                    ),
                  ),
                ),

                // Action row
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          // Confirm delete
                          final confirm =
                              await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Supprimer la photo'),
                                      content: const Text(
                                        'Êtes-vous sûr de vouloir supprimer cette photo ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                              ) ??
                              false;

                          if (confirm) {
                            final viewModel =
                                Provider.of<TechnicalVisitReportViewModel>(
                                  context,
                                  listen: false,
                                );

                            if (widget.componentType ==
                                'Composant personnalisé') {
                              await viewModel.removePhotoFromCustomComponent(
                                widget.componentIndex,
                                index,
                              );
                            }
                            // Add similar conditions for other component types
                          }
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Supprimer',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
