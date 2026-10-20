import 'dart:math';
import 'package:flutter/material.dart';

enum TravelPace { fast, normal, slow }

enum WeatherType { clear, heavyRain, tropicalStorm, extremeHeat }

class HexNavigationWidget extends StatefulWidget {
  final Function(int rations, int water) onResourceUpdate;

  const HexNavigationWidget({super.key, required this.onResourceUpdate});

  @override
  State<HexNavigationWidget> createState() => _HexNavigationWidgetState();
}

class _HexNavigationWidgetState extends State<HexNavigationWidget> {
  final Random _rng = Random();

  // Налаштування навігації
  TravelPace _selectedPace = TravelPace.normal;
  int _survivalBonus = 5;
  int _targetDc = 15;

  // Поточний стан
  bool _isLost = false;
  String _navigationLog =
      'Оберіть параметри та здійсніть перевірку орієнтування.';
  WeatherType _currentWeather = WeatherType.clear;

  void _rollWeather() {
    int roll = _rng.nextInt(100) + 1;
    WeatherType newWeather;

    if (roll <= 60) {
      newWeather = WeatherType.clear;
    } else if (roll <= 85) {
      newWeather = WeatherType.heavyRain;
    } else if (roll <= 95) {
      newWeather = WeatherType.extremeHeat;
    } else {
      newWeather = WeatherType.tropicalStorm;
    }

    setState(() {
      _currentWeather = newWeather;
    });
  }

  void _performDailyNavigation() {
    _rollWeather();

    int d20 = _rng.nextInt(20) + 1;

    int paceModifier = 0;
    if (_selectedPace == TravelPace.fast) paceModifier = -5;
    if (_selectedPace == TravelPace.slow) paceModifier = 5;

    int totalRoll = d20 + _survivalBonus + paceModifier;
    bool success = totalRoll >= _targetDc;

    int waterCost = 2;
    int rationCost = 1;

    if (_currentWeather == WeatherType.extremeHeat) {
      waterCost = 4;
    }

    setState(() {
      _isLost = !success;

      String weatherText = _getWeatherTitle(_currentWeather);

      _navigationLog =
          '''
🎲 Кидок Навігації: $d20 + $_survivalBonus (модифікатор темпу: $paceModifier) = $totalRoll (Складність DC $_targetDc)
Результат: ${success ? 'УСПІХ! Загін тримає курс.' : 'ПРОВАЛ! Загін заблукав у гексі.'}

🌤 Погода: $weatherText
💧 Споживання ресурсів за день: -$waterCost гал. води, -$rationCost раціон.
''';
    });

    widget.onResourceUpdate(rationCost, waterCost);
  }

  String _getWeatherTitle(WeatherType weather) {
    switch (weather) {
      case WeatherType.clear:
        return 'Спекотно та сонячно (Звичайна погода)';
      case WeatherType.heavyRain:
        return 'Тропічна злива (Знижена видимість)';
      case WeatherType.extremeHeat:
        return 'Аномальна спека (Подвійне споживання води!)';
      case WeatherType.tropicalStorm:
        return 'Тропічний шторм (Пересування ускладнене)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF252525),
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compass_calibration, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Навігатор Джунглів',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isLost
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _isLost ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Text(
                    _isLost ? 'СТАТУС: ЗАБЛУКАЛИ' : 'СТАТУС: КУРС ВІРНИЙ',
                    style: TextStyle(
                      color: _isLost ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Бонус Навігатора (Survival):',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 38,
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(
                            text: '$_survivalBonus',
                          ),
                          onChanged: (val) =>
                              _survivalBonus = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Складність (DC):',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      DropdownButton<int>(
                        value: _targetDc,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2A2A2A),
                        items: const [
                          DropdownMenuItem(
                            value: 10,
                            child: Text(
                              'DC 10 (Річка / Стежка)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text(
                              'DC 15 (Дикі джунглі)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 20,
                            child: Text(
                              'DC 20 (Болота / Туман)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _targetDc = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            const Text(
              'Темп пересування:',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: TravelPace.values.map((pace) {
                String label = pace == TravelPace.fast
                    ? 'Швидкий'
                    : (pace == TravelPace.slow ? 'Повільний' : 'Звичайний');
                return ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 11)),
                  selected: _selectedPace == pace,
                  selectedColor: Colors.amber,
                  labelStyle: TextStyle(
                    color: _selectedPace == pace ? Colors.black : Colors.white,
                  ),
                  onSelected: (sel) {
                    if (sel) setState(() => _selectedPace = pace);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                minimumSize: const Size.fromHeight(38),
              ),
              icon: const Icon(Icons.explore, color: Colors.black, size: 18),
              label: const Text(
                'Розрахувати навігацію та погоду',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _performDailyNavigation,
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _navigationLog,
                style: const TextStyle(fontSize: 11, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
