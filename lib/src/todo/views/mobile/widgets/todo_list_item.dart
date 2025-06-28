import 'package:flutter/material.dart';
import 'package:todo_app/src/todo/bloc/todo_bloc.dart';
import 'package:todo_app/src/todo/views/mobile/widgets/todo_form_bottom_sheet.dart';

class TodoListItem extends StatelessWidget {
  final TodoBloc _todoBloc;
  final Map<String, dynamic> todo;
  const TodoListItem({super.key, required this.todo, required TodoBloc todoBloc}) : _todoBloc = todoBloc;

  @override
  Widget build(BuildContext context) {
    final isCompleted = todo['is_completed'] == 1;
    final priority = todo['priority'] ?? 'medium';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
        child: Row(
          spacing: 10.0,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) {
                var updatedTodo = Map<String, dynamic>.from(todo);
                updatedTodo['is_completed'] = value ?? false;
                _todoBloc.add(UpdateTodo(todo: updatedTodo));
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        todo['title'] ?? '',
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted ? Colors.grey : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          !isCompleted
                              ? IconButton(
                                  onPressed: () {
                                    showTodoFormBottomSheet(context, _todoBloc, todo: todo);
                                  },
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: Icon(Icons.edit),
                                )
                              : const SizedBox.shrink(),
                          IconButton(
                            onPressed: () {
                              _showDeleteDialog(context, todo);
                            },
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(Icons.delete_outline, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (todo['description'] != null && todo['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(todo['description'] ?? '', style: TextStyle(color: isCompleted ? Colors.grey : null)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityChip(priority),
                      Spacer(),
                      if (todo['due_date'] != null && todo['due_date'].toString().isNotEmpty) ...[
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(_formatDate(todo['due_date']), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    IconData icon;

    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        icon = Icons.arrow_upward;
        break;
      case 'medium':
        color = Colors.orange;
        icon = Icons.remove;
        break;
      case 'low':
        color = Colors.green;
        icon = Icons.arrow_downward;
        break;
      default:
        color = Colors.grey;
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _todoBloc.add(DeleteTodo(id: todo['id']));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
