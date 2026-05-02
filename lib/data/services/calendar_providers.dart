import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event_model.dart';
import 'firestore_providers.dart';
import 'auth_provider.dart';

class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addEvent(CalendarEventModel event) async {
    DocumentReference docRef = _db.collection('calendar_events').doc();
    await docRef.set(event.toMap()..['id'] = docRef.id);
  }

  Future<void> updateEvent(CalendarEventModel event) async {
    await _db.collection('calendar_events').doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _db.collection('calendar_events').doc(eventId).delete();
  }
}

final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(),
);

// StreamProvider para escutar os eventos do pai (e das crianças filtradas)
final calendarEventsStreamProvider =
    StreamProvider.family<List<CalendarEventModel>, String?>((ref, childId) {
      final firestore = ref.watch(firestoreProvider);
      final user = ref.watch(authStateProvider).value;

      if (user == null) return Stream.value([]);

      Query query = firestore
          .collection('calendar_events')
          .where('parentId', isEqualTo: user.uid);

      // Se um filho específico estiver selecionado, traz os eventos da família toda ('all') E os do filho
      if (childId != null && childId != 'all') {
        query = query.where('childId', whereIn: [childId, 'all']);
      }

      return query.snapshots().map((snapshot) {
        final events = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return CalendarEventModel.fromMap(data, doc.id);
        }).toList();

        events.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        return events;
      });
    });
