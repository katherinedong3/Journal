import 'package:flutter/material.dart';
import 'package:at_onboarding_flutter/at_onboarding_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../services/at_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Future<AtClientPreference> _getAtClientPreference() async {
    final directory = await getApplicationSupportDirectory();
    return AtClientPreference()
      ..rootDomain = 'root.atsign.org'
      ..namespace = 'journal'
      ..hiveStoragePath = directory.path
      ..commitLogPath = directory.path
      ..downloadPath = directory.path
      ..isLocalStoreRequired = true;
  }

  void _startOnboarding() async {
    final preference = await _getAtClientPreference();

    final result = await AtOnboarding.onboard(
      context: context,
      config: AtOnboardingConfig(
        atClientPreference: preference,
        domain: 'root.atsign.org',
        rootEnvironment: RootEnvironment.Production,
        appAPIKey: '', // Leave blank unless you're using a paid API key
      ),
    );

    switch (result.status) {
      case AtOnboardingResultStatus.success:
        final atsign = result.atsign!;
        await AtService().init(atsign);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        break;

      case AtOnboardingResultStatus.error:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onboarding error: ${result.message}')),
        );
        break;

      case AtOnboardingResultStatus.cancel:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Onboarding canceled.')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to Private Journal')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startOnboarding,
          child: const Text('Onboard my @sign'),
        ),
      ),
    );
  }

  //function for logging out
  Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('atsign');
  AtClientManager.getInstance().reset();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }
}
}
