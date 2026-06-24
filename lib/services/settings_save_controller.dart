import 'dart:async';

class SettingsSaveController {
  final List<Future<bool> Function()> _saveCallbacks = [];

  void register(Future<bool> Function() callback) {
    _saveCallbacks.add(callback);
  }

  void deregister(Future<bool> Function() callback) {
    _saveCallbacks.remove(callback);
  }

  Future<bool> saveAll() async {
    bool success = true;
    // We run the saves in sequence or parallel. Sequence is safer.
    for (final callback in _saveCallbacks) {
      final res = await callback();
      if (!res) {
        success = false;
      }
    }
    return success;
  }
}
