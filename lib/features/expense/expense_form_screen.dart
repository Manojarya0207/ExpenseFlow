import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_categories.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/expense_model.dart';

/// Add or edit an expense (§5.2). Pass [existing] to edit.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, this.existing});

  final ExpenseModel? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  String? _category;
  late String _paymentMethod;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final ExpenseModel? e = widget.existing;
    _amountController = TextEditingController(
      text: e != null ? _trimAmount(e.amount) : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _category = e?.category;
    _paymentMethod = e?.paymentMethod ?? AppCategories.paymentMethods.first;
    _date = e?.date ?? DateTime.now();
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
      // Preserve time-of-day component.
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
    if (_category == null) return;

    final double amount = double.parse(_amountController.text.trim());
    final String notes = _notesController.text.trim();
    final ExpenseModel model = ExpenseModel(
      id: widget.existing?.id,
      amount: amount,
      category: _category!,
      paymentMethod: _paymentMethod,
      notes: notes.isEmpty ? null : notes,
      date: _date,
      image: widget.existing?.image,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final TransactionController controller =
        ref.read(transactionControllerProvider);
    if (widget.isEditing) {
      await controller.updateExpense(model);
    } else {
      await controller.addExpense(model);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Expense updated' : 'Expense added'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = ref.watch(currencySymbolProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Expense' : 'Add Expense'),
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
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AppCategories.expense
                  .map((String c) => DropdownMenuItem<String>(
                        value: c,
                        child: Row(
                          children: <Widget>[
                            Icon(AppCategories.expenseIcon(c), size: 18),
                            const SizedBox(width: 10),
                            Text(c),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (String? v) => setState(() => _category = v),
              validator: (String? v) =>
                  v == null ? 'Category is required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: AppCategories.paymentMethods
                  .map((String m) => DropdownMenuItem<String>(
                        value: m,
                        child: Row(
                          children: <Widget>[
                            Icon(AppCategories.paymentIcon(m), size: 18),
                            const SizedBox(width: 10),
                            Text(m),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (String? v) =>
                  setState(() => _paymentMethod = v ?? _paymentMethod),
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
              label: Text(widget.isEditing ? 'Update Expense' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
