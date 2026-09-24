import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/auth/data/auth_service.dart';
import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

class OtpVerificationScreen extends HookConsumerWidget {
  final String email;

  /// Destination demandée avant la redirection vers la connexion.
  final String? from;

  const OtpVerificationScreen({super.key, required this.email, this.from});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final codeController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final authService = ref.watch(authServiceProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    // 6 individual focus nodes for OTP boxes
    final focusNodes = List.generate(6, (i) => useFocusNode());
    final digitControllers =
        List.generate(6, (i) => useTextEditingController());

    // Resend timer
    final resendTimer = useState(60);
    final canResend = useState(false);

    useEffect(() {
      Timer? timer;
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (resendTimer.value > 0) {
          resendTimer.value--;
        } else {
          canResend.value = true;
          t.cancel();
        }
      });
      return () => timer?.cancel();
    }, const []);

    // Sync digit controllers to codeController
    void syncCode() {
      final code = digitControllers.map((c) => c.text).join();
      codeController.text = code;
    }

    void handleVerify() async {
      syncCode();
      if (codeController.text.length < 6) {
        errorMessage.value = 'Veuillez entrer le code a 6 chiffres';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await authService.verifyCode(email, codeController.text);

        // Invalider les providers pour forcer le rechargement des donnees de l'utilisateur
        ref.invalidate(userNameProvider);
        ref.invalidate(userRoleProvider);
        ref.invalidate(userIdProvider);

        if (context.mounted) {
          context.go(AppRouter.afterLogin(from));
        }
      } catch (e) {
        errorMessage.value = e.toString();
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                // Left branding panel (60%)
                Expanded(
                  flex: 6,
                  child: _OtpBrandingPanel(),
                ),
                // Right form panel (40%)
                Expanded(
                  flex: 4,
                  child: _OtpFormPanel(
                    email: email,
                    digitControllers: digitControllers,
                    focusNodes: focusNodes,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    canResend: canResend,
                    resendTimer: resendTimer,
                    onVerify: handleVerify,
                    onResend: () async {
                      try {
                        await authService.login(email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nouveau code envoye'),
                            ),
                          );
                        }
                        resendTimer.value = 60;
                        canResend.value = false;
                      } catch (e) {
                        errorMessage.value = e.toString();
                      }
                    },
                    syncCode: syncCode,
                  ),
                ),
              ],
            )
          : _OtpFormPanel(
              email: email,
              digitControllers: digitControllers,
              focusNodes: focusNodes,
              isLoading: isLoading,
              errorMessage: errorMessage,
              canResend: canResend,
              resendTimer: resendTimer,
              onVerify: handleVerify,
              showLogo: true,
              onResend: () async {
                try {
                  await authService.login(email);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nouveau code envoye'),
                      ),
                    );
                  }
                  resendTimer.value = 60;
                  canResend.value = false;
                } catch (e) {
                  errorMessage.value = e.toString();
                }
              },
              syncCode: syncCode,
            ),
    );
  }
}

// ─── Branding Panel (mirrors login) ───

class _OtpBrandingPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.accent],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(32),
                  Text(
                    'Verification',
                    style: GoogleFonts.inter(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 350.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(12),
                  Text(
                    'Connexion securisee par code OTP',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 500.ms)
                      .slideX(begin: -0.2, end: 0),
                  const Gap(32),
                  Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 650.ms),
                  const Gap(24),
                  Text(
                    'Un code a 6 chiffres a ete envoye a votre\nadresse email. Il expire dans quelques minutes.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.7,
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTP Form Panel ───

class _OtpFormPanel extends StatelessWidget {
  final String email;
  final List<TextEditingController> digitControllers;
  final List<FocusNode> focusNodes;
  final ValueNotifier<bool> isLoading;
  final ValueNotifier<String?> errorMessage;
  final ValueNotifier<bool> canResend;
  final ValueNotifier<int> resendTimer;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback syncCode;
  final bool showLogo;

  const _OtpFormPanel({
    required this.email,
    required this.digitControllers,
    required this.focusNodes,
    required this.isLoading,
    required this.errorMessage,
    required this.canResend,
    required this.resendTimer,
    required this.onVerify,
    required this.onResend,
    required this.syncCode,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, AppTheme.accent],
                          ),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryContent.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.shield_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const Gap(32),
                  ],
                  // Back button + title row
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Icon(
                            Icons.arrow_back_rounded,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      const Gap(16),
                      Text(
                        'Verification',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                  const Gap(12),
                  // Email indicator
                  Row(
                    children: [
                      const Gap(52), // align with title
                      Expanded(
                        child: Text(
                          'Code envoye a $email',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 280.ms),
                  const Gap(40),
                  // OTP boxes label
                  Text(
                    'Code de verification',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
                  const Gap(12),
                  // 6 OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return _OtpDigitBox(
                        controller: digitControllers[index],
                        focusNode: focusNodes[index],
                        hasError: errorMessage.value != null,
                        onChanged: (value) {
                          if (value.length == 1 && index < 5) {
                            focusNodes[index + 1].requestFocus();
                          }
                          syncCode();
                          // Auto-submit when all 6 digits are filled
                          final code =
                              digitControllers.map((c) => c.text).join();
                          if (code.length == 6) {
                            onVerify();
                          }
                        },
                        onBackspace: () {
                          if (digitControllers[index].text.isEmpty &&
                              index > 0) {
                            focusNodes[index - 1].requestFocus();
                            digitControllers[index - 1].clear();
                            syncCode();
                          }
                        },
                      );
                    }),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  // Error message
                  if (errorMessage.value != null) ...[
                    const Gap(12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppTheme.error),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              errorMessage.value!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms).shake(
                          hz: 3,
                          offset: const Offset(4, 0),
                          duration: 400.ms,
                        ),
                  ],
                  const Gap(28),
                  // Verify button
                  ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (context, loading, _) {
                      return AnimatedContainer(
                        duration: AppTheme.animFast,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          gradient: loading
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    AppTheme.primary,
                                    AppTheme.accent
                                  ],
                                ),
                          color: loading
                              ? AppTheme.primary.withValues(alpha: 0.6)
                              : null,
                          boxShadow: loading
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: loading ? null : onVerify,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            child: Center(
                              child: loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Verifier le code',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).animate().fadeIn(duration: 500.ms, delay: 470.ms),
                  const Gap(24),
                  // Resend section
                  Center(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: canResend,
                      builder: (context, canResendNow, _) {
                        if (canResendNow) {
                          return TextButton(
                            onPressed: onResend,
                            child: Text(
                              'Renvoyer le code',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryContent,
                              ),
                            ),
                          );
                        }
                        return ValueListenableBuilder<int>(
                          valueListenable: resendTimer,
                          builder: (context, seconds, _) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: AppTheme.textTertiary,
                                ),
                                const Gap(6),
                                Text(
                                  'Renvoyer dans ${seconds}s',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 550.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Single OTP Digit Box ───

class _OtpDigitBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(), // wrapper focus node for key events
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: hasError ? AppTheme.error : AppTheme.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: hasError ? AppTheme.error : AppTheme.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide(
                color: hasError ? AppTheme.error : AppTheme.primaryContent,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
