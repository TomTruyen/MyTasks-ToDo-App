import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simple_todo/models/Todo.dart';
import 'package:sqflite/sqflite.dart';

Future<String> getPersistentDBPath() async {
  try {
    if (await Permission.storage.request().isGranted) {
      String externalDirectoryPath =
          await ExtStorage.getExternalStorageDirectory();
      String directoryPath = "$externalDirectoryPath/simple_todo_persistent";
      await (new Directory(directoryPath).create());
      return "$directoryPath/simple_todo.db";
    }

    return null;
  } catch (e) {
    print("Error getting PersistentPath: $e");
    return null;
  }
}

Future<Database> setupDatabase() async {
  try {
    String path = await getPersistentDBPath();

    if (path == null) {
      String databasePath = await getDatabasesPath();
      path = databasePath + 'simple_todo.db';
    }

    // NOTE: Boolean is not available, so 0 = False, 1 = True
    Database db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
        'CREATE TABLE todos (id INTEGER PRIMARY KEY UNIQUE, title TEXT, completed INTEGER, orderIndex INTEGER UNIQUE)',
        [],
      );
    });

    return db;
  } catch (e) {
    print("Setup Error: $e");
    return null;
  }
}

Future<List> getTodos(Database db) async {
  try {
    List<Todo> todos = [];

    List<Map> dbTodos = await db.rawQuery(
      'SELECT * FROM todos ORDER BY orderIndex ASC',
    );

    for (int i = 0; i < dbTodos.length; i++) {
      todos.add(Todo.fromJSON(dbTodos[i]));
    }

    return todos;
  } catch (e) {
    print("Get Todos Error: $e");
    return null;
  }
}

Future addTodo(Database db, Map args) async {
  try {
    await db.rawInsert(
      'INSERT INTO todos (title, completed, orderIndex) VALUES (?, ?, ?)',
      [args['title'], args['completed'], args['orderIndex']],
    );

    return true;
  } catch (e) {
    print("Add Todo Error $e");
    return null;
  }
}

Future editTodo(Database db, Map args) async {
  try {
    await db.rawUpdate(
      'UPDATE todos SET title = ?, completed = ? WHERE id = ?',
      [args['title'], args['completed'], args['id']],
    );

    return true;
  } catch (e) {
    print("Edit Todo Error $e");
    return null;
  }
}

Future deleteTodo(Database db, Map args) async {
  try {
    await db.rawDelete(
      'DELETE FROM todos WHERE id = ?',
      [args['id']],
    );

    return true;
  } catch (e) {
    print("Delete Todo Error: $e");
    return null;
  }
}

Future toggleComplete(Database db, Map args) async {
  try {
    await db.rawUpdate(
      'UPDATE todos SET completed = ? WHERE id = ?',
      [args['completed'], args['id']],
    );

    return true;
  } catch (e) {
    print("Complete Todo Error: $e");
    return null;
  }
}

Future reorderTodos(Database db, List<Todo> todos, int startIndex) async {
  try {
    Batch batch = db.batch();

    for (int i = startIndex; i < todos.length; i++) {
      batch.rawUpdate('UPDATE todos SET orderIndex = ? WHERE id = ?', [
        todos[i].orderIndex,
        todos[i].id,
      ]);
    }

    await batch.commit(noResult: true, continueOnError: true);

    return true;
  } catch (e) {
    print("Reorder Todo Error: $e");
    return null;
  }
}
