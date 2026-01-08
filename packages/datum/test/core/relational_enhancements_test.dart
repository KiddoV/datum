import 'package:datum/datum.dart';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks/mock_adapters.dart';
import '../mocks/mock_connectivity_checker.dart';

MockConnectivityChecker createMockConnectivityChecker() {
  final checker = MockConnectivityChecker();
  when(() => checker.isConnected).thenAnswer((_) async => true);
  when(() => checker.onStatusChange).thenAnswer((_) => Stream.value(true));
  return checker;
}

class User extends RelationalDatumEntity {
  @override
  final String id;
  @override
  final String userId;
  final String name;
  @override
  final DateTime modifiedAt;
  @override
  final DateTime createdAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  User({
    required this.id,
    required this.name,
    required this.modifiedAt,
    required this.createdAt,
    this.version = 1,
    this.isDeleted = false,
  }) : userId = id;

  @override
  List<Object?> get props => [id, userId, name, modifiedAt, createdAt, version, isDeleted];

  late final Map<String, Relation> _relations = {
    'posts': HasMany<Post>(this, 'userId', cascadeDeleteBehavior: CascadeDeleteBehavior.setNull),
  };

  @override
  Map<String, Relation> get relations => _relations;

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) => {
        'id': id,
        'userId': userId,
        'name': name,
        'modifiedAt': modifiedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'version': version,
        'isDeleted': isDeleted,
      };

  @override
  User copyWith({DateTime? modifiedAt, int? version, bool? isDeleted}) {
    return User(
      id: id,
      name: name,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdAt: createdAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) => null;
}

class Post extends RelationalDatumEntity {
  @override
  final String id;
  @override
  final String userId; // Foreign key
  final String title;
  @override
  final DateTime modifiedAt;
  @override
  final DateTime createdAt;
  @override
  final int version;
  @override
  final bool isDeleted;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.modifiedAt,
    required this.createdAt,
    this.version = 1,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [id, userId, title, modifiedAt, createdAt, version, isDeleted];

  @override
  Map<String, Relation> get relations => {};

  @override
  Map<String, dynamic> toDatumMap({MapTarget target = MapTarget.local}) => {
        'id': id,
        'userId': userId,
        'title': title,
        'modifiedAt': modifiedAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'version': version,
        'isDeleted': isDeleted,
      };

  @override
  Post copyWith({DateTime? modifiedAt, int? version, bool? isDeleted}) {
    return Post(
      id: id,
      userId: userId,
      title: title,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      createdAt: createdAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  Map<String, dynamic>? diff(DatumEntityInterface oldVersion) => null;
}

void main() {
  late DatumManager<User> userManager;
  late MockLocalAdapter<User> userAdapter;
  late MockLocalAdapter<Post> postAdapter;

  final testUser = User(
    id: 'user-1',
    name: 'John',
    modifiedAt: DateTime(2023),
    createdAt: DateTime(2023),
  );

  final testPost = Post(
    id: 'post-1',
    userId: 'user-1',
    title: 'Post 1',
    modifiedAt: DateTime(2023),
    createdAt: DateTime(2023),
  );

  setUpAll(() {
    registerFallbackValue(testUser);
    registerFallbackValue(testPost);
  });

  setUp(() async {
    Datum.resetForTesting();
    userAdapter = MockLocalAdapter<User>()..addLocalItem(testUser.id, testUser);
    postAdapter = MockLocalAdapter<Post>()..addLocalItem(testUser.id, testPost);

    await Datum.initialize(
      config: const DatumConfig(enableLogging: false),
      connectivityChecker: createMockConnectivityChecker(),
      registrations: [
        DatumRegistration<User>(
          localAdapter: userAdapter,
          remoteAdapter: MockRemoteAdapter<User>(),
        ),
        DatumRegistration<Post>(
          localAdapter: postAdapter,
          remoteAdapter: MockRemoteAdapter<Post>(),
        ),
      ],
    );

    userManager = Datum.manager<User>();
  });

  group('Eager Loading', () {
    test('read with eager loading fetches related entities', () async {
      final user = await userManager.read('user-1', withRelated: ['posts']);

      expect(user, isNotNull);
      final posts = (user as User).relations['posts'] as HasMany;
      expect(posts.value, hasLength(1)); // Should be set directly via eager loading
      expect(await posts.fetch(), hasLength(1)); // Should returns same
      expect(posts.value!.first.id, 'post-1');
    });

    test('readAll with eager loading fetches related entities', () async {
      final users = await userManager.readAll(withRelated: ['posts']);

      expect(users, hasLength(1));
      final user = users.first;
      final posts = user.relations['posts'] as HasMany;
      expect(posts.value, hasLength(1));
      expect(posts.value!.first.id, 'post-1');
    });
  });

  group('Cascade Delete Visualization', () {
    test('getDeletePlan returns correct preview for SetNull', () async {
      final preview = await userManager.getDeletePlan('user-1');

      expect(preview, isNotNull);
      expect(preview!.steps, isNotEmpty);

      // Should contain 2 steps: update post and delete user
      expect(preview.steps.length, 2);

      final postStep = preview.steps.firstWhere((s) => s.entityId == 'post-1');
      expect(postStep.action, 'SetNull');
      expect(postStep.details, {'userId': null});

      final userStep = preview.steps.firstWhere((s) => s.entityId == 'user-1');
      expect(userStep.action, 'Delete');
    });
  });

  group('Transactional Relationships', () {
    test('DatumManager exposes transaction method', () async {
      bool transactionExecuted = false;

      await userManager.transaction(() async {
        transactionExecuted = true;
        return true;
      });

      expect(transactionExecuted, isTrue);
    });
  });
}
