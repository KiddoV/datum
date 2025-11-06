import 'package:datum/datum.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_adapters.dart';
import '../mocks/mock_connectivity_checker.dart';

import 'relational_data_test.dart';

void main() {
  group("Direct Relational Test", () {
    late MockDatumManager<User> mockUserManager;
    late MockDatumManager<Post> mockPostManager;
    late MockDatumManager<Profile> mockProfileManager;
    late MockDatumManager<PostTag> mockPostTagManager;

    final testUser = User(
      id: 'user-1',
      name: 'John Doe',
      modifiedAt: DateTime(2023),
      createdAt: DateTime(2023),
    );

    final testPost = Post(
      id: 'post-1',
      userId: 'user-1',
      title: 'Test Post',
      modifiedAt: DateTime(2023),
      createdAt: DateTime(2023),
    );

    final testProfile = Profile(
      id: 'profile-1',
      userId: 'user-1',
      bio: 'Test bio',
      modifiedAt: DateTime(2023),
      createdAt: DateTime(2023),
    );

    final testTag = Tag(
      id: 'tag-1',
      userId: 'user-1',
      name: 'Test Tag',
      modifiedAt: DateTime(2023),
      createdAt: DateTime(2023),
    );

    final testPostTag = PostTag(
      id: 'posttag-1',
      userId: 'user-1',
      postId: 'post-1',
      tagId: 'tag-1',
      modifiedAt: DateTime(2023),
      createdAt: DateTime(2023),
    );

    setUpAll(() {
      registerFallbackValue(
        User(
          id: 'fb',
          name: 'fb',
          modifiedAt: DateTime(0),
          createdAt: DateTime(0),
        ),
      );
      registerFallbackValue(
        Post(
          id: 'fb',
          userId: 'fb',
          title: 'fb',
          modifiedAt: DateTime(0),
          createdAt: DateTime(0),
        ),
      );
      registerFallbackValue(
        Profile(
          id: 'fb',
          userId: 'fb',
          bio: 'fb',
          modifiedAt: DateTime(0),
          createdAt: DateTime(0),
        ),
      );
      registerFallbackValue(
        Tag(
          id: 'fb',
          userId: 'fb',
          name: 'fb',
          modifiedAt: DateTime(0),
          createdAt: DateTime(0),
        ),
      );
      registerFallbackValue(
        PostTag(
          id: 'fb',
          userId: 'fb',
          postId: 'fb',
          tagId: 'fb',
          modifiedAt: DateTime(0),
          createdAt: DateTime(0),
        ),
      );
      registerFallbackValue(
        const DatumQuery(),
      );
      registerFallbackValue(DataSource.local);
    });

    setUp(() {
      Datum.resetForTesting();
      mockUserManager = MockDatumManager<User>();
      mockPostManager = MockDatumManager<Post>();
      mockProfileManager = MockDatumManager<Profile>();
      mockPostTagManager = MockDatumManager<PostTag>();
    });

    group('BelongsTo', () {
      test('constructor initializes correctly without initial value', () {
        final belongsTo = BelongsTo<User>(testPost, 'userId');

        expect(belongsTo.foreignKey, 'userId');
        expect(belongsTo.localKey, 'id');
        expect(belongsTo.value, isNull);
      });

      test('constructor initializes correctly with initial value', () {
        final belongsTo = BelongsTo<User>(testPost, 'userId', value: testUser);

        expect(belongsTo.foreignKey, 'userId');
        expect(belongsTo.localKey, 'id');
        expect(belongsTo.value, testUser);
      });

      test('constructor with custom localKey', () {
        final belongsTo = BelongsTo<User>(testPost, 'userId', localKey: 'customId');

        expect(belongsTo.localKey, 'customId');
      });

      test('value getter returns cached value', () {
        final belongsTo = BelongsTo<User>(testPost, 'userId', value: testUser);

        expect(belongsTo.value, testUser);
      });

      test('set method updates value', () {
        final belongsTo = BelongsTo<User>(testPost, 'userId');

        belongsTo.set(testUser);

        expect(belongsTo.value, testUser);
      });

      test('fetch returns cached value when already loaded', () async {
        final belongsTo = BelongsTo<User>(testPost, 'userId', value: testUser);

        final result = await belongsTo.fetch();

        expect(result, testUser);
        verifyNever(() => mockUserManager.read(any(), userId: any(named: 'userId')));
      });

      test('getRelatedManager returns correct manager', () async {
        await Datum.initialize(
          config: const DatumConfig(enableLogging: false),
          connectivityChecker: MockConnectivityChecker(),
          registrations: [
            DatumRegistration<User>(
              localAdapter: MockLocalAdapter<User>()..addLocalItem(testUser.id, testUser),
              remoteAdapter: MockRemoteAdapter<User>(),
            ),
          ],
        );

        final belongsTo = BelongsTo<User>(testPost, 'userId');

        final manager = belongsTo.getRelatedManager();

        expect(manager, isA<DatumManager<User>>());
      });
    });

    group('HasMany', () {
      test('constructor initializes correctly without initial value', () {
        final hasMany = HasMany<Post>(testUser, 'userId');

        expect(hasMany.foreignKey, 'userId');
        expect(hasMany.localKey, 'id');
        expect(hasMany.value, isNull);
      });

      test('constructor initializes correctly with initial value', () {
        final posts = [testPost];
        final hasMany = HasMany<Post>(testUser, 'userId', value: posts);

        expect(hasMany.foreignKey, 'userId');
        expect(hasMany.localKey, 'id');
        expect(hasMany.value, posts);
      });

      test('constructor with custom localKey', () {
        final hasMany = HasMany<Post>(testUser, 'userId', localKey: 'customId');

        expect(hasMany.localKey, 'customId');
      });

      test('value getter returns cached value', () {
        final posts = [testPost];
        final hasMany = HasMany<Post>(testUser, 'userId', value: posts);

        expect(hasMany.value, posts);
      });

      test('set method updates value', () {
        final hasMany = HasMany<Post>(testUser, 'userId');
        final posts = [testPost];

        hasMany.set(posts);

        expect(hasMany.value, posts);
      });

      test('fetch returns cached value when already loaded', () async {
        final posts = [testPost];
        final hasMany = HasMany<Post>(testUser, 'userId', value: posts);

        final result = await hasMany.fetch();

        expect(result, posts);
        verifyNever(() => mockPostManager.query(any(), source: any(named: 'source'), userId: any(named: 'userId')));
      });

      test('getRelatedManager returns correct manager', () async {
        await Datum.initialize(
          config: const DatumConfig(enableLogging: false),
          connectivityChecker: MockConnectivityChecker(),
          registrations: [
            DatumRegistration<Post>(
              localAdapter: MockLocalAdapter<Post>()..addLocalItem(testUser.id, testPost),
              remoteAdapter: MockRemoteAdapter<Post>(),
            ),
          ],
        );

        final hasMany = HasMany<Post>(testUser, 'userId');

        final manager = hasMany.getRelatedManager();

        expect(manager, isA<DatumManager<Post>>());
      });
    });

    group('HasOne', () {
      test('constructor initializes correctly without initial value', () {
        final hasOne = HasOne<Profile>(testUser, 'userId');

        expect(hasOne.foreignKey, 'userId');
        expect(hasOne.localKey, 'id');
        expect(hasOne.value, isNull);
      });

      test('constructor initializes correctly with initial value', () {
        final hasOne = HasOne<Profile>(testUser, 'userId', value: testProfile);

        expect(hasOne.foreignKey, 'userId');
        expect(hasOne.localKey, 'id');
        expect(hasOne.value, testProfile);
      });

      test('constructor with custom localKey', () {
        final hasOne = HasOne<Profile>(testUser, 'userId', localKey: 'customId');

        expect(hasOne.localKey, 'customId');
      });

      test('value getter returns cached value', () {
        final hasOne = HasOne<Profile>(testUser, 'userId', value: testProfile);

        expect(hasOne.value, testProfile);
      });

      test('set method updates value', () {
        final hasOne = HasOne<Profile>(testUser, 'userId');

        hasOne.set(testProfile);

        expect(hasOne.value, testProfile);
      });

      test('fetch returns cached value when already loaded', () async {
        final hasOne = HasOne<Profile>(testUser, 'userId', value: testProfile);

        final result = await hasOne.fetch();

        expect(result, testProfile);
        verifyNever(() => mockProfileManager.read(any(), userId: any(named: 'userId')));
      });

      test('getRelatedManager returns correct manager', () async {
        await Datum.initialize(
          config: const DatumConfig(enableLogging: false),
          connectivityChecker: MockConnectivityChecker(),
          registrations: [
            DatumRegistration<Profile>(
              localAdapter: MockLocalAdapter<Profile>()..addLocalItem(testUser.id, testProfile),
              remoteAdapter: MockRemoteAdapter<Profile>(),
            ),
          ],
        );

        final hasOne = HasOne<Profile>(testUser, 'userId');

        final manager = hasOne.getRelatedManager();

        expect(manager, isA<DatumManager<Profile>>());
      });
    });

    group('ManyToMany', () {
      test('constructor initializes correctly without initial value', () {
        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId');

        expect(manyToMany.pivotEntity, testPostTag);
        expect(manyToMany.thisForeignKey, 'tagId');
        expect(manyToMany.otherForeignKey, 'postId');
        expect(manyToMany.thisLocalKey, 'id');
        expect(manyToMany.otherLocalKey, 'id');
        expect(manyToMany.value, isNull);
      });

      test('constructor initializes correctly with initial value', () {
        final posts = [testPost];
        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId', value: posts);

        expect(manyToMany.pivotEntity, testPostTag);
        expect(manyToMany.thisForeignKey, 'tagId');
        expect(manyToMany.otherForeignKey, 'postId');
        expect(manyToMany.thisLocalKey, 'id');
        expect(manyToMany.otherLocalKey, 'id');
        expect(manyToMany.value, posts);
      });

      test('constructor with custom keys', () {
        final manyToMany = ManyToMany<Post>(
          testTag,
          testPostTag,
          'tagId',
          'postId',
          thisLocalKey: 'customThis',
          otherLocalKey: 'customOther',
        );

        expect(manyToMany.thisLocalKey, 'customThis');
        expect(manyToMany.otherLocalKey, 'customOther');
      });

      test('value getter returns cached value', () {
        final posts = [testPost];
        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId', value: posts);

        expect(manyToMany.value, posts);
      });

      test('set method updates value', () {
        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId');
        final posts = [testPost];

        manyToMany.set(posts);

        expect(manyToMany.value, posts);
      });

      test('fetch returns cached value when already loaded', () async {
        final posts = [testPost];
        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId', value: posts);

        final result = await manyToMany.fetch();

        expect(result, posts);
        verifyNever(() => mockPostTagManager.query(any(), source: any(named: 'source'), userId: any(named: 'userId')));
      });

      test('getRelatedManager returns correct manager', () async {
        await Datum.initialize(
          config: const DatumConfig(enableLogging: false),
          connectivityChecker: MockConnectivityChecker(),
          registrations: [
            DatumRegistration<Post>(
              localAdapter: MockLocalAdapter<Post>()..addLocalItem(testUser.id, testPost),
              remoteAdapter: MockRemoteAdapter<Post>(),
            ),
          ],
        );

        final manyToMany = ManyToMany<Post>(testTag, testPostTag, 'tagId', 'postId');

        final manager = manyToMany.getRelatedManager();

        expect(manager, isA<DatumManager<Post>>());
      });
    });
  });
}
