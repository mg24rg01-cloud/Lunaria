import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../utils/l10n.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _checkUserExists();
  }

  Future<void> _checkUserExists() async {
    final exists = await AppState().userExists();
    setState(() {
      _isLogin = exists;
    });
  }

  Future<void> _submit() async {
    if (_passwordController.text.isEmpty) {
      _showError(L10n.s('password_required'));
      return;
    }
    if (!_isLogin && _nicknameController.text.isEmpty) {
      _showError(L10n.s('nickname_required'));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await AppState().login(_passwordController.text);
      } else {
        await AppState().signup(_nicknameController.text, _passwordController.text);
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).cardColor)),
        backgroundColor: Colors.red[300],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color dustyPink = isDarkMode ? const Color(0xFFF49FB6) : const Color(0xFFD4A5A5);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF2C2C37);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: dustyPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.account_balance_wallet_outlined, size: 64, color: dustyPink),
                ),
                const SizedBox(height: 32),
                Text(
                  _isLogin ? L10n.s('welcome_back') : L10n.s('create_space'),
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? L10n.s('enter_password') : L10n.s('personalize_control'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                const SizedBox(height: 48),
                if (!_isLogin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F7FB),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _nicknameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: L10n.s('nickname'),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        icon: Icon(Icons.person_outline, color: dustyPink, size: 20),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white.withOpacity(0.05) : const Color(0xFFF7F7FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: TextStyle(color: textColor),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: L10n.s('password'),
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: Icon(Icons.lock_outline, color: dustyPink, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400], size: 20),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dustyPink,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isLogin ? L10n.s('login') : L10n.s('signup'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _nicknameController.clear();
                    _passwordController.clear();
                  }),
                  child: Text(
                    _isLogin ? L10n.s('no_account') : L10n.s('already_account'),
                    style: TextStyle(color: dustyPink, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
