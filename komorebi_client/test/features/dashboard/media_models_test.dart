import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/features/dashboard/domain/media_models.dart';

void main() {
  group('MediaItem domain models and helper tests', () {
    test('asMap converts maps safely and handles non-maps', () {
      final validMap = {'id': 1, 'name': 'test'};
      final converted = asMap(validMap);
      expect(converted['id'], 1);
      expect(converted['name'], 'test');

      expect(asMap(null), isEmpty);
      expect(asMap('not a map'), isEmpty);
      expect(asMap(123), isEmpty);
      expect(asMap(['list', 'item']), isEmpty);
    });

    test('MediaItem deserializes normalized sidecar JSON correctly', () {
      final jsonMap = {
        'id': 1,
        'id_mal': 1,
        'provider': 'mal',
        'title': {
          'user_preferred': 'Cowboy Bebop',
          'romanized': 'Cowboy Bebop',
          'english': 'Cowboy Bebop',
          'native': 'カウボーイビバップ',
        },
        'cover_image': {
          'medium': 'https://example.com/med.jpg',
          'large': 'https://example.com/large.jpg',
        },
        'synopsis': 'Bounty hunters in space.',
        'format': 'tv',
        'status': 'finished_airing',
        'mean_score': 8.75,
        'rank': 30,
        'popularity': 40,
        'episodes': 26,
        'genres': ['Action', 'Sci-Fi'],
        'synonyms': ['Bebop'],
        'is_adult': false,
        'list_status': {
          'status': 'watching',
          'score': 9.0,
          'progress': 12,
          'is_rewatching': false,
          'tags': ['favorite'],
          'comments': 'Awesome',
        },
      };

      final item = MediaItem.fromJson(jsonMap);

      expect(item.id, 1);
      expect(item.provider, 'mal');
      expect(item.title.userPreferred, 'Cowboy Bebop');
      expect(item.title.romanized, 'Cowboy Bebop');
      expect(item.title.native, 'カウボーイビバップ');
      expect(item.coverImage.medium, 'https://example.com/med.jpg');
      expect(item.episodes, 26);
      expect(item.genres, ['Action', 'Sci-Fi']);
      expect(item.listStatus?.status, 'watching');
      expect(item.listStatus?.progress, 12);
      expect(item.listStatus?.score, 9.0);
    });

    test('AnimeStatusFilter and MangaStatusFilter formatted values', () {
      expect(AnimeStatusFilter.watching.apiValue, 'watching');
      expect(AnimeStatusFilter.onHold.apiValue, 'on_hold');
      expect(AnimeStatusFilter.planToWatch.apiValue, 'plan_to_watch');

      expect(MangaStatusFilter.reading.apiValue, 'reading');
      expect(MangaStatusFilter.planToRead.apiValue, 'plan_to_read');
    });
  });
}
