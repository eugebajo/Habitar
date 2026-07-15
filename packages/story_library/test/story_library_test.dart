import 'package:habitar_story_library/story_library.dart';
import 'package:test/test.dart';

void main() {
  test('provides three demo stories for the MVP', () {
    final stories = demoStoryContent();

    expect(stories, hasLength(3));
    expect(stories.every((content) => content.questions.isNotEmpty), isTrue);
    expect(stories.every((content) => content.activity.isNotEmpty), isTrue);
  });
}
