import 'package:hive_flutter/hive_flutter.dart';

abstract class ISettingsRepository {
  bool getHideCompleted();
  Future<void> setHideCompleted(bool value);

  bool getInboxCollapsed();
  Future<void> setInboxCollapsed(bool value);

  ValueListenable<Box> listenable();
}

class HiveSettingsRepository implements ISettingsRepository {
  static const String boxName = 'settingsBox';
  static const String hideCompletedKey = 'hideCompleted';
  static const String inboxCollapsedKey = 'inboxCollapsed';

  Box get _box => Hive.box(boxName);

  @override
  bool getHideCompleted() => (_box.get(hideCompletedKey) as bool?) ?? false;

  @override
  Future<void> setHideCompleted(bool value) async {
    await _box.put(hideCompletedKey, value);
  }

  @override
  bool getInboxCollapsed() => (_box.get(inboxCollapsedKey) as bool?) ?? false;

  @override
  Future<void> setInboxCollapsed(bool value) async {
    await _box.put(inboxCollapsedKey, value);
  }

  @override
  ValueListenable<Box> listenable() => _box.listenable();
}
