import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  const PinLockScreen({super.key, this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String? _error;

  void _onKeyPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _error = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _error = null;
      });
    }
  }

  void _verifyPin() {
    final savedPin = Hive.box('settings').get('pinCode');
    if (savedPin == _enteredPin) {
      Hive.box('settings').put('pinVerified', true);
      if (widget.onUnlocked != null) {
        widget.onUnlocked!();
      } else {
        if (mounted) context.pop();
      }
    } else {
      setState(() {
        _error = 'Incorrect PIN';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.lock, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please enter your 4-digit PIN',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? Theme.of(context).primaryColor
                        : Colors.grey[800],
                  ),
                );
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
            const Spacer(),
            // NumPad
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                for (var i = 1; i <= 9; i++)
                  _buildDigitButton('$i'),
                _buildDigitButton('', onTap: () {}),
                _buildDigitButton('0'),
                _buildDigitButton('', icon: Icons.backspace, onTap: _onBackspace),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitButton(String digit, {IconData? icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _onKeyPressed(digit),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon ?? Icons.text_fields,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

