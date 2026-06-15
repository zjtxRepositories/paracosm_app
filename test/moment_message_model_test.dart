import 'package:flutter_test/flutter_test.dart';
import 'package:paracosm/core/models/moment_message_model.dart';

void main() {
  group('MomentMessageModel', () {
    test('优先使用 action 字段', () {
      final model = MomentMessageModel.fromJson({
        'type': 1,
        'action': 'follow',
        'from': '0xfan',
      });

      expect(model.action, MomentMessageAction.follow);
    });

    test('兼容老数据中的字符串 data', () {
      final model = MomentMessageModel.fromJson({'type': 0, 'data': 'like'});

      expect(model.action, MomentMessageAction.like);
    });

    test('action 缺失时按 type 推断', () {
      final review = MomentMessageModel.fromJson({
        'type': '3',
        'review_id': 'review_xxx',
        'content': '评论内容',
      });
      final collect = MomentMessageModel.fromJson({'type': 2});

      expect(review.action, MomentMessageAction.review);
      expect(review.reviewId, 'review_xxx');
      expect(review.content, '评论内容');
      expect(collect.action, MomentMessageAction.collect);
    });
  });
}
