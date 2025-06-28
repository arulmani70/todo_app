import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/src/common/common.dart';
import 'package:todo_app/src/todo/bloc/todo_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TodoFormBottomSheet extends StatefulWidget {
  final Map<String, dynamic>? todo;

  const TodoFormBottomSheet({super.key, this.todo});

  @override
  State<TodoFormBottomSheet> createState() => _TodoFormBottomSheetState();
}

class _TodoFormBottomSheetState extends State<TodoFormBottomSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.todo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.patchValue({
          'title': widget.todo!['title'] ?? '',
          'description': widget.todo!['description'] ?? '',
          'priority': widget.todo!['priority'] ?? Constants.database.PRIORITY_MEDIUM,
          'due_date': widget.todo!['due_date'] != null ? DateTime.tryParse(widget.todo!['due_date']) : null,
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.todo != null ? 'Edit Todo' : 'Add New Todo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: FormBuilder(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FormBuilderTextField(
                            name: 'title',
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              hintText: 'Enter todo title',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.title),
                            ),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(errorText: 'Title is required'),
                              FormBuilderValidators.minLength(3, errorText: 'Title must be at least 3 characters'),
                            ]),
                            textInputAction: TextInputAction.next,
                          ),

                          const SizedBox(height: 16),

                          FormBuilderTextField(
                            name: 'description',
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter todo description (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.next,
                          ),

                          const SizedBox(height: 16),

                          FormBuilderDropdown<String>(
                            name: 'priority',
                            decoration: const InputDecoration(
                              labelText: 'Priority *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.priority_high),
                            ),
                            validator: FormBuilderValidators.compose([FormBuilderValidators.required(errorText: 'Priority is required')]),
                            items: [
                              DropdownMenuItem(
                                value: Constants.database.PRIORITY_LOW,
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_downward, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text('Low'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: Constants.database.PRIORITY_MEDIUM,
                                child: Row(
                                  children: [
                                    Icon(Icons.remove, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text('Medium'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: Constants.database.PRIORITY_HIGH,
                                child: Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text('High'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          FormBuilderDateTimePicker(
                            name: 'due_date',
                            decoration: const InputDecoration(
                              labelText: 'Due Date',
                              hintText: 'Select due date (optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            inputType: InputType.date,
                            format: DateFormat('yyyy-MM-dd'),
                            initialValue: null,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                                  : Text(
                                      widget.todo != null ? 'Update Todo' : 'Create Todo',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final formData = _formKey.currentState!.value;

        final todoData = <String, dynamic>{
          Constants.database.COLUMN_TODO_TITLE: formData['title'],
          Constants.database.COLUMN_TODO_DESCRIPTION: formData['description'] ?? '',
          Constants.database.COLUMN_TODO_PRIORITY: formData['priority'],
          Constants.database.COLUMN_TODO_IS_COMPLETED: 0,
        };

        if (formData['due_date'] != null) {
          todoData[Constants.database.COLUMN_TODO_DUE_DATE] = (formData['due_date'] as DateTime).toIso8601String();
        }

        if (widget.todo != null) {
          context.read<TodoBloc>().add(UpdateTodo(todo: {...widget.todo!, ...todoData}));
        } else {
          context.read<TodoBloc>().add(CreateTodo(todo: todoData));
        }

        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error'), backgroundColor: Colors.red));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

void showTodoFormBottomSheet(BuildContext context, TodoBloc bloc, {Map<String, dynamic>? todo}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BlocProvider.value(
      value: bloc,
      child: TodoFormBottomSheet(todo: todo),
    ),
  );
}
