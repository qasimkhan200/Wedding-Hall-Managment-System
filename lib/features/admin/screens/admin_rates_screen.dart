import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/commercial_rates_model.dart';
import '../../../core/services/commercial_rates_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminRatesScreen extends StatefulWidget {
  const AdminRatesScreen({super.key});

  @override
  State<AdminRatesScreen> createState() => _AdminRatesScreenState();
}

class _AdminRatesScreenState extends State<AdminRatesScreen>
    with SingleTickerProviderStateMixin {
  final CommercialRatesService _service = CommercialRatesService();
  late TabController _tabController;
  bool _isLoading = true;
  CommercialRatesModel? _rates;

  // Controllers
  final Map<String, TextEditingController> _commissionControllers = {};
  final Map<String, TextEditingController> _vehicleControllers =
      {}; // 'bike_base', 'bike_km', etc.
  final TextEditingController _riderSplitController = TextEditingController();
  final TextEditingController _emergencyPremiumController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    final rates = await _service.getRates(forceRefresh: true);

    // Initialize controllers
    rates.commissionTiers.forEach((key, value) {
      _commissionControllers[key] =
          TextEditingController(text: (value * 100).toStringAsFixed(1));
    });

    // Initialize vehicle controllers for ALL types, using defaults if missing
    final vehicleTypes = ['bike', 'car', 'van'];
    for (var vehicle in vehicleTypes) {
      final data = rates.vehicleRates[vehicle] ??
          CommercialRatesModel.defaults().vehicleRates[vehicle] ??
          {'base': 0, 'perKm': 0};

      _vehicleControllers['${vehicle}_base'] =
          TextEditingController(text: (data['base'] ?? 0).toString());
      _vehicleControllers['${vehicle}_km'] =
          TextEditingController(text: (data['perKm'] ?? 0).toString());
    }

    _riderSplitController.text =
        (rates.riderSplitPercentage * 100).toStringAsFixed(1);
    _emergencyPremiumController.text =
        (rates.emergencyPremiumPercentage * 100).toStringAsFixed(1);

    setState(() {
      _rates = rates;
      _isLoading = false;
    });
  }

  Future<void> _saveRates() async {
    if (_rates == null) return;

    setState(() => _isLoading = true);

    try {
      final newCommissions = <String, double>{};
      _commissionControllers.forEach((key, controller) {
        newCommissions[key] = (double.tryParse(controller.text) ?? 0) / 100.0;
      });

      final newVehicleRates = <String, dynamic>{};
      // We expect keys like 'bike_base', 'bike_km'
      // Group them by vehicle type
      final vehicleTypes = ['bike', 'car', 'van'];
      for (var type in vehicleTypes) {
        newVehicleRates[type] = {
          'base': double.tryParse(
                  _vehicleControllers['${type}_base']?.text ?? '0') ??
              0.0,
          'perKm':
              double.tryParse(_vehicleControllers['${type}_km']?.text ?? '0') ??
                  0.0,
        };
      }

      final newRiderSplit =
          (double.tryParse(_riderSplitController.text) ?? 70) / 100.0;
      final newEmergency =
          (double.tryParse(_emergencyPremiumController.text) ?? 30) / 100.0;

      final newRates = _rates!.copyWith(
        commissionTiers: newCommissions,
        riderSplitPercentage: newRiderSplit,
        emergencyPremiumPercentage: newEmergency,
        vehicleRates: newVehicleRates,
      );

      await _service.updateRates(newRates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rates updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating rates: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commercial Rates Configuration',
            style: TextStyle(
              color: AppColors.primary,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveRates,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Commissions'),
            Tab(text: 'Vehicles'),
            Tab(text: 'Multipliers'),
            Tab(text: 'Payouts'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCommissionsTab(),
                _buildVehiclesTab(),
                _buildMultipliersTab(), // Placeholder for now
                _buildPayoutsTab(),
              ],
            ),
    );
  }

  Widget _buildCommissionsTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSectionHeader('Vendor Commission Tiers'),
        Text('Percentage of subtotal taken by platform (0-100%)',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        SizedBox(height: 16.h),
        ..._commissionControllers.entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: TextField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: '${entry.key.toUpperCase()} Tier (%)',
                border: const OutlineInputBorder(),
                suffixText: '%',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          );
        }),
        const SizedBox(height: 24),
        _buildSectionHeader('Emergency Premium'),
        const Text('Additional surcharge for emergency orders',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        TextField(
          controller: _emergencyPremiumController,
          decoration: const InputDecoration(
            labelText: 'Emergency Surcharge (%)',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      ],
    );
  }

  Widget _buildVehiclesTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSectionHeader('Vehicle Based Pricing'),
        Text('Configure base charges and per-km rates for each vehicle type.',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        SizedBox(height: 16.h),
        _buildVehicleInputs('Motorcycle / Bike', 'bike', Icons.two_wheeler),
        _buildVehicleInputs('Car / Sedan', 'car', Icons.directions_car),
        _buildVehicleInputs('Van / Truck', 'van', Icons.local_shipping),
      ],
    );
  }

  Widget _buildVehicleInputs(String title, String key, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 24.w),
                SizedBox(width: 8.w),
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16.sp)),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _vehicleControllers['${key}_base'],
                    decoration: const InputDecoration(
                      labelText: 'Base Fee (PKR)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _vehicleControllers['${key}_km'],
                    decoration: const InputDecoration(
                      labelText: 'Per Km (PKR)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSectionHeader('Rider Payout Split'),
        Text('Percentage of delivery fee paid to rider',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        SizedBox(height: 16.h),
        TextField(
          controller: _riderSplitController,
          decoration: const InputDecoration(
            labelText: 'Rider Share (%)',
            border: OutlineInputBorder(),
            suffixText: '%',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SizedBox(height: 24.h),
        _buildPayoutCalculatorWithController(),
      ],
    );
  }

  // Calculator controller
  final TextEditingController _calculatorAmountController =
      TextEditingController(text: '200');

  Widget _buildPayoutCalculatorWithController() {
    double amount = double.tryParse(_calculatorAmountController.text) ?? 0;
    double split = double.tryParse(_riderSplitController.text) ?? 70;
    double riderEarn = amount * (split / 100);
    double platformEarn = amount - riderEarn;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rider Payout Calculator',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
            SizedBox(height: 8.h),
            Text(
                'Enter a delivery fee to see the split based on current settings.',
                style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            TextField(
              controller: _calculatorAmountController,
              decoration: const InputDecoration(
                labelText: 'Delivery Fee Amount (PKR)',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildResultBox('Rider Amount',
                      'PKR ${riderEarn.toStringAsFixed(0)}', Colors.green),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildResultBox('Platform Fee',
                      'PKR ${platformEarn.toStringAsFixed(0)}', Colors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBox(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
          SizedBox(height: 4.h),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18.sp)),
        ],
      ),
    );
  }

  Widget _buildMultipliersTab() {
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        _buildSectionHeader('Regional Multipliers'),
        if (_rates != null && _rates!.areaMultipliers.isNotEmpty)
          ..._rates!.areaMultipliers.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value}x'),
                subtitle: const Text('Area Surcharge'),
              ))
        else
          const Text('No active area multipliers'),
        Divider(height: 32.h),
        _buildSectionHeader('Seasonal Multipliers'),
        if (_rates != null && _rates!.seasonalMultipliers.isNotEmpty)
          ..._rates!.seasonalMultipliers.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text('${e.value['multiplier']}x'),
                subtitle: Text(
                    'Month ${e.value['startMonth']} - ${e.value['endMonth']}'),
              ))
        else
          const Text('No active seasonal multipliers'),
        SizedBox(height: 16.h),
        const Center(
            child: Text('Advanced multiplier editing coming soon in v2',
                style: TextStyle(color: Colors.grey))),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commissionControllers.forEach((_, c) => c.dispose());
    _vehicleControllers.forEach((_, c) => c.dispose());
    _riderSplitController.dispose();
    _emergencyPremiumController.dispose();
    _calculatorAmountController.dispose();
    super.dispose();
  }
}
