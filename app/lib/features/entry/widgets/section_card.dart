import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/section_model.dart';

class SectionCard extends StatefulWidget {
  final SectionEntryInput entry;
  final ValueChanged<double> onAmountChanged;
  final void Function({int? jobsCompleted, int? ongoing, int? newJobs, int? outstanding}) onJobCountsChanged;

  const SectionCard({
    super.key,
    required this.entry,
    required this.onAmountChanged,
    required this.onJobCountsChanged,
  });

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  late TextEditingController _amountController;
  late TextEditingController _jobsController;
  late TextEditingController _ongoingController;
  late TextEditingController _newJobsController;
  late TextEditingController _outstandingController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.entry.amount > 0 ? widget.entry.amount.toStringAsFixed(2) : '',
    );
    _jobsController = TextEditingController(
      text: widget.entry.jobsCompleted != null ? widget.entry.jobsCompleted.toString() : '',
    );
    _ongoingController = TextEditingController(
      text: widget.entry.ongoingJobs != null ? widget.entry.ongoingJobs.toString() : '',
    );
    _newJobsController = TextEditingController(
      text: widget.entry.newJobs != null ? widget.entry.newJobs.toString() : '',
    );
    _outstandingController = TextEditingController(
      text: widget.entry.outstandingJobs != null ? widget.entry.outstandingJobs.toString() : '',
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
    if (widget.entry.countType == 'SINGLE') {
      final jcText = (widget.entry.jobsCompleted ?? 0).toString();
      if (_jobsController.text != jcText) {
        _jobsController.text = jcText;
      }
    } else {
      final onText = (widget.entry.ongoingJobs ?? 0).toString();
      final newText = (widget.entry.newJobs ?? 0).toString();
      final outText = (widget.entry.outstandingJobs ?? 0).toString();
      if (_ongoingController.text != onText) _ongoingController.text = onText;
      if (_newJobsController.text != newText) _newJobsController.text = newText;
      if (_outstandingController.text != outText) _outstandingController.text = outText;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _jobsController.dispose();
    _ongoingController.dispose();
    _newJobsController.dispose();
    _outstandingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTriple = widget.entry.countType == 'TRIPLE';

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

            // Amount Field
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputOption(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                prefixText: '₹ ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                hintText: '0.00',
              ),
              onChanged: (val) {
                final amount = double.tryParse(val) ?? 0.0;
                widget.onAmountChanged(amount);
              },
            ),
            const SizedBox(height: 12),

            // Job Counts based on count_type
            if (!isTriple)
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
              // ACCOUNTS TRIPLE COUNTS
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Status Counts',
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
                          controller: _ongoingController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Ongoing',
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            final count = int.tryParse(val) ?? 0;
                            widget.onJobCountsChanged(ongoing: count);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _newJobsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'New Job',
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            final count = int.tryParse(val) ?? 0;
                            widget.onJobCountsChanged(newJobs: count);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _outstandingController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Outstanding',
                            hintText: '0',
                          ),
                          onChanged: (val) {
                            final count = int.tryParse(val) ?? 0;
                            widget.onJobCountsChanged(outstanding: count);
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

