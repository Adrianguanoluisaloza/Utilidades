import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de formulario moderno estilo Copilot de Windows 11
class ModernFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final bool showFloatingLabel;
  final Color? accentColor;

  const ModernFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.onTap,
    this.suffixIcon,
    this.inputFormatters,
    this.showFloatingLabel = true,
    this.accentColor,
  });

  @override
  State<ModernFormField> createState() => _ModernFormFieldState();
}

class _ModernFormFieldState extends State<ModernFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _animationController.forward();
      HapticFeedback.lightImpact();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.accentColor ?? const Color(0xFF0078D4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showFloatingLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withAlpha(204)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (widget.validator != null)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: accentColor.withAlpha(77),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Focus(
                  onFocusChange: _onFocusChange,
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    maxLines: widget.maxLines,
                    enabled: widget.enabled,
                    onTap: widget.onTap,
                    inputFormatters: widget.inputFormatters,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint ?? widget.label,
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _isFocused ? accentColor : Colors.grey.shade400,
                              _isFocused
                                  ? accentColor.withAlpha(204)
                                  : Colors.grey.shade500,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      suffixIcon: widget.suffixIcon,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2D2D30)
                          : (_isFocused ? Colors.white : Colors.grey.shade50),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: accentColor,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.red.shade400,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: widget.validator,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Campo de contraseña moderno con toggle de visibilidad
class ModernPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final bool enabled;
  final Color? accentColor;

  const ModernPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.enabled = true,
    this.accentColor,
  });

  @override
  State<ModernPasswordField> createState() => _ModernPasswordFieldState();
}

class _ModernPasswordFieldState extends State<ModernPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return ModernFormField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      icon: Icons.lock_outline,
      obscureText: _obscureText,
      validator: widget.validator,
      enabled: widget.enabled,
      accentColor: widget.accentColor,
      suffixIcon: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(_obscureText),
            color: widget.accentColor ?? const Color(0xFF0078D4),
          ),
        ),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
          HapticFeedback.lightImpact();
        },
      ),
    );
  }
}

/// Selector de roles moderno
class ModernRoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;
  final List<RoleOption> roles;
  final Color? accentColor;

  const ModernRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.roles,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentColor ?? const Color(0xFF0078D4);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withAlpha(26),
            accent.withAlpha(13),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withAlpha(204)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.how_to_reg, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Como quieres registrarte?',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: roles
                .map((role) => _buildRoleChip(
                      context,
                      role,
                      selectedRole == role.value,
                      accent,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
      BuildContext context, RoleOption role, bool isSelected, Color accent) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          onRoleChanged(role.value);
          HapticFeedback.lightImpact();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [accent, accent.withAlpha(204)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accent
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: accent.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isSelected) ...[
                Icon(
                  role.icon,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                role.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleOption {
  final String label;
  final String value;
  final IconData icon;

  const RoleOption({
    required this.label,
    required this.value,
    required this.icon,
  });
}

/// Botón moderno estilo Copilot
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height = 60,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF0078D4);
    final textColor = widget.textColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.isLoading
                  ? null
                  : LinearGradient(
                      colors: [color, color.withAlpha(204)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.isLoading ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.isLoading
                  ? null
                  : [
                      BoxShadow(
                        color: color.withAlpha(102),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.isLoading
                    ? null
                    : () {
                        _animationController.forward().then((_) {
                          _animationController.reverse();
                        });
                        HapticFeedback.mediumImpact();
                        widget.onPressed?.call();
                      },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: widget.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Procesando...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.icon != null) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: 20,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Text(
                              widget.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
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
