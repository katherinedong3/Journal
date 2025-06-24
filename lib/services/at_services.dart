import 'package:at_client/at_client.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:path_provider/path_provider.dart';

class AtService {
  static final AtService _instance = AtService._internal();
  factory AtService() => _instance;
  AtService._internal();

  late AtClientManager atClientManager;

  Future<void> init(String atSign) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final prefs = AtClientPreference()
      ..rootDomain = 'root.atsign.org'
      ..namespace = 'journal'
      ..hiveStoragePath = appSupportDir.path
      ..commitLogPath = appSupportDir.path
      ..downloadPath = appSupportDir.path;

    await AtClientManager.getInstance().setCurrentAtSign(
      atSign,
      'root.atsign.org',
      prefs,
    );
    atClientManager = AtClientManager.getInstance();
  }

  AtClient get client => atClientManager.atClient;
} 