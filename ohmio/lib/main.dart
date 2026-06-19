import 'package:flutter/material.dart';

void main() {
  runApp(const OhmioApp());
}

class OhmioApp extends StatelessWidget {
  const OhmioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4FA8B0);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ohmio',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1012),
        cardTheme: const CardThemeData(
          color: Color(0xFF161719),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1C1D20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const CableResistancePage(),
    );
  }
}

class CableResistancePage extends StatefulWidget {
  const CableResistancePage({super.key});

  @override
  State<CableResistancePage> createState() => _CableResistancePageState();
}

class _CableResistancePageState extends State<CableResistancePage> {
  static const List<double> diameters = [0.4, 0.5, 0.6, 0.8, 0.9, 1.2, 1.4];
  static const List<double> tableLengths = [
    0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    30, 40, 50, 60, 70, 80, 90, 100, 200, 300, 400, 500, 600,
    700, 800, 900, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000,
  ];

  static Map<double, double> rPerM = {
    0.4: 0.142,
    0.5: 0.089,
    0.6: 0.062,
    0.8: 0.0355,
    0.9: 0.0276,
    1.2: 0.0156,
    1.4: 0.0115,
  };

  double selectedLength = 100.0;
  double selectedDiameter = 0.8;
  late final TextEditingController lengthController;

  @override
  void initState() {
    super.initState();
    lengthController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    lengthController.dispose();
    super.dispose();
  }

  List<double> decompose(double length) {
    double remainder = ((length * 10).round()) / 10;
    final parts = <double>[];
    final sorted = [...tableLengths]..sort((a, b) => b.compareTo(a));

    for (final item in sorted) {
      while (remainder >= item - 0.00001) {
        parts.add(item);
        remainder = (((remainder - item) * 10).round()) / 10;
      }
      if (remainder < 0.00001) {
        break;
      }
    }
    return parts;
  }

  double resistanceFor(double length, double diameter) {
    return (rPerM[diameter] ?? 0) * length;
  }

  double totalResistance(double length, double diameter) {
    final parts = decompose(length);
    return parts.fold(0.0, (sum, item) => sum + resistanceFor(item, diameter));
  }

  String fmt(double value) {
    if (value == 0) return '0';
    if (value >= 1000) return value.toStringAsFixed(1);
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 10) return value.toStringAsFixed(3);
    if (value >= 1) return value.toStringAsFixed(4);
    if (value >= 0.001) return value.toStringAsPrecision(4);
    return value.toStringAsExponential(3);
  }

  String fmtLength(double value) {
    if (value >= 1) {
      return value == value.roundToDouble()
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(1);
  }

  void onLengthChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return;
    final clamped = parsed.clamp(0.1, 10000.0);
    setState(() {
      selectedLength = ((clamped * 10).round()) / 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = decompose(selectedLength);
    final result = totalResistance(selectedLength, selectedDiameter);
    final perMeter = rPerM[selectedDiameter] ?? 0;
    final maxR = resistanceFor(10000, 0.4);
    final progress = (result / maxR).clamp(0.0, 1.0);

    String formula;
    if (parts.length > 1) {
      final left = parts.map((e) => 'R(${fmtLength(e)}m)').join(' + ');
      final right = parts.map((e) => fmt(resistanceFor(e, selectedDiameter))).join(' + ');
      formula = '$left = $right = ${fmt(result)} Ω';
    } else {
      formula = 'R(${fmtLength(selectedLength)}m) = ${fmt(result)} Ω';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ohmio'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kalkulator omske otpornosti',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unesi dužinu kabela i odaberi prečnik provodnika.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: lengthController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Dužina kabela (m)',
                        hintText: 'npr. 112 ili 24.5',
                        suffixText: 'm',
                      ),
                      onChanged: onLengthChanged,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Slider dužine: ${fmtLength(selectedLength)} m',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      min: 0.1,
                      max: 10000,
                      value: selectedLength.clamp(0.1, 10000),
                      onChanged: (value) {
                        setState(() {
                          selectedLength = ((value * 10).round()) / 10;
                          lengthController.text = fmtLength(selectedLength);
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('0.1 m', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('10 km', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Prečnik provodnika',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: diameters.map((diameter) {
                        final selected = diameter == selectedDiameter;
                        return ChoiceChip(
                          label: Text('$diameter mm'),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              selectedDiameter = diameter;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rezultat',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt(result),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Ω',
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _InfoPill(label: 'Dužina', value: '${fmtLength(selectedLength)} m'),
                        _InfoPill(label: 'Prečnik', value: '$selectedDiameter mm'),
                        _InfoPill(label: 'Otpornost/m', value: '$perMeter Ω/m'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rastavljanje dužine',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: parts
                          .map(
                            (part) => Chip(
                              label: Text('${fmtLength(part)} m'),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formula,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ExpansionTile(
                collapsedBackgroundColor: const Color(0xFF161719),
                backgroundColor: const Color(0xFF161719),
                collapsedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text('Referentna tabela'),
                subtitle: const Text('Prikaži tabelu na zahtjev'),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('m')),
                        ...diameters.map((d) => DataColumn(label: Text('$d'))),
                      ],
                      rows: tableLengths.map((length) {
                        return DataRow(
                          cells: [
                            DataCell(Text(fmtLength(length))),
                            ...diameters.map((d) => DataCell(Text(fmt(resistanceFor(length, d))))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1D20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}