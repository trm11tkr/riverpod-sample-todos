import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/todo.dart';

final _addTodoKey = UniqueKey();
final _activeFilterKey = UniqueKey();
final _completedFilterKey = UniqueKey();
final _allFilterKey = UniqueKey();

final todoListProvider = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList([
    Todo(todoId: 'todo-0', title: 'hi', createdAt: DateTime.now()),
    Todo(todoId: 'todo-1', title: 'hello', createdAt: DateTime.now()),
    Todo(todoId: 'todo-2', title: 'bonjour', createdAt: DateTime.now()),
  ]);
});

enum TodoListFilter {
  all,
  active,
  isCompleted,
}

final todoListFilter = StateProvider((_) => TodoListFilter.all);

final uncompletedTodosCount = Provider<int>((ref) {
  return ref.watch(todoListProvider).where((todo) => !todo.isCompleted).length;
});
final filteredTodos = Provider<List<Todo>>((ref) {
  final filter = ref.watch(todoListFilter);
  final todos = ref.watch(todoListProvider);

  switch (filter) {
    case TodoListFilter.isCompleted:
      return todos.where((todo) => todo.isCompleted).toList();
    case TodoListFilter.active:
      return todos.where((todo) => !todo.isCompleted).toList();
    case TodoListFilter.all:
      return todos;
  }
});

class BasicTodoPage extends HookConsumerWidget {
  const BasicTodoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(filteredTodos);
    final newTodoController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('basic todo'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          children: [
            const _Title(),
            TextField(
              key: _addTodoKey,
              controller: newTodoController,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
              ),
              onSubmitted: (value) {
                ref.read(todoListProvider.notifier).add(value);
                newTodoController.clear();
              },
            ),
            const SizedBox(height: 42),
            const Toolbar(),
            if (todos.isNotEmpty) const Divider(height: 0),
            for (var i = 0; i < todos.length; i++) ...[
              if (i > 0) const Divider(height: 0),
              Dismissible(
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
                direction: DismissDirection.endToStart,
                key: ValueKey(todos[i].todoId),
                onDismissed: (direction) {
                  ref.read(todoListProvider.notifier).remove(todos[i]);
                },
                child: ProviderScope(
                  overrides: [
                    _currentTodo.overrideWithValue(todos[i]),
                  ],
                  child: const _TodoItem(),
                ),
              )
            ],
          ],
        ),
      ),
    );
  }
}

class Toolbar extends HookConsumerWidget {
  const Toolbar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _filter = ref.watch(todoListFilter);

    Color? textColorFor(TodoListFilter value) {
      return _filter == value ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(uncompletedTodosCount).toString()} items left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: _allFilterKey,
            message: 'All todos',
            child: TextButton(
              onPressed: () =>
                  ref.read(todoListFilter.notifier).state = TodoListFilter.all,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor:
                    MaterialStateProperty.all(textColorFor(TodoListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            key: _activeFilterKey,
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.active,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.active),
                ),
              ),
              child: const Text('Active'),
            ),
          ),
          Tooltip(
            key: _completedFilterKey,
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () => ref.read(todoListFilter.notifier).state =
                  TodoListFilter.isCompleted,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TodoListFilter.isCompleted),
                ),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'todos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

final _currentTodo = Provider<Todo>((ref) => throw UnimplementedError());

class _TodoItem extends HookConsumerWidget {
  const _TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(_currentTodo);
    final _itemFocusNode = useFocusNode();
    final _itemIsFocused = _useIsFocused(_itemFocusNode);

    final _textEditingController = useTextEditingController();
    final _textFieldFocusNode = useFocusNode();

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: _itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            _textEditingController.text = todo.title;
          } else {
            ref
                .read(todoListProvider.notifier)
                .edit(todoId: todo.todoId, title: _textEditingController.text);
          }
        },
        child: ListTile(
          onTap: () {
            _itemFocusNode.requestFocus();
            _textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (value) =>
                ref.read(todoListProvider.notifier).toggle(todo.todoId),
          ),
          title: _itemIsFocused
              ? TextField(
                  autofocus: true,
                  focusNode: _textFieldFocusNode,
                  controller: _textEditingController,
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

bool _useIsFocused(FocusNode node) {
  final _isFocused = useState(node.hasFocus);

  useEffect(() {
    void listener() {
      _isFocused.value = node.hasFocus;
    }

    node.addListener(listener);
    return () => node.removeListener(listener);
  }, [node]);

  return _isFocused.value;
}
