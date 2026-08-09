/// Represents real-time system performance telemetry and LLM token quota metrics.
class TelemetryData {
  final double cpuUsage;
  final List<double> perCpu;
  final double ramPercent;
  final double ramUsedGb;
  final double ramTotalGb;
  final int batteryPercent;
  final bool isCharging;
  final List<Map<String, dynamic>> topApps;
  final List<String> networks;
  final int lastPromptTokens;
  final int lastCompletionTokens;
  final int totalPromptTokens;
  final int totalCompletionTokens;

  // Gemini Free Tier Rate Limit Counters
  final int requestsPerMin;
  final int tokensPerMin;
  final int requestsToday;

  const TelemetryData({
    this.cpuUsage = 0.0,
    this.perCpu = const [12.0, 8.5, 15.0, 6.2, 10.0, 14.5, 9.0, 11.2],
    this.ramPercent = 0.0,
    this.ramUsedGb = 0.0,
    this.ramTotalGb = 0.0,
    this.batteryPercent = 100,
    this.isCharging = true,
    this.topApps = const [],
    this.networks = const ['Wi-Fi'],
    this.lastPromptTokens = 0,
    this.lastCompletionTokens = 0,
    this.totalPromptTokens = 0,
    this.totalCompletionTokens = 0,
    this.requestsPerMin = 0,
    this.tokensPerMin = 0,
    this.requestsToday = 0,
  });

  int get lastTotalTokens => lastPromptTokens + lastCompletionTokens;
  int get grandTotalTokens => totalPromptTokens + totalCompletionTokens;

  factory TelemetryData.fromJson(Map<String, dynamic> json, {
    int lastPromptTokens = 0,
    int lastCompletionTokens = 0,
    int totalPromptTokens = 0,
    int totalCompletionTokens = 0,
    int requestsPerMin = 0,
    int tokensPerMin = 0,
    int requestsToday = 0,
  }) {
    final ram = json['ram_usage'] as Map<String, dynamic>? ?? {};
    final bat = json['battery'] as Map<String, dynamic>? ?? {};
    final appsRaw = json['top_apps'] as List<dynamic>? ?? [];
    final netsRaw = json['networks'] as List<dynamic>? ?? [];
    final perCpuRaw = json['per_cpu'] as List<dynamic>? ?? [];

    return TelemetryData(
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble() ?? 0.0,
      perCpu: perCpuRaw.map((e) => (e as num).toDouble()).toList(),
      ramPercent: (ram['percent'] as num?)?.toDouble() ?? 0.0,
      ramUsedGb: (ram['used_gb'] as num?)?.toDouble() ?? 0.0,
      ramTotalGb: (ram['total_gb'] as num?)?.toDouble() ?? 0.0,
      batteryPercent: (bat['percent'] as num?)?.toInt() ?? 100,
      isCharging: bat['is_charging'] as bool? ?? true,
      topApps: appsRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      networks: netsRaw.map((e) => e.toString()).toList(),
      lastPromptTokens: lastPromptTokens,
      lastCompletionTokens: lastCompletionTokens,
      totalPromptTokens: totalPromptTokens,
      totalCompletionTokens: totalCompletionTokens,
      requestsPerMin: requestsPerMin,
      tokensPerMin: tokensPerMin,
      requestsToday: requestsToday,
    );
  }

  TelemetryData copyWith({
    double? cpuUsage,
    List<double>? perCpu,
    double? ramPercent,
    double? ramUsedGb,
    double? ramTotalGb,
    int? batteryPercent,
    bool? isCharging,
    List<Map<String, dynamic>>? topApps,
    List<String>? networks,
    int? lastPromptTokens,
    int? lastCompletionTokens,
    int? totalPromptTokens,
    int? totalCompletionTokens,
    int? requestsPerMin,
    int? tokensPerMin,
    int? requestsToday,
  }) {
    return TelemetryData(
      cpuUsage: cpuUsage ?? this.cpuUsage,
      perCpu: perCpu ?? this.perCpu,
      ramPercent: ramPercent ?? this.ramPercent,
      ramUsedGb: ramUsedGb ?? this.ramUsedGb,
      ramTotalGb: ramTotalGb ?? this.ramTotalGb,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      topApps: topApps ?? this.topApps,
      networks: networks ?? this.networks,
      lastPromptTokens: lastPromptTokens ?? this.lastPromptTokens,
      lastCompletionTokens: lastCompletionTokens ?? this.lastCompletionTokens,
      totalPromptTokens: totalPromptTokens ?? this.totalPromptTokens,
      totalCompletionTokens: totalCompletionTokens ?? this.totalCompletionTokens,
      requestsPerMin: requestsPerMin ?? this.requestsPerMin,
      tokensPerMin: tokensPerMin ?? this.tokensPerMin,
      requestsToday: requestsToday ?? this.requestsToday,
    );
  }
}
