import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:uuid/uuid.dart';

part 'todo.freezed.dart';

part 'todo.g.dart';

const _uuid = Uuid();

@freezed
class Todo with _$Todo {
  const factory Todo({
    required String todoId,
    required String title,
    @Default(false) bool completed,
    required DateTime createdAt,
  }) = _Todo;

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);
}

/// An object that controls a list of [Todo].
class TodoList extends StateNotifier<List<Todo>> {
  TodoList([List<Todo>? initialTodos]) : super(initialTodos ?? []);

  void add(String title) {
    state = [
      ...state,
      Todo(
        todoId: _uuid.v4(),
        title: title,
        createdAt: DateTime.now(),
      ),
    ];
  }

  void toggle(String todoId) {
    state = [
      for (final todo in state)
        if (todo.todoId == todoId)
          todo.copyWith(
            completed: !todo.completed,
          )
        else
          todo
    ];
  }

  void edit({required String todoId, required String title}) {
    state = [
      for (final todo in state)
        if (todo.todoId == todoId)
          todo.copyWith(
            title: title,
          )
        else
          todo,
    ];
  }

  void remove(Todo target) {
    state = state.where((todo) => todo.todoId != target.todoId).toList();
  }
}
