import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../controller/fire_store_controller.dart';
import '../data/todo.dart';

final addWithFireStoreKey = UniqueKey();

final collectionProvider =
    Provider((ref) => FirebaseFirestore.instance.collection('todos'));

// StreamでFireStoreのデータをリストとして取得
final todoListStreamProvider = StreamProvider.autoDispose<List<Todo>>((ref) {
  CollectionReference collection = ref.read(collectionProvider);
  return collection.snapshots().map((snapshot) {
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

    // コントローラーのインスタンス化
    final FireStoreController controller =
        FireStoreController(collection: ref.read(collectionProvider));

    return MaterialApp(
        home: GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('From FireStore'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
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
                  controller.add(value);
                  newTodoController.clear();
                },
              ),
              Expanded(
                child: todoList.when(
                    data: (todo) {
                      return ListView.builder(
                        itemBuilder: (BuildContext context, int index) {
                          return Dismissible(
                              key: ValueKey(todo[index].todoId),
                              background: Container(
                                color: Colors.red,
                                padding: EdgeInsets.only(
                                  right: 10,
                                ),
                                alignment: AlignmentDirectional.centerEnd,
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              onDismissed: (direction) {
                                controller.delete(todo[index].todoId);
                              },
                              child: FireStoreTodoItem(
                                todo: todo[index],
                                controller: controller,
                              ));
                        },
                        itemCount: todo.length,
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
      ),
    ));
  }
}

// Item
class FireStoreTodoItem extends HookWidget {
  const FireStoreTodoItem(
      {Key? key,
      required Todo this.todo,
      required FireStoreController this.controller})
      : super(key: key);
  final Todo todo;
  final FireStoreController controller;

  @override
  Widget build(BuildContext context) {
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = todo.title;
          } else {
            controller.edit(todo, textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (value) {
                controller.toggle(todo);
              }),
          title: itemIsFocused
              ? TextField(
                  autofocus: true,
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(todo.title),
          subtitle: Text(
            DateFormat.yMMMd('ja').add_Hm().format(todo.createdAt),
          ),
        ),
      ),
    );
  }
}

bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(() {
    void listener() {
      isFocused.value = node.hasFocus;
    }

    node.addListener(listener);
    return () => node.removeListener(listener);
  }, [node]);

  return isFocused.value;
}
