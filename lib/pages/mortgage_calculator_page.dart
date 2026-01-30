import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MortgageCalculatorPage extends StatefulWidget {
  const MortgageCalculatorPage({super.key});

  @override
  State<MortgageCalculatorPage> createState() => _MortgageCalculatorPageState();
}

class _MortgageCalculatorPageState extends State<MortgageCalculatorPage> {
  final _priceController = TextEditingController();
  final _downPaymentController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _loanTermController = TextEditingController(text: '30');

  double _monthlyPayment = 0;
  double _totalPayment = 0;
  double _totalInterest = 0;

  @override
  void dispose() {
    _priceController.dispose();
    _downPaymentController.dispose();
    _interestRateController.dispose();
    _loanTermController.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus();
    final price = double.tryParse(_priceController.text) ?? 0;
    final downPayment = double.tryParse(_downPaymentController.text) ?? 0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0;
    final loanTerm = int.tryParse(_loanTermController.text) ?? 30;

    // Validate inputs and show error messages
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid home price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (interestRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid interest rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (downPayment >= price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Down payment must be less than home price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (loanTerm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid loan term'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final principal = price - downPayment;
    final monthlyRate = (interestRate / 100) / 12;
    final numberOfPayments = loanTerm * 12;

    // Calculate monthly payment using mortgage formula
    final monthlyPayment = principal *
        (monthlyRate * pow(1 + monthlyRate, numberOfPayments)) /
        (pow(1 + monthlyRate, numberOfPayments) - 1);

    setState(() {
      _monthlyPayment = monthlyPayment;
      _totalPayment = monthlyPayment * numberOfPayments;
      _totalInterest = _totalPayment - principal;
    });
  }

  double pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Mortgage Calculator'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loan Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Home Price (\$)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _downPaymentController,
                      decoration: InputDecoration(
                        labelText: 'Down Payment (\$)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _interestRateController,
                      decoration: InputDecoration(
                        labelText: 'Interest Rate (%)',
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _loanTermController,
                      decoration: InputDecoration(
                        labelText: 'Loan Term (years)',
                        suffixText: 'years',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _calculate,
                        icon: const Icon(Icons.calculate, size: 20),
                        label: const Text('Calculate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_monthlyPayment > 0) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Results',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                      ),
                      const SizedBox(height: 16),
                      _buildResultRow(
                        'Monthly Payment',
                        '\$${_monthlyPayment.toStringAsFixed(2)}',
                        true,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Total Payment',
                        '\$${_totalPayment.toStringAsFixed(2)}',
                        false,
                      ),
                      const SizedBox(height: 12),
                      _buildResultRow(
                        'Total Interest',
                        '\$${_totalInterest.toStringAsFixed(2)}',
                        false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, bool isHighlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isHighlight
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
