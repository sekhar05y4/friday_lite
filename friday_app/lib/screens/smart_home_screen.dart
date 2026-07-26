import 'package:flutter/material.dart';

import '../config/theme_config.dart';
import '../smarthome/smart_home_device.dart';
import '../smarthome/smart_home_manager.dart';
import '../widgets/glass_card.dart';

/// Smart Home UI Control Screen for FRIDAY.
class SmartHomeScreen extends StatefulWidget {
  const SmartHomeScreen({super.key});

  @override
  State<SmartHomeScreen> createState() => _SmartHomeScreenState();
}

class _SmartHomeScreenState extends State<SmartHomeScreen> {
  List<SmartHomeDevice> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final devices = await SmartHomeManager.instance.getAllDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleDevice(SmartHomeDevice device) async {
    final action = device.isOn ? 'turn off' : 'turn on';
    await SmartHomeManager.instance.executeCommand(device.id, action);
    await _loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    final adapters = SmartHomeManager.instance.registeredAdapterNames;

    return Scaffold(
      backgroundColor: ThemeConfig.background,
      appBar: AppBar(
        title: Text(
          'SMART HOME PLATFORM',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 14,
                letterSpacing: 4,
                color: ThemeConfig.textPrimary,
              ),
        ),
        centerTitle: true,
        backgroundColor: ThemeConfig.background,
        iconTheme: const IconThemeData(color: ThemeConfig.textSecondary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: ThemeConfig.primary,
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: ThemeConfig.primary))
          : RefreshIndicator(
              onRefresh: _loadDevices,
              color: ThemeConfig.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                children: [
                  // ── Registered Ecosystem Adapters ─────────────────────────
                  const Text(
                    'ECOSYSTEM ADAPTERS',
                    style: TextStyle(color: ThemeConfig.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: adapters
                        .map((name) => Chip(
                              label: Text(name, style: const TextStyle(fontSize: 11, color: Colors.white)),
                              backgroundColor: ThemeConfig.primary.withValues(alpha: 0.15),
                              side: BorderSide(color: ThemeConfig.primary.withValues(alpha: 0.4)),
                            ))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // ── Devices Grid ─────────────────────────────────────────
                  Text(
                    'DISCOVERED DEVICES (${_devices.length})',
                    style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      return InkWell(
                        onTap: () => _toggleDevice(device),
                        borderRadius: BorderRadius.circular(16),
                        child: GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    _getDeviceIcon(device.type),
                                    color: device.isOn ? ThemeConfig.statusListening : ThemeConfig.textMuted,
                                    size: 24,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ThemeConfig.surface,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      device.protocol.name.toUpperCase(),
                                      style: const TextStyle(color: ThemeConfig.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.name,
                                    style: const TextStyle(color: ThemeConfig.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    device.location,
                                    style: const TextStyle(color: ThemeConfig.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  IconData _getDeviceIcon(SmartHomeDeviceType type) {
    switch (type) {
      case SmartHomeDeviceType.light:
        return Icons.lightbulb_rounded;
      case SmartHomeDeviceType.switchDevice:
        return Icons.power_rounded;
      case SmartHomeDeviceType.thermostat:
        return Icons.thermostat_rounded;
      case SmartHomeDeviceType.lock:
        return Icons.lock_rounded;
      case SmartHomeDeviceType.camera:
        return Icons.videocam_rounded;
      case SmartHomeDeviceType.sensor:
        return Icons.sensors_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }
}
