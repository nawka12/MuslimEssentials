import 'package:flutter/material.dart';
import '../models/quran.dart';
import '../localizations/app_localizations.dart';

class EditionSelector extends StatelessWidget {
  final List<QuranEdition> editions;
  final String selectedEdition;
  final ValueChanged<String> onEditionChanged;
  final bool showNoTranslationOption;

  const EditionSelector({
    Key? key,
    required this.editions,
    required this.selectedEdition,
    required this.onEditionChanged,
    this.showNoTranslationOption = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the selected edition exists in the list or is the special "no_translation" value
    bool selectedEditionExists = selectedEdition == 'no_translation' || 
        editions.any((edition) => edition.identifier == selectedEdition);
    
    // If the selection doesn't exist, use the first edition or "no_translation" as the default
    final effectiveValue = selectedEditionExists ? selectedEdition : 
                           (showNoTranslationOption ? 'no_translation' : 
                            (editions.isNotEmpty ? editions.first.identifier : ''));
    
    // Find the selected edition object if it's not "no_translation"
    final isNoTranslation = effectiveValue == 'no_translation';
    final QuranEdition selectedEditionObject = isNoTranslation 
        ? QuranEdition(
            identifier: 'no_translation',
            language: '',
            name: '',
            englishName: t(context, 'no_translation'),
            format: 'text',
            type: 'translation',
            direction: 'ltr',
          ) 
        : editions.firstWhere(
            (edition) => edition.identifier == effectiveValue,
            orElse: () => QuranEdition(
              identifier: '',
              language: 'en',
              name: '',
              englishName: t(context, 'select_translation'),
              format: 'text',
              type: 'translation',
              direction: 'ltr',
            ),
          );
    
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _showTranslationPicker(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isNoTranslation ? Icons.not_interested : Icons.translate,
                  color: isNoTranslation 
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRect(
                    child: Container(
                      height: 36,
                      alignment: Alignment.centerLeft,
                      child: isNoTranslation
                        ? Text(
                            t(context, 'translation_disabled'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: LimitedBox(
                                  maxHeight: 32,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 14,
                                        child: Text(
                                          t(context, 'translation'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        height: 16,
                                        child: Text(
                                          editions.isEmpty
                                              ? t(context, 'no_translations_available')
                                              : '${selectedEditionObject.englishName} (${selectedEditionObject.language.toUpperCase()})',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showTranslationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle indicator
                  Container(
                    height: 4,
                    width: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      t(context, 'select_translation'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  
                  if (showNoTranslationOption)
                    InkWell(
                      onTap: () {
                        onEditionChanged('no_translation');
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: selectedEdition == 'no_translation'
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.not_interested,
                              color: Theme.of(context).colorScheme.secondary,
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                t(context, 'no_translation'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: selectedEdition == 'no_translation' 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (selectedEdition == 'no_translation')
                              Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  if (editions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        t(context, 'no_translations_available'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: editions.length,
                        itemBuilder: (context, index) {
                          final edition = editions[index];
                          final isSelected = edition.identifier == selectedEdition;
                          
                          return InkWell(
                            onTap: () {
                              onEditionChanged(edition.identifier);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                    : Colors.transparent,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          edition.englishName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          edition.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      edition.language.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 20,
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
              ),
            );
          },
        );
      },
    );
  }
} 