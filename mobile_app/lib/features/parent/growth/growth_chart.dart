import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../phm/growth_record/growth_zone.dart';

/// One weight on the chart: age in days and kg.
typedef GrowthPoint = ({int days, double kg});

/// The CHDR weight-for-age chart: WHO zone bands (red below −3, orange −3 to
/// −2, green −2 to +2, light above +2) and the child's own weights as a
/// line, blue for boys and pink for girls.
///
/// Drawn with a CustomPainter instead of a chart package: the bands are just
/// the WHO LMS formula turned round ([Lms.valueAt]) for z = −3, −2 and +2 at
/// each age, so there is nothing hidden in a library.
class GrowthChart extends StatelessWidget {
  const GrowthChart({
    super.key,
    required this.sex,
    required this.dob,
    required this.measurements,
    required this.reference,
    required this.today,
    required this.semanticLabel,
  });

  final Sex sex;
  final DateTime dob;
  final List<GrowthMeasurement> measurements;

  /// Null when the WHO table is missing: only the child's line is drawn.
  final GrowthReference? reference;
  final DateTime today;
  final String semanticLabel;

  static int ageDays(DateTime dob, DateTime d) =>
      DateTime(d.year, d.month, d.day).difference(DateTime(dob.year, dob.month, dob.day)).inDays;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final m in measurements.where((m) => !m.deleted)) (days: ageDays(dob, m.measuredOn), kg: m.weightKg)
    ]..sort((a, b) => a.days.compareTo(b.days));
    final lastDay = math.max(points.lastOrNull?.days ?? 0, ageDays(dob, today));
    // Show the child's life so far plus 2 months, at least 6 months, at most 5 years.
    final maxDays = ((lastDay + 60) / 30).ceil().clamp(6, 61) * 30;
    return Semantics(
      label: semanticLabel,
      child: AspectRatio(
        aspectRatio: 1.35,
        child: CustomPaint(
          painter: GrowthChartPainter(
            points: points,
            lms: reference == null ? null : (day) => reference!.lms(sex, day),
            maxDays: math.min(maxDays, 1826),
            lineColor: sex == Sex.boy ? AppColors.boyAccent : AppColors.girlAccent,
            labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 10),
          ),
        ),
      ),
    );
  }
}

class GrowthChartPainter extends CustomPainter {
  GrowthChartPainter({
    required this.points,
    required this.lms,
    required this.maxDays,
    required this.lineColor,
    required this.labelStyle,
  });

  final List<GrowthPoint> points;
  final Lms? Function(int day)? lms;
  final int maxDays;
  final Color lineColor;
  final TextStyle labelStyle;

  static const _left = 30.0, _bottom = 18.0, _top = 6.0, _right = 6.0;

  /// The kg of z-score [z] at each sampled day (the band edges).
  List<Offset> _line(double z, double Function(int) x, double Function(double) y, int step) => [
        for (var d = 0; d <= maxDays; d += step)
          if (lms!(math.min(d, maxDays)) case final r?) Offset(x(d), y(r.valueAt(z)))
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_left, _top, size.width - _right, size.height - _bottom);

    // Kg range: the WHO −3 line at the start to the +2 line at the end, and
    // every point of the child.
    final kgs = [
      for (final p in points) p.kg,
      if (lms?.call(0) case final r?) r.valueAt(-3),
      if (lms?.call(maxDays) case final r?) r.valueAt(2.5),
    ];
    final lo = kgs.isEmpty ? 0.0 : (kgs.reduce(math.min) - 0.5).floorToDouble().clamp(0.0, 100.0);
    final hi = kgs.isEmpty ? 10.0 : (kgs.reduce(math.max) + 0.5).ceilToDouble();
    double x(int d) => plot.left + d / maxDays * plot.width;
    double y(double kg) => plot.bottom - (kg - lo) / (hi - lo) * plot.height;

    canvas.save();
    canvas.clipRect(plot);
    if (lms != null) {
      final step = math.max(1, maxDays ~/ 80);
      final m3 = _line(-3, x, y, step), m2 = _line(-2, x, y, step), p2 = _line(2, x, y, step);
      final bottom = [for (final o in m3) Offset(o.dx, plot.bottom)];
      final top = [for (final o in p2) Offset(o.dx, plot.top)];
      _band(canvas, m3, bottom, AppColors.dangerLight);
      _band(canvas, m2, m3, AppColors.warnLight);
      _band(canvas, p2, m2, AppColors.goodLight);
      _band(canvas, top, p2, AppColors.background);
    }
    canvas.restore();

    // Grid and labels.
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final kgStep = _niceStep(hi - lo);
    for (var kg = lo; kg <= hi; kg += kgStep) {
      canvas.drawLine(Offset(plot.left, y(kg)), Offset(plot.right, y(kg)), grid);
      _label(canvas, kg.toStringAsFixed(0), Offset(plot.left - 4, y(kg)), alignRight: true);
    }
    final monthStep = maxDays <= 400 ? 3 : maxDays <= 800 ? 6 : 12;
    for (var mo = 0; mo * 30.4375 <= maxDays; mo += monthStep) {
      final dx = x((mo * 30.4375).round());
      canvas.drawLine(Offset(dx, plot.bottom), Offset(dx, plot.bottom + 3), grid);
      _label(canvas, mo < 24 || mo % 12 != 0 ? '${mo}m' : '${mo ~/ 12}y', Offset(dx, plot.bottom + 9), center: true);
    }
    canvas.drawRect(plot, grid..style = PaintingStyle.stroke);

    // The child's weights.
    if (points.isEmpty) return;
    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(x(points.first.days), y(points.first.kg));
    for (final p in points.skip(1)) {
      path.lineTo(x(p.days), y(p.kg));
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = lineColor;
    for (final p in points) {
      canvas.drawCircle(Offset(x(p.days), y(p.kg)), 3.5, dot);
      canvas.drawCircle(Offset(x(p.days), y(p.kg)), 1.5, Paint()..color = AppColors.surface);
    }
  }

  /// Fills the area between an upper and a lower line.
  static void _band(Canvas canvas, List<Offset> upper, List<Offset> lower, Color color) {
    if (upper.length < 2 || lower.length < 2) return;
    final path = Path()..addPolygon([...upper, ...lower.reversed], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  /// 1, 2 or 5 kg between grid lines, so there are at most 7 lines.
  static double _niceStep(double range) {
    for (final s in [1.0, 2.0, 5.0, 10.0]) {
      if (range / s <= 7) return s;
    }
    return 20;
  }

  void _label(Canvas canvas, String text, Offset at, {bool alignRight = false, bool center = false}) {
    final tp = TextPainter(text: TextSpan(text: text, style: labelStyle), textDirection: TextDirection.ltr)..layout();
    final dx = alignRight ? at.dx - tp.width : center ? at.dx - tp.width / 2 : at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(GrowthChartPainter old) =>
      old.points != points || old.maxDays != maxDays || old.lineColor != lineColor;
}
