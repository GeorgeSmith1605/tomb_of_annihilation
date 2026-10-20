import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/chult_map_widget.dart';
import 'widgets/hex_navigation_widget.dart';

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

class Combatant {
  String name;
  int initiative;
  int currentHp;
  int maxHp;
  bool isMonster;

  Combatant({
    required this.name,
    required this.initiative,
    required this.currentHp,
    required this.maxHp,
    this.isMonster = false,
  });
}

class MainDMDesktopScreen extends StatefulWidget {
  const MainDMDesktopScreen({super.key});

  @override
  State<MainDMDesktopScreen> createState() => _MainDMDesktopScreenState();
}

class _MainDMDesktopScreenState extends State<MainDMDesktopScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _locations = [];
  dynamic _selectedLocation;
  String _searchQuery = '';
  int _currentDay = 1;
  bool _showMap = false;

  List<dynamic> _monsters = [];
  List<dynamic> _rumors = [];
  List<dynamic> _puzzles = [];
  List<dynamic> _guides = [];
  List<dynamic> _dinosaurs = [];
  List<dynamic> _factions = [];
  List<dynamic> _sideQuests = [];
  List<dynamic> _marketItems = [];
  List<dynamic> _dmReference = [];
  final Map<String, String> _questStatuses = {};

  dynamic _activeGuide;

  final Map<String, String> _locationNotes = {};
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sessionLogController = TextEditingController();

  Map<String, dynamic> _encounterTables = {};
  String _selectedBiome = 'jungle_normal';
  String _lastEncounterResult =
      'Натисніть "Провести день" або "Кидок зустрічі"';
  int _rationsLeft = 20;
  int _waterGallonsLeft = 30;
  int _partyGold = 150;

  List<dynamic> _tricksterGods = [];
  List<Combatant> _combatants = [];
  int _activeCombatantIndex = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLocations();
    _loadEncounters();
    _loadTricksterGods();
    _loadMonsters();
    _loadRumors();
    _loadPuzzles();
    _loadGuides();
    _loadDinosaurs();
    _loadFactions();
    _loadSideQuests();
    _loadMarketItems();
    _loadDmReference();
    _loadCampaignState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _sessionLogController.dispose();
    super.dispose();
  }

  Future<void> _saveCampaignState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentDay', _currentDay);
    await prefs.setInt('rationsLeft', _rationsLeft);
    await prefs.setInt('waterGallonsLeft', _waterGallonsLeft);
    await prefs.setInt('partyGold', _partyGold);
    await prefs.setString('selectedBiome', _selectedBiome);
    await prefs.setString('lastEncounter', _lastEncounterResult);
    await prefs.setString('sessionLogNotes', _sessionLogController.text);

    if (_activeGuide != null) {
      await prefs.setString('activeGuideId', _activeGuide['id']);
    } else {
      await prefs.remove('activeGuideId');
    }

    _questStatuses.forEach((qId, status) async {
      await prefs.setString('quest_status_$qId', status);
    });

    if (_selectedLocation != null) {
      _locationNotes[_selectedLocation['id']] = _notesController.text;
      await prefs.setString(
          'notes_${_selectedLocation['id']}', _notesController.text);
    }
  }

  Future<void> _loadCampaignState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentDay = prefs.getInt('currentDay') ?? 1;
      _rationsLeft = prefs.getInt('rationsLeft') ?? 20;
      _waterGallonsLeft = prefs.getInt('waterGallonsLeft') ?? 30;
      _partyGold = prefs.getInt('partyGold') ?? 150;
      _selectedBiome = prefs.getString('selectedBiome') ?? 'jungle_normal';
      _lastEncounterResult = prefs.getString('lastEncounter') ??
          'Натисніть "Провести день" або "Кидок зустрічі"';
      _sessionLogController.text = prefs.getString('sessionLogNotes') ?? '';

      final savedGuideId = prefs.getString('activeGuideId');
      if (savedGuideId != null && _guides.isNotEmpty) {
        _activeGuide = _guides.firstWhere(
          (g) => g['id'] == savedGuideId,
          orElse: () => null,
        );
      }

      for (var q in _sideQuests) {
        final qId = q['id'].toString();
        _questStatuses[qId] =
            prefs.getString('quest_status_$qId') ?? 'Доступний';
      }
    });
  }

  Future<void> _loadLocationNote(String locId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedNote = prefs.getString('notes_$locId') ?? '';
    setState(() {
      _notesController.text = savedNote;
    });
  }

  Future<void> _loadDmReference() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/dm_reference.json');
      final data = json.decode(response);
      setState(() {
        _dmReference = data;
      });
    } catch (e) {
      debugPrint("Error loading DM reference: $e");
    }
  }

  Future<void> _loadMarketItems() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/market_items.json');
      final data = json.decode(response);
      setState(() {
        _marketItems = data;
      });
    } catch (e) {
      debugPrint("Error loading market items: $e");
    }
  }

  Future<void> _loadSideQuests() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/side_quests.json');
      final data = json.decode(response);
      setState(() {
        _sideQuests = data;
      });
    } catch (e) {
      debugPrint("Error loading side quests: $e");
    }
  }

  Future<void> _loadFactions() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/factions.json');
      final data = json.decode(response);
      setState(() {
        _factions = data;
      });
    } catch (e) {
      debugPrint("Error loading factions: $e");
    }
  }

  Future<void> _loadDinosaurs() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/dinosaurs.json');
      final data = json.decode(response);
      setState(() {
        _dinosaurs = data;
      });
    } catch (e) {
      debugPrint("Error loading dinosaurs: $e");
    }
  }

  Future<void> _loadGuides() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/guides.json');
      final data = json.decode(response);
      setState(() {
        _guides = data;
      });
    } catch (e) {
      debugPrint("Error loading guides: $e");
    }
  }

  Future<void> _loadPuzzles() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/puzzles.json');
      final data = json.decode(response);
      setState(() {
        _puzzles = data;
      });
    } catch (e) {
      debugPrint("Error loading puzzles: $e");
    }
  }

  Future<void> _loadRumors() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/rumors.json');
      final data = json.decode(response);
      setState(() {
        _rumors = data;
      });
    } catch (e) {
      debugPrint("Error loading rumors: $e");
    }
  }

  Future<void> _loadMonsters() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/monsters.json');
      final data = json.decode(response);
      setState(() {
        _monsters = data;
      });
    } catch (e) {
      debugPrint("Error loading monsters: $e");
    }
  }

  Future<void> _loadLocations() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/locations.json');
      final data = json.decode(response);
      setState(() {
        _locations = data;
        if (_locations.isNotEmpty) {
          _selectedLocation = _locations.first;
          _loadLocationNote(_selectedLocation['id']);
        }
      });
    } catch (e) {
      debugPrint("Error loading locations: $e");
    }
  }

  Future<void> _loadEncounters() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/encounters.json');
      final data = json.decode(response);
      setState(() {
        _encounterTables = data;
      });
    } catch (e) {
      debugPrint("Error loading encounters: $e");
    }
  }

  Future<void> _loadTricksterGods() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/trickster_gods.json');
      final data = json.decode(response);
      setState(() {
        _tricksterGods = data;
      });
    } catch (e) {
      debugPrint("Error loading trickster gods: $e");
    }
  }

  void _openDmReferenceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 2,
          child: AlertDialog(
            backgroundColor: const Color(0xFF222222),
            title: const Row(
              children: [
                Icon(Icons.menu_book, color: Colors.amber),
                SizedBox(width: 10),
                Text('Шпора ДМ та Журнал Сесій',
                    style: TextStyle(color: Colors.amber)),
              ],
            ),
            content: SizedBox(
              width: 680,
              height: 520,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white60,
                    tabs: [
                      Tab(text: 'Правила та Шпора'),
                      Tab(text: 'Лог Подій / Нотатки Сесії'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Вкладка 1: Правила
                        ListView.builder(
                          itemCount: _dmReference.length,
                          itemBuilder: (context, index) {
                            final ref = _dmReference[index];
                            final rules = ref['rules'] as List<dynamic>;
                            return Card(
                              color: const Color(0xFF2E2E2E),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ExpansionTile(
                                title: Text(ref['category'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: rules
                                          .map<Widget>((r) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 6.0),
                                                child: Text('• $r',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        height: 1.3)),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Вкладка 2: Нотатки Сесій
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Загальний журнал подій кампанії:',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextField(
                                controller: _sessionLogController,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                decoration: InputDecoration(
                                  hintText:
                                      'Записуйте тут важливі події кожної сесії (хто загинув, де зупинилися, домовленості з НПС)...',
                                  filled: true,
                                  fillColor: const Color(0xFF181818),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (val) => _saveCampaignState(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Закрити',
                    style: TextStyle(color: Colors.amber)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMarketAndLootDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String lootResult =
            'Натисніть кнопку нижче, щоб згенерувати скарби Чульта.';
        return DefaultTabController(
          length: 2,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void generateLoot(String CRTier) {
                final rng = Random();
                int gold = 0;
                List<String> items = [];

                if (CRTier == 'low') {
                  gold = (rng.nextInt(6) + 1) * 10;
                  final lootTable = [
                    'Намисто з ікол тиранозавра (25 зм)',
                    'Старовинна маска Ому з нефриту (50 зм)',
                    'Флакон з отрутою су-монстра (2 дози)',
                    'Сувій заклинання: Disguise Self',
                    'Самоцвіт Агат (10 зм)',
                  ];
                  items.add(lootTable[rng.nextInt(lootTable.length)]);
                } else {
                  gold = (rng.nextInt(20) + 1) * 50;
                  final lootTable = [
                    'Кільце Зими (Ілюзія / Копія)',
                    'Призрачний ліхтар (Ghost Lantern з духом Старфален)',
                    'Загадковий куб божества Ому',
                    'Доспех Скорпиона (Scorpion Armor)',
                    'Амулет Чорного Черепа (Black Skull Amulet)',
                  ];
                  items.add(lootTable[rng.nextInt(lootTable.length)]);
                }

                setModalState(() {
                  lootResult =
                      '💰 Золото: $gold зм\n🎁 Трофеї: ${items.join(', ')}';
                  _partyGold += gold;
                });
                setState(() {});
                _saveCampaignState();
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF222222),
                title: const Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.amber),
                    SizedBox(width: 10),
                    Text('Ринок та Генератор Скарбів',
                        style: TextStyle(color: Colors.amber)),
                  ],
                ),
                content: SizedBox(
                  width: 700,
                  height: 520,
                  child: Column(
                    children: [
                      const TabBar(
                        indicatorColor: Colors.amber,
                        labelColor: Colors.amber,
                        unselectedLabelColor: Colors.white60,
                        tabs: [
                          Tab(text: 'Ринок Порту Нянзару'),
                          Tab(text: 'Генератор Скарбів'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ListView.builder(
                              itemCount: _marketItems.length,
                              itemBuilder: (context, index) {
                                final item = _marketItems[index];
                                final cost = item['cost'] as int;
                                final canAfford = _partyGold >= cost;

                                return Card(
                                  color: const Color(0xFF2E2E2E),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(item['name'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                            fontSize: 14)),
                                    subtitle: Text(
                                        '${item['description']}\nЦіна: $cost зм (${item['unit']})'),
                                    isThreeLine: true,
                                    trailing: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: canAfford
                                            ? Colors.amber.shade700
                                            : Colors.grey,
                                      ),
                                      child: const Text('Купити',
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold)),
                                      onPressed: canAfford
                                          ? () {
                                              setState(() {
                                                _partyGold -= cost;
                                                if (item['type'] == 'rations') {
                                                  _rationsLeft +=
                                                      item['amount'] as int;
                                                } else if (item['type'] ==
                                                    'water') {
                                                  _waterGallonsLeft +=
                                                      item['amount'] as int;
                                                }
                                              });
                                              setModalState(() {});
                                              _saveCampaignState();
                                            }
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'Оберіть рівень складності / небезпеки:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.green.shade700),
                                        icon: const Icon(Icons.casino,
                                            color: Colors.white),
                                        label: const Text(
                                            'Низький рівень (CR 0-4)',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () => generateLoot('low'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.red.shade700),
                                        icon: const Icon(Icons.auto_awesome,
                                            color: Colors.white),
                                        label: const Text(
                                            'Високий рівень (CR 5+)',
                                            style:
                                                TextStyle(color: Colors.white)),
                                        onPressed: () => generateLoot('high'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF151515),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.amber.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    lootResult,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.amberAccent),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Закрити',
                        style: TextStyle(color: Colors.amber)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openSideQuestsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Row(
                children: [
                  Icon(Icons.assignment, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Побічні Завдання та Дошка Оголошень',
                      style: TextStyle(color: Colors.amber)),
                ],
              ),
              content: SizedBox(
                width: 680,
                height: 520,
                child: ListView.builder(
                  itemCount: _sideQuests.length,
                  itemBuilder: (context, index) {
                    final q = _sideQuests[index];
                    final qId = q['id'].toString();
                    final currentStatus = _questStatuses[qId] ?? 'Доступний';

                    Color statusColor = Colors.amber;
                    if (currentStatus == 'Активний')
                      statusColor = Colors.lightBlueAccent;
                    if (currentStatus == 'Завершений')
                      statusColor = Colors.greenAccent;

                    return Card(
                      color: const Color(0xFF2E2E2E),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                q['title'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                    fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: statusColor, width: 1),
                              ),
                              child: Text(
                                currentStatus,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text('${q['location']} • НПС: ${q['npc']}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Суть завдання: ${q['summary']}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Деталі: ${q['details']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                                const SizedBox(height: 6),
                                Text('Винагорода: ${q['reward']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.greenAccent)),
                                const SizedBox(height: 6),
                                Text('Примітки для ДМ: ${q['dmNotes']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.redAccent)),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text('Змінити статус: ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60)),
                                    DropdownButton<String>(
                                      value: currentStatus,
                                      dropdownColor: const Color(0xFF333333),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white),
                                      items: const [
                                        DropdownMenuItem(
                                            value: 'Доступний',
                                            child: Text('Доступний')),
                                        DropdownMenuItem(
                                            value: 'Активний',
                                            child: Text('Активний')),
                                        DropdownMenuItem(
                                            value: 'Завершений',
                                            child: Text('Завершений')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            _questStatuses[qId] = val;
                                          });
                                          setModalState(() {});
                                          _saveCampaignState();
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Закрити',
                      style: TextStyle(color: Colors.amber)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openFactionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: _factions.length,
          child: AlertDialog(
            backgroundColor: const Color(0xFF222222),
            title: const Row(
              children: [
                Icon(Icons.groups, color: Colors.amber),
                SizedBox(width: 10),
                Text('Торгові Принці та Фракції',
                    style: TextStyle(color: Colors.amber)),
              ],
            ),
            content: SizedBox(
              width: 680,
              height: 520,
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Colors.amber,
                    labelColor: Colors.amber,
                    unselectedLabelColor: Colors.white60,
                    tabs: _factions
                        .map<Widget>((f) => Tab(text: f['category'].toString()))
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: TabBarView(
                      children: _factions.map<Widget>((group) {
                        final members = group['members'] as List<dynamic>;
                        return ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final m = members[index];
                            return Card(
                              color: const Color(0xFF2E2E2E),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                title: Text(m['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                        fontSize: 14)),
                                subtitle: Text(m['role'],
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Опис: ${m['details']}',
                                            style: const TextStyle(
                                                fontSize: 13, height: 1.3)),
                                        const SizedBox(height: 6),
                                        Text('Секрет для ДМ: ${m['secret']}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.redAccent)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Закрити',
                    style: TextStyle(color: Colors.amber)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openDinoRaceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String raceLog =
            'Натисніть "Запустити забіг", щоб симулювати перегони на 300 футів!';
        return StatefulBuilder(
          builder: (context, setModalState) {
            void runRaceSimulation() {
              final rng = Random();
              Map<String, int> distances = {};
              for (var dino in _dinosaurs) {
                distances[dino['name']] = 0;
              }

              List<String> logEntries = [];
              logEntries.add('🏁 СТАРТ ПЕРЕГОНІВ ДИНОЗАВРІВ!');

              int round = 1;
              bool finished = false;
              String winner = '';

              while (!finished && round <= 10) {
                logEntries.add('\n--- Раунд $round ---');
                for (var dino in _dinosaurs) {
                  final name = dino['name'] as String;
                  final baseSpeed = dino['speed'] as int;
                  final skillDc = dino['skillCheck'] as int;

                  final roll = rng.nextInt(20) + 1;
                  int actualMove = baseSpeed;

                  if (roll >= skillDc) {
                    actualMove += (rng.nextInt(6) + 1) * 5;
                    logEntries.add(
                        '• $name: Кидок $roll (Успіх). Просунувся на $actualMove фт.');
                  } else {
                    actualMove = (baseSpeed / 2).round();
                    logEntries.add(
                        '• $name: Кидок $roll (Провал всадника). Сповільнився до $actualMove фт.');
                  }

                  distances[name] = (distances[name] ?? 0) + actualMove;

                  if (distances[name]! >= 300 && !finished) {
                    finished = true;
                    winner = name;
                  }
                }
                round++;
              }

              logEntries.add('\n🏆 ПЕРЕМОЖЕЦЬ: $winner!');

              setModalState(() {
                raceLog = logEntries.join('\n');
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Row(
                children: [
                  Icon(Icons.directions_run, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Перегони Динозаврів (Dinosaur Races)',
                      style: TextStyle(color: Colors.amber)),
                ],
              ),
              content: SizedBox(
                width: 700,
                height: 540,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: ListView.builder(
                        itemCount: _dinosaurs.length,
                        itemBuilder: (context, index) {
                          final d = _dinosaurs[index];
                          return Card(
                            color: const Color(0xFF2E2E2E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13)),
                                  Text('${d['type']} • Ставки: ${d['odds']}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text('Базова швидкість: ${d['speed']} фт.',
                                      style: const TextStyle(fontSize: 11)),
                                  Text('DC контролю: ${d['skillCheck']}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.greenAccent)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const VerticalDivider(width: 16, color: Colors.white24),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            icon: const Icon(Icons.play_arrow,
                                color: Colors.black),
                            label: const Text('Запустити забіг (300 фт)',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            onPressed: runRaceSimulation,
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF151515),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  raceLog,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      height: 1.3,
                                      fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Закрити',
                      style: TextStyle(color: Colors.amber)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openGuidesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Row(
                children: [
                  Icon(Icons.person_pin_circle, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Проводники Чульта (Port Nyanzaru Guides)',
                      style: TextStyle(color: Colors.amber)),
                ],
              ),
              content: SizedBox(
                width: 680,
                height: 520,
                child: ListView.builder(
                  itemCount: _guides.length,
                  itemBuilder: (context, index) {
                    final g = _guides[index];
                    final isSelected =
                        _activeGuide != null && _activeGuide['id'] == g['id'];

                    return Card(
                      color: isSelected
                          ? Colors.amber.withOpacity(0.15)
                          : const Color(0xFF2E2E2E),
                      shape: isSelected
                          ? RoundedRectangleBorder(
                              side: const BorderSide(
                                  color: Colors.amber, width: 1.5),
                              borderRadius: BorderRadius.circular(8))
                          : null,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        title: Text(g['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                                fontSize: 15)),
                        subtitle: Text(
                            '${g['raceClass']} • Плата: ${g['costPerDay']} зм/день'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.amber.shade700,
                          ),
                          child: Text(
                            isSelected ? 'Активний' : 'Найняти',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              _activeGuide = isSelected ? null : g;
                            });
                            setModalState(() {});
                            _saveCampaignState();
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Оголошення / Раздатка:',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFF181818),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(g['handoutText'],
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 13)),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                    'Умова знижки / безкоштовно: ${g['freeCondition']}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.greenAccent)),
                                const SizedBox(height: 6),
                                Text('Секрет ДМ: ${g['dmSecret']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Закрити',
                      style: TextStyle(color: Colors.amber)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPuzzlesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchPuzzle = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredPuzzles = _puzzles.where((p) {
              final title = p['title'].toString().toLowerCase();
              final category = p['category'].toString().toLowerCase();
              final query = searchPuzzle.toLowerCase();
              return title.contains(query) || category.contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Row(
                children: [
                  Icon(Icons.extension, color: Colors.amber),
                  SizedBox(width: 10),
                  Text('Загадки та Підказки Ацерерака',
                      style: TextStyle(color: Colors.amber)),
                ],
              ),
              content: SizedBox(
                width: 650,
                height: 520,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Пошук загадки або категорії...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFF333333),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) =>
                          setModalState(() => searchPuzzle = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredPuzzles.length,
                        itemBuilder: (context, index) {
                          final p = filteredPuzzles[index];
                          return Card(
                            color: const Color(0xFF2E2E2E),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              title: Text(p['title'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber)),
                              subtitle: Text('Категорія: ${p['category']}'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF181818),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border:
                                              Border.all(color: Colors.white12),
                                        ),
                                        child: SelectableText(
                                          p['text'],
                                          style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.4,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.lightbulb,
                                              size: 16,
                                              color: Colors.greenAccent),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Відповідь / Рішення для ДМ: ${p['solution']}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.greenAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Закрити',
                      style: TextStyle(color: Colors.amber)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _rollRumorDialog() {
    final roll = 1 + (DateTime.now().microsecondsSinceEpoch % 100);
    dynamic foundRumor;
    for (var r in _rumors) {
      if (roll >= r['range'][0] && roll <= r['range'][1]) {
        foundRumor = r;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: Row(
          children: [
            const Icon(Icons.record_voice_over, color: Colors.amber),
            const SizedBox(width: 10),
            Text('Чультський слух (d100: $roll)',
                style: const TextStyle(color: Colors.amber)),
          ],
        ),
        content: Text(
          foundRumor != null
              ? foundRumor['text']
              : 'Нічого цікавого не вдалося дізнатися.',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700),
            child: const Text('Ще один слух',
                style: TextStyle(color: Colors.black)),
            onPressed: () {
              Navigator.pop(context);
              _rollRumorDialog();
            },
          ),
          TextButton(
            child: const Text('Закрити', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _openBestiaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchMonster = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredMonsters = _monsters.where((m) {
              return m['name']
                      .toString()
                      .toLowerCase()
                      .contains(searchMonster.toLowerCase()) ||
                  m['type']
                      .toString()
                      .toLowerCase()
                      .contains(searchMonster.toLowerCase());
            }).toList();

            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text('Бестіарій та Статблоки',
                  style: TextStyle(color: Colors.amber)),
              content: SizedBox(
                width: 600,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Пошук монстра або НПС...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFF333333),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) =>
                          setModalState(() => searchMonster = val),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredMonsters.length,
                        itemBuilder: (context, index) {
                          final m = filteredMonsters[index];
                          final stats = m['stats'];
                          return Card(
                            color: const Color(0xFF2E2E2E),
                            child: ExpansionTile(
                              title: Text(m['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber)),
                              subtitle: Text(
                                  '${m['type']} • CR: ${m['cr']} • КД: ${m['ac']} • ХП: ${m['hp']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.shield,
                                    color: Colors.redAccent),
                                tooltip: 'Додати в трекер бою',
                                onPressed: () {
                                  _addMonsterToCombat(m);
                                  Navigator.of(context).pop();
                                  _tabController.animateTo(3);
                                },
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Характеристики: СИЛ ${stats['str']} | СПР ${stats['dex']} | ТІЛ ${stats['con']} | ІНТ ${stats['int']} | МУД ${stats['wis']} | ХАР ${stats['cha']}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white70)),
                                      const SizedBox(height: 8),
                                      const Text('Особливості:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber)),
                                      ...(m['traits'] as List).map((t) => Text(
                                          '• $t',
                                          style:
                                              const TextStyle(fontSize: 12))),
                                      const SizedBox(height: 8),
                                      const Text('Дії:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent)),
                                      ...(m['actions'] as List)
                                          .map((a) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 4.0),
                                                child: Text(
                                                    '• ${a['name']}: ${a['desc']}',
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              )),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Закрити',
                      style: TextStyle(color: Colors.amber)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addMonsterToCombat(dynamic monster) {
    final rollInit = (1 + (DateTime.now().microsecondsSinceEpoch % 20));
    final hp = monster['hp'] is int
        ? monster['hp'] as int
        : int.tryParse(monster['hp'].toString()) ?? 30;
    setState(() {
      _combatants.add(
        Combatant(
          name: '${monster['name']} #${_combatants.length + 1}',
          initiative: rollInit,
          currentHp: hp,
          maxHp: hp,
          isMonster: true,
        ),
      );
      _sortCombatants();
    });
  }

  void _addCustomCombatantDialog() {
    String name = '';
    int init = 10;
    int hp = 20;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('Додати учасника бою',
            style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Ім\'я / Персонаж'),
              onChanged: (v) => name = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ініціатива'),
              keyboardType: TextInputType.number,
              onChanged: (v) => init = int.tryParse(v) ?? 10,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Максимальне HP'),
              keyboardType: TextInputType.number,
              onChanged: (v) => hp = int.tryParse(v) ?? 20,
            ),
          ],
        ),
        actions: [
          TextButton(
              child: const Text('Скасувати'),
              onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            child: const Text('Додати'),
            onPressed: () {
              if (name.isNotEmpty) {
                setState(() {
                  _combatants.add(Combatant(
                      name: name, initiative: init, currentHp: hp, maxHp: hp));
                  _sortCombatants();
                });
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _sortCombatants() {
    _combatants.sort((a, b) => b.initiative.compareTo(a.initiative));
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
    _saveCampaignState();
  }

  void _advanceDay() {
    setState(() {
      _currentDay++;
      if (_rationsLeft > 0) _rationsLeft -= 1;
      if (_waterGallonsLeft > 0) _waterGallonsLeft -= 2;

      if (_activeGuide != null) {
        final guideFee = _activeGuide['costPerDay'] as int? ?? 5;
        if (_partyGold >= guideFee) {
          _partyGold -= guideFee;
        }
      }
    });
    _rollDailyEncounter();
    _saveCampaignState();
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
            icon: const Icon(Icons.menu_book, color: Colors.amber),
            tooltip: 'Шпора ДМ та Журнал Сесій',
            onPressed: _openDmReferenceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.amber),
            tooltip: 'Ринок та Генератор скарбів',
            onPressed: _openMarketAndLootDialog,
          ),
          IconButton(
            icon: const Icon(Icons.assignment, color: Colors.amber),
            tooltip: 'Побічні завдання та Дошка оголошень',
            onPressed: _openSideQuestsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.groups, color: Colors.amber),
            tooltip: 'Торгові Принці та Фракції',
            onPressed: _openFactionsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.directions_run, color: Colors.amber),
            tooltip: 'Перегони Динозаврів',
            onPressed: _openDinoRaceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_pin_circle, color: Colors.amber),
            tooltip: 'Проводники Чульта',
            onPressed: _openGuidesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.extension, color: Colors.amber),
            tooltip: 'Загадки та Підказки',
            onPressed: _openPuzzlesDialog,
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over, color: Colors.amber),
            tooltip: 'Генератор слухів (d100)',
            onPressed: _rollRumorDialog,
          ),
          IconButton(
            icon: const Icon(Icons.adb, color: Colors.amber),
            tooltip: 'Швидкий бестіарій',
            onPressed: _openBestiaryDialog,
          ),
          IconButton(
            icon:
                Icon(_showMap ? Icons.article : Icons.map, color: Colors.amber),
            tooltip: _showMap ? 'Перейти до опису' : 'Відкрити карту',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.redAccent),
            tooltip: 'Скинути прогрес кампанії',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              setState(() {
                _currentDay = 1;
                _rationsLeft = 20;
                _waterGallonsLeft = 30;
                _partyGold = 150;
                _activeGuide = null;
                _selectedBiome = 'jungle_normal';
                _lastEncounterResult =
                    'Натисніть "Провести день" або "Кидок зустрічі"';
                _notesController.clear();
                _sessionLogController.clear();
                _questStatuses.clear();
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text('День подорожі: $_currentDay',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon:
                      const Icon(Icons.add_circle_outline, color: Colors.amber),
                  onPressed: () {
                    setState(() => _currentDay++);
                    _saveCampaignState();
                  },
                  tooltip: 'Наступний день',
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Панель 1: Навігація
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
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredLocations.length,
                    itemBuilder: (context, index) {
                      final item = filteredLocations[index];
                      final isSelected = _selectedLocation != null &&
                          _selectedLocation['id'] == item['id'];
                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Colors.amber.withOpacity(0.2),
                        title: Text(item['name'],
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${item['category']} • ${item['region']}',
                            style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          if (_selectedLocation != null) {
                            _saveCampaignState();
                          }
                          setState(() {
                            _selectedLocation = item;
                          });
                          _loadLocationNote(item['id']);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Панель 2: Зміст локації + Карта / Нотатки
          Expanded(
            flex: 3,
            child: _showMap
                ? ChultMapWidget(
                    locations: _locations,
                    selectedLocation: _selectedLocation,
                    onSelectLocation: (loc) {
                      if (_selectedLocation != null) {
                        _saveCampaignState();
                      }
                      setState(() => _selectedLocation = loc);
                      _loadLocationNote(loc['id']);
                    },
                  )
                : (_selectedLocation == null
                    ? const Center(child: Text('Оберіть локацію для перегляду'))
                    : Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ListView(
                          children: [
                            Text(_selectedLocation['name'],
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.amber)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                    label: Text(_selectedLocation['category'])),
                                const SizedBox(width: 8),
                                Chip(
                                    label: Text(
                                        'Рівень загрози: ${_selectedLocation['dangerLevel']}')),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(_selectedLocation['summary'],
                                style:
                                    const TextStyle(fontSize: 16, height: 1.4)),
                            const Divider(height: 32, color: Colors.white24),
                            const Text('Ключові особливості:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...(_selectedLocation['keyFeatures'] as List).map(
                              (feature) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.label_important,
                                        size: 16, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(feature,
                                            style:
                                                const TextStyle(fontSize: 15))),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 32, color: Colors.white24),
                            const Text('Нотатки Майстра (ДМ):',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                    'Запишіть нотатки для цієї локації (стан НПС, здобич, події)...',
                                filled: true,
                                fillColor: const Color(0xFF252525),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              onChanged: (val) => _saveCampaignState(),
                            ),
                          ],
                        ),
                      )),
          ),
          const VerticalDivider(width: 1, color: Colors.white12),

          // Панель 3: Інструменти DM з 4 Вкладками
          Container(
            width: 360,
            color: const Color(0xFF1A1A1A),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amber,
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(icon: Icon(Icons.explore, size: 16), text: 'Подорож'),
                    Tab(icon: Icon(Icons.warning, size: 16), text: 'Прокляття'),
                    Tab(icon: Icon(Icons.auto_awesome, size: 16), text: 'Боги'),
                    Tab(icon: Icon(Icons.shield, size: 16), text: 'Бій'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTravelTab(),
                      _buildCurseTab(),
                      _buildGodsTab(),
                      _buildCombatTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Харчі (Раціони):'),
                    Text('$_rationsLeft дн.',
                        style: TextStyle(
                            color: _rationsLeft < 5 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Вода (Галони):'),
                    Text('$_waterGallonsLeft гал.',
                        style: TextStyle(
                            color: _waterGallonsLeft < 10
                                ? Colors.red
                                : Colors.blue,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Золото загону:'),
                    Text('$_partyGold зм',
                        style: const TextStyle(
                            color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (_activeGuide != null) ...[
                  const Divider(color: Colors.white24, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Проводник:'),
                      Text('${_activeGuide['name']}',
                          style: const TextStyle(
                              color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          HexNavigationWidget(
            onResourceUpdate: (rationCost, waterCost) {
              setState(() {
                _rationsLeft = (_rationsLeft - rationCost).clamp(0, 999);
                _waterGallonsLeft =
                    (_waterGallonsLeft - waterCost).clamp(0, 999);
              });
              _saveCampaignState();
            },
          ),
          const SizedBox(height: 12),
          const Text('Поточний біом:',
              style: TextStyle(fontSize: 12, color: Colors.white70)),
          DropdownButton<String>(
            value: _selectedBiome,
            isExpanded: true,
            dropdownColor: const Color(0xFF2A2A2A),
            items: const [
              DropdownMenuItem(
                  value: 'jungle_normal',
                  child: Text('Джунглі (Нормальна загроза)')),
              DropdownMenuItem(
                  value: 'undead_high', child: Text('Зона високої нежиті')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedBiome = val);
                _saveCampaignState();
              }
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                minimumSize: const Size.fromHeight(38)),
            icon:
                const Icon(Icons.arrow_forward, color: Colors.black, size: 18),
            label: const Text('Провести день (+1 день)',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            onPressed: _advanceDay,
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(34)),
            icon: const Icon(Icons.casino, size: 16),
            label: const Text('Кидок зустрічі (d20)'),
            onPressed: _rollDailyEncounter,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12)),
            child: Text(_lastEncounterResult,
                style: const TextStyle(fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildCurseTab() {
    final hpLostPerResurrected = _currentDay;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('Прокляття Смерті (Death Curse)',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withOpacity(0.4))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Втрата Max HP для воскреслих: -$hpLostPerResurrected HP',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.redAccent)),
              const SizedBox(height: 4),
              const Text(
                  'Усі воскреслі істоти втрачають 1 Max HP щодня з початку прокляття.',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
        const Divider(height: 24, color: Colors.white24),
        const Text('Хвороби Чульта',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.amber)),
        const SizedBox(height: 8),
        _buildDiseaseCard(
          'Гортанні п\'явки (Throat Leeches)',
          'Пиття некип\'яченої води. Спасбрусок Con DC 12.',
          'Виснаження +1 рівень, неможливість говорити або чаклувати вербальні заклинання.',
        ),
        const SizedBox(height: 8),
        _buildDiseaseCard(
          'Дрожаща хвороба (Shivering Sickness)',
          'Укуси комах (без репеленту). Спасбрусок Con DC 11.',
          'Оздоб та лихоманка. Disadvantage на всі перевірки здібностей та атаки.',
        ),
        const SizedBox(height: 8),
        _buildDiseaseCard(
          'Лихорадка божевільної мавпи (Mad Monkey Fever)',
          'Контакт з магічним туманом Mad Monkey Mist. Con DC 13.',
          'Божевілля на 1d6 годин, галюцинації.',
        ),
      ],
    );
  }

  Widget _buildDiseaseCard(String title, String trigger, String effect) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Text('Тригер: $trigger',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 2),
          Text('Ефект: $effect',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildGodsTab() {
    return _tricksterGods.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _tricksterGods.length,
            itemBuilder: (context, index) {
              final god = _tricksterGods[index];
              return Card(
                color: const Color(0xFF252525),
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(god['name'],
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber)),
                  subtitle: Text('${god['animal']} • ${god['alignment']}',
                      style: const TextStyle(fontSize: 11)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сила: ${god['power']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.greenAccent)),
                          const SizedBox(height: 4),
                          Text('Слабкість: ${god['flaw']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildCombatTab() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700),
                  icon: const Icon(Icons.person_add,
                      size: 16, color: Colors.black),
                  label: const Text('Учасник',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  onPressed: _addCustomCombatantDialog,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear_all, color: Colors.redAccent),
                tooltip: 'Очистити бій',
                onPressed: () => setState(() => _combatants.clear()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _combatants.isEmpty
                ? const Center(
                    child: Text(
                      'Бій не розпочато.\nДодайте монстра з бестіарію або гравця.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _combatants.length,
                    itemBuilder: (context, index) {
                      final c = _combatants[index];
                      final isCurrentTurn = _activeCombatantIndex == index;

                      return Card(
                        color: isCurrentTurn
                            ? Colors.amber.withOpacity(0.15)
                            : const Color(0xFF252525),
                        shape: isCurrentTurn
                            ? RoundedRectangleBorder(
                                side: const BorderSide(
                                    color: Colors.amber, width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 6.0),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.amber),
                                alignment: Alignment.center,
                                child: Text('${c.initiative}',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: c.isMonster
                                                ? Colors.redAccent
                                                : Colors.lightBlueAccent)),
                                    Text('HP: ${c.currentHp} / ${c.maxHp}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white70)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove,
                                    size: 16, color: Colors.red),
                                onPressed: () => setState(() => c.currentHp =
                                    (c.currentHp - 5).clamp(0, c.maxHp)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add,
                                    size: 16, color: Colors.green),
                                onPressed: () => setState(() => c.currentHp =
                                    (c.currentHp + 5).clamp(0, c.maxHp)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 16, color: Colors.white30),
                                onPressed: () =>
                                    setState(() => _combatants.removeAt(index)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_combatants.isNotEmpty) ...[
            const Divider(color: Colors.white24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  minimumSize: const Size.fromHeight(36)),
              icon: const Icon(Icons.skip_next, color: Colors.black, size: 18),
              label: const Text('Наступний хід',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                setState(() {
                  _activeCombatantIndex =
                      (_activeCombatantIndex + 1) % _combatants.length;
                });
              },
            ),
          ],
        ],
      ),
    );
  }
}
