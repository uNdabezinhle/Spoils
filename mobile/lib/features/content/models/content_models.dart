class StaticPageModel {
  const StaticPageModel({
    required this.pageType,
    required this.title,
    required this.content,
  });

  final String pageType;
  final String title;
  final String content;

  factory StaticPageModel.fromJson(Map<String, dynamic> json) {
    return StaticPageModel(
      pageType: json['page_type'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }
}

class FaqModel {
  const FaqModel({
    required this.id,
    required this.question,
    required this.answer,
  });

  final int id;
  final String question;
  final String answer;

  factory FaqModel.fromJson(Map<String, dynamic> json) {
    return FaqModel(
      id: json['id'] as int,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}