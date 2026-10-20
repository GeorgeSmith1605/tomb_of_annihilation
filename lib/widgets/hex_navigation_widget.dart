import 'dart:math';
import 'package:flutter/material.dart';

enum TravelPace { fast, normal, slow }
enum WeatherType { clear, heavyRain, tropicalStorm, extremeHeat }

class HexNavigationWidget extends StatefulWidget {
  final Function(int rations, int water) OnResourceUpdate;

  Const HexNavigationWidget({
    Super.key,
    Required this.onResourceUpdate,
  });

  @override
  State<HexNavigationWidget> createState() => _HexNavigationWidgetState();
}

Class _HexNavigationWidgetState extends State<HexNavigationWidget> {
  Final Random _rng = Random();

  // Налаштування навігації
  TravelPace _selectedPace = TravelPace.normal;
  Int _survivalBonus = 5; // Модифікується користувачем (Wisdom + Survival)
  Int _targetDc = 15; // Складність навігації (зазвичай 10 або 15 в джунглях)
  
  // Поточний стан
  Bool _isLost = false;
  String _navigationLog = 'Оберіть параметри та здійсніть перевірку орієнтування.';
  WeatherType _currentWeather = WeatherType.clear;

  Void _rollWeather() {
    Int roll = _rng.nextInt(100) + 1;
    WeatherType newWeather;

    If (roll <= 60) {
      NewWeather = WeatherType.clear;
    } else if (roll <= 85) {
      NewWeather = WeatherType.heavyRain;
    } else if (roll <= 95) {
      NewWeather = WeatherType.extremeHeat;
    } else {
      NewWeather = WeatherType.tropicalStorm;
    }

    SetState(() {
      _currentWeather = newWeather;
    });
  }

  Void _performDailyNavigation() {
    _rollWeather();

    Int d20 = _rng.nextInt(20) + 1;
    
    // Модифікатор темпу
    Int paceModifier = 0;
    If (_selectedPace == TravelPace.fast) paceModifier = -5; // Помеха / штраф
    If (_selectedPace == TravelPace.slow) paceModifier = 5;  // Преимущество / бонус

    Int totalRoll = d20 + _survivalBonus + paceModifier;
    Bool success = totalRoll >= _targetDc;

    Int waterCost = 2; // Базове споживання води на день
    Int rationCost = 1; // Базове споживання їжі

    If (_currentWeather == WeatherType.extremeHeat) {
      WaterCost = 4; // При сильній спеці подвійне споживання води[cite: 8]
    }

    SetState(() {
      _isLost = !success;
      
      String paceText = _selectedPace == TravelPace.fast 
          ? 'Швидкий (Штраф -5)' 
          : (_selectedPace == TravelPace.slow ? 'Повільний (Бонус +5)' : 'Звичайний');

      String weatherText = _getWeatherTitle(_currentWeather);

      _navigationLog = '''
🎲 Кидок Навігації: $d20 + $_survivalBonus (модифікував темп: $paceModifier) = $totalRoll (Складність DC $_targetDc)
Результат: ${success ? 'УСПІХ! Загін тримає курс.' : 'ПРОВАЛ! Загін заблукав у гексі.'}

🌤 Погода: $weatherText
💧 Споживання ресурсів за день: -$waterCost гал. Води, -$rationCost раціон.
''';
    });

    Widget.onResourceUpdate(rationCost, waterCost);
  }

  String _getWeatherTitle(WeatherType weather) {
    Switch (weather) {
      Case WeatherType.clear:
        Return 'Спекотно та сонячно (Звичайна погода)';
      Case WeatherType.heavyRain:
        Return 'Тропічна злива (Знижена видимість)';
      Case WeatherType.extremeHeat:
        Return 'Аномальна спека (Подвійне споживання води!)';
      Case WeatherType.tropicalStorm:
        Return 'Тропічний шторм (Пересування ускладнене)';
    }
  }

  @override
  Widget build(BuildContext context) {
    Return Card(
      Color: const Color(0xFF252525),
      Margin: const EdgeInsets.all(8.0),
      Child: Padding(
        Padding: const EdgeInsets.all(12.0),
        Child: Column(
          CrossAxisAlignment: CrossAxisAlignment.start,
          Children: [
            Row(
              Children: [
                Const Icon(Icons.compass_calibration, color: Colors.amber),
                Const SizedBox(width: 8),
                Text(
                  'Навігатор Джунглів',
                  Style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Const Spacer(),
                Container(
                  Padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  Decoration: BoxDecoration(
                    Color: _isLost ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                    BorderRadius: BorderRadius.circular(4),
                    Border: Border.all(color: _isLost ? Colors.red : Colors.green),
                  ),
                  Child: Text(
                    _isLost ? 'СТАТУС: ЗАБЛУКАЛИ' : 'СТАТУС: КУРС ВІРНИЙ',
                    Style: TextStyle(
                      Color: _isLost ? Colors.redAccent : Colors.greenAccent,
                      FontWeight: FontWeight.bold,
                      FontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            Const Divider(color: Colors.white24, height: 20),
            
            // Налаштування
            Row(
              Children: [
                Expanded(
                  Child: Column(
                    CrossAxisAlignment: CrossAxisAlignment.start,
                    Children: [
                      Const Text('Бонус Навігатора (Survival):', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      SizedBox(
                        Height: 35,
                        Child: TextField(
                          Decoration: InputDecoration(
                            Filled: true,
                            FillColor: const Color(0xFF1A1A1A),
                            Border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            ContentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          KeyboardType: TextInputType.number,
                          Controller: TextEditingController(text: '$_survivalBonus'),
                          OnChanged: (val) => _survivalBonus = int.tryParse(val) ?? 0,
                        ),
                      ),
                    ],
                  ),
                ),
                Const SizedBox(width: 12),
                Expanded(
                  Child: Column(
                    CrossAxisAlignment: CrossAxisAlignment.start,
                    Children: [
                      Const Text('Складність (DC):', style: TextStyle(fontSize: 11, color: Colors.white70)),
                      DropdownButton<int>(
                        Value: _targetDc,
                        IsExpanded: true,
                        DropdownColor: const Color(0xFF2A2A2A),
                        Items: const [
                          DropdownMenuItem(value: 10, child: Text('DC 10 (Річка / Стежка)')),
                          DropdownMenuItem(value: 15, child: Text('DC 15 (Дикі джунглі)')),
                          DropdownMenuItem(value: 20, child: Text('DC 20 (Болота / Туман)')),
                        ],
                        OnChanged: (val) {
                          If (val != null) setState(() => _targetDc = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Const SizedBox(height: 8),
            
            // Темп руху
            Const Text('Темп пересування:', style: TextStyle(fontSize: 11, color: Colors.white70)),
            Row(
              MainAxisAlignment: MainAxisAlignment.spaceAround,
              Children: TravelPace.values.map((pace) {
                String label = pace == TravelPace.fast ? 'Швидкий' : (pace == TravelPace.slow ? 'Повільний' : 'Звичайний');
                Return ChoiceChip(
                  Label: Text(label, style: const TextStyle(fontSize: 11)),
                  Selected: _selectedPace == pace,
                  SelectedColor: Colors.amber,
                  LabelStyle: TextStyle(color: _selectedPace == pace ? Colors.black : Colors.white),
                  OnSelected: (sel) {
                    If (sel) setState(() => _selectedPace = pace);
                  },
                );
              }).toList(),
            ),
            Const SizedBox(height: 12),
            
            ElevatedButton.icon(
              Style: ElevatedButton.styleFrom(
                BackgroundColor: Colors.amber.shade700,
                MinimumSize: const Size.fromHeight(38),
              ),
              Icon: const Icon(Icons.explore, color: Colors.black, size: 18),
              Label: const Text('Розрахувати навігацію та погоду', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              OnPressed: _performDailyNavigation,
            ),
            Const SizedBox(height: 10),
            
            // Лог
            Container(
              Width: double.infinity,
              Padding: const EdgeInsets.all(8),
              Decoration: BoxDecoration(
                Color: const Color(0xFF151515),
                BorderRadius: BorderRadius.circular(6),
                Border: Border.all(color: Colors.white12),
              ),
              Child: Text(
                _navigationLog,
                Style: const TextStyle(fontSize: 11, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}