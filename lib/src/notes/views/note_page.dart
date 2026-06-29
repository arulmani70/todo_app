import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:todo_app/src/common/services/services_locator.dart';
import 'package:todo_app/src/notes/bloc/note_bloc.dart';

import 'mobile/note_page_mobile.dart';
import 'note_page_placeholder.dart';

class NotePage extends StatelessWidget {
  const NotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NoteBloc(repository: ServicesLocator.noteRepository)..add(const InitializeNotes()),
      child: Builder(
        builder: (context) {
          return ResponsiveValue<Widget>(
            context,
            defaultValue: const NotePagePlaceholder(),
            conditionalValues: [
              const Condition.equals(name: TABLET, value: NotePageMobile()),
              const Condition.smallerThan(name: TABLET, value: NotePageMobile()),
            ],
          ).value;
        },
      ),
    );
  }
}
