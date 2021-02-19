class Todo {
  int id;
  String title;
  int completed;
  int orderIndex;

  Todo({
    this.id,
    this.title = "",
    this.completed = 0,
    this.orderIndex,
  });

  static fromJSON(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'] ?? "",
      completed: json['completed'] ?? 0,
      orderIndex: json['orderIndex'],
    );
  }
}
