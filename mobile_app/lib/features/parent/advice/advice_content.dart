import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Text in the app's languages; falls back to English when a language is
/// not written yet (Sinhala and Tamil come on Day 20).
class LocalText {
  const LocalText(this._byLanguage);
  final Map<String, String> _byLanguage;

  String of(String languageCode) => _byLanguage[languageCode] ?? _byLanguage['en'] ?? '';

  factory LocalText.fromJson(Object? j) => LocalText((j as Map<String, dynamic>).cast<String, String>());
}

enum AdviceKind { feeding, play, safety }

class AdviceCard {
  const AdviceCard(this.kind, this.title, this.body);
  final AdviceKind kind;
  final LocalText title;
  final LocalText body;

  factory AdviceCard.fromJson(Map<String, dynamic> j) => AdviceCard(
      AdviceKind.values.byName(j['kind'] as String), LocalText.fromJson(j['title']), LocalText.fromJson(j['body']));
}

/// Advice for one age band, e.g. 6–12 months (`fromMonths` ≤ age < `toMonths`).
class AdviceGroup {
  const AdviceGroup(this.id, this.fromMonths, this.toMonths, this.label, this.cards);
  final String id;
  final int fromMonths;
  final int toMonths;
  final LocalText label;
  final List<AdviceCard> cards;

  bool covers(int ageMonths) => ageMonths >= fromMonths && ageMonths < toMonths;

  factory AdviceGroup.fromJson(Map<String, dynamic> j) => AdviceGroup(
        j['id'] as String,
        j['fromMonths'] as int,
        j['toMonths'] as int,
        LocalText.fromJson(j['label']),
        [for (final c in j['cards'] as List) AdviceCard.fromJson(c as Map<String, dynamic>)],
      );
}

/// `assets/advice/advice.json`: shipped with the app, so it works offline.
class AdviceContent {
  const AdviceContent(this.groups, this.dangerSigns, this.pregnancyDangerSigns, this.source);

  final List<AdviceGroup> groups;
  final AdviceCard dangerSigns;
  final AdviceCard pregnancyDangerSigns;
  final String source;

  static const assetPath = 'assets/advice/advice.json';

  /// The band for a child's age; the last band after 5 years.
  AdviceGroup groupFor(int ageMonths) => groups.firstWhere((g) => g.covers(ageMonths), orElse: () => groups.last);

  factory AdviceContent.fromJson(Map<String, dynamic> j) {
    AdviceCard sign(String key) {
      final m = j[key] as Map<String, dynamic>;
      return AdviceCard(AdviceKind.safety, LocalText.fromJson(m['title']), LocalText.fromJson(m['body']));
    }

    return AdviceContent(
      [for (final g in j['groups'] as List) AdviceGroup.fromJson(g as Map<String, dynamic>)],
      sign('dangerSigns'),
      sign('pregnancyDangerSigns'),
      j['source'] as String? ?? '',
    );
  }

  static Future<AdviceContent>? _cached;

  /// Tests start each case with a fresh load (a cached future from an
  /// earlier test's fake clock never completes in the next one).
  @visibleForTesting
  static void clearCache() => _cached = null;

  static Future<AdviceContent> load([AssetBundle? bundle]) => _cached ??= () async {
        final text = await (bundle ?? rootBundle).loadString(assetPath);
        return AdviceContent.fromJson(jsonDecode(text) as Map<String, dynamic>);
      }();
}
