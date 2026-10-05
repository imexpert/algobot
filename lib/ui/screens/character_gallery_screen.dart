import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../characters/character_painter.dart';
import '../../characters/character_registry.dart';
import '../../core/colors.dart';
import '../../l10n/l10n.dart';
import '../../models/direction.dart';
import '../widgets/character_view.dart';

/// Geliştirici görsel kontrol ekranı: her karakter 4 yön × 5 durum.
/// Yalnızca debug derlemesinde açılır.
class CharacterGalleryScreen extends StatelessWidget {
  const CharacterGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(context.l10n.gallery),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: CharacterRegistry.all.length,
        itemBuilder: (context, i) {
          final def = CharacterRegistry.all[i];
          return Card(
            color: AppColors.panel,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.l10n.characterName(def.id)} (${def.id})',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {0: FixedColumnWidth(64)},
                    children: [
                      TableRow(
                        children: [
                          const SizedBox(),
                          for (final d in Direction.values)
                            Center(child: _label(d.name)),
                        ],
                      ),
                      for (final s in CharacterState.values)
                        TableRow(
                          children: [
                            _label(s.name),
                            for (final d in Direction.values)
                              SizedBox(
                                height: 72,
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  color: AppColors.floor,
                                  child: CharacterView(
                                    character: def,
                                    facing: d,
                                    state: s,
                                    showDisc: true,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.all(4),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    ),
  );
}
