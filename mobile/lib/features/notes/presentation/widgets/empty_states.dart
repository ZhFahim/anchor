import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyNotesState extends StatelessWidget {
  const EmptyNotesState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.sparkles, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Capture your ideas here'),
          ],
        ),
      ),
    );
  }
}

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No matching notes found'),
          ],
        ),
      ),
    );
  }
}
