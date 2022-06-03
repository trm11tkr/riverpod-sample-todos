import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../data/todo.dart';

/// FirestoreのTodoに対するコントローラ
class FirestoreController {
  FirestoreController({required CollectionReference this.collection});
  CollectionReference collection;

  /// Todoの追加
  void add(String title) {
    final String todoId = (Uuid().v1()).toString();
    collection.doc(todoId).set(
          Todo(todoId: todoId, title: title, createdAt: DateTime.now())
              .toJson(),
        );
  }

  /// Todoの削除
  void delete(String todoId) {
    collection.doc(todoId).delete();
  }

  /// Todoのステータスを反転
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
