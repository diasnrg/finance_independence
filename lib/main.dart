import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIRE калькулятор',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FireCalculatorPage(),
    );
  }
}

class FireCalculatorPage extends StatefulWidget {
  const FireCalculatorPage({super.key});

  @override
  State<FireCalculatorPage> createState() => _FireCalculatorPageState();
}

class _FireCalculatorPageState extends State<FireCalculatorPage> {
  final _monthlyExpensesController = TextEditingController();

  double? _monthlyExpenses;

  void _calculate() {
    final expenses = double.tryParse(_monthlyExpensesController.text);

    setState(() {
      _monthlyExpenses = expenses;
    });
  }

  double _calculateTargetAmount(double monthlyExpenses) {
    final yearlyExpenses = monthlyExpenses * 12;
    return yearlyExpenses / 0.04;
  }

  double _calculateMonthlySavings(double targetAmount, int years) {
    return targetAmount / (years * 12);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Калькулятор пенсии FIRE'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InfoCard(),
            const SizedBox(height: 32),
            ExpenseInput(
              controller: _monthlyExpensesController,
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 32),
            if (_monthlyExpenses != null && _monthlyExpenses! > 0) ...[
              TargetAmountCard(
                targetAmount: _calculateTargetAmount(_monthlyExpenses!),
              ),
              const SizedBox(height: 24),
              SavingsTable(
                targetAmount: _calculateTargetAmount(_monthlyExpenses!),
                calculateMonthlySavings: _calculateMonthlySavings,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _monthlyExpensesController.dispose();
    super.dispose();
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Правило 4%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Накопите сумму, равную 25-кратному размеру ваших годовых расходов. '
              'Затем вы сможете снимать 4% в год, и капитал будет восполняться.',
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const ExpenseInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: const InputDecoration(
        labelText: 'Месячные расходы',
        suffixText: '₸',
        border: OutlineInputBorder(),
        helperText: 'Введите ваши текущие месячные расходы',
      ),
    );
  }
}

class TargetAmountCard extends StatelessWidget {
  final double targetAmount;

  const TargetAmountCard({
    super.key,
    required this.targetAmount,
  });

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Icon(
            Icons.stars,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Целевая сумма',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatAmount(targetAmount)} ₸',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsTable extends StatelessWidget {
  final double targetAmount;
  final double Function(double, int) calculateMonthlySavings;

  const SavingsTable({
    super.key,
    required this.targetAmount,
    required this.calculateMonthlySavings,
  });

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'План накопления',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 31,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
            itemBuilder: (context, index) {
              final years = 5 + index;
              final monthlySavings = calculateMonthlySavings(targetAmount, years);
              final isHighlighted = years == 10 || years == 15 || years == 20;

              return Container(
                color: isHighlighted
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$years',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isHighlighted
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                            Text(
                              years == 1 ? 'год' : years < 5 ? 'года' : 'лет',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isHighlighted
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                                    : Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatAmount(monthlySavings)} ₸',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'в месяц',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
