import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class getFireStorePage extends StatefulWidget {
  @override
  State<getFireStorePage> createState() => _getFireStorePageState();
}

class _getFireStorePageState extends State<getFireStorePage> {
  final Stream<QuerySnapshot> _todosStream =
      FirebaseFirestore.instance.collection('todos').snapshots();

  final Map<String, dynamic> todolist = {};

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: Center(
          child: Column(
            children: [
              TextField(
                key: UniqueKey(),
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'What needs to be done?',
                ),
                onSubmitted: (value) {
                  onSubmit(value);
                  controller.clear();
                },
              ),
              const SizedBox(height: 10,),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _todosStream,
                  builder:
                      (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text("Loading");
                    }

                    return ListView(
                      children: snapshot.data!.docs.map((DocumentSnapshot document) {
                        Map<String, dynamic> data =
                            document.data()! as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['title'] ?? 'no data'),
                          subtitle: Text(data['todoId'] ?? 'no data'),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSubmit(String title) {
    final CollectionReference _instance = FirebaseFirestore.instance.collection('todos');
    _instance.add(
      {
        'title' : title,
        'createdAt' : DateTime.now().toIso8601String(),
        'isCompleted' : false,
        'todoId' : UniqueKey().toString()
      }
    );
  }
}
