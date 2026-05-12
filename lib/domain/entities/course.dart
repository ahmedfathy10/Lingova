import 'package:flutter/material.dart';

class Course {
  final String title;
  final String level;
  final String price;
  final String levelBadge;
  final IconData icon;
  final String language;
  final String lessonsCount;
  final String duration;
  final String description;
  final String imageDataUrl;
  final List<String> learningOutcomes;

  const Course({
    required this.title,
    required this.level,
    required this.price,
    required this.levelBadge,
    required this.icon,
    required this.language,
    required this.lessonsCount,
    required this.duration,
    required this.description,
    this.imageDataUrl = '',
    this.learningOutcomes = const [],
  });
}
