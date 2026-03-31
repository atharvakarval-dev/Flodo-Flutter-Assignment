import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks();
  Future<void> saveTasks(List<TaskModel> tasks);
  Future<void> saveDraft(Map<String, dynamic> draft);
  Future<Map<String, dynamic>?> getDraft();
  Future<void> clearDraft();
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String _tasksKey = 'task_tasks';
  static const String _draftKey = 'task_draft';

  final SharedPreferences _prefs;

  TaskLocalDataSourceImpl(this._prefs);

  @override
  Future<List<TaskModel>> getTasks() async {
    final jsonString = _prefs.getString(_tasksKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => TaskModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveTasks(List<TaskModel> tasks) async {
    final jsonString = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await _prefs.setString(_tasksKey, jsonString);
  }

  @override
  Future<void> saveDraft(Map<String, dynamic> draft) async {
    await _prefs.setString(_draftKey, jsonEncode(draft));
  }

  @override
  Future<Map<String, dynamic>?> getDraft() async {
    final jsonString = _prefs.getString(_draftKey);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<void> clearDraft() async {
    await _prefs.remove(_draftKey);
  }
}
