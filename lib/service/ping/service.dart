import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:onexray/core/model/xray_standard.dart';
import 'package:onexray/core/tools/json.dart';
import 'package:onexray/core/tools/logger.dart';
import 'package:onexray/service/event_bus/service.dart';
import 'package:onexray/core/db/database/constants.dart';
import 'package:onexray/core/db/database/database.dart';
import 'package:onexray/core/db/database/enum.dart';
import 'package:onexray/core/tools/empty.dart';
import 'package:onexray/service/localizations/service.dart';
import 'package:onexray/core/tools/platform.dart';
import 'package:onexray/service/ping/batch.dart';
import 'package:onexray/service/ping/state.dart';
import 'package:onexray/service/ping/tun_bypass.dart';
import 'package:onexray/service/tun_settings/state.dart';
import 'package:onexray/service/xray/full_config/state.dart';
import 'package:onexray/service/xray/full_config/state_reader.dart';
import 'package:onexray/service/xray/full_config/state_writer.dart';
import 'package:onexray/service/xray/outbound/state.dart';
import 'package:onexray/service/xray/outbound/state_reader.dart';
import 'package:onexray/service/xray/outbound/state_writer.dart';

class PingService {
  static final PingService _singleton = PingService._internal();

  factory PingService() => _singleton;

  PingService._internal();

  Future<void> _scheduledPingQueue = Future.value();
  var _pingingTaskCount = 0;

  Future<void> pingOutboundConfigs(int subId) async {
    final db = AppDatabase();
    await _runPinging(() async {
      final rows = await db.coreConfigDao.allOutboundRowsWithDataBySubId(subId);
      await _pingConfigs(db, rows);
    });
  }

  Future<void> pingHomeNodeConfigs(int subId) async {
    final db = AppDatabase();
    await _runPinging(() async {
      final rows = await db.coreConfigDao.allHomeNodeRowsWithDataBySubId(subId);
      await _pingConfigs(db, rows);
    });
  }

  void schedulePingConfigIds(List<int> ids) {
    final targetIds = ids
        .where((id) => id > DBConstants.defaultId)
        .toSet()
        .toList();
    if (targetIds.isEmpty) {
      return;
    }
    _enqueueAutoPing(() async {
      final db = AppDatabase();
      final rows = <CoreConfigData>[];
      for (final id in targetIds) {
        final row = await db.coreConfigDao.searchRow(id);
        if (row != null && _isPingableConfig(row)) {
          rows.add(row);
        }
      }
      if (rows.isEmpty) {
        return;
      }
      await _runPinging(() => _pingConfigs(db, rows));
    });
  }

  void schedulePingSubscription(int subId) {
    schedulePingSubscriptions([subId]);
  }

  void schedulePingSubscriptions(Iterable<int> subIds) {
    final targetSubIds = subIds
        .where((id) => id > DBConstants.defaultId)
        .toSet()
        .toList(growable: false);
    if (targetSubIds.isEmpty) {
      return;
    }
    _enqueueAutoPing(() async {
      final db = AppDatabase();
      final rows = <CoreConfigData>[];
      for (final subId in targetSubIds) {
        rows.addAll(
          await db.coreConfigDao.allOutboundRowsWithDataBySubId(subId),
        );
      }
      if (rows.isEmpty) {
        return;
      }
      await _runPinging(() => _pingConfigs(db, rows));
    });
  }

  void _enqueueAutoPing(Future<void> Function() task) {
    _scheduledPingQueue = _scheduledPingQueue.then((_) async {
      try {
        final pingState = PingState();
        await pingState.readFromPreferences();
        if (!pingState.autoPingNewConfigs) {
          return;
        }
        await task();
      } catch (e, stackTrace) {
        ygLogger("Auto ping failed: $e\n$stackTrace");
      }
    });
  }

  Future<void> _runPinging(Future<void> Function() task) async {
    _startPinging();
    try {
      await task();
    } finally {
      _stopPinging();
    }
  }

  void _startPinging() {
    _pingingTaskCount += 1;
    if (_pingingTaskCount == 1) {
      AppEventBus.instance.updatePinging(true);
    }
  }

  void _stopPinging() {
    if (_pingingTaskCount > 0) {
      _pingingTaskCount -= 1;
    }
    if (_pingingTaskCount == 0) {
      AppEventBus.instance.updatePinging(false);
    }
  }

  bool _isPingableConfig(CoreConfigData row) {
    final type = CoreConfigType.fromString(row.type);
    return type == CoreConfigType.outbound ||
        type == CoreConfigType.raw ||
        type == CoreConfigType.full;
  }

  Future<void> _pingConfigs(AppDatabase db, List<CoreConfigData> rows) async {
    final pingState = PingState();
    await pingState.readFromPreferences();
    final tunSettings = TunSettingsState();
    await tunSettings.readFromPreferences();
    final interfaceName = tunSettings.autoOutboundsInterface;

    for (final rowSlice in rows.slices(PingBatchRunner.maxBatchSize)) {
      final batchRows = <CoreConfigData>[];
      final sources = <PingBatchSource>[];
      for (final row in rowSlice) {
        final source = _makePingSource(row, interfaceName);
        if (source != null) {
          batchRows.add(row);
          sources.add(source);
        }
      }
      if (sources.isEmpty) {
        continue;
      }

      final results = await PingBatchRunner.run(sources, pingState);
      await db.transaction(() async {
        for (var index = 0; index < results.length; index++) {
          await _updateRow(db, batchRows[index], results[index].delay);
        }
      });
    }
  }

  PingBatchSource? _makePingSource(CoreConfigData row, String interfaceName) {
    if (!EmptyTool.checkString(row.data)) {
      return null;
    }
    try {
      final type = CoreConfigType.fromString(row.type);
      final encoded = switch (type) {
        CoreConfigType.outbound => _encodeOutbound(row),
        CoreConfigType.raw => utf8.decode(base64Decode(row.data!)),
        CoreConfigType.full => _encodeFullConfig(row),
        _ => null,
      };
      if (encoded == null) {
        return null;
      }
      return PingBatchSource(
        PingTunBypass.applyToXrayJsonText(
          encoded,
          apply: AppPlatform.isWindows || AppPlatform.isLinux,
          interfaceName: interfaceName,
        ),
      );
    } catch (error, stackTrace) {
      ygLogger("Prepare ping source failed: ${row.id}, $error\n$stackTrace");
      return null;
    }
  }

  String? _encodeOutbound(CoreConfigData row) {
    final outbound = OutboundState();
    if (!outbound.readFromDbData(row)) {
      return null;
    }
    final xrayJson = XrayJsonStandard.standard..outbounds = [outbound.xrayJson];
    return JsonTool.encoder.convert(xrayJson.toJson());
  }

  String _encodeFullConfig(CoreConfigData row) {
    final state = XrayFullConfigState()..readFromDbData(row);
    return JsonTool.encoder.convert(state.xrayJson.toJson());
  }

  Future<void> _updateRow(AppDatabase db, CoreConfigData row, int delay) async {
    var newRow = row;
    if (delay != PingDelayConstants.unknown) {
      newRow = newRow.copyWith(delay: delay);
    }
    await db.coreConfigDao.updateRow(newRow);
  }

  String parsePingResponse(int delay) {
    var content = "";
    switch (delay) {
      case PingDelayConstants.timeout:
        content = appLocalizationsNoContext().pingTimeout;
        break;
      case PingDelayConstants.error:
        content = appLocalizationsNoContext().pingError;
        break;
      default:
        content = "${delay}ms";
        break;
    }

    return content;
  }
}
