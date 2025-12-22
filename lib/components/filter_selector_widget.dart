import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_messenger/helpers/image_filters_helper.dart';
import 'package:chat_messenger/config/theme_config.dart';

/// Widget para seleccionar y aplicar filtros a imágenes
class FilterSelectorWidget extends StatefulWidget {
  final File imageFile;
  final Function(File?) onFilterApplied;

  const FilterSelectorWidget({
    super.key,
    required this.imageFile,
    required this.onFilterApplied,
  });

  @override
  State<FilterSelectorWidget> createState() => _FilterSelectorWidgetState();
}

class _FilterSelectorWidgetState extends State<FilterSelectorWidget> {
  String _selectedFilter = 'original';
  File? _filteredImage;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _filteredImage = widget.imageFile;
  }

  Future<void> _applyFilter(String filterName) async {
    if (filterName == 'original') {
      setState(() {
        _selectedFilter = filterName;
        _filteredImage = widget.imageFile;
      });
      widget.onFilterApplied(widget.imageFile);
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedFilter = filterName;
    });

    try {
      final File? filtered = await ImageFiltersHelper.applyFilter(
        imageFile: widget.imageFile,
        filterName: filterName,
        intensity: 1.0,
      );

      if (filtered != null && mounted) {
        setState(() {
          _filteredImage = filtered;
          _isProcessing = false;
        });
        widget.onFilterApplied(filtered);
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al aplicar filtro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = ImageFiltersHelper.getAvailableFilters();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Preview de la imagen
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isProcessing
              ? const Center(child: CircularProgressIndicator())
              : _filteredImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _filteredImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(child: Icon(Icons.image, size: 64)),
        ),
        const SizedBox(height: 20),
        
        // Lista de filtros
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = _selectedFilter == filter['name'];
              
              return GestureDetector(
                onTap: () => _applyFilter(filter['name'] as String),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        filter['icon'] as String,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        filter['label'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white : Colors.black),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}





















