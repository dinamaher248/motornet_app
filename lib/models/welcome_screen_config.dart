class WelcomeScreenConfig {
  final bool enabled;
  final String title;
  final String message;
  final List<String> features;
  final String buttonText;

  const WelcomeScreenConfig({
    required this.enabled,
    required this.title,
    required this.message,
    required this.features,
    required this.buttonText,
  });

  factory WelcomeScreenConfig.defaults() {
    return const WelcomeScreenConfig(
      enabled: true,
      title: '🎉 مرحبًا بك في توصيلة برو',
      message:
          'أنت الآن من أوائل مستخدمي توصيلة برو.\n'
          'نعمل حاليًا على تطوير التطبيق وإضافة المزيد من السائقين وأصحاب الأنشطة لتقديم أفضل تجربة ممكنة.',
      features: [
        'إنشاء حساب مجاني بالكامل.',
        'لا توجد أي رسوم أو عمولات خلال الفترة التجريبية.',
        'استخدام جميع خدمات التطبيق مجانًا.',
        'يمكنك إرسال اقتراحاتك وملاحظاتك للمساهمة في تطوير التطبيق.',
        'يتم إضافة خدمات ومزايا جديدة بشكل مستمر.',
      ],
      buttonText: 'ابدأ الآن',
    );
  }

  factory WelcomeScreenConfig.fromJson(Map<String, dynamic> json) {
    final defaults = WelcomeScreenConfig.defaults();
    final rawFeatures = json['features'];

    return WelcomeScreenConfig(
      enabled: json['enabled'] == true || json['enabled'] == 1 || json['enabled'] == '1',
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : defaults.title,
      message: json['message']?.toString().trim().isNotEmpty == true
          ? json['message'].toString()
          : defaults.message,
      features: rawFeatures is List
          ? rawFeatures.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
          : defaults.features,
      buttonText: json['button_text']?.toString().trim().isNotEmpty == true
          ? json['button_text'].toString()
          : defaults.buttonText,
    );
  }
}
