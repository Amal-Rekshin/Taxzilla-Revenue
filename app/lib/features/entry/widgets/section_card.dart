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

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount > 0 ? widget.entry.amount.toStringAsFixed(2) : '',
    );
    _jobsController = TextEditingController(
      text: widget.entry.jobsCompleted != null ? widget.entry.jobsCompleted.toString() : '',
    );
    _newJobsAmountController = TextEditingController(
      text: (widget.entry.newJobsAmount ?? 0) > 0 ? widget.entry.newJobsAmount!.toStringAsFixed(2) : '',
    );
    _outstandingAmountController = TextEditingController(
      text: (widget.entry.outstandingJobsAmount ?? 0) > 0 ? widget.entry.outstandingJobsAmount!.toStringAsFixed(2) : '',
    );
  }

  @override
  void didUpdateWidget(covariant SectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.amount != widget.entry.amount) {
      final text = widget.entry.amount > 0 ? widget.entry.amount.toStringAsFixed(2) : '';
      if (_amountController.text != text) {
        _amountController.text = text;
      }
    }
    if (!widget.entry.isTriple) {
      final jcText = (widget.entry.jobsCompleted ?? 0).toString();
      if (_jobsController.text != jcText) {
        _jobsController.text = jcText;
      }
    } else {
      final njaText = (widget.entry.newJobsAmount ?? 0) > 0 ? widget.entry.newJobsAmount!.toStringAsFixed(2) : '';
      final ojaText = (widget.entry.outstandingJobsAmount ?? 0) > 0 ? widget.entry.outstandingJobsAmount!.toStringAsFixed(2) : '';
      if (_newJobsAmountController.text != njaText) _newJobsAmountController.text = njaText;
      if (_outstandingAmountController.text != ojaText) _outstandingAmountController.text = ojaText;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _jobsController.dispose();
    _newJobsAmountController.dispose();
    _outstandingAmountController.dispose();
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
              enabled: !isAccounts,
              keyboardType: const TextInputOption(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
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
                          keyboardType: const TextInputOption(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
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
                          keyboardType: const TextInputOption(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
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

class TextInputOption extends TextInputType {
  const TextInputOption({required bool decimal})
      : super.numberWithOptions(signed: false, decimal: decimal);
}
