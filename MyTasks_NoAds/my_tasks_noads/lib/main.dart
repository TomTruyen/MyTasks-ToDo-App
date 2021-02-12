import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:my_tasks_noads/services/db.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Tasks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int editCount = 0; //used for deciding when to display ad

  Database db;
  List<Map> todos = [];

  void updateTodoState(List _todos) {
    setState(() {
      todos = _todos;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Database _db = await setupDatabase();
      List<Map> _todos = await getTodos(_db);

      if (_db != null && _todos != null) {
        setState(() {
          this.db = _db;
          this.todos = _todos;
        });
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget deleteSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.fromLTRB(24.0, 0.0, 16.0, 0.0),
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(50.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
        color: Colors.red,
      ),
      child: Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget editSwipeBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(24.0, 0.0, 16.0, 0.0),
      margin: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(50.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
          )
        ],
        color: Colors.green,
      ),
      child: Icon(Icons.edit, color: Colors.white),
    );
  }

  void displayEditBottomSheet(
    BuildContext context,
    Function updateTodoState,
    Map dbArgs,
  ) {
    final _formKey = GlobalKey<FormState>();

    String title = dbArgs['title'];

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  height: 170.0,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TextFormField(
                          initialValue: dbArgs['title'],
                          onChanged: (String value) {
                            setState(() {
                              title = value;
                            });
                          },
                          validator: (String value) {
                            if (value.length > 30) {
                              return "Max length: 30";
                            }

                            return null;
                          },
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Title',
                            fillColor: Colors.grey[300],
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50.0),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(50.0),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.0),
                            isDense: true,
                          ),
                        ),
                        SizedBox(
                          height: 16.0,
                        ),
                        FlatButton(
                          height: 48.0,
                          minWidth: MediaQuery.of(context).size.width,
                          color: Color.fromRGBO(0, 175, 255, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          child: Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            if (title != "") {
                              if (_formKey.currentState.validate()) {
                                Map args = {
                                  'id': dbArgs['id'],
                                  'title': title,
                                  'completed': dbArgs['completed'],
                                };

                                dynamic result = await editTodo(db, args);

                                if (result != null) {
                                  List _todos = await getTodos(db);

                                  if (_todos != null) {
                                    updateTodoState(_todos);
                                  }

                                  if (Navigator.canPop(context)) {
                                    Navigator.of(context).pop();
                                  }
                                }
                              }
                            } else if (Navigator.canPop(context)) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void displayAddBottomSheet(BuildContext context, Function updateTodoState) {
    final _formKey = GlobalKey<FormState>();

    String title = "";

    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      context: context,
      builder: (ctx) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(16.0),
              height: 170.0,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextFormField(
                      onChanged: (String value) {
                        title = value;
                      },
                      validator: (String value) {
                        if (value.length > 30) {
                          return "Max length: 30";
                        }

                        return null;
                      },
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Title',
                        fillColor: Colors.grey[300],
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50.0),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50.0),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16.0),
                        isDense: true,
                      ),
                    ),
                    SizedBox(
                      height: 16.0,
                    ),
                    FlatButton(
                      height: 48.0,
                      minWidth: MediaQuery.of(context).size.width,
                      color: Color.fromRGBO(0, 175, 255, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () async {
                        if (title != "") {
                          if (_formKey.currentState.validate()) {
                            Map args = {
                              'title': title,
                              'completed': 0,
                            };

                            dynamic result = await addTodo(db, args);

                            if (result != null) {
                              List _todos = await getTodos(db);

                              if (_todos != null) {
                                updateTodoState(_todos);
                              }

                              if (Navigator.canPop(context)) {
                                Navigator.of(context).pop();
                              }
                            }
                          }
                        } else if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 80.0,
        backgroundColor: Colors.grey[100],
        elevation: 0.0,
        title: Center(
          child: Text(
            "All Tasks",
            style: TextStyle(
              color: Colors.grey[900],
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(8.0),
        color: Colors.grey[100],
        child: Center(
          child: todos.length > 0
              ? ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == todos.length) return SizedBox(height: 80.0);
                    return Dismissible(
                      key: ObjectKey(todos[index]),
                      background: editSwipeBackground(),
                      secondaryBackground: deleteSwipeBackground(),
                      confirmDismiss: (DismissDirection direction) async {
                        if (direction == DismissDirection.endToStart) {
                          // Delete
                          Map args = {
                            'id': todos[index]['id'],
                          };

                          dynamic result = await deleteTodo(db, args);

                          if (result != null) {
                            List _todos = await getTodos(db);

                            if (_todos != null) {
                              updateTodoState(_todos);
                            }
                          }

                          return true;
                        } else if (direction == DismissDirection.startToEnd) {
                          // Edit
                          editCount++;
                          displayEditBottomSheet(
                            context,
                            updateTodoState,
                            todos[index],
                          );

                          return false;
                        }

                        return false;
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                            )
                          ],
                          color: Colors.white,
                        ),
                        height: 60.0,
                        margin: EdgeInsets.all(8.0),
                        padding: EdgeInsets.fromLTRB(24.0, 0.0, 16.0, 0.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                todos[index]['title'],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  decoration: todos[index]['completed'] == 1
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                            InkWell(
                              child: CircleAvatar(
                                radius: 15.0,
                                backgroundColor: todos[index]['completed'] == 1
                                    ? Color.fromRGBO(35, 220, 160, 1)
                                    : Colors.grey[900],
                                child: CircleAvatar(
                                  radius: 14.0,
                                  backgroundColor:
                                      todos[index]['completed'] == 1
                                          ? Color.fromRGBO(35, 220, 160, 1)
                                          : Colors.white,
                                  foregroundColor:
                                      todos[index]['completed'] == 1
                                          ? Colors.white
                                          : Colors.grey[900],
                                  child: Center(
                                    child: Icon(
                                      Icons.check,
                                      size: 20.0,
                                    ),
                                  ),
                                ),
                              ),
                              onTap: () async {
                                Map args = {
                                  'id': todos[index]['id'],
                                  'completed':
                                      todos[index]['completed'] == 0 ? 1 : 0,
                                };

                                dynamic result = await toggleComplete(db, args);

                                if (result != null) {
                                  dynamic _todos = await getTodos(db);

                                  if (_todos != null) {
                                    updateTodoState(_todos);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  itemCount: todos.length + 1,
                )
              : Text("No Tasks."),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(0, 175, 255, 1),
        child: Icon(Icons.add),
        onPressed: () {
          displayAddBottomSheet(context, updateTodoState);
        },
      ),
    );
  }
}
