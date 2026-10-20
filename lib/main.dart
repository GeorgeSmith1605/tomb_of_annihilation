import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/chult_map_widget.dart';

void main() {
  runApp(const ToaDMCompanionApp());
}

class ToaDMCompanionApp extends StatelessWidget {
  const ToaDMCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomb of Annihilation DM Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardColor: const Color(0xFF2A2A2A),
      ),
      home: const MainDMDesktopScreen(),
    );
  }
}

class MainDMDesktopScreen extends StatefulWidget {
  const MainDMDesktopScreen({super.key});

  @override
  State<MainDMDesktopScreen> createState() => _MainDMDesktopScreenState();
}

class _MainDMDesktopScreenState extends State<MainDMDesktopScreen> {
  // Список локацій та стан карти
  List<dynamic> _locations = [];
  dynamic _selectedLocation;
  String _searchQuery = '';
  int _currentDay = 1;
  bool _showMap = false;

  // Подорож та зустрічі
  Map<String, dynamic> _encounterTables = {};
  String _selectedBiome = 'jungle_normal';
  String _lastEncounterResult =
      'Натисніть "Провести день" або "Кидок зустрічі"';
  int _rationsLeft = 20;
  int _waterGallonsLeft = 30;

  @override
  void initState() {
    super.initState();
    _loadLocations();
    _loadEncounters();
  }

  Future<void> _loadLocations() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/locations.json',
      );
      final data = await json.decode(response);
      setState(() {
        _locations = data;
        if (_locations.isNotEmpty) {
          _selectedLocation = _locations.first;
        }
      });
    } catch (e) {
      debugPrint("Error loading locations: $e");
    }
  }

  Future<void> _loadEncounters() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/encounters.json',
      );
      final data = await json.decode(response);
      setState(() {
        _encounterTables = data;
      });
    } catch (e) {
      debugPrint("Error loading encounters: $e");
    }
  }

  void _rollDailyEncounter() {
    final roll = 1 + (DateTime.now().microsecondsSinceEpoch % 20);
    final table = _encounterTables[_selectedBiome] as List<dynamic>?;

    if (table == null) return;

    dynamic found;
    for (var enc in table) {
      if (roll >= enc['range'][0] && roll <= enc['range'][1]) {
        found = enc;
        break;
      }
    }

    setState(() {
      if (found != null) {
        _lastEncounterResult =
            '[$roll по d20] ${found['name']}\n\n${found['description']}\n(Загроза: ${found['threat']})';
      } else {
        _lastEncounterResult =
            '[$roll по d20] Спокійний день. Нічого не сталося.';
      }
    });
  }

  void _advanceDay() {
    setState(() {
      _currentDay++;
      if (_rationsLeft > 0) _rationsLeft -= 1;
      if (_waterGallonsLeft > 0) _waterGallonsLeft -= 2;
    });
    _rollDailyEncounter();
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _locations.where((loc) {
      final name = loc['name'].toString().toLowerCase();
      final category = loc['category'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || category.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToA DM Companion — Desktop Workspace'),
        backgroundColor: const Color(0xFF111111),
        actions: [
          IconButton(
            icon: Icon(
              _showMap ? Icons.article : Icons.map,
              color: Colors.amber,
            ),
            tooltip: _showMap ? 'Перейти до опису' : 'Відкрити карту',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'День подорожі: $_currentDay',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.amber,
                  ),
                  onPressed: () => setState(() => _currentDay++),
                  tooltip: 'Наступний день',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Панель 1: Навігація та пошук по локаціях
          Container(
            width: 320,
            color: const Color(0xFF242424),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Пошук локацій...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFF333333),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final item = filteredLocations[index];
                      final isSelected =
                          _selectedLocation != null &&
                          _selectedLocation['id'] == item['id'];
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.amber.withOpacity(0.2),
                        title: Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${item['category']} • ${item['region']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => setState(() => _selectedLocation = item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Панель 2: Детальний вміст обраної локації або Карта
          Expanded(
            flex: 3,
            child: _showMap
                ? ChultMapWidget(
                    locations: _locations,
                    selectedLocation: _selectedLocation,
                    onSelectLocation: (loc) =>
                        setState(() => _selectedLocation = loc),
                  )
                : (_selectedLocation == null
                      ? const Center(
                          child: Text('Оберіть локацію для перегляду'),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ListView(
                            children: [
                              Text(
                                _selectedLocation['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.amber),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(_selectedLocation['category']),
                                  ),
                                  const SizedBox(width: 8),
                                  Chip(
                                    label: Text(
                                      'Рівень загрози: ${_selectedLocation['dangerLevel']}',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedLocation['summary'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const Divider(height: 32, color: Colors.white24),
                              const Text(
                                'Ключові особливості:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_selectedLocation['keyFeatures'] as List).map(
                                (feature) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.label_important,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Панель 3: Інструменти DM та трекер подорожі
          Container(
            width: 320,
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Інструменти DM',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 12),

                // Трекер ресурсів
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282828),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Харчі (Раціони):'),
                          Text(
                            '$_rationsLeft дн.',
                            style: TextStyle(
                              color: _rationsLeft < 5
                                  ? Colors.red
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Вода (Галони):'),
                          Text(
                            '$_waterGallonsLeft гал.',
                            style: TextStyle(
                              color: _waterGallonsLeft < 10
                                  ? Colors.red
                                  : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Вибір біому
                const Text(
                  'Поточний біом / зона:',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
                DropdownButton<String>(
                  value: _selectedBiome,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2A2A),
                  items: const [
                    DropdownMenuItem(
                      value: 'jungle_normal',
                      child: Text('Джунглі (Нормальна загроза)'),
                    ),
                    DropdownMenuItem(
                      value: 'undead_high',
                      child: Text('Зона високої нежиті'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBiome = val);
                  },
                ),
                const SizedBox(height: 12),

                // Кнопки дій
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.arrow_forward, color: Colors.black),
                  label: const Text(
                    'Провести день (+1 день)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _advanceDay,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                  ),
                  icon: const Icon(Icons.casino, size: 18),
                  label: const Text('Кидок зустрічі (d20)'),
                  onPressed: _rollDailyEncounter,
                ),
                const SizedBox(height: 16),

                // Вікно результату зустрічі
                const Text(
                  'Результат події:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _lastEncounterResult,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
