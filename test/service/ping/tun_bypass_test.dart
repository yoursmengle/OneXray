import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/service/ping/state.dart';
import 'package:onexray/service/ping/tun_bypass.dart';
import 'package:onexray/service/tun_settings/state.dart';

void main() {
  test('applies interface to proxy outbounds and skips system outbounds', () {
    const source = '''
{
  "outbounds": [
    {"protocol": "vless", "tag": "proxy"},
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "block"},
    {"protocol": "dns", "tag": "dns-out"}
  ]
}
''';

    final patched = PingTunBypass.applyToXrayJsonText(
      source,
      apply: true,
      interfaceName: 'auto',
    );
    final json = jsonDecode(patched) as Map<String, dynamic>;
    final outbounds = (json['outbounds'] as List).cast<Map<String, dynamic>>();

    expect(outbounds[0]['streamSettings']['sockopt']['interface'], 'auto');
    expect(outbounds[1].containsKey('streamSettings'), isFalse);
    expect(outbounds[2].containsKey('streamSettings'), isFalse);
    expect(outbounds[3].containsKey('streamSettings'), isFalse);
  });

  test('does not change json when apply is false', () {
    const source = '{"outbounds":[{"protocol":"vmess","tag":"proxy"}]}';

    final patched = PingTunBypass.applyToXrayJsonText(
      source,
      apply: false,
      interfaceName: 'auto',
    );

    expect(patched, source);
  });

  test('preserves existing sockopt fields', () {
    const source = '''
{
  "outbounds": [
    {
      "protocol": "trojan",
      "tag": "proxy",
      "streamSettings": {
        "sockopt": {"tcpFastOpen": true}
      }
    }
  ]
}
''';

    final patched = PingTunBypass.applyToXrayJsonText(
      source,
      apply: true,
      interfaceName: 'Ethernet',
    );
    final json = jsonDecode(patched) as Map<String, dynamic>;
    final sockopt =
        ((json['outbounds'] as List).first
                as Map<String, dynamic>)['streamSettings']['sockopt']
            as Map<String, dynamic>;

    expect(sockopt['interface'], 'Ethernet');
    expect(sockopt['tcpFastOpen'], isTrue);
  });

  test('ping timeout range and probe urls stay unchanged', () {
    expect(PingTimeout.min, 3);
    expect(PingTimeout.max, 8);
    expect(PingTimeout.defaultValue, 5);
    expect(PingUrl.cloudflare.url, 'https://cp.cloudflare.com/');
    expect(PingUrl.google.url, 'https://www.google.com/generate_204');
    expect(TunSettingsState.autoOutboundsInterfaceAuto, 'auto');
  });
}
