import 'package:flutter/material.dart';
import 'package:gear_list_planner/model.dart';

Future<bool> showDeleteWarningDialog(
  BuildContext context,
  String entityName,
  String? message,
) =>
    showWarningDialog(context, "Delete $entityName", message, "Delete");

Future<bool> showWarningDialog(
  BuildContext context,
  String title,
  String? message,
  String actionName,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(
          child: Text(
            "Cancel",
            style: TextStyle(
              color: Theme.of(context).colorScheme.errorContainer,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text(
            actionName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> showNameDialog(
  BuildContext context,
  String? initialName,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => NameDialog(initialName: initialName),
  );
}

class NameDialog extends StatefulWidget {
  const NameDialog({
    super.key,
    required this.initialName,
  });

  final String? initialName;

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name = widget.initialName ?? "";

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: widget.initialName,
              decoration: const InputDecoration(labelText: "Name"),
              autofocus: true,
              onChanged: (name) => setState(() => _name = name),
              validator: (name) {
                if (name == null || name.isEmpty) {
                  return 'please enter a name';
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            onPressed: _formKey.currentState?.validate() ?? false
                ? () => Navigator.of(context).pop(_name)
                : null,
            child: Text(
              widget.initialName != null ? "Update" : "Create",
            ),
          ),
        ],
      ),
    );
  }
}

Future<(String, int)?> showNameWeightDialog(
  BuildContext context,
  String initialName,
  int initialWeight,
) {
  return showDialog<(String, int)>(
    context: context,
    builder: (_) => NameWeightDialog(
      initialName: initialName,
      initialWeight: initialWeight,
    ),
  );
}

class NameWeightDialog extends StatefulWidget {
  const NameWeightDialog({
    super.key,
    required this.initialName,
    required this.initialWeight,
  });

  final String initialName;
  final int initialWeight;

  @override
  State<NameWeightDialog> createState() => _NameWeightDialogState();
}

class _NameWeightDialogState extends State<NameWeightDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _name = widget.initialName;
  late int _weight = widget.initialWeight;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: widget.initialName,
              decoration: const InputDecoration(labelText: "Name"),
              autofocus: true,
              onChanged: (name) => setState(() => _name = name),
              validator: (name) {
                if (name == null || name.isEmpty) {
                  return 'please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: widget.initialWeight.toString(),
              decoration: const InputDecoration(labelText: "Weight"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final weight = int.tryParse(value);
                if (weight != null) {
                  setState(() => _weight = weight);
                }
              },
              validator: (weight) {
                if (weight == null || weight.isEmpty) {
                  return 'please enter a weight';
                } else if (int.tryParse(weight) == null) {
                  return "not a valid weight";
                }
                return null;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            onPressed: _formKey.currentState?.validate() ?? false
                ? () => Navigator.of(context).pop((_name, _weight))
                : null,
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}

Future<(String, GearListVersionId?)?> showCloneVersionDialog(
  BuildContext context,
  List<GearListVersion> versions,
) {
  return showDialog<(String, GearListVersionId?)>(
    context: context,
    builder: (_) => CloneVersionDialog(
      versions: versions,
    ),
  );
}

class CloneVersionDialog extends StatefulWidget {
  const CloneVersionDialog({super.key, required this.versions});

  final List<GearListVersion> versions;

  @override
  State<CloneVersionDialog> createState() => _CloneVersionDialogState();
}

class _CloneVersionDialogState extends State<CloneVersionDialog> {
  final _formKey = GlobalKey<FormState>();

  String _name = "";
  GearListVersionId? _versionId;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: "Name"),
              autofocus: true,
              onChanged: (name) => setState(() => _name = name),
              validator: (name) {
                if (name == null || name.isEmpty) {
                  return 'please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            const Text(
              "You can create a new version by cloning an existing one or create one from scratch.",
            ),
            DropdownButtonFormField(
              items: widget.versions
                  .map(
                    (v) => DropdownMenuItem(
                      value: v.id,
                      child: Text("clone ${v.name}"),
                    ),
                  )
                  .toList()
                ..add(
                  const DropdownMenuItem(child: Text("create from scratch")),
                ),
              onChanged: (versionId) => setState(() => _versionId = versionId),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          TextButton(
            onPressed: _formKey.currentState?.validate() ?? false
                ? () => Navigator.of(context).pop((_name, _versionId))
                : null,
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
