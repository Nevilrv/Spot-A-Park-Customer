import 'package:customer_app/lang/app_ar.dart';
import 'package:customer_app/lang/app_de.dart';
import 'package:customer_app/lang/app_en.dart';
import 'package:customer_app/lang/app_fr.dart';
import 'package:customer_app/lang/app_hi.dart';
import 'package:customer_app/lang/app_ja.dart';
import 'package:customer_app/lang/app_pt.dart';
import 'package:customer_app/lang/app_ru.dart';
import 'package:customer_app/lang/app_zh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  static const locale = Locale('en', 'US');

  static final locales = [
    const Locale('en'),
    const Locale('fr'),
    const Locale('zh'),
    const Locale('ja'),
    const Locale('hi'),
    const Locale('de'),
    const Locale('pt'),
    const Locale('ru'),
    const Locale('ar'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUS,
        'fr': trFR,
        'zh': zhCH,
        'ja': jaJP,
        'hi': hiIN,
        'de': deGR,
        'pt': ptPO,
        'ru': ruRU,
        'ar': lnAr,
      };

  void changeLocale(String lang) {
    Get.updateLocale(Locale(lang));
  }
}
