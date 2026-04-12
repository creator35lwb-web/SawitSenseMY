/// Regional FFB price card widget.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_data.dart';
import '../l10n/l10n_provider.dart';

class RegionPriceCard extends ConsumerWidget {
  final RegionalPrice regionalPrice;

  const RegionPriceCard({super.key, required this.regionalPrice});

  IconData _regionIcon(String region) {
    switch (region) {
      case 'North':
        return Icons.north;
      case 'South':
        return Icons.south;
      case 'Central':
        return Icons.center_focus_strong;
      case 'East Coast':
        return Icons.east;
      case 'Sabah':
        return Icons.terrain;
      case 'Sarawak':
        return Icons.forest;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final tr = ref.read(trProvider);
    final regionName = localizedRegion(regionalPrice.region, locale);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(
            _regionIcon(regionalPrice.region),
            color: Colors.green.shade700,
            size: 22,
          ),
        ),
        title: Text(
          regionName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${tr('source')}: ${regionalPrice.source}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'RM ${regionalPrice.price1PctOer.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            Text(
              tr('per_1pct'),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
