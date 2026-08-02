import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/investment_model.dart';

/// Add or edit an investment (SIP or stock). Pass [existing] to edit.
class InvestmentFormScreen extends ConsumerStatefulWidget {
  const InvestmentFormScreen({super.key, this.existing});

  final InvestmentModel? existing;

  bool get isEditing => existing != null;

  @override
  ConsumerState<InvestmentFormScreen> createState() =>
      _InvestmentFormScreenState();
}

class _InvestmentFormScreenState extends ConsumerState<InvestmentFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _quantityController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _currentPriceController;
  late final TextEditingController _notesController;

  late InvestmentType _type;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final InvestmentModel? e = widget.existing;
    _type = e?.type ?? InvestmentType.sip;
    _nameController = TextEditingController(text: e?.name ?? '');
    _amountController = TextEditingController(
      text: e != null && !e.isStock ? _trimAmount(e.amount) : '',
    );
    _quantityController = TextEditingController(
      text: e?.quantity != null ? _trimAmount(e!.quantity!) : '',
    );
    _buyPriceController = TextEditingController(
      text: e?.buyPrice != null ? _trimAmount(e!.buyPrice!) : '',
    );
    _currentPriceController = TextEditingController(
      text: e?.currentPrice != null ? _trimAmount(e!.currentPrice!) : '',
    );
    _notesController = TextEditingController(text: e?.notes ?? '');
    _date = e?.date ?? DateTime.now();
  }

  String _trimAmount(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _buyPriceController.dispose();
    _currentPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isStock => _type == InvestmentType.stock;

  /// Live qty x buy price preview shown under the stock fields.
  double get _stockTotal {
    final double qty = double.tryParse(_quantityController.text.trim()) ?? 0;
    final double price = double.tryParse(_buyPriceController.text.trim()) ?? 0;
    return qty * price;
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

    final String notes = _notesController.text.trim();
    final double? quantity = _isStock
        ? double.parse(_quantityController.text.trim())
        : null;
    final double? buyPrice = _isStock
        ? double.parse(_buyPriceController.text.trim())
        : null;
    final String currentPriceText = _currentPriceController.text.trim();
    final double? currentPrice = _isStock
        ? (currentPriceText.isEmpty
            ? buyPrice
            : double.parse(currentPriceText))
        : null;
    final double amount = _isStock
        ? quantity! * buyPrice!
        : double.parse(_amountController.text.trim());

    final InvestmentModel model = InvestmentModel(
      id: widget.existing?.id,
      type: _type,
      name: _nameController.text.trim(),
      amount: amount,
      quantity: quantity,
      buyPrice: buyPrice,
      currentPrice: currentPrice,
      date: _date,
      notes: notes.isEmpty ? null : notes,
      linkedExpenseId: widget.existing?.linkedExpenseId,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    final InvestmentController controller =
        ref.read(investmentControllerProvider);
    if (widget.isEditing) {
      await controller.updateInvestment(model);
    } else {
      await controller.addInvestment(model);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(widget.isEditing ? 'Investment updated' : 'Investment added'),
      ),
    );
  }

  String? _validateNumber(String? value, String label) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return '$label is required';
    final double? parsed = double.tryParse(v);
    if (parsed == null) return 'Enter a valid number';
    if (parsed <= 0) return '$label must be greater than 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String symbol = ref.watch(currencySymbolProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Investment' : 'Add Investment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            SegmentedButton<InvestmentType>(
              segments: const <ButtonSegment<InvestmentType>>[
                ButtonSegment<InvestmentType>(
                  value: InvestmentType.sip,
                  label: Text('SIP'),
                  icon: Icon(Icons.autorenew),
                ),
                ButtonSegment<InvestmentType>(
                  value: InvestmentType.stock,
                  label: Text('Stock'),
                  icon: Icon(Icons.show_chart),
                ),
              ],
              selected: <InvestmentType>{_type},
              onSelectionChanged: widget.isEditing
                  ? null // Type switch on an existing holding would orphan fields.
                  : (Set<InvestmentType> selection) =>
                      setState(() => _type = selection.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              autofocus: !widget.isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: _isStock ? 'Stock Name' : 'Fund Name',
                hintText: _isStock ? 'e.g. TCS, Reliance' : 'e.g. Nifty 50 Index Fund',
              ),
              validator: (String? v) => (v ?? '').trim().isEmpty
                  ? (_isStock ? 'Stock name is required' : 'Fund name is required')
                  : null,
            ),
            const SizedBox(height: 16),
            if (_isStock) ...<Widget>[
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: 'Quantity (shares)'),
                validator: (String? v) => _validateNumber(v, 'Quantity'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Buy Price (per share)',
                  prefixText: '$symbol ',
                ),
                validator: (String? v) => _validateNumber(v, 'Buy price'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Current Price (optional)',
                  prefixText: '$symbol ',
                  helperText: 'Defaults to buy price; update anytime for P/L',
                ),
                validator: (String? v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  return _validateNumber(v, 'Current price');
                },
              ),
              if (_stockTotal > 0) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Total Investment: ${Formatters.money(_stockTotal, symbol)}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ] else
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Monthly Amount',
                  prefixText: '$symbol ',
                ),
                validator: (String? v) => _validateNumber(v, 'Amount'),
              ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _isStock ? 'Buy Date' : 'Start Date',
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
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
              label: Text(
                  widget.isEditing ? 'Update Investment' : 'Save Investment'),
            ),
          ],
        ),
      ),
    );
  }
}
