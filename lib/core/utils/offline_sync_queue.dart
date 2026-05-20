import 'package:hive/hive.dart';
import 'dart:async';

enum SyncAction { create, update, delete }

class SyncQueueItem {
  final String id;
  final String entityType;
  final String entityId;
  final SyncAction action;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType,
        'entityId': entityId,
        'action': action.name,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
        id: json['id'],
        entityType: json['entityType'],
        entityId: json['entityId'],
        action: SyncAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => SyncAction.create,
        ),
        data: Map<String, dynamic>.from(json['data'] ?? {}),
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'] ?? 0,
      );
}

class OfflineSyncQueue {
  static const String _boxName = 'sync_queue';
  static Box<Map>? _box;
  static Timer? _syncTimer;

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Map>(_boxName);
    } else {
      _box = Hive.box<Map>(_boxName);
    }
  }

  static Future<void> enqueue({
    required String entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> data,
  }) async {
    await init();

    final item = SyncQueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      data: data,
      timestamp: DateTime.now(),
    );

    await _box!.put(item.id, item.toJson());
  }

  static Future<List<SyncQueueItem>> getPendingItems() async {
    await init();
    return _box!.values
        .map((v) => SyncQueueItem.fromJson(Map<String, dynamic>.from(v)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static Future<void> removeItem(String id) async {
    await init();
    await _box!.delete(id);
  }

  static Future<void> incrementRetryCount(String id) async {
    await init();
    final item = _box!.get(id);
    if (item != null) {
      final syncItem = SyncQueueItem.fromJson(Map<String, dynamic>.from(item));
      final updated = SyncQueueItem(
        id: syncItem.id,
        entityType: syncItem.entityType,
        entityId: syncItem.entityId,
        action: syncItem.action,
        data: syncItem.data,
        timestamp: syncItem.timestamp,
        retryCount: syncItem.retryCount + 1,
      );
      await _box!.put(id, updated.toJson());
    }
  }

  static Future<void> clear() async {
    await init();
    await _box!.clear();
  }

  static int get pendingCount => _box?.length ?? 0;

  // Start periodic sync attempts
  static void startPeriodicSync({
    required Future<bool> Function() onSync,
    Duration interval = const Duration(minutes: 5),
  }) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) async {
      final items = await getPendingItems();
      if (items.isNotEmpty) {
        await onSync();
      }
    });
  }

  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
