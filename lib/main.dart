import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  List<dynamic> _locations = [];
  dynamic _selectedLocation;
  String _searchQuery = '';
  int _currentDay = 1;

  @override
  void initState() {
    super.initState();
    _loadLocations();
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

          // Панель 2: Детальний вміст обраної локації
          Expanded(
            flex: 3,
            child: _selectedLocation == null
                ? const Center(child: Text('Оберіть локацію для перегляду'))
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ListView(
                      children: [
                        Text(
                          _selectedLocation['name'],
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.amber),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(label: Text(_selectedLocation['category'])),
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
                          style: const TextStyle(fontSize: 16, height: 1.4),
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
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                  ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Панель 3: Інструменти Майстра (Дайс-ролер та події)
          Container(
            width: 300,
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.casino, color: Colors.black),
                  label: const Text(
                    'Випадкова зустріч (d20)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    final roll =
                        (1 + (DateTime.now().microsecondsSinceEpoch % 20));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Кидок: $roll ${roll >= 16 ? "— Сталася зустріч!" : "— Тихий день."}',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: const Text('Перевірка погоди'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Погода: Тропічна злива (Знижена видимість)',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
