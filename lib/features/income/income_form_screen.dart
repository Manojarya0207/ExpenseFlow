import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_categories.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/income_model.dart';

/// Add or edit an income entry (§5.3). Pass [existing] to edit.
class IncomeFormScreen extends ConsumerStatefulWidget {
  const IncomeFormScreen({super.key, this.existing});

  final IncomeModel? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<IncomeFormScreen> createState() => _IncomeFormScreenState();
}

class _IncomeFormScreenState extends ConsumerState<IncomeFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _source;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final IncomeModel? i = widget.existing;
    _amountController = TextEditingController(
      text: i != null ? _trimAmount(i.amount) : '',
    );
    _notesController = TextEditingController(text: i?.notes ?? '');
    _source = i?.category;
    _date = i?.date ?? DateTime.now();
  }

  String _trimAmount(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_source == null) return;

    final double amount = double.parse(_amountController.text.trim());
    final String notes = _notesController.text.trim();
    final IncomeModel model = IncomeModel(
      id: widget.existing?.id,
      amount: amount,
      category: _source!,
      notes: notes.isEmpty ? null : notes,
      date: _date,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final TransactionController controller =
        ref.read(transactionControllerProvider);
    if (widget.isEditing) {
      await controller.updateIncome(model);
    } else {
      await controller.addIncome(model);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Income updated' : 'Income added'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = ref.watch(currencySymbolProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Income' : 'Add Income'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _amountController,
              autofocus: !widget.isEditing,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '$symbol ',
              ),
              validator: (String? value) {
                final String v = (value ?? '').trim();
                if (v.isEmpty) return 'Amount is required';
                final double? parsed = double.tryParse(v);
                if (parsed == null) return 'Enter a valid number';
                if (parsed <= 0) return 'Amount must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _source,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Income Source'),
              items: AppCategories.income
                  .map((String c) => DropdownMenuItem<String>(
                        value: c,
                        child: Row(
                          children: <Widget>[
                            Icon(AppCategories.incomeIcon(c), size: 18),
                            const SizedBox(width: 10),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (String? v) => setState(() => _source = v),
              validator: (String? v) =>
                  v == null ? 'Income source is required' : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(Formatters.fullDate(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(widget.isEditing ? 'Update Income' : 'Save Income'),
            ),
          ],
        ),
      ),
    );
  }
}
