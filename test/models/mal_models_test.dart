import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/models/mal_models.dart';

void main() {
  group('MalModels parsing and type safety', () {
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

    test('MalUser parses correctly with complete and partial data', () {
      final fullJson = {
        'id': 100,
        'name': 'KomorebiUser',
        'picture': 'https://example.com/avatar.png',
        'gender': 'male',
        'birthday': '2000-01-01',
        'location': 'Tokyo',
        'joined_at': '2020-05-10T12:00:00Z',
        'time_zone': 'Asia/Tokyo',
        'is_supporter': true,
      };

      final user = MalUser.fromJson(fullJson);
      expect(user.id, 100);
      expect(user.name, 'KomorebiUser');
      expect(user.picture, 'https://example.com/avatar.png');
      expect(user.gender, 'male');
      expect(user.isSupporter, true);

      // Partial data (only required fields)
      final partialJson = {'id': 101, 'name': 'MinimalUser'};
      final minimalUser = MalUser.fromJson(partialJson);
      expect(minimalUser.id, 101);
      expect(minimalUser.name, 'MinimalUser');
      expect(minimalUser.picture, isNull);
      expect(minimalUser.isSupporter, isNull);
    });

    test('MalUser handles type mismatches (string numbers, string bools)', () {
      final weirdJson = {
        'id': '200', // string instead of int
        'name': 'WeirdUser',
        'is_supporter': 'true', // string instead of bool
      };

      final user = MalUser.fromJson(weirdJson);
      expect(user.id, 200);
      expect(user.name, 'WeirdUser');
      expect(user.isSupporter, true);
    });

    test('MalAnimeListStatus parses correctly with tags and defaults', () {
      final statusJson = {
        'status': 'watching',
        'score': 8,
        'num_episodes_watched': 5,
        'is_rewatching': false,
        'updated_at': '2023-10-01T10:00:00Z',
        'tags': ['action', 'favorite'],
      };

      final status = MalAnimeListStatus.fromJson(statusJson);
      expect(status.status, 'watching');
      expect(status.score, 8);
      expect(status.numEpisodesWatched, 5);
      expect(status.isRewatching, false);
      expect(status.tags, ['action', 'favorite']);
      expect(status.comments, isNull);
    });

    test(
      'MalAnimeNode parses nested pictures, titles, genres, and related anime',
      () {
        final animeJson = {
          'id': 1,
          'title': 'Cowboy Bebop',
          'main_picture': {
            'medium': 'https://example.com/med.jpg',
            'large': 'https://example.com/large.jpg',
          },
          'alternative_titles': {
            'synonyms': ['Bebop'],
            'en': 'Cowboy Bebop',
            'ja': 'カウボーイビバップ',
          },
          'mean': 8.75,
          'rank': 30,
          'popularity': 40,
          'num_episodes': 26,
          'status': 'finished_airing',
          'genres': [
            {'id': 1, 'name': 'Action'},
            {'id': 24, 'name': 'Sci-Fi'},
          ],
          'related_anime': [
            {
              'node': {'id': 5, 'title': 'Cowboy Bebop Movie'},
              'relation_type': 'side_story',
              'relation_type_formatted': 'Side story',
            },
          ],
        };

        final anime = MalAnimeNode.fromJson(animeJson);
        expect(anime.id, 1);
        expect(anime.title, 'Cowboy Bebop');
        expect(anime.mainPicture?.medium, 'https://example.com/med.jpg');
        expect(anime.alternativeTitles?.synonyms, ['Bebop']);
        expect(anime.alternativeTitles?.ja, 'カウボーイビバップ');
        expect(anime.mean, 8.75);
        expect(anime.numEpisodes, 26);
        expect(anime.genres.length, 2);
        expect(anime.genres[0].name, 'Action');
        expect(anime.relatedAnime.length, 1);
        expect(anime.relatedAnime[0].node.title, 'Cowboy Bebop Movie');
        expect(anime.relatedAnime[0].relationTypeFormatted, 'Side story');
      },
    );

    test('MalPaginated parses list items and paging info correctly', () {
      final paginatedJson = {
        'data': [
          {
            'node': {'id': 10, 'title': 'Naruto'},
            'list_status': {
              'status': 'completed',
              'score': 9,
              'num_episodes_watched': 220,
              'is_rewatching': false,
            },
          },
          {
            'node': {'id': 20, 'title': 'Bleach'},
          },
        ],
        'paging': {'next': 'https://api.myanimelist.net/v2/anime?offset=2'},
      };

      final paginated = MalPaginated<MalAnimeListItem>.fromJson(
        paginatedJson,
        (item) => MalAnimeListItem.fromJson(asMap(item)),
      );

      expect(paginated.data.length, 2);
      expect(paginated.data[0].node.title, 'Naruto');
      expect(paginated.data[0].listStatus?.status, 'completed');
      expect(paginated.data[0].listStatus?.numEpisodesWatched, 220);
      expect(paginated.data[1].node.title, 'Bleach');
      expect(paginated.data[1].listStatus, isNull);
      expect(
        paginated.paging?.next,
        'https://api.myanimelist.net/v2/anime?offset=2',
      );
      expect(paginated.paging?.previous, isNull);
    });

    test('MalForumTopicDetail and MalForumPost parse correctly', () {
      final forumJson = {
        'data': {
          'title': 'Episode 1 Discussion',
          'posts': [
            {
              'id': 500,
              'number': 1,
              'created_at': '2023-01-01T12:00:00Z',
              'created_by': {'id': 7, 'name': 'Admin'},
              'body': 'What did you think of episode 1?',
            },
          ],
        },
        'paging': {
          'next': 'https://api.myanimelist.net/v2/forum/topic/1?offset=20',
        },
      };

      final topicDetail = MalForumTopicDetail.fromJson(forumJson);
      expect(topicDetail.title, 'Episode 1 Discussion');
      expect(topicDetail.posts.length, 1);
      expect(topicDetail.posts[0].id, 500);
      expect(topicDetail.posts[0].createdBy?.name, 'Admin');
      expect(topicDetail.posts[0].body, 'What did you think of episode 1?');
      expect(topicDetail.paging?.next, isNotNull);
    });
  });
}
