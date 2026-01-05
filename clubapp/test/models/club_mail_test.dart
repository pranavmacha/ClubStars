import 'package:flutter_test/flutter_test.dart';
import 'package:clubapp/models/club_mail.dart';

void main() {
  group('ClubMail Model', () {
    const validJson = {
      'link': 'https://example.com/event',
      'sender': 'tech-club@university.edu',
      'msg_id': 'msg123',
      'title': 'Tech Workshop',
      'venue': 'Room 101',
      'date': '2024-01-15',
      'time': '10:00 AM',
      'recipient': 'user@university.edu',
      'banner_url': 'https://example.com/banner.jpg',
    };

    test('fromJson creates ClubMail with all fields', () {
      final mail = ClubMail.fromJson(validJson);

      expect(mail.link, 'https://example.com/event');
      expect(mail.sender, 'tech-club@university.edu');
      expect(mail.msgId, 'msg123');
      expect(mail.title, 'Tech Workshop');
      expect(mail.venue, 'Room 101');
      expect(mail.date, '2024-01-15');
      expect(mail.time, '10:00 AM');
      expect(mail.recipient, 'user@university.edu');
      expect(mail.bannerUrl, 'https://example.com/banner.jpg');
    });

    test('fromJson handles missing required fields with defaults', () {
      const minimalJson = <String, dynamic>{
        'link': null,
        'sender': null,
        'msg_id': null,
      };

      final mail = ClubMail.fromJson(minimalJson);

      expect(mail.link, '');
      expect(mail.sender, 'Unknown');
      expect(mail.msgId, '');
      expect(mail.title, 'Club Mail');
      expect(mail.venue, 'N/A');
      expect(mail.date, 'N/A');
      expect(mail.time, 'N/A');
    });

    test('fromJson handles partial data', () {
      const partialJson = {
        'link': 'https://example.com',
        'sender': 'organizer@university.edu',
        'msg_id': 'msg456',
      };

      final mail = ClubMail.fromJson(partialJson);

      expect(mail.link, 'https://example.com');
      expect(mail.sender, 'organizer@university.edu');
      expect(mail.title, 'Club Mail');
      expect(mail.venue, 'N/A');
    });

    test('toJson serializes all fields correctly', () {
      final mail = ClubMail(
        link: 'https://example.com/event',
        sender: 'tech-club@university.edu',
        msgId: 'msg123',
        title: 'Tech Workshop',
        venue: 'Room 101',
        date: '2024-01-15',
        time: '10:00 AM',
        recipient: 'user@university.edu',
        bannerUrl: 'https://example.com/banner.jpg',
      );

      final json = mail.toJson();

      expect(json['link'], 'https://example.com/event');
      expect(json['sender'], 'tech-club@university.edu');
      expect(json['msg_id'], 'msg123');
      expect(json['title'], 'Tech Workshop');
    });

    test('copyWith creates new instance with modified fields', () {
      final original = ClubMail(
        link: 'https://example.com',
        sender: 'club@university.edu',
        msgId: 'msg123',
        title: 'Original Title',
        venue: 'Room 101',
        date: '2024-01-15',
        time: '10:00 AM',
      );

      final modified = original.copyWith(title: 'Modified Title');

      expect(modified.title, 'Modified Title');
      expect(modified.link, original.link);
      expect(modified.sender, original.sender);
    });

    test('equality based on link and msgId', () {
      const json1 = {
        'link': 'https://example.com/event1',
        'sender': 'club1@university.edu',
        'msg_id': 'msg123',
        'title': 'Event 1',
        'venue': 'Room 1',
        'date': '2024-01-15',
        'time': '10:00 AM',
      };

      const json2 = {
        'link': 'https://example.com/event1',
        'sender': 'club2@university.edu',
        'msg_id': 'msg123',
        'title': 'Event 1 Different',
        'venue': 'Room 2',
        'date': '2024-01-16',
        'time': '11:00 AM',
      };

      final mail1 = ClubMail.fromJson(json1);
      final mail2 = ClubMail.fromJson(json2);

      // Same link and msgId = equal
      expect(mail1, mail2);
    });

    test('toString provides readable representation', () {
      const json = {
        'link': 'https://example.com/event',
        'sender': 'tech-club@university.edu',
        'msg_id': 'msg123',
        'title': 'Tech Workshop',
        'venue': 'Room 101',
        'date': '2024-01-15',
        'time': '10:00 AM',
      };

      final mail = ClubMail.fromJson(json);
      final str = mail.toString();

      expect(str, contains('ClubMail'));
      expect(str, contains('Tech Workshop'));
      expect(str, contains('tech-club@university.edu'));
    });
  });
}
