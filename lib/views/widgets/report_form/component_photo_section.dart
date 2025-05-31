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
  State<ComponentPhotoSection> createState() => _ComponentPhotoSectionState();
}

class _ComponentPhotoSectionState extends State<ComponentPhotoSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isAddingPhoto = false;
  File? _selectedImage;
  bool _isUploading = false;

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.add_a_photo, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 12),
                const Text('Choisir la source'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  title: 'Appareil photo',
                  subtitle: 'Prendre une nouvelle photo',
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const SizedBox(height: 12),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  title: 'Galerie',
                  subtitle: 'Choisir depuis la galerie',
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ],
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.blue.shade600),
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
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    if (_selectedImage == null) return;

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter un commentaire à la photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final viewModel = Provider.of<TechnicalVisitReportViewModel>(
        context,
        listen: false,
      );

      // Call the appropriate method based on component type
      switch (widget.componentType) {
        case 'Baie Informatique':
          await viewModel.addPhotoToNetworkCabinet(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Percement':
          await viewModel.addPhotoToPerforation(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Trappe d\'accès':
          await viewModel.addPhotoToAccessTrap(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Chemin de câbles':
          await viewModel.addPhotoToCablePath(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Goulotte':
          await viewModel.addPhotoToCableTrunking(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Conduit':
          await viewModel.addPhotoToConduit(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Câblage cuivre':
          await viewModel.addPhotoToCopperCabling(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Câblage fibre optique':
          await viewModel.addPhotoToFiberOpticCabling(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        case 'Composant personnalisé':
          await viewModel.addPhotoToCustomComponent(
            widget.componentIndex,
            _selectedImage!,
            _commentController.text.trim(),
          );
          break;
        default:
          throw Exception(
            'Type de composant non supporté: ${widget.componentType}',
          );
      }

      if (mounted) {
        setState(() {
          _selectedImage = null;
          _isAddingPhoto = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de la photo: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _cancelAddPhoto() {
    setState(() {
      _selectedImage = null;
      _isAddingPhoto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.photo_camera,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Photos ${widget.photos.isEmpty ? '' : '(${widget.photos.length})'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!_isAddingPhoto && !_isUploading)
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

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
                  Row(
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Nouvelle photo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                  const SizedBox(height: 16),

                  // Comment field
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      labelText: 'Commentaire *',
                      hintText: 'Décrivez ce que montre cette photo...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isUploading ? null : _cancelAddPhoto,
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isUploading ? null : _addPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isUploading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Enregistrer'),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return _buildPhotoCard(photo, index);
              },
            ),
          ] else if (!_isAddingPhoto) ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoCard(Photo photo, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo section
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child:
                        photo.url.isNotEmpty
                            ? Image.network(
                              photo.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            )
                            : photo.localPath != null
                            ? Image.file(
                              File(photo.localPath!),
                              fit: BoxFit.cover,
                            )
                            : Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                  ),
                ),
                // Photo number badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comment and actions section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Comment text
                  Expanded(
                    child: Text(
                      photo.comment.isNotEmpty
                          ? photo.comment
                          : 'Aucun commentaire',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            photo.comment.isNotEmpty
                                ? Colors.black87
                                : Colors.grey.shade500,
                        fontStyle:
                            photo.comment.isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => _editComment(index, photo.comment),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _deletePhoto(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red.shade600,
                          ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 32,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune photo ajoutée',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des photos pour documenter visuellement ce composant',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _editComment(int photoIndex, String currentComment) {
    final commentController = TextEditingController(text: currentComment);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Modifier le commentaire'),
            content: TextField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: 'Commentaire',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final viewModel = Provider.of<TechnicalVisitReportViewModel>(
                    context,
                    listen: false,
                  );

                  // Call the appropriate method based on component type
                  switch (widget.componentType) {
                    case 'Baie Informatique':
                      viewModel.updateNetworkCabinetPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Percement':
                      viewModel.updatePerforationPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Trappe d\'accès':
                      viewModel.updateAccessTrapPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Chemin de câbles':
                      viewModel.updateCablePathPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Goulotte':
                      viewModel.updateCableTrunkingPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Conduit':
                      viewModel.updateConduitPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Câblage cuivre':
                      viewModel.updateCopperCablingPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Câblage fibre optique':
                      viewModel.updateFiberOpticCablingPhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                    case 'Composant personnalisé':
                      viewModel.updatePhotoComment(
                        widget.componentIndex,
                        photoIndex,
                        commentController.text.trim(),
                      );
                      break;
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          ),
    );
  }

  void _deletePhoto(int photoIndex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Supprimer la photo'),
              ],
            ),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette photo ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final viewModel = Provider.of<TechnicalVisitReportViewModel>(
          context,
          listen: false,
        );

        // Call the appropriate method based on component type
        switch (widget.componentType) {
          case 'Baie Informatique':
            await viewModel.removePhotoFromNetworkCabinet(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Percement':
            await viewModel.removePhotoFromPerforation(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Trappe d\'accès':
            await viewModel.removePhotoFromAccessTrap(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Chemin de câbles':
            await viewModel.removePhotoFromCablePath(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Goulotte':
            await viewModel.removePhotoFromCableTrunking(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Conduit':
            await viewModel.removePhotoFromConduit(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Câblage cuivre':
            await viewModel.removePhotoFromCopperCabling(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Câblage fibre optique':
            await viewModel.removePhotoFromFiberOpticCabling(
              widget.componentIndex,
              photoIndex,
            );
            break;
          case 'Composant personnalisé':
            await viewModel.removePhotoFromCustomComponent(
              widget.componentIndex,
              photoIndex,
            );
            break;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }
}
