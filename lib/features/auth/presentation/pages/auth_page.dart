import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/responsive.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'forgot_password_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _shopNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLogin = true;
  bool _acceptTerms = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _authenticate() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isLogin && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isLogin) {
      context.read<AuthBloc>().add(AuthLoginRequested(email, password));
    } else {
      if (password != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      context.read<AuthBloc>().add(AuthSignupRequested(email, password, _shopNameController.text.trim(), _phoneController.text.trim()));
    }
  }

  String _getErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    if (lowerError.contains('invalid login credentials') || lowerError.contains('invalid_credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }
    if (lowerError.contains('email not confirmed') || lowerError.contains('email_not_confirmed')) {
      return 'Please check your email and click the verification link before signing in.';
    }
    if (lowerError.contains('user already registered') || lowerError.contains('user_already_exists')) {
      return 'An account with this email already exists. Please try logging in instead.';
    }
    if (lowerError.contains('password') && (lowerError.contains('weak') || lowerError.contains('min'))) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (lowerError.contains('supabase') && lowerError.contains('configured')) {
      return 'Authentication service is not configured properly. Please contact support.';
    }
    return 'Unable to authenticate. Please check your details and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          final errorMessage = _getErrorMessage(state.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red,
                    Colors.black,
                    Colors.white,
                    Colors.red,
                  ],
                  stops: [0.0, 0.33, 0.67, 1.0],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFF8F9FA)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.store_rounded,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // App Name
                      const Text(
                        'TwigaPOS',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        _isLogin ? 'Welcome Back!' : 'Join Our Community',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Form Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tab Switcher
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _isLogin = true;
                                          _shopNameController.clear();
                                          _phoneController.clear();
                                          _confirmPasswordController.clear();
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                           decoration: BoxDecoration(
                                             color: _isLogin ? Colors.red : Colors.transparent,
                                             borderRadius: BorderRadius.circular(10),
                                           ),
                                          child: Text(
                                            'Login',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: _isLogin ? Colors.white : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _isLogin = false;
                                          _shopNameController.clear();
                                          _phoneController.clear();
                                          _confirmPasswordController.clear();
                                        }),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                           decoration: BoxDecoration(
                                             color: !_isLogin ? Colors.red : Colors.transparent,
                                             borderRadius: BorderRadius.circular(10),
                                           ),
                                          child: Text(
                                            'Sign Up',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: !_isLogin ? Colors.white : Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                               const SizedBox(height: 20),

                               // Shop Name Field (Signup only)
                               if (!_isLogin) ...[
                                 TextFormField(
                                   controller: _shopNameController,
                                   focusNode: _shopNameFocus,
                                   keyboardType: TextInputType.text,
                                   textInputAction: TextInputAction.next,
                                   onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                                   style: const TextStyle(fontSize: 16, color: Colors.black87),
                                   decoration: InputDecoration(
                                     label: const Text('Shop Name'),
                                     labelStyle: const TextStyle(color: Colors.black54),
                                     prefixIcon: const Icon(Icons.store, color: Colors.black54),
                                     filled: true,
                                     fillColor: Colors.grey[50],
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     enabledBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     focusedBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: const BorderSide(color: Colors.red, width: 2),
                                     ),
                                   ),
                                   validator: (value) {
                                     if (value == null || value.trim().isEmpty) {
                                       return 'Shop name is required';
                                     }
                                     if (value.trim().length < 2) {
                                       return 'Shop name must be at least 2 characters long';
                                     }
                                     return null;
                                   },
                                 ),

                                 const SizedBox(height: 16),

                                 // Phone Number Field (Signup only)
                                 TextFormField(
                                   controller: _phoneController,
                                   focusNode: _phoneFocus,
                                   keyboardType: TextInputType.phone,
                                   textInputAction: TextInputAction.next,
                                   onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                                   style: const TextStyle(fontSize: 16, color: Colors.black87),
                                   decoration: InputDecoration(
                                     label: const Text('Phone Number'),
                                     labelStyle: const TextStyle(color: Colors.black54),
                                     prefixIcon: const Icon(Icons.phone, color: Colors.black54),
                                     filled: true,
                                     fillColor: Colors.grey[50],
                                     border: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     enabledBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     focusedBorder: OutlineInputBorder(
                                       borderRadius: BorderRadius.circular(12),
                                       borderSide: const BorderSide(color: Colors.red, width: 2),
                                     ),
                                   ),
                                   validator: (value) {
                                     if (value == null || value.trim().isEmpty) {
                                       return 'Phone number is required';
                                     }
                                     if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value.trim())) {
                                       return 'Please enter a valid phone number';
                                     }
                                     return null;
                                   },
                                 ),

                                 const SizedBox(height: 16),
                               ],

                               // Email Field
                              TextFormField(
                                controller: _emailController,
                                focusNode: _emailFocus,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                   onFieldSubmitted: (_) => _isLogin ? _passwordFocus.requestFocus() : _shopNameFocus.requestFocus(),
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: InputDecoration(
                                  label: const Text('Email Address'),
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                   focusedBorder: OutlineInputBorder(
                                     borderRadius: BorderRadius.circular(12),
                                     borderSide: const BorderSide(color: Colors.red, width: 2),
                                   ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Email address is required';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                obscureText: true,
                                textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  if (_isLogin) {
                                    _authenticate();
                                  } else {
                                    _confirmPasswordFocus.requestFocus();
                                  }
                                },
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                                decoration: InputDecoration(
                                  label: const Text('Password'),
                                  labelStyle: const TextStyle(color: Colors.black54),
                                  prefixIcon: const Icon(Icons.lock_outlined, color: Colors.black54),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                   focusedBorder: OutlineInputBorder(
                                     borderRadius: BorderRadius.circular(12),
                                     borderSide: const BorderSide(color: Colors.red, width: 2),
                                   ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                              
                              // Confirm Password & Terms (Signup only)
                              if (!_isLogin) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  focusNode: _confirmPasswordFocus,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _authenticate(),
                                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  decoration: InputDecoration(
                                    label: const Text('Confirm Password'),
                                    labelStyle: const TextStyle(color: Colors.black54),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                
                                const SizedBox(height: 16),
                                
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _acceptTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _acceptTerms = value ?? false;
                                        });
                                      },
                                       activeColor: Colors.red,
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I agree to the Terms & Conditions',
                                        style: TextStyle(fontSize: 14, color: Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              
                              const SizedBox(height: 24),
                              
                              // Submit Button
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _authenticate,
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: Colors.red,
                                     foregroundColor: Colors.white,
                                     elevation: 4,
                                     shadowColor: Colors.red.withValues(alpha: 0.3),
                                     shape: RoundedRectangleBorder(
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                   ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isLogin ? 'Sign In' : 'Create Account',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              _isLogin ? Icons.arrow_forward : Icons.person_add,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              
                              // Forgot Password (Login only)
                              if (_isLogin) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const ForgotPasswordPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                       style: TextStyle(
                                         fontSize: 14,
                                         fontWeight: FontWeight.w500,
                                         color: Colors.red,
                                       ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Footer
                      Text(
                        'Secure • Fast • Reliable',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
