import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/section_model.dart';

class SectionCard extends StatefulWidget {
  final SectionEntryInput entry;
  final ValueChanged<double> onAmountChanged;
  final void Function({int? jobsCompleted, int? ongoing, int? newJobs, int? outstanding}) onJobCountsChanged;
  final void Function({double? newJobsAmount, double? outstandingJobsAmount})? onAccountsAmountsChanged;

  const SectionCard({
    super.key,
    required this.entry,
    required this.onAmountChanged,
    required this.onJobCountsChanged,
    this.onAccountsAmountsChanged,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late TextEditingController _amountController;
  late TextEditingController _jobsController;
  late TextEditingController _newJobsAmountController;
  late TextEditingController _outstandingAmountController;

  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _jobsFocusNode = FocusNode();
  final FocusNode _newJobsAmountFocusNode = FocusNode();
  final FocusNode _outstandingAmountFocusNode = FocusNode();

  static final _decimalFormatter = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (RegExp(r'^\d*\.?\d{0,2}$').hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  });

  String _formatAmount(double val) {
    if (val <= 0) return '';
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount > 0 ? _formatAmount(widget.entry.amount) : '',
    );
    _jobsController = TextEditingController(
      text: (widget.entry.jobsCompleted != null && widget.entry.jobsCompleted! > 0)
          ? widget.entry.jobsCompleted.toString()
          : '',
    );
    _newJobsAmountController = TextEditingController(
      text: (widget.entry.newJobsAmount ?? 0) > 0 ? _formatAmount(widget.entry.newJobsAmount!) : '',
    );
    _outstandingAmountController = TextEditingController(
      text: (widget.entry.outstandingJobsAmount ?? 0) > 0 ? _formatAmount(widget.entry.outstandingJobsAmount!) : '',
    );

    _amountFocusNode.addListener(_onAmountFocusChanged);
    _newJobsAmountFocusNode.addListener(_onNewJobsAmountFocusChanged);
    _outstandingAmountFocusNode.addListener(_onOutstandingAmountFocusChanged);
  }

  void _onAmountFocusChanged() {
    if (!_amountFocusNode.hasFocus) {
      if (_amountController.text.endsWith('.')) {
        _amountController.text = _amountController.text.substring(0, _amountController.text.length - 1);
      }
    }
  }

  void _onNewJobsAmountFocusChanged() {
    if (!_newJobsAmountFocusNode.hasFocus) {
      if (_newJobsAmountController.text.endsWith('.')) {
        _newJobsAmountController.text = _newJobsAmountController.text.substring(0, _newJobsAmountController.text.length - 1);
      }
    }
  }

  void _onOutstandingAmountFocusChanged() {
    if (!_outstandingAmountFocusNode.hasFocus) {
      if (_outstandingAmountController.text.endsWith('.')) {
        _outstandingAmountController.text = _outstandingAmountController.text.substring(0, _outstandingAmountController.text.length - 1);
      }
    }
  }

  @override
  void didUpdateWidget(covariant SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isAccounts = widget.entry.isTriple || widget.entry.code == 'ACCOUNTS';

    if (isAccounts) {
      // ACCOUNTS total amount is auto-calculated and disabled; update display when sum changes
      final sumText = widget.entry.amount > 0 ? _formatAmount(widget.entry.amount) : '';
      if (_amountController.text != sumText) {
        _amountController.text = sumText;
      }

      // Only update New Jobs Amount if the field does NOT have focus and the value changed externally
      if (!_newJobsAmountFocusNode.hasFocus) {
        final currentNja = double.tryParse(_newJobsAmountController.text) ?? 0.0;
        final newNja = widget.entry.newJobsAmount ?? 0.0;
        if ((currentNja - newNja).abs() > 0.001) {
          _newJobsAmountController.text = newNja > 0 ? _formatAmount(newNja) : '';
        }
      }

      // Only update Outstanding Amount if the field does NOT have focus and the value changed externally
      if (!_outstandingAmountFocusNode.hasFocus) {
        final currentOja = double.tryParse(_outstandingAmountController.text) ?? 0.0;
        final newOja = widget.entry.outstandingJobsAmount ?? 0.0;
        if ((currentOja - newOja).abs() > 0.001) {
          _outstandingAmountController.text = newOja > 0 ? _formatAmount(newOja) : '';
        }
      }
    } else {
      // Non-ACCOUNTS: Amount field (only update if not focused and external value differs)
      if (!_amountFocusNode.hasFocus) {
        final currentAmt = double.tryParse(_amountController.text) ?? 0.0;
        if ((currentAmt - widget.entry.amount).abs() > 0.001) {
          _amountController.text = widget.entry.amount > 0 ? _formatAmount(widget.entry.amount) : '';
        }
      }

      // Jobs Completed field (only update if not focused and external value differs)
      if (!_jobsFocusNode.hasFocus) {
        final currentJc = int.tryParse(_jobsController.text) ?? 0;
        final newJc = widget.entry.jobsCompleted ?? 0;
        if (currentJc != newJc) {
          _jobsController.text = newJc > 0 ? newJc.toString() : '';
        }
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChanged);
    _newJobsAmountFocusNode.removeListener(_onNewJobsAmountFocusChanged);
    _outstandingAmountFocusNode.removeListener(_onOutstandingAmountFocusChanged);

    _amountController.dispose();
    _jobsController.dispose();
    _newJobsAmountController.dispose();
    _outstandingAmountController.dispose();

    _amountFocusNode.dispose();
    _jobsFocusNode.dispose();
    _newJobsAmountFocusNode.dispose();
    _outstandingAmountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAccounts = widget.entry.isTriple || widget.entry.code == 'ACCOUNTS';

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.entry.inCoreTotal
              ? AppTheme.primaryLight.withValues(alpha: 0.3)
              : AppTheme.border,
          width: widget.entry.inCoreTotal ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.entry.inCoreTotal
                            ? AppTheme.primary
                            : AppTheme.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.entry.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.entry.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (widget.entry.inCoreTotal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Core Total 1',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Amount Field: Disabled for ACCOUNTS (auto-calculated from New Job & Outstanding), editable for others
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              enabled: !isAccounts,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [_decimalFormatter],
              decoration: InputDecoration(
                labelText: isAccounts ? 'Total Amount (₹) [Auto-calculated]' : 'Amount (₹)',
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAccounts ? AppTheme.textSecondary : AppTheme.primary,
                ),
                hintText: '0.00',
                filled: isAccounts,
                fillColor: isAccounts ? Colors.grey.shade100 : null,
                helperText: isAccounts ? 'Auto-calculated sum of New Job and Outstanding amounts' : null,
                helperStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
              onChanged: (val) {
                if (!isAccounts) {
                  final amount = double.tryParse(val) ?? 0.0;
                  widget.onAmountChanged(amount);
                }
              },
            ),
            const SizedBox(height: 12),

            // Fields based on section
            if (!isAccounts)
              TextFormField(
                controller: _jobsController,
                focusNode: _jobsFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jobs Completed',
                  prefixIcon: Icon(Icons.check_circle_outline, size: 20),
                  hintText: '0',
                ),
                onChanged: (val) {
                  final jc = int.tryParse(val) ?? 0;
                  widget.onJobCountsChanged(jobsCompleted: jc);
                },
              )
            else
              // ACCOUNTS: Separate New Job Amount and Outstanding Amount inputs (No Ongoing, No Job Counts)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accounts Revenue Breakdown',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _newJobsAmountController,
                          focusNode: _newJobsAmountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [_decimalFormatter],
                          decoration: const InputDecoration(
                            labelText: 'New Job Amount (₹)',
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                            hintText: '0.00',
                          ),
                          onChanged: (val) {
                            final amt = double.tryParse(val) ?? 0.0;
                            widget.onAccountsAmountsChanged?.call(newJobsAmount: amt);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _outstandingAmountController,
                          focusNode: _outstandingAmountFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [_decimalFormatter],
                          decoration: const InputDecoration(
                            labelText: 'Outstanding Amount (₹)',
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary),
                            hintText: '0.00',
                          ),
                          onChanged: (val) {
                            final amt = double.tryParse(val) ?? 0.0;
                            widget.onAccountsAmountsChanged?.call(outstandingJobsAmount: amt);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
