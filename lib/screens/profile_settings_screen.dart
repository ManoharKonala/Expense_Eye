import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_language.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  double _budgetProgress = 0.3;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.current;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          strings.t('profileSettings'),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              strings.t('save'),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // Profile Information
              _buildProfileImage(),
              const SizedBox(height: 16),
              const Text(
                'Chaitanya Sharma',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'chai.sharma@email.com',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // App Settings Card
              _buildCard(
                title: strings.t('appSettings'),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.notifications_none,
                      title: strings.t('notifications'),
                      showTrailingArrow: true,
                    ),
                    _buildListTile(
                      icon: Icons.language,
                      title: strings.t('language'),
                      trailingText:
                          AppLanguageController.language.value.nativeName,
                      showTrailingArrow: true,
                      onTap: () => _showLanguagePicker(context),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Monthly Budget Card
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            strings.t('monthlyBudget'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          Text(
                            '₹${NumberFormat('#,##0').format((_budgetProgress * 50000).toInt())}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 6,
                                activeTrackColor: Colors.greenAccent.shade400,
                                inactiveTrackColor: Colors.grey.shade200,
                                thumbColor: Colors.greenAccent.shade400,
                                overlayShape: SliderComponentShape.noOverlay,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                ),
                              ),
                              child: Slider(
                                value: _budgetProgress,
                                onChanged: (val) {
                                  setState(() {
                                    _budgetProgress = val;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Data Management Card
              _buildCard(
                title: strings.t('dataManagement'),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.upload_outlined,
                      title: strings.t('exportExpenseHistory'),
                      showTrailingArrow: true,
                    ),
                    _buildListTile(
                      icon: Icons.receipt_long_outlined,
                      title: strings.t('downloadMonthlyReport'),
                      showTrailingArrow: true,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Privacy & Data Card
              _buildCard(
                title: strings.t('privacyData'),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      title: strings.t('privacySettings'),
                      showTrailingArrow: true,
                      onTap: () => _showPrivacyPolicy(context),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          strings.t('logOut'),
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final strings = AppStrings.current;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          strings.t('privacyPolicy'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            strings.t('privacyPolicyBody'),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              strings.t('gotIt'),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final strings = AppStrings.current;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.t('chooseLanguage'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              ...AppLanguage.values.map(
                (language) => ListTile(
                  title: Text(language.nativeName),
                  subtitle: Text(language.englishName),
                  trailing: AppLanguageController.language.value == language
                      ? const Icon(Icons.check, color: Colors.deepPurple)
                      : null,
                  onTap: () {
                    AppLanguageController.setLanguage(language);
                    setState(() {});
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.orange.shade300, Colors.teal.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 65,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? trailingText,
    bool showTrailingArrow = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.greenAccent.shade100.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blueGrey.shade700, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF2C3E50),
        ),
      ),
      trailing: showTrailingArrow
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: const TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap ?? () {},
    );
  }
}
