import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:badger/models/note.dart';
import 'package:badger/repositories/notes.dart';
import 'package:badger/utils/colors.dart';
import 'package:badger/utils/constants.dart';
import 'package:badger/utils/functions.dart';

class ManageNote extends StatefulWidget {
  const ManageNote({Key? key}) : super(key: key);

  @override
  State<ManageNote> createState() => _ManageNoteState();
}

class _ManageNoteState extends State<ManageNote> {
  final _notesRepository = NotesRepository();

  ManagementModes _mode = ManagementModes.view;

  late Note _note;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  bool _initialFocus = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();

    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();

    super.dispose();
  }

  void _setInitialInputFocus() {
    if (_mode != ManagementModes.view && _initialFocus) {
      _titleFocusNode.requestFocus();
    }

    _initialFocus = false;
  }

  @override
  Widget build(BuildContext context) {
    _setMode(context);
    _setNote(context);
    _setInitialInputFocus();

    return WillPopScope(
      onWillPop: () async {
        if (_titleFocusNode.hasFocus) {
          _titleFocusNode.unfocus();

          return false;
        }

        if (_bodyFocusNode.hasFocus) {
          _bodyFocusNode.unfocus();

          return false;
        }

        if (_mode == ManagementModes.edit) {
          setState(() {
            _mode = ManagementModes.view;
          });

          return false;
        }

        ScaffoldMessenger.of(context).clearSnackBars();

        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return _mode == ManagementModes.view
        ? GestureDetector(
            onTap: () {
              if (_mode == ManagementModes.view) {
                setState(() {
                  _mode = ManagementModes.edit;
                });

                _bodyFocusNode.requestFocus();
              }
            },
            child: _buildMarkdownPreview(),
          )
        : _getBodyInput();
  }

  Widget _getBodyInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 24.0,
      ),
      child: TextField(
        controller: _bodyController,
        focusNode: _bodyFocusNode,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText: 'Start writing here...',
          hintStyle: TextStyle(color: themeColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMarkdownPreview() {
    return Container(
      width: screenSize(context).width,
      height: screenSize(context).height,
      padding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 24.0,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 1,
        ),
      ),
      child: MarkdownBody(
        data: _note.body,
        fitContent: false,
        styleSheet: MarkdownStyleSheet(
          blockSpacing: 12.0,
          code: TextStyle(
            color: themeColor,
            backgroundColor: themeColor.shade50,
            fontFamily: 'SourceCodePro',
            fontWeight: FontWeight.w500,
          ),
          codeblockDecoration: BoxDecoration(
            color: themeColor.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          codeblockPadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          blockquoteDecoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8.0),
          ),
          blockquotePadding:
              const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: _buildTitleInput(),
      actions: [
        _buildMainBtn(context),
        _buildCopyBtn(context),
        _buildDeleteBtn(context),
      ],
    );
  }

  Widget _buildMainBtn(BuildContext context) {
    return Visibility(
      visible: _mode != ManagementModes.view,
      child: IconButton(
        icon: _getActionIcon(),
        color: themeColor,
        onPressed: () {
          if (_mode == ManagementModes.add) {
            _saveNote(context).then((bool isNoteSaved) {
              if (isNoteSaved) {
                Navigator.pop(context);
              }
            });
          }

          if (_mode == ManagementModes.edit) {
            _updateNote(context).then((bool isNoteUpdated) {
              if (isNoteUpdated) {
                Navigator.pop(context);
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildCopyBtn(BuildContext context) {
    return Visibility(
      visible: _mode == ManagementModes.view,
      child: IconButton(
        icon: const Icon(Icons.copy),
        color: themeColor,
        onPressed: () {
          FlutterClipboard.copy(_note.body).then((_) {
            SnackBar snackBar = getSnackBar('Copied note body to clipboard');

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }).catchError((_) {
            SnackBar snackBar = getSnackBar(
              'Something went wrong!',
              type: AlertTypes.error,
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          });
        },
      ),
    );
  }

  Widget _buildDeleteBtn(BuildContext context) {
    return Visibility(
      visible: _mode == ManagementModes.view,
      child: IconButton(
        icon: const Icon(Icons.delete_outline_rounded),
        color: Colors.red,
        onPressed: () {
          if (_mode != ManagementModes.add) {
            SnackBar snackBar = getSnackBar(
              'Are you sure you want to delete this note?',
              action: SnackBarAction(
                  label: 'Delete',
                  textColor: Colors.red,
                  onPressed: () {
                    _notesRepository
                        .delete(_note)
                        .then((_) => Navigator.pop(context));
                  }),
              duration: const Duration(seconds: 5),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        },
      ),
    );
  }

  TextField _buildTitleInput() {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      decoration: InputDecoration(
        hintText: 'Enter a title',
        hintStyle: TextStyle(color: themeColor),
        border: InputBorder.none,
      ),
      readOnly: _mode == ManagementModes.view,
      onTap: () {
        if (_mode == ManagementModes.view) {
          setState(() {
            _mode = ManagementModes.edit;
          });
        }
      },
      onSubmitted: (_) {
        _bodyFocusNode.requestFocus();
      },
    );
  }

  Icon _getActionIcon() {
    if (_mode == ManagementModes.view) {
      return const Icon(Icons.edit_rounded);
    } else {
      return const Icon(Icons.done_rounded);
    }
  }

  void _setMode(BuildContext context) {
    Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

    if (_mode != ManagementModes.edit) {
      _mode = arguments['mode'] as ManagementModes;
    }
  }

  void _setNote(BuildContext context) {
    if (_mode != ManagementModes.add) {
      Map arguments = ModalRoute.of(context)!.settings.arguments as Map;

      _note = arguments['note'] as Note;

      _titleController.text = _note.title;
      _bodyController.text = _note.body;
    }
  }

  Future<bool> _saveNote(BuildContext context) async {
    int id = await _notesRepository.getLastInsertedId() + 1;
    String title = _titleController.text;
    String body = _bodyController.text;

    if (title == '') {
      SnackBar snackBar = getSnackBar('Note title cannot be empty');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    } else if (body == '') {
      SnackBar snackBar = getSnackBar('Note body cannot be empty');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    } else {
      final note = Note(
        id: id,
        title: title,
        body: body,
      );

      await _notesRepository.insert(note);

      return true;
    }
  }

  Future<bool> _updateNote(BuildContext context) async {
    String title = _titleController.text;
    String body = _bodyController.text;

    if (title == '') {
      SnackBar snackBar = getSnackBar('Note title cannot be empty');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    } else if (body == '') {
      SnackBar snackBar = getSnackBar('Note body cannot be empty');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }

      return false;
    } else {
      await _notesRepository.update(_note.copyWith(
        title: title,
        body: body,
      ));

      return true;
    }
  }
}
