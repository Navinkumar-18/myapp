import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/user_service.dart';
import '../utils/password_generator.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  late final UserService _userService;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  String? _selectedRole;
  String? _selectedManagedAdmin;
  List<Map<String, dynamic>> _adminUsers = [];
  bool _isLoading = false;
  bool _passwordVisible = false;

  static const List<String> _roles = ['admin', 'bla', 'super_admin'];

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _generatePassword();
    _loadAdminUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Generate a new random password
  void _generatePassword() {
    _passwordController.text = PasswordGenerator.generatePassword();
  }

  /// Load admin users for managed_by dropdown
  Future<void> _loadAdminUsers() async {
    try {
      final admins = await _userService.getAdminUsers();
      if (mounted) {
        setState(() => _adminUsers = admins);
      }
    } catch (error) {
      debugPrint('Error loading admin users: $error');
    }
  }

  /// Copy password to clipboard
  void _copyPasswordToClipboard() {
    Clipboard.setData(ClipboardData(text: _passwordController.text)).then((_) {
      _showSnackbar('Password copied to clipboard');
    });
  }

  /// Handle form submission
  Future<void> _handleCreateUser() async {
    // Validate role selection
    if (_selectedRole == null) {
      _showSnackbar('Please select a role', isError: true);
      return;
    }

    // Validate managed admin for BLA role
    if (_selectedRole == 'bla' && _selectedManagedAdmin == null) {
      _showSnackbar('Please select a managed admin for BLA role', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final errorMessage = await _userService.createUser(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        phone: _phoneController.text.replaceAll(RegExp(r'[^\d]'), ''),
        password: _passwordController.text,
        role: _selectedRole!,
        managedBy: _selectedRole == 'bla' ? _selectedManagedAdmin : null,
      );

      if (mounted) {
        if (errorMessage == null) {
          _showSuccessDialog();
          _clearForm();
        } else {
          _showSnackbar(errorMessage, isError: true);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Clear form fields
  void _clearForm() {
    _emailController.clear();
    _usernameController.clear();
    _phoneController.clear();
    setState(() {
      _selectedRole = null;
      _selectedManagedAdmin = null;
    });
    _generatePassword();
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('User created successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show snackbar message
  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Create New System User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in all details to create a new user account',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              // Email Field
              _buildLabel('Email Address'),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'user@example.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Username Field
              _buildLabel('Username'),
              TextField(
                controller: _usernameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: 'username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number Field
              _buildLabel('Phone Number (Indian Format)'),
              TextField(
                controller: _phoneController,
                enabled: !_isLoading,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: '9876543210',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  helperText: 'Enter 10-digit mobile number',
                ),
              ),
              const SizedBox(height: 20),

              // Role Dropdown
              _buildLabel('Role'),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                disabledHint: _isLoading ? const Text('Loading...') : null,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.security),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRole = value);
                  if (value != 'bla') {
                    setState(() => _selectedManagedAdmin = null);
                  }
                },
                hint: const Text('Select role'),
              ),
              const SizedBox(height: 20),

              // Managed Admin Dropdown (only for BLA role)
              if (_selectedRole == 'bla') ...[
                _buildLabel('Managed Admin'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedManagedAdmin,

                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    helperText: _adminUsers.isEmpty
                        ? 'No admin users available'
                        : null,
                  ),
                  items: _adminUsers.map((admin) {
                    return DropdownMenuItem(
                      value: admin['id'].toString(),
                      child: Text(admin['username'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: _adminUsers.isNotEmpty
                      ? (value) => setState(() => _selectedManagedAdmin = value)
                      : null,
                  hint: const Text('Select admin'),
                ),
                const SizedBox(height: 20),
              ],

              // Password Field with Copy Button
              _buildLabel('Generated Password'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _passwordController,
                      enabled: false,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() =>
                                _passwordVisible = !_passwordVisible);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _copyPasswordToClipboard,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generatePassword,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('New'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Create User',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Reset Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          _emailController.clear();
                          _usernameController.clear();
                          _phoneController.clear();
                          setState(() {
                            _selectedRole = null;
                            _selectedManagedAdmin = null;
                          });
                          _generatePassword();
                        },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clear Form'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build label widget for form fields
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
