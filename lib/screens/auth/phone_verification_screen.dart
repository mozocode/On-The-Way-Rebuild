import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/firebase_config.dart';
import '../../config/theme.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const PhoneVerificationScreen({super.key, this.phoneNumber});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController();
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final formatted = phone.startsWith('+') ? phone : '+1$phone';

    await FirebaseConfig.auth.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (credential) async {
        await FirebaseConfig.auth.currentUser
            ?.linkWithCredential(credential);
        if (mounted) Navigator.pop(context, true);
      },
      verificationFailed: (e) {
        setState(() {
          _isLoading = false;
          _error = e.message ?? 'Verification failed';
        });
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _codeSent = true;
          _isLoading = false;
        });
        _codeFocusNodes[0].requestFocus();
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await FirebaseConfig.auth.currentUser?.linkWithCredential(credential);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.message ?? 'Invalid code';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _codeSent ? 'Enter Verification Code' : 'Enter Phone Number',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'We sent a 6-digit code to ${_phoneController.text}'
                    : 'We\'ll send a verification code to your phone',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (!_codeSent) _buildPhoneInput() else _buildCodeInput(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_codeSent ? 'Verify' : 'Send Code'),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _sendCode,
                    child: const Text('Resend Code'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
      decoration: const InputDecoration(
        hintText: '(555) 123-4567',
        prefixIcon: Icon(Icons.phone),
        prefixText: '+1 ',
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          child: TextField(
            controller: _codeControllers[i],
            focusNode: _codeFocusNodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: AppTheme.brandGreen, width: 2),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              if (value.isNotEmpty && i < 5) {
                _codeFocusNodes[i + 1].requestFocus();
              }
              if (value.isEmpty && i > 0) {
                _codeFocusNodes[i - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
