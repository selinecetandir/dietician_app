import 'package:flutter/material.dart';
import '../../../data/repository_locator.dart';
import '../../../data/models/weight_entry_model.dart';
import '../../../shared/widgets/weight_progress_chart.dart';

class WeightLogScreen extends StatefulWidget {
  const WeightLogScreen({super.key});

  @override
  State<WeightLogScreen> createState() => _WeightLogScreenState();
}

class _WeightLogScreenState extends State<WeightLogScreen> {
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  List<WeightEntryModel> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;
    final entries = await RepositoryLocator.weight.getWeightEntriesForPatient(user.id);
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  Future<void> _addEntry() async {
    final user = RepositoryLocator.auth.currentUser;
    if (user == null) return;

    _weightCtrl.clear();
    _noteCtrl.clear();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddWeightSheet(
        weightCtrl: _weightCtrl,
        noteCtrl: _noteCtrl,
      ),
    );

    if (result == true) {
      final weight = double.tryParse(_weightCtrl.text.trim());
      if (weight == null || weight <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid weight.')),
          );
        }
        return;
      }

      final entry = WeightEntryModel(
        id: '',
        patientId: user.id,
        weight: weight,
        date: DateTime.now(),
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );
      await RepositoryLocator.weight.addWeightEntry(entry);
      await RepositoryLocator.firebaseAuth.updateUserProfile({'weight': weight});
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Weight logged: ${weight.toStringAsFixed(1)} kg')),
        );
      }
    }
  }

  Future<void> _confirmDelete(WeightEntryModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
          'Remove the ${entry.weight.toStringAsFixed(1)} kg record '
          'from ${_formatDate(entry.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await RepositoryLocator.weight.deleteWeightEntry(entry.id);
      await _load();
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    return '${_formatDate(dt)} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final reversedEntries = List<WeightEntryModel>.from(_entries.reversed);

    return Scaffold(
      appBar: AppBar(title: const Text('Weight Tracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: const Text('Log Weight'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: WeightProgressChart(entries: _entries),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'History',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (reversedEntries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Tap "Log Weight" to add your first record.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  )
                else
                  ...reversedEntries.asMap().entries.map((mapEntry) {
                    final i = mapEntry.key;
                    final entry = mapEntry.value;

                    String? changeText;
                    Color? changeColor;
                    if (i < reversedEntries.length - 1) {
                      final prev = reversedEntries[i + 1];
                      final change = entry.weight - prev.weight;
                      if (change != 0) {
                        changeText = change > 0
                            ? '+${change.toStringAsFixed(1)} kg'
                            : '${change.toStringAsFixed(1)} kg';
                        changeColor = change < 0 ? Colors.green : Colors.orange;
                      }
                    }

                    return Card(
                      elevation: 0,
                      color: colorScheme.surfaceContainerLow,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.monitor_weight_outlined,
                            size: 20,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              '${entry.weight.toStringAsFixed(1)} kg',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (changeText != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: changeColor!.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  changeText,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: changeColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDateTime(entry.date),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            if (entry.note != null && entry.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  entry.note!,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, size: 18, color: colorScheme.error),
                          onPressed: () => _confirmDelete(entry),
                          tooltip: 'Delete record',
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

class _AddWeightSheet extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController noteCtrl;

  const _AddWeightSheet({
    required this.weightCtrl,
    required this.noteCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Log Weight',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Record your current weight to track your progress.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 72.5',
              border: OutlineInputBorder(),
              suffixText: 'kg',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. After breakfast, morning...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_alt_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
