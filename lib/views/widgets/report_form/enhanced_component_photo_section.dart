// lib/views/widgets/report_form/component_photo_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/photo.dart';

class ComponentPhotoSection extends StatefulWidget {
  final List<Photo> photos;
  final Function(File, String) onPhotoAdded;
  final Function(int) onPhotoRemoved;
  final Function(int, String) onPhotoCommentUpdated;
  final bool isReadOnly;

  const ComponentPhotoSection({
    super.key,
    required this.photos,
    required this.onPhotoAdded,
    required this.onPhotoRemoved,
    required this.onPhotoCommentUpdated,
    this.isReadOnly = false,
  });

  @override
  State<ComponentPhotoSection> createState() => _ComponentPhotoSectionState();
}

class _ComponentPhotoSectionState extends State<ComponentPhotoSection> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text(
                'Photos (${widget.photos.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.photos.isNotEmpty) _buildPhotosGrid(),
          if (!widget.isReadOnly) _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildPhotosGrid() {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) => _buildPhotoCard(index),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotoCard(int index) {
    final photo = widget.photos[index];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child:
                  photo.url.isNotEmpty
                      ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          photo.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      )
                      : photo.localPath != null
                      ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.file(
                          File(photo.localPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                      : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.comment.isNotEmpty)
                    Expanded(
                      child: Text(
                        photo.comment,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (!widget.isReadOnly)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        InkWell(
                          onTap: () => _editComment(index),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _deletePhoto(index),
                          child: Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isUploading ? null : _showImageSourceDialog,
        icon:
            _isUploading
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.add_photo_alternate),
        label: Text(_isUploading ? 'Upload...' : 'Ajouter une photo'),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ajouter une photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Prendre une photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galerie'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        _showCommentDialog(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _showCommentDialog(File imageFile) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Commentaire'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ajouter un commentaire (optionnel)',
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
                  Navigator.pop(context);
                  _uploadPhoto(imageFile, controller.text);
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
    );
  }

  Future<void> _uploadPhoto(File imageFile, String comment) async {
    setState(() => _isUploading = true);

    try {
      widget.onPhotoAdded(imageFile, comment);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _editComment(int index) {
    final controller = TextEditingController(
      text: widget.photos[index].comment,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modifier le commentaire'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPhotoCommentUpdated(index, controller.text);
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _deletePhoto(int index) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la photo'),
            content: const Text('Voulez-vous vraiment supprimer cette photo ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onPhotoRemoved(index);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );
  }
}
