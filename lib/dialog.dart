import 'package:flutter/material.dart';
import 'package:gear_list_planner/model.dart';

Future<void> showMessageDialog(
  BuildContext context,
  String title,
  String message,
) async {
  await showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

Future<bool> showDeleteWarningDialog(
  BuildContext context,
  String entityName,
  String? message,
) =>
    showWarningDialog(context, "Delete $entityName?", message, "Delete");

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
    builder: (_) => _NameDialog(initialName: initialName),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.initialName,
  });

  final String? initialName;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
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

Future<(String, String, int)?> showTypeNameWeightDialog(
  BuildContext context,
  String initialType,
  String initialName,
  int initialWeight,
) {
  return showDialog<(String, String, int)>(
    context: context,
    builder: (_) => _TypeNameWeightDialog(
      initialType: initialType,
      initialName: initialName,
      initialWeight: initialWeight,
    ),
  );
}

class _TypeNameWeightDialog extends StatefulWidget {
  const _TypeNameWeightDialog({
    required this.initialType,
    required this.initialName,
    required this.initialWeight,
  });

  final String initialType;
  final String initialName;
  final int initialWeight;

  @override
  State<_TypeNameWeightDialog> createState() => _TypeNameWeightDialogState();
}

class _TypeNameWeightDialogState extends State<_TypeNameWeightDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _type = widget.initialType;
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
              initialValue: widget.initialType,
              decoration: const InputDecoration(labelText: "Type"),
              autofocus: true,
              onChanged: (type) => setState(() => _type = type),
              validator: (type) {
                if (type == null || type.isEmpty) {
                  return 'please enter a type';
                }
                return null;
              },
            ),
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
                ? () => Navigator.of(context).pop((_type, _name, _weight))
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
    builder: (_) => _CloneVersionDialog(
      versions: versions,
    ),
  );
}

class _CloneVersionDialog extends StatefulWidget {
  const _CloneVersionDialog({required this.versions});

  final List<GearListVersion> versions;

  @override
  State<_CloneVersionDialog> createState() => _CloneVersionDialogState();
}

class _CloneVersionDialogState extends State<_CloneVersionDialog> {
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
