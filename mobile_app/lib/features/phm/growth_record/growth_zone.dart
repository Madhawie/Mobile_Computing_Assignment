import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../../../data/models/models.dart';

/// CHDR weight-for-age zones, from the WHO z-score:
/// red below −3, orange −3 to −2, green −2 to +2, above green over +2.
enum GrowthZone { severe, moderate, normal, overweight }

GrowthZone zoneFor(double z) => z < -3
    ? GrowthZone.severe
    : z < -2
        ? GrowthZone.moderate
        : z > 2
            ? GrowthZone.overweight
            : GrowthZone.normal;

/// One row of the WHO LMS table: Box-Cox power [l], median [m] and
/// coefficient of variation [s] for one sex and one age in days.
class Lms {
  const Lms(this.l, this.m, this.s);
  final double l, m, s;

  /// WHO LMS z-score: z = ((x / M)^L − 1) / (L·S), or ln(x / M) / S if L = 0.
  ///
  /// WHO adjusts z for weight beyond ±3 SD; that changes how far past −3 a
  /// child is, not which zone, so the plain formula is enough for zones.
  double zScore(double x) =>
      l == 0 ? math.log(x / m) / s : (math.pow(x / m, l) - 1) / (l * s);
}

/// Weight-for-age reference: LMS for each sex and age in days (0 … 1856).
class GrowthReference {
  GrowthReference({required this.boys, required this.girls, required this.source});

  final List<Lms> boys;
  final List<Lms> girls;

  /// Where the numbers came from (shown in tests and the README).
  final String source;

  /// Asset made by `tool/make_wfa_table.py` from WHO's weianthro.txt.
  static const assetPath = 'assets/growth/wfa_lms.json';

  Lms? lms(Sex sex, int ageDays) {
    final table = sex == Sex.boy ? boys : girls;
    return ageDays < 0 || ageDays >= table.length ? null : table[ageDays];
  }

  /// Z-score for a weight, or null if the age is outside the table.
  double? weightForAgeZ(Sex sex, DateTime dob, DateTime measuredOn, double weightKg) {
    final ageDays = DateTime(measuredOn.year, measuredOn.month, measuredOn.day)
        .difference(DateTime(dob.year, dob.month, dob.day))
        .inDays;
    return lms(sex, ageDays)?.zScore(weightKg);
  }

  factory GrowthReference.fromJson(Map<String, dynamic> j) {
    List<Lms> rows(String key) =>
        (j[key] as List).map((r) => Lms((r[0] as num).toDouble(), (r[1] as num).toDouble(), (r[2] as num).toDouble())).toList();
    return GrowthReference(boys: rows('boy'), girls: rows('girl'), source: j['source'] as String? ?? '');
  }

  static Future<GrowthReference?>? _cached;

  /// Loads the WHO table once. Returns null when the file is not in the app
  /// yet: the growth form then saves the weight but shows no zone.
  static Future<GrowthReference?> load([AssetBundle? bundle]) => _cached ??= () async {
        try {
          final text = await (bundle ?? rootBundle).loadString(assetPath);
          return GrowthReference.fromJson(jsonDecode(text) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }();
}
