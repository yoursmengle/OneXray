import 'dart:convert';

import 'package:onexray/core/tools/json.dart';

abstract final class PingTunBypass {
  static const skippedProtocols = {'freedom', 'blackhole', 'dns'};

  static String applyToXrayJsonText(
    String jsonText, {
    required bool apply,
    required String interfaceName,
  }) {
    if (!apply || interfaceName.isEmpty) {
      return jsonText;
    }
    final decoded = json.decode(jsonText);
    if (decoded is! Map) {
      return jsonText;
    }
    final map = Map<String, dynamic>.from(decoded);
    applyToJsonMap(map, interfaceName);
    return JsonTool.encoder.convert(map);
  }

  static void applyToJsonMap(
    Map<String, dynamic> xrayJson,
    String interfaceName,
  ) {
    final outbounds = xrayJson['outbounds'];
    if (outbounds is! List) {
      return;
    }
    for (var index = 0; index < outbounds.length; index++) {
      final item = outbounds[index];
      if (item is! Map) {
        continue;
      }
      final outbound = Map<String, dynamic>.from(item);
      if (_shouldSkip(outbound)) {
        continue;
      }
      _setInterface(outbound, interfaceName);
      outbounds[index] = outbound;
    }
  }

  static bool _shouldSkip(Map<String, dynamic> outbound) {
    final protocol = outbound['protocol']?.toString().toLowerCase();
    final tag = outbound['tag']?.toString().toLowerCase();
    return skippedProtocols.contains(protocol) ||
        skippedProtocols.contains(tag);
  }

  static void _setInterface(
    Map<String, dynamic> outbound,
    String interfaceName,
  ) {
    final stream = outbound['streamSettings'];
    final streamSettings = stream is Map
        ? Map<String, dynamic>.from(stream)
        : <String, dynamic>{};
    final sockopt = streamSettings['sockopt'];
    final sockoptMap = sockopt is Map
        ? Map<String, dynamic>.from(sockopt)
        : <String, dynamic>{};
    sockoptMap['interface'] = interfaceName;
    streamSettings['sockopt'] = sockoptMap;
    outbound['streamSettings'] = streamSettings;
  }
}
