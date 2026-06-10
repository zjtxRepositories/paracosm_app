import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/moment_post_model.dart';
import 'package:paracosm/core/models/social_Invitation_model.dart';
import 'package:paracosm/core/models/social_review_model.dart';
import 'package:paracosm/core/models/user_display_model.dart';
import 'package:paracosm/modules/im/listener/user_display_state_center.dart';
import 'package:paracosm/pages/moments/moment_comments_section.dart';
import 'package:paracosm/widgets/base/app_localizations.dart';
import 'package:rongcloud_im_wrapper_plugin/rongcloud_im_wrapper_plugin.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    UserDisplayStateCenter().resetForTesting();
  });

  tearDown(() {
    UserDisplayStateCenter().resetForTesting();
  });

  test('MomentsResolver uses social user_id directly as IM user id', () async {
    const userId = '0x1111111111111111111111111111111111111111';
    UserDisplayStateCenter().updateUserProfile(
      RCIMIWUserProfile.create(userId: userId, name: 'Direct User'),
    );
    final post = MomentPostModel(item: _invitation(userId: userId));

    await MomentsResolver().resolve([post]);

    expect(post.user?.userId, userId);
    expect(post.user?.name, 'Direct User');
  });

  testWidgets('comment replies render their own user profile', (tester) async {
    final parent = SocialReviewModel(
      'review-parent',
      'parent-user',
      'note-1',
      0,
      'parent content',
      '',
      [
        SocialReviewModel(
          'review-child',
          'child-user',
          'note-1',
          0,
          'child content',
          'parent-user',
          const [],
          userFullInfo: UserDisplayModel(
            profile: RCIMIWUserProfile.create(
              userId: 'child-user',
              name: 'Child Name',
            ),
          ),
        ),
      ],
      userFullInfo: UserDisplayModel(
        profile: RCIMIWUserProfile.create(
          userId: 'parent-user',
          name: 'Parent Name',
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh'), Locale('en')],
        locale: const Locale('zh'),
        home: Scaffold(
          body: MomentCommentsSection(noteId: 'note-1', reviews: [parent]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parent Name'), findsOneWidget);
    expect(find.text('Child Name'), findsOneWidget);
  });
}

SocialInvitationModel _invitation({required String userId}) {
  return SocialInvitationModel(
    'note-1',
    userId,
    0,
    '',
    '',
    '',
    false,
    0,
    const [],
    0,
    0,
    0,
    0,
    0,
    false,
    false,
    const [],
  );
}
