import '../models/dream_record.dart';
import 'database_service.dart';

class DreamRecordService {
  static final DreamRecordService instance = DreamRecordService._init();
  final DatabaseService _db = DatabaseService.instance;

  DreamRecordService._init();

  Future<List<DreamRecord>> readAllDreams() async {
    final records = await _db.readAllDreams();
    return records;
  }

  Future<DreamRecord?> readDream(String id) async {
    return await _db.readDream(id);
  }

  Future<void> saveDreamRecord(DreamRecord record) async {
    await _db.createDream(record);
  }

  Future<void> deleteRecord(String id) async {
    await _db.deleteDream(id);
  }

  Future<DreamRecord?> getLatestDreamForDate(DateTime date) async {
    final allDreams = await readAllDreams();
    final sameDayDreams = allDreams.where((dream) {
      return dream.date.year == date.year &&
             dream.date.month == date.month &&
             dream.date.day == date.day;
    }).toList();
    
    if (sameDayDreams.isEmpty) return null;
    
    sameDayDreams.sort((a, b) => b.date.compareTo(a.date));
    return sameDayDreams.first;
  }
} 