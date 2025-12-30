import 'dart:math';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FIRECalculator(),
    );
  }
}

enum InvestmentType {
  indexFund(name: 'Индексный фонд', returnRate: 0.10),
  dollarDeposit(name: 'Долларовый депозит', returnRate: 0.01);

  final String name;

  final double returnRate;

  const InvestmentType({required this.name, required this.returnRate});
}

class FIRECalculator extends StatefulWidget {
  const FIRECalculator({super.key});

  @override
  State<FIRECalculator> createState() => _FIRECalculatorState();
}

class _NumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    final reversed = digitsOnly.split('').reversed.toList();
    final chunks = <String>[];

    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.sublist(i, end).reversed.join());
    }

    final formatted = chunks.reversed.join(' ');

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _FIRECalculatorState extends State<FIRECalculator>
    with SingleTickerProviderStateMixin {
  static const double _fireMultiplier = 25;
  static const double _inflationRate = 0.03;

  late TabController _tabController;
  InvestmentType _selectedInvestmentType = InvestmentType.indexFund;

  double get _annualReturn => _selectedInvestmentType.returnRate;
  double get _monthlyReturn => _annualReturn / 12;

  static const double _minYears = 1.0;
  static const double _maxYears = 40.0;
  static const double _defaultYears = 20.0;
  static const int _yearsSliderDivisions = 390;

  final _monthlyExpensesController = TextEditingController();

  double _monthlyExpenses = 0;
  double _targetAmount = 0;
  double _targetAmountWithInflation = 0;
  double _yearsToSave = _defaultYears;
  double _monthlySavings = 0;
  bool _isCalculated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: InvestmentType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _monthlyExpensesController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedInvestmentType = InvestmentType.values[_tabController.index];
      _calculateTargetAmount();
    });
  }

  void _calculateTargetAmount() {
    setState(() {
      final cleanText = _monthlyExpensesController.text.replaceAll(' ', '');
      _monthlyExpenses = double.tryParse(cleanText) ?? 0;

      if (_monthlyExpenses == 0) {
        _isCalculated = false;
      }

      _targetAmount = _monthlyExpenses * 12 * _fireMultiplier;
      _targetAmountWithInflation =
          _targetAmount * pow(1 + _inflationRate, _yearsToSave);
      _calculateMonthlySavings();
    });
  }

  void _onCalculatePressed() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isCalculated = true;
    });
  }

  void _calculateMonthlySavings() {
    if (_targetAmountWithInflation == 0) {
      _monthlySavings = 0;
      return;
    }

    final months = _yearsToSave * 12;
    final numerator = _targetAmountWithInflation * _monthlyReturn;
    final denominator = pow(1 + _monthlyReturn, months) - 1;

    _monthlySavings = numerator / denominator;
  }

  String _formatNumber(double number) {
    final numStr = number.toStringAsFixed(0);
    final reversed = numStr.split('').reversed.toList();
    final chunks = <String>[];

    for (var i = 0; i < reversed.length; i += 3) {
      final end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
      chunks.add(reversed.sublist(i, end).reversed.join());
    }

    return chunks.reversed.join(' ');
  }

  void _onYearsChanged(double years) {
    setState(() {
      _yearsToSave = years;
      _targetAmountWithInflation =
          _targetAmount * pow(1 + _inflationRate, _yearsToSave);
      _calculateMonthlySavings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: _monthlyExpenses > 0
      //     ? AppBar(
      //         title: const Text('Калькулятор финансовой независимости'),
      //         // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //       )
      //     : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isCalculated) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                      ),
                      Text(
                        '''
Привет, это калькулятор финансовой свободы.

Оно позволяет посчитать необходимую сумму денег, чтобы человеку больше не было необходимости работать.
        ''',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    _buildMonthlyExpensesInput(),
                    if (_monthlyExpenses > 0 && !_isCalculated) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _onCalculatePressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                          ),
                          child: Text(
                            'Показать сумму',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: _isCalculated
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTargetAmountDisplay(),
                                const SizedBox(height: 16),
                                _buildInvestmentTypeSelector(),
                                const SizedBox(height: 16),
                                _buildContributionBreakdown(),
                                const SizedBox(height: 16),
                                _buildSliders(),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentTypeSelector() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Инструмент накоплений',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: InvestmentType.values
                .map(
                  (type) => Tab(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(type.name, style: const TextStyle(fontSize: 13)),
                        Text(
                          '${(type.returnRate * 100).toStringAsFixed(0)}% годовых',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyExpensesInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _monthlyExpensesController,
            keyboardType: TextInputType.number,
            inputFormatters: [_NumberFormatter()],
            textAlign: TextAlign.center,
            autofocus: true,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(color: Colors.grey.shade300),
              suffix: Text(
                '₸',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            onChanged: (_) => _calculateTargetAmount(),
          ),
        ),
        Text(
          'Введите сумму ежемесячных расходов',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        // const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTargetAmountDisplay() {
    return Column(
      children: [
        Divider(),
        SizedBox(height: 16),
        Text(
          'Cумма необходимая для финансовой свободы:',

          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        '${_formatNumber(_targetAmount)} ₸',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Сумма на сегодня\n',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        '${_formatNumber(_targetAmountWithInflation)} ₸',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onTertiaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'C учетом инфляции \n${(_inflationRate * 100).toStringAsFixed(0)}% в год за ${_yearsToSave.toStringAsFixed(1)} лет',
                        style: Theme.of(context).textTheme.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContributionBreakdown() {
    if (_targetAmountWithInflation == 0 || _monthlySavings == 0) {
      return const SizedBox.shrink();
    }

    final totalContributed = _monthlySavings * _yearsToSave * 12;
    final interestEarned = _targetAmountWithInflation - totalContributed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                // color: Colors.lightBlueAccent,
                margin: const EdgeInsets.only(right: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Ваши вклады',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatNumber(totalContributed)} ₸',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                // color: Colors.lightGreen,
                margin: const EdgeInsets.only(left: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Доход от процентов',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '+${_formatNumber(interestEarned)} ₸',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliders() {
    return Column(
      children: [
        _buildYearsSlider(),
        const SizedBox(height: 24),
        _buildMonthlySavingsChart(),
      ],
    );
  }

  Widget _buildYearsSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Срок накопления',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_yearsToSave.toStringAsFixed(1)} лет',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _yearsToSave,
              min: _minYears,
              max: _maxYears,
              divisions: _yearsSliderDivisions,
              onChanged: _monthlyExpenses > 0 ? _onYearsChanged : null,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMonthlySavingsForYears(double years) {
    if (_targetAmountWithInflation == 0) return 0;

    final targetWithInflation = _targetAmount * pow(1 + _inflationRate, years);
    final months = years * 12;
    final numerator = targetWithInflation * _monthlyReturn;
    final denominator = pow(1 + _monthlyReturn, months) - 1;

    return numerator / denominator;
  }

  Widget _buildMonthlySavingsChart() {
    if (_targetAmount == 0) {
      return const SizedBox.shrink();
    }

    final yearSteps = [5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0];
    final savingsData = yearSteps
        .map(
          (years) => {
            'years': years,
            'savings': _calculateMonthlySavingsForYears(years),
          },
        )
        .toList();

    final maxSavings = savingsData
        .map((data) => data['savings'] as double)
        .reduce((a, b) => a > b ? a : b);

    int closestIndex = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < yearSteps.length; i++) {
      final distance = (_yearsToSave - yearSteps[i]).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ежемесячные вклады:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_formatNumber(_monthlySavings)} ₸',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(savingsData.length, (index) {
                  final data = savingsData[index];
                  final years = data['years'] as double;
                  final savings = data['savings'] as double;
                  final heightRatio = savings / maxSavings;
                  final isSelected = index == closestIndex;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 150 * heightRatio,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${years.toInt()}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                          Text(
                            'лет',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
