import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isResetLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('last_login_email');
    if (email != null && mounted) {
      setState(() => _emailController.text = email);
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_login_email', email);
  }

  Future<void> _clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_login_email');
    setState(() => _emailController.clear());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Sign In ──────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Bitte E-Mail und Passwort eingeben', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService().signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        await _saveEmail(email);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showSnackBar('Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
            isError: true);
      }
    } on AuthException catch (e) {
      if (mounted) _showSnackBar(_mapAuthError(e.message), isError: true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Verbindungsfehler. Prüfe deine Internetverbindung.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Bitte zuerst deine E-Mail eingeben', isError: true);
      return;
    }

    setState(() => _isResetLoading = true);
    try {
      await AuthService().resetPassword(email);
      if (mounted) {
        _showSnackBar('✉️ Passwort-Reset E-Mail wurde gesendet!',
            isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Fehler: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isResetLoading = false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'E-Mail oder Passwort ist falsch.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (msg.contains('too many requests')) {
      return 'Zu viele Versuche. Bitte warte kurz.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Verbindungsfehler. Prüfe deine Internetverbindung.';
    }
    return message;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        backgroundColor: isError ? AppColors.expensive : AppColors.cheap,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmall = screenWidth < 360;
    final isShort = screenHeight < 700;
    final logoSize = isSmall ? 56.0 : 72.0;
    final hPad = isSmall ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            hPad,
            isShort ? 8 : 24,
            hPad,
            hPad + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: isShort ? 8 : 20),

              // Logo
              Center(
                child: Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(logoSize * 0.28),
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    color: Colors.white,
                    size: logoSize * 0.5,
                  ),
                ),
              ),
              SizedBox(height: isShort ? 16 : 24),

              Text(
                'Willkommen zurück!',
                style: GoogleFonts.outfit(
                  fontSize: isSmall ? 24 : 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Melde dich an um Favoriten & Einstellungen zu synchronisieren.',
                style: GoogleFonts.outfit(
                  fontSize: isSmall ? 13 : 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isShort ? 24 : 40),

              // Email field
              _buildTextField(
                controller: _emailController,
                label: 'E-Mail',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                suffixIcon: _emailController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.cancel_rounded,
                            size: 18, color: AppColors.textMuted),
                        onPressed: _clearSavedEmail,
                      )
                    : null,
              ),
              const SizedBox(height: 16),

              // Password field
              _buildTextField(
                controller: _passwordController,
                label: 'Passwort',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isResetLoading ? null : _resetPassword,
                  child: _isResetLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          'Passwort vergessen?',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Login button
              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 3, color: AppColors.background),
                        )
                      : FittedBox(
                          child: Text(
                            'Anmelden',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'oder',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Noch kein Konto?',
                    style: GoogleFonts.outfit(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/register'),
                    child: Text(
                      'Jetzt registrieren',
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              // Guest mode — prominent secondary button (P1 visibility fix)
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  icon: const Icon(Icons.person_outline_rounded, size: 24),
                  label: FittedBox(
                    child: Text(
                      'Als Gast fortfahren',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Keine Registrierung nötig',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
