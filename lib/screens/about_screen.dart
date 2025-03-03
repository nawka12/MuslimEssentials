import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../localizations/app_localizations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'about')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App logo
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Image.asset(
                'assets/icon/logo.png',
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.mosque_outlined, size: 100),
              ),
            ),
          ),
          
          // App name with large bold text
          Center(
            child: Text(
              'Muslim Essentials',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          
          // Version and build
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
              child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
                    'Version $_version (Build $_buildNumber)',
                    style: textTheme.bodyMedium,
                  ),
            ),
          ),
          
          // Developer section
          _buildInfoSection(
            context,
            t(context, 'developer'),
            [
              {'title': 'KayfaHaarukku', 'subtitle': null, 'icon': Icons.person_outline},
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Acknowledgements section
          _buildInfoSection(
            context,
            t(context, 'acknowledgements'),
            [
              {
                'title': 'Al-Adhan API',
                'subtitle': t(context, 'prayer_times_data'),
                'icon': Icons.api_outlined
              },
              {
                'title': 'Flutter & Dart',
                'subtitle': t(context, 'framework_and_language'),
                'icon': Icons.code_outlined
              },
              {
                'title': 'Open Source Contributors',
                'subtitle': t(context, 'libraries_and_plugins'),
                'icon': Icons.people_outline
              },
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context, 
    String title, 
    List<Map<String, dynamic>> items
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
        
        // Section items
        ...items.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(item['icon'] as IconData, color: colorScheme.primary),
            title: Text(item['title'] as String),
            subtitle: item['subtitle'] != null ? Text(item['subtitle'] as String) : null,
          ),
        )).toList(),
      ],
    );
  }
} 