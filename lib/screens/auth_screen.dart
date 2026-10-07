import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/cottagecore_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSigningUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_isSigningUp) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo conectar. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    var isSending = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Escribe el correo asociado a tu cuenta.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                  ),
                  validator: (value) =>
                      value != null && value.trim().contains('@')
                          ? null
                          : 'Escribe un correo válido',
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(errorMessage!,
                      style: const TextStyle(color: CottagecoreColors.urgentRed)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        isSending = true;
                        errorMessage = null;
                      });
                      try {
                        await Supabase.instance.client.auth
                            .resetPasswordForEmail(
                          emailController.text.trim(),
                          redirectTo: Uri.base.origin,
                        );
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Revisa tu correo. Si la dirección está registrada, recibirás un enlace para cambiar la contraseña.',
                            ),
                          ),
                        );
                      } on AuthException catch (error) {
                        setDialogState(() {
                          errorMessage = error.message;
                          isSending = false;
                        });
                      } catch (_) {
                        setDialogState(() {
                          errorMessage =
                              'No se pudo enviar el correo. Comprueba tu conexión e inténtalo de nuevo.';
                          isSending = false;
                        });
                      }
                    },
              child: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar enlace'),
            ),
          ],
        ),
      ),
    );
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.local_florist, size: 44, color: CottagecoreColors.sage),
                    const SizedBox(height: 16),
                    const Text(
                      'Mi agenda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: CottagecoreColors.forest,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSigningUp ? 'Crea tu cuenta' : 'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: CottagecoreColors.warmBrown),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (!email.contains('@')) return 'Escribe un correo válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      autofillHints: _isSigningUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').length < 6) return 'Usa al menos 6 caracteres';
                        return null;
                      },
                    ),
                    if (_isSigningUp) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        obscureText: _obscureConfirmPassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword
                                ? 'Mostrar confirmación'
                                : 'Ocultar confirmación',
                            onPressed: () => setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            }),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: CottagecoreColors.forest,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(_isSigningUp
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded),
                      label: Text(
                        _isSigningUp ? 'Crear cuenta' : 'Entrar',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!_isSigningUp)
                      TextButton(
                        onPressed:
                            _isLoading ? null : _showForgotPasswordDialog,
                        child: const Text('¿Has olvidado tu contraseña?'),
                      ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _isSigningUp = !_isSigningUp),
                      child: Text(
                        _isSigningUp
                            ? 'Ya tengo una cuenta'
                            : 'Crear una cuenta nueva',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({required this.onCompleted, super.key});

  final VoidCallback onCompleted;

  @override
  State<PasswordRecoveryScreen> createState() =>
      _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Supabase.instance.client.auth;
      await auth.updateUser(UserAttributes(password: _password.text));
      await auth.signOut();
      widget.onCompleted();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo guardar la contraseña. Vuelve a abrir el enlace e inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_reset_rounded,
                          size: 44, color: CottagecoreColors.sage),
                      const SizedBox(height: 16),
                      const Text(
                        'Nueva contraseña',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: CottagecoreColors.forest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Elige una contraseña nueva para tu cuenta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CottagecoreColors.warmBrown),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) => (value ?? '').length >= 6
                            ? null
                            : 'Usa al menos 6 caracteres',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmation,
                        obscureText: _obscureConfirmation,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Confirmar contraseña',
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmation
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () => setState(() =>
                                _obscureConfirmation = !_obscureConfirmation),
                            icon: Icon(_obscureConfirmation
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: (value) => value == _password.text
                            ? null
                            : 'Las contraseñas no coinciden',
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _savePassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: CottagecoreColors.forest,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: _isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text('Guardar contraseña'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
