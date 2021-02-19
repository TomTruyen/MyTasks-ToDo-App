import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'package:simple_todo/services/db.dart';
import 'package:simple_todo/ad_manager.dart';
import 'package:simple_todo/models/Todo.dart';
import 'package:simple_todo/CustomReorderablesSliverList.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
  List<Todo> todos = [];

  InterstitialAd _interstitialAd;

  bool _isInterstitialAdReady;

  void _loadInterstitialAd() {
    _interstitialAd.load();
  }

  void _onIntersistialAdEvent(MobileAdEvent event) {
    switch (event) {
      case MobileAdEvent.loaded:
        _isInterstitialAdReady = true;
        break;
      case MobileAdEvent.failedToLoad:
        _isInterstitialAdReady = false;
        break;
      case MobileAdEvent.closed:
        break;
      default:
    }
  }

  void onNewTask(int taskCount, bool isEdit) {
    if (isEdit) {
      if (editCount % 2 != 0) {
        _loadInterstitialAd();
      }
    } else if (taskCount % 2 != 0) {
      _loadInterstitialAd();
    }
  }

  Future<void> _initAdMob() {
    return FirebaseAdMob.instance.initialize(appId: AdManager.appId);
  }

  void updateTodoState(List _todos) {
    setState(() {
      todos = _todos;
    });
  }

  @override
  void initState() {
    _isInterstitialAdReady = false;
    _interstitialAd = InterstitialAd(
      adUnitId: AdManager.interstitialAdUnitId,
      listener: _onIntersistialAdEvent,
    );

    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Database _db = await setupDatabase();
      List<Todo> _todos = await getTodos(_db);

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
    _interstitialAd?.dispose();

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
    Todo todo,
  ) {
    final _formKey = GlobalKey<FormState>();

    String title = todo.title ?? "";

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
                          initialValue: title,
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
                                  'id': todo.id,
                                  'title': title,
                                  'completed': todo.completed,
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

                                if (_isInterstitialAdReady) {
                                  _interstitialAd.show();
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

                            if (_isInterstitialAdReady) {
                              _interstitialAd.show();
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
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            title: Center(
              child: Text(
                "All Tasks",
                style: TextStyle(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            elevation: 0.0,
            toolbarHeight: 80.0,
            backgroundColor: Colors.grey[50],
          ),
          todos.length <= 0
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text("No Tasks."),
                  ),
                )
              : CustomReorderableSliverList(
                  delegate: ReorderableSliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return Container(
                        height: 70.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(50.0),
                          ),
                        ),
                        child: Card(
                          elevation: 5.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Dismissible(
                            key: ObjectKey(todos[index]),
                            background: editSwipeBackground(),
                            secondaryBackground: deleteSwipeBackground(),
                            confirmDismiss: (DismissDirection direction) async {
                              if (direction == DismissDirection.endToStart) {
                                // Delete
                                Map args = {
                                  'id': todos[index].id,
                                };

                                dynamic result = await deleteTodo(db, args);

                                if (result != null) {
                                  List _todos = await getTodos(db);

                                  if (_todos != null) {
                                    updateTodoState(_todos);
                                  }
                                }

                                return true;
                              } else if (direction ==
                                  DismissDirection.startToEnd) {
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
                              padding:
                                  EdgeInsets.fromLTRB(24.0, 0.0, 16.0, 0.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      todos[index].title,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        decoration: todos[index].completed == 1
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
                                      backgroundColor:
                                          todos[index].completed == 1
                                              ? Color.fromRGBO(35, 220, 160, 1)
                                              : Colors.grey[900],
                                      child: CircleAvatar(
                                        radius: 14.0,
                                        backgroundColor: todos[index]
                                                    .completed ==
                                                1
                                            ? Color.fromRGBO(35, 220, 160, 1)
                                            : Colors.white,
                                        foregroundColor:
                                            todos[index].completed == 1
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
                                        'id': todos[index].id,
                                        'completed':
                                            todos[index].completed == 0 ? 1 : 0,
                                      };

                                      dynamic result =
                                          await toggleComplete(db, args);

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
                          ),
                        ),
                      );
                    },
                    childCount: todos.length,
                  ),
                  onReorder: (int oldIndex, int newIndex) async {
                    List<Todo> _todos = List.of(todos);

                    Todo todo = _todos.removeAt(oldIndex);
                    _todos.insert(newIndex, todo);

                    for (int i = 0; i < _todos.length; i++) {
                      _todos[i].orderIndex = i;
                    }

                    dynamic result = await reorderTodos(db, todos, newIndex);

                    if (result != null) {
                      setState(() {
                        todos = _todos;
                      });
                    }
                  },
                ),
        ],
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
