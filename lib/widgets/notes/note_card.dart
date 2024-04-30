import 'package:badger/models/note_model.dart';
import 'package:badger/screens/notes/manage_note_screen.dart';
import 'package:badger/utils/colors.dart';
import 'package:badger/utils/enums.dart';
import 'package:badger/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;

  const NoteCard({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          ManageNoteScreen.routePath,
          arguments: {
            'mode': ManagementModes.view,
            'note': note,
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? Colors.white
              : Colors.black54,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: primaryColor.shade200,
            ),
          ],
        ),
        margin: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (note.title.isNotEmpty)
                Text(
                  note.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              if (note.title.isNotEmpty) const SizedBox(height: 8.0),
              if (note.body.isNotEmpty)
                MarkdownBody(
                  data: getTrimmedContent(note.body),
                ),
              if (note.date != null)
                Text(
                  formatDateToTimeAgo(note.date!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
