import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnimatedRefreshAction extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String tooltip;
  final Color? color;

  const AnimatedRefreshAction({
    super.key,
    required this.onRefresh,
    this.tooltip = 'Refresh',
    this.color,
  });

  @override
  State<AnimatedRefreshAction> createState() => _AnimatedRefreshActionState();
}

class _AnimatedRefreshActionState extends State<AnimatedRefreshAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _controller.repeat();

    try {
      await widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Data refreshed successfully'),
              ],
            ),
            duration: const Duration(milliseconds: 1400),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.success,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Refresh failed: $e')),
              ],
            ),
            backgroundColor: AppTheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        _controller.stop();
        _controller.reset();
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.tooltip,
      color: widget.color,
      onPressed: _isLoading ? null : _handleRefresh,
      icon: RotationTransition(
        turns: _controller,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

