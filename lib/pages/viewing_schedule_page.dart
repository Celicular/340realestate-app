import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/property.dart';

class ViewingSchedulePage extends StatefulWidget {
  const ViewingSchedulePage({super.key});

  @override
  State<ViewingSchedulePage> createState() => _ViewingSchedulePageState();
}

class _ViewingSchedulePageState extends State<ViewingSchedulePage> {
  // Mock data for scheduled viewings
  final List<Map<String, dynamic>> _scheduledViewings = [
    {
      'id': '1',
      'property': Property(
        id: '2',
        name: 'Cozy Family Home',
        location: 'Suburban, Los Angeles',
        price: 850000,
        imageUrl:
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
        description: 'Beautiful family home...',
        bedrooms: 3,
        bathrooms: 2,
        sqft: 2200,
        amenities: ['Garden', 'Parking'],
        type: PropertyType.house,
      ),
      'date': 'Tomorrow',
      'time': '2:00 PM',
      'status': 'Confirmed',
      'agentName': 'Sarah Johnson',
    },
    {
      'id': '2',
      'property': Property(
        id: '3',
        name: 'Urban Loft Apartment',
        location: 'Midtown, New York',
        price: 1200000,
        imageUrl:
            'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
        description: 'Stylish loft apartment...',
        bedrooms: 2,
        bathrooms: 2,
        sqft: 1800,
        amenities: ['Gym', 'Concierge'],
        type: PropertyType.rental,
      ),
      'date': 'Nov 15, 2023',
      'time': '10:30 AM',
      'status': 'Pending',
      'agentName': 'Michael Chen',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Viewing Schedule',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        child: _scheduledViewings.isEmpty
            ? _buildEmptyState(context)
            : ListView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                itemCount: _scheduledViewings.length,
                itemBuilder: (context, index) {
                  final viewing = _scheduledViewings[index];
                  return _buildViewingCard(context, viewing);
                },
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_today,
              size: 80,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'No Scheduled Viewings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Schedule a viewing from any property page.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewingCard(BuildContext context, Map<String, dynamic> viewing) {
    final property = viewing['property'] as Property;
    final status = viewing['status'] as String;
    final isConfirmed = status == 'Confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Date/Time
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: isConfirmed
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusMedium),
                topRight: Radius.circular(AppTheme.borderRadiusMedium),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: isConfirmed ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${viewing['date']} at ${viewing['time']}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isConfirmed ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConfirmed ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Property Info
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    property.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property.location,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Agent: ${viewing['agentName']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              0,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Reschedule
                    },
                    child: const Text('Reschedule'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Cancel
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel'),
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
