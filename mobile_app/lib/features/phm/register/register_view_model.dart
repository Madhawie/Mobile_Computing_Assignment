import 'package:material_ui/material_ui.dart';

import '../../../data/models/models.dart';
import '../../../data/repositories/app_repositories.dart';

enum RegisterTab { mothers, children }

/// One mother in the list, with how many children she has.
class MotherRow {
  const MotherRow(this.mother, this.childCount);
  final Mother mother;
  final int childCount;
}

/// One child in the list, with the mother's name for the second line.
class ChildRow {
  const ChildRow(this.child, this.mother);
  final Child child;
  final Mother mother;
}

/// M2 · Area register: every mother and child in the PHM's area, from the
/// phone's database. Search filters on the phone, so it works offline.
class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this.repos, {required this.areaId, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AppRepositories repos;
  final String areaId;
  final DateTime Function() _clock;

  bool loading = true;
  Object? error;
  RegisterTab tab = RegisterTab.mothers;
  String query = '';
  DateTime today = DateTime.now();

  List<MotherRow> _mothers = const [];
  List<ChildRow> _children = const [];

  bool get isEmpty => _mothers.isEmpty;

  /// Mothers whose name or phone contains [query] (any case, spaces ignored).
  List<MotherRow> get mothers => _mothers.where((r) => _matches(r.mother.fullName, r.mother.phone)).toList();

  /// Children whose own or mother's name, or the mother's phone, matches.
  List<ChildRow> get children => _children
      .where((r) => _matches(r.child.name, r.mother.phone) || _matches(r.mother.fullName, ''))
      .toList();

  bool _matches(String name, String phone) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return name.toLowerCase().contains(q) ||
        (digits.length >= 3 && phone.replaceAll(RegExp(r'\D'), '').contains(digits.replaceFirst(RegExp('^0'), '')));
  }

  void setTab(RegisterTab value) {
    tab = value;
    notifyListeners();
  }

  void search(String text) {
    query = text;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      today = _clock();
      final mothers = <MotherRow>[];
      final children = <ChildRow>[];
      for (final m in await repos.mothers.inArea(areaId)) {
        final kids = await repos.children.forMother(m.id);
        mothers.add(MotherRow(m, kids.length));
        children.addAll(kids.map((c) => ChildRow(c, m)));
      }
      children.sort((a, b) => a.child.name.toLowerCase().compareTo(b.child.name.toLowerCase()));
      _mothers = mothers;
      _children = children;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
