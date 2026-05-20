import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Map<String, dynamic>> _events = [];
  List<String> _notes = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  void _loadData() {
    final eventsBox = Hive.box('planner_events');
    final notesBox = Hive.box('planner_notes');

    if (eventsBox.isNotEmpty) {
      _events = eventsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (notesBox.isNotEmpty) {
      _notes = notesBox.values.cast<String>().toList();
    }
    setState(() {});
  }

  void _saveEvents() {
    final eventsBox = Hive.box('planner_events');
    eventsBox.clear();
    for (var event in _events) {
      eventsBox.add(event);
    }
  }

  void _saveNotes() {
    final notesBox = Hive.box('planner_notes');
    notesBox.clear();
    for (var note in _notes) {
      notesBox.add(note);
    }
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Event'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(hintText: 'Event title'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  setState(() {
                    _events.add({
                      'date': _selectedDay?.toIso8601String(),
                      'title': titleController.text,
                    });
                  });
                  _saveEvents();
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addNote() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController noteController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Write your note...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (noteController.text.isNotEmpty) {
                  setState(() {
                    _notes.add(noteController.text);
                  });
                  _saveNotes();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _searchNotes() {
    showSearch<String>(context: context, delegate: _NoteSearchDelegate(_notes, _saveNotes));
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _events
        .where((e) =>
            e['date'] != null &&
            isSameDay(DateTime.parse(e['date'] as String), _selectedDay ?? _focusedDay))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner & Calendar'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _searchNotes),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Events'),
                      Tab(text: 'Notes'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: ElevatedButton.icon(
                                onPressed: _addEvent,
                                icon: const Icon(Icons.event),
                                label: const Text('Add Event'),
                              ),
                            ),
                            Expanded(
                              child: dayEvents.isEmpty
                                  ? const Center(child: Text('No events for this day'))
                                  : ListView.builder(
                                      itemCount: dayEvents.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(dayEvents[index]['title']),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                _events.remove(dayEvents[index]);
                                              });
                                              _saveEvents();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton.icon(
                                onPressed: _addNote,
                                icon: const Icon(Icons.note_add),
                                label: const Text('Add Note'),
                              ),
                            ),
                            Expanded(
                              child: _notes.isEmpty
                                  ? const Center(child: Text('No notes yet'))
                                  : ListView.builder(
                                      itemCount: _notes.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(_notes[index]),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () {
                                              setState(() {
                                                _notes.removeAt(index);
                                              });
                                              _saveNotes();
                                            },
                                          ),
                                        );
                                      },
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
          ],
        ),
      ),
    );
  }
}

class _NoteSearchDelegate extends SearchDelegate<String> {
  final List<String> notes;
  final VoidCallback onSave;
  _NoteSearchDelegate(this.notes, this.onSave);

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, ''));

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final filtered = notes.where((n) => n.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => ListTile(title: Text(filtered[i])),
    );
  }
}
