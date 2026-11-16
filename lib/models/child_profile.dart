import 'recommendation_engine.dart';

class ChildProfile {
  const ChildProfile({
    required this.name,
    required this.grade,
    required this.avatar,
  });

  final String name;
  final int grade;
  final String avatar;

  int get startingCourse =>
      const RecommendationEngine().startingCourseForGrade(grade);

  Map<String, Object> toJson() => {
        'name': name,
        'grade': grade,
        'avatar': avatar,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        name: json['name'] as String,
        grade: json['grade'] as int,
        avatar: json['avatar'] as String,
      );
}
