import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rkfm_broadcast/core/constants/app_constants.dart';
import 'package:rkfm_broadcast/core/theme/app_theme.dart';
import 'package:rkfm_broadcast/data/models/program_models.dart';
import 'package:rkfm_broadcast/presentation/viewmodels/settings_viewmodel.dart';
import 'package:uuid/uuid.dart';

class TemplateEditorScreen extends StatefulWidget {
  final TemplateModel? template;

  const TemplateEditorScreen({super.key, this.template});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late List<TemplateElement> _elements;
  TemplateElement? _selected;
  final _nameController = TextEditingController();
  TemplateCategory _category = TemplateCategory.news;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _elements = List.from(widget.template!.elements);
      _nameController.text = widget.template!.name;
      _category = widget.template!.category;
    } else {
      _elements = [
        TemplateElement(
          id: _uuid.v4(),
          type: 'lowerThird',
          content: 'Program Title',
          x: 60,
          y: 880,
          width: 600,
          height: 100,
          fontSize: 32,
          color: AppColors.primary.value,
        ),
      ];
      _nameController.text = 'New Template';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addElement(String type) {
    setState(() {
      final element = TemplateElement(
        id: _uuid.v4(),
        type: type,
        content: type == 'ticker' ? 'Ticker text here' : type.toUpperCase(),
        x: 100,
        y: 100 + (_elements.length * 40).toDouble(),
        width: type == 'ticker' ? 1920 : 300,
        height: 60,
      );
      _elements.add(element);
      _selected = element;
    });
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final template = TemplateModel(
      id: widget.template?.id ?? _uuid.v4(),
      name: _nameController.text,
      category: _category,
      isBuiltIn: false,
      elementsJson: jsonEncode(_elements.map((e) => e.toMap()).toList()),
      createdAt: widget.template?.createdAt ?? now,
      updatedAt: now,
    );

    await context.read<SettingsViewModel>().saveTemplate(template);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: () {}),
          IconButton(icon: const Icon(Icons.redo), onPressed: () {}),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _save, child: const Text('SAVE')),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: _ToolPanel(
              onAdd: _addElement,
              selected: _selected,
              onDelete: () {
                if (_selected != null) {
                  setState(() {
                    _elements.remove(_selected);
                    _selected = null;
                  });
                }
              },
              onDuplicate: () {
                if (_selected != null) {
                  setState(() {
                    final copy = TemplateElement(
                      id: _uuid.v4(),
                      type: _selected!.type,
                      content: _selected!.content,
                      x: _selected!.x + 20,
                      y: _selected!.y + 20,
                      width: _selected!.width,
                      height: _selected!.height,
                      fontSize: _selected!.fontSize,
                      color: _selected!.color,
                    );
                    _elements.add(copy);
                    _selected = copy;
                  });
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      color: AppColors.surface,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _elements.map((e) => _DraggableElement(
                            element: e,
                            isSelected: _selected?.id == e.id,
                            onTap: () => setState(() => _selected = e),
                            onMoved: (x, y) {
                              setState(() {
                                final idx = _elements.indexWhere((el) => el.id == e.id);
                                _elements[idx] = e.copyWith(x: x, y: y);
                                _selected = _elements[idx];
                              });
                            },
                          )).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 280,
            child: _PropertiesPanel(
              nameController: _nameController,
              category: _category,
              onCategoryChanged: (c) => setState(() => _category = c),
              selected: _selected,
              onUpdate: (updated) {
                setState(() {
                  final idx = _elements.indexWhere((e) => e.id == updated.id);
                  _elements[idx] = updated;
                  _selected = updated;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolPanel extends StatelessWidget {
  final void Function(String type) onAdd;
  final TemplateElement? selected;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const _ToolPanel({
    required this.onAdd,
    required this.selected,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    const tools = [
      ('text', Icons.text_fields, 'Text'),
      ('image', Icons.image, 'Image'),
      ('logo', Icons.branding_watermark, 'Logo'),
      ('clock', Icons.access_time, 'Clock'),
      ('date', Icons.calendar_today, 'Date'),
      ('lowerThird', Icons.view_agenda, 'Lower Third'),
      ('ticker', Icons.view_stream, 'Ticker'),
      ('shape', Icons.crop_square, 'Shape'),
      ('qr', Icons.qr_code, 'QR Code'),
      ('sponsor', Icons.campaign, 'Sponsor'),
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('OBJECTS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          ...tools.map((t) => ListTile(
                dense: true,
                leading: Icon(t.$2, size: 20),
                title: Text(t.$3, style: const TextStyle(fontSize: 13)),
                onTap: () => onAdd(t.$1),
              )),
          const Divider(),
          Text('ACTIONS', style: Theme.of(context).textTheme.labelLarge),
          ListTile(
            dense: true,
            leading: const Icon(Icons.copy, size: 20),
            title: const Text('Duplicate', style: TextStyle(fontSize: 13)),
            onTap: onDuplicate,
            enabled: selected != null,
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.delete, size: 20, color: AppColors.recording),
            title: const Text('Delete', style: TextStyle(fontSize: 13)),
            onTap: onDelete,
            enabled: selected != null,
          ),
        ],
      ),
    );
  }
}

class _PropertiesPanel extends StatelessWidget {
  final TextEditingController nameController;
  final TemplateCategory category;
  final ValueChanged<TemplateCategory> onCategoryChanged;
  final TemplateElement? selected;
  final ValueChanged<TemplateElement> onUpdate;

  const _PropertiesPanel({
    required this.nameController,
    required this.category,
    required this.onCategoryChanged,
    required this.selected,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('TEMPLATE', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TemplateCategory>(
            value: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: TemplateCategory.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) onCategoryChanged(v);
            },
          ),
          if (selected != null) ...[
            const Divider(height: 32),
            Text('ELEMENT', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Content'),
              controller: TextEditingController(text: selected!.content),
              onChanged: (v) => onUpdate(selected!.copyWith(content: v)),
            ),
            const SizedBox(height: 8),
            _slider('Opacity', selected!.opacity, 0, 1, (v) => onUpdate(selected!.copyWith(opacity: v))),
            _slider('Font Size', selected!.fontSize, 12, 72, (v) => onUpdate(selected!.copyWith(fontSize: v))),
          ],
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _DraggableElement extends StatefulWidget {
  final TemplateElement element;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(double x, double y) onMoved;

  const _DraggableElement({
    required this.element,
    required this.isSelected,
    required this.onTap,
    required this.onMoved,
  });

  @override
  State<_DraggableElement> createState() => _DraggableElementState();
}

class _DraggableElementState extends State<_DraggableElement> {
  late double _x;
  late double _y;

  @override
  void initState() {
    super.initState();
    _x = widget.element.x;
    _y = widget.element.y;
  }

  @override
  void didUpdateWidget(_DraggableElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _x = widget.element.x;
    _y = widget.element.y;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
          widget.onMoved(_x, _y);
        },
        child: Container(
          width: widget.element.width,
          height: widget.element.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
            color: widget.element.type == 'lowerThird'
                ? Color(widget.element.color).withValues(alpha: widget.element.opacity)
                : null,
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8),
          child: Text(
            widget.element.content,
            style: TextStyle(
              fontSize: widget.element.fontSize * 0.5,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
