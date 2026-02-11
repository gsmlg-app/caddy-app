import 'dart:math' as math;

import 'package:app_chart/app_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── ChartDataPoint ──────────────────────────────────────────────────

  group('ChartDataPoint', () {
    test('stores x, y values', () {
      const p = ChartDataPoint(1.0, 2.5);
      expect(p.x, 1.0);
      expect(p.y, 2.5);
      expect(p.label, isNull);
    });

    test('stores optional label', () {
      const p = ChartDataPoint(0, 10, label: 'Peak');
      expect(p.label, 'Peak');
    });
  });

  // ── CategoryDataPoint ───────────────────────────────────────────────

  group('CategoryDataPoint', () {
    test('stores label and value', () {
      const d = CategoryDataPoint(label: 'Sales', value: 100);
      expect(d.label, 'Sales');
      expect(d.value, 100);
      expect(d.color, isNull);
    });

    test('stores optional color', () {
      const d = CategoryDataPoint(label: 'X', value: 42, color: Colors.red);
      expect(d.color, Colors.red);
    });
  });

  // ── defaultChartColors ──────────────────────────────────────────────

  group('defaultChartColors', () {
    test('has 8 colors', () {
      expect(defaultChartColors, hasLength(8));
    });

    test('all entries are Color', () {
      for (final c in defaultChartColors) {
        expect(c, isA<Color>());
      }
    });
  });

  // ── SimpleLineChart ─────────────────────────────────────────────────

  group('SimpleLineChart', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        home: Scaffold(body: SizedBox(width: 300, height: 200, child: child)),
      );
    }

    final sampleData = [
      const ChartDataPoint(0, 10),
      const ChartDataPoint(1, 20),
      const ChartDataPoint(2, 15),
    ];

    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(wrap(SimpleLineChart(data: sampleData)));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with empty data', (tester) async {
      await tester.pumpWidget(wrap(const SimpleLineChart(data: [])));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts custom lineColor', (tester) async {
      await tester.pumpWidget(
        wrap(SimpleLineChart(data: sampleData, lineColor: Colors.red)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts all configuration options', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleLineChart(
            data: sampleData,
            strokeWidth: 3.0,
            showPoints: false,
            pointRadius: 6.0,
            fillArea: true,
            fillColor: Colors.blue.withValues(alpha: 0.3),
            smooth: false,
            padding: const EdgeInsets.all(16),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('has correct default values', () {
      final chart = SimpleLineChart(data: sampleData);
      expect(chart.strokeWidth, 2.0);
      expect(chart.showPoints, true);
      expect(chart.pointRadius, 4.0);
      expect(chart.fillArea, false);
      expect(chart.fillColor, isNull);
      expect(chart.smooth, true);
      expect(chart.padding, const EdgeInsets.all(24));
      expect(chart.lineColor, isNull);
    });

    testWidgets('renders with single data point', (tester) async {
      await tester.pumpWidget(
        wrap(const SimpleLineChart(data: [ChartDataPoint(0, 5)])),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with fillArea enabled', (tester) async {
      await tester.pumpWidget(
        wrap(SimpleLineChart(data: sampleData, fillArea: true)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with smooth disabled', (tester) async {
      await tester.pumpWidget(
        wrap(SimpleLineChart(data: sampleData, smooth: false)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  // ── SimpleBarChart ──────────────────────────────────────────────────

  group('SimpleBarChart', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        home: Scaffold(body: SizedBox(width: 300, height: 200, child: child)),
      );
    }

    final sampleData = [
      const CategoryDataPoint(label: 'A', value: 30),
      const CategoryDataPoint(label: 'B', value: 50),
      const CategoryDataPoint(label: 'C', value: 20),
    ];

    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(wrap(SimpleBarChart(data: sampleData)));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with empty data', (tester) async {
      await tester.pumpWidget(wrap(const SimpleBarChart(data: [])));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders horizontal bars', (tester) async {
      await tester.pumpWidget(
        wrap(SimpleBarChart(data: sampleData, horizontal: true)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleBarChart(
            data: sampleData,
            colors: const [Colors.red, Colors.green, Colors.blue],
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts all configuration options', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleBarChart(
            data: sampleData,
            barPadding: 0.3,
            borderRadius: 8.0,
            horizontal: true,
            showLabels: false,
            labelStyle: const TextStyle(fontSize: 14),
            padding: const EdgeInsets.all(16),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('has correct default values', () {
      final chart = SimpleBarChart(data: sampleData);
      expect(chart.barPadding, 0.2);
      expect(chart.borderRadius, 4.0);
      expect(chart.horizontal, false);
      expect(chart.showLabels, true);
      expect(chart.labelStyle, isNull);
      expect(chart.colors, isNull);
      expect(chart.padding, const EdgeInsets.all(24));
    });

    testWidgets('renders with labels hidden', (tester) async {
      await tester.pumpWidget(
        wrap(SimpleBarChart(data: sampleData, showLabels: false)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with per-item colors', (tester) async {
      final data = [
        const CategoryDataPoint(label: 'A', value: 30, color: Colors.red),
        const CategoryDataPoint(label: 'B', value: 50, color: Colors.green),
      ];
      await tester.pumpWidget(wrap(SimpleBarChart(data: data)));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  // ── SimplePieChart ──────────────────────────────────────────────────

  group('SimplePieChart', () {
    Widget wrap(Widget child) {
      return MaterialApp(
        home: Scaffold(body: SizedBox(width: 300, height: 300, child: child)),
      );
    }

    final sampleData = [
      const CategoryDataPoint(label: 'X', value: 40),
      const CategoryDataPoint(label: 'Y', value: 35),
      const CategoryDataPoint(label: 'Z', value: 25),
    ];

    testWidgets('renders CustomPaint', (tester) async {
      await tester.pumpWidget(wrap(SimplePieChart(data: sampleData)));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with empty data', (tester) async {
      await tester.pumpWidget(wrap(const SimplePieChart(data: [])));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders donut chart', (tester) async {
      await tester.pumpWidget(
        wrap(SimplePieChart(data: sampleData, innerRadiusRatio: 0.5)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom colors', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimplePieChart(
            data: sampleData,
            colors: const [Colors.orange, Colors.teal, Colors.pink],
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts all configuration options', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimplePieChart(
            data: sampleData,
            innerRadiusRatio: 0.6,
            startAngle: 0,
            showLabels: false,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
            padding: const EdgeInsets.all(8),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    test('has correct default values', () {
      final chart = SimplePieChart(data: sampleData);
      expect(chart.innerRadiusRatio, 0.0);
      expect(chart.startAngle, -math.pi / 2);
      expect(chart.showLabels, true);
      expect(chart.labelStyle, isNull);
      expect(chart.colors, isNull);
      expect(chart.padding, const EdgeInsets.all(24));
    });

    testWidgets('renders with labels hidden', (tester) async {
      await tester.pumpWidget(
        wrap(SimplePieChart(data: sampleData, showLabels: false)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with per-item colors', (tester) async {
      final data = [
        const CategoryDataPoint(label: 'A', value: 60, color: Colors.amber),
        const CategoryDataPoint(label: 'B', value: 40, color: Colors.cyan),
      ];
      await tester.pumpWidget(wrap(SimplePieChart(data: data)));
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom start angle', (tester) async {
      await tester.pumpWidget(
        wrap(SimplePieChart(data: sampleData, startAngle: math.pi)),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
