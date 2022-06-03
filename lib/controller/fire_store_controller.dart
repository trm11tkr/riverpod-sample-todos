import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/todo.dart';

/// FireStoreのTodoに対するコントローラ
class FireStoreController {
  FireStoreController({required CollectionReference this.collection});
  CollectionReference collection;

  void add(String title) {
    final String todoId = (Uuid().v1()).toString();
    collection.doc(todoId).set(
          Todo(todoId: todoId, title: title, createdAt: DateTime.now())
              .toJson(),
        );
  }

  void delete(String todoId) {
    collection.doc(todoId).delete();
  }

  /// Todoの削除
  void toggle(Todo todo) {
    collection.doc(todo.todoId).update(
          todo
              .copyWith(
                isCompleted: !todo.isCompleted,
              )
              .toJson(),
        );
  }

  /// Todoの編集
  void edit(Todo todo, String title) {
    collection.doc(todo.todoId).update(
          todo.copyWith(title: title).toJson(),
        );
  }
}
