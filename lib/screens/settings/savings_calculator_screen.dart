import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme.dart';

class SavingsCalculatorScreen extends StatefulWidget {
  const SavingsCalculatorScreen({super.key});

  @override
  State<SavingsCalculatorScreen> createState() =>
      _SavingsCalculatorScreenState();
}

class _SavingsCalculatorScreenState extends State<SavingsCalculatorScreen> {
  final _tankSizeController = TextEditingController(text: '50');
  final _mileageController =
      TextEditingController(text: '15000'); // km per year
  final _consumptionController = TextEditingController(text: '7.0'); // L/100km
  final _priceDiffController =
      TextEditingController(text: '0.10'); // saving per Liter

  double _monthlySavings = 0.0;
  double _yearlySavings = 0.0;
  double _perTankSavings = 0.0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _tankSizeController.dispose();
    _mileageController.dispose();
    _consumptionController.dispose();
    _priceDiffController.dispose();
    super.dispose();
  }

  void _calculate() {
    final tankSize = double.tryParse(_tankSizeController.text) ?? 50;
    final mileage = double.tryParse(_mileageController.text) ?? 15000;
    final consumption = double.tryParse(_consumptionController.text) ?? 7.0;
    final priceDiff = double.tryParse(_priceDiffController.text) ?? 0.10;

    final totalLitersPerYear = (mileage / 100) * consumption;
    final yearly = totalLitersPerYear * priceDiff;

    setState(() {
      _perTankSavings = tankSize * priceDiff;
      _yearlySavings = yearly;
      _monthlySavings = yearly / 12;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Ersparnis-Rechner',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultHeader(),
            const SizedBox(height: 32),
            _sectionTitle('Deine Fahrzeugdaten'),
            const SizedBox(height: 16),
            _buildInput('Tankgröße (Liter)', _tankSizeController, 'L'),
            _buildInput('Verbrauch (L/100km)', _consumptionController, 'L'),
            _buildInput(
                'Jährliche Fahrleistung (km)', _mileageController, 'km'),
            _buildInput(
                'Preisunterschied (pro Liter)', _priceDiffController, '€'),
            const SizedBox(height: 24),
            Text(
              '* Vergleiche den Preis deiner Stammtankstelle mit der günstigsten Option in der App.',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFFB4FC03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Deine Ersparnis pro Tankfüllung',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_perTankSavings.toStringAsFixed(2)} €',
            style: GoogleFonts.outfit(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.black12),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem(
                  'Pro Monat', '${_monthlySavings.toStringAsFixed(2)} €'),
              _summaryItem(
                  'Pro Jahr', '${_yearlySavings.toStringAsFixed(0)} €'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary),
    );
  }

  Widget _buildInput(
      String label, TextEditingController controller, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => _calculate(),
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: GoogleFonts.outfit(color: AppColors.primary),
              filled: true,
              fillColor: AppColors.cardBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
