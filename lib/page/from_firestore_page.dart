import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../data/todo.dart';

final addWithFireStoreKey = UniqueKey();

final todoListStreamProvider = StreamProvider.autoDispose<List<Todo>>((_) {
  CollectionReference ref = FirebaseFirestore.instance.collection('todos');
  return ref.snapshots().map((snapshot) {
    final List<Todo> list = snapshot.docs
        .map((doc) => Todo.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
    return list;
  });
});

class FromFireStorePage extends HookConsumerWidget {
  const FromFireStorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Todo>> todoList = ref.watch(todoListStreamProvider);
    final newTodoController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('From FireStore'),
      ),
      body: Container(
        margin: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Column(
          children: [
            TextField(
              key: addWithFireStoreKey,
              controller: newTodoController,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
              ),
              onSubmitted: (value) {
                onSubmit(value);
                newTodoController.clear();
              },
            ),
            Expanded(
              child: todoList.when(
                  data: (data) {
                    return ListView.builder(
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          title: Text(data[index].title),
                          subtitle: Text(DateFormat.yMMMd('ja')
                              .add_Hm()
                              .format(data[index].createdAt)),
                        );
                      },
                      itemCount: data.length,
                    );
                  },
                  error: (error, stack) => Text('Error: $error'),
                  loading: () {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void onSubmit(String title) {
    print('submit');
    final String todoId = Uuid().v1.toString();
    final CollectionReference _instance =
        FirebaseFirestore.instance.collection('todos');
    _instance.doc(todoId).set(
          Todo(todoId: todoId, title: title, createdAt: DateTime.now())
              .toJson(),
        );
  }
}
