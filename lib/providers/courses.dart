import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/http_exception.dart';
import 'dart:convert';
import '../models/course.dart';
import '../constants.dart';
import '../models/course_detail.dart';
import '../models/section.dart';
import '../models/lesson.dart';

class Courses with ChangeNotifier {
  List<Course> _items = [];
  List<Course> _topItems = [];
  List<CourseDetail> _courseDetailsitems = [];
  final String authToken;

  Courses(this.authToken, this._items, this._topItems);

  List<Course> get items {
    return [..._items];
  }

  CourseDetail get getCourseDetail {
    return _courseDetailsitems.first;
  }

  List<Course> get topItems {
    return [..._topItems];
  }

  int get itemCount {
    return _items.length;
  }

  Course findById(int id) {
    // return _topItems.firstWhere((course) => course.id == id);
    return _items.firstWhere((course) => course.id == id,
        orElse: () => _topItems.firstWhere((course) => course.id == id));
  }

  Future<void> fetchTopCourses() async {
    var url = BASE_URL + '/api/top_courses';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      _topItems = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> fetchCoursesByCategory(int categoryId) async {
    var url = BASE_URL + '/api/category_wise_course?category_id=$categoryId';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }
      // print(extractedData);

      _items = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> fetchCoursesBySearchQuery(String searchQuery) async {
    var url =
        BASE_URL + '/api/courses_by_search_string?search_string=$searchQuery';
    print(url);
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }
      // print(extractedData);

      _items = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> filterCourses(
      String selectedCategory,
      String selectedPrice,
      String selectedLevel,
      String selectedLanguage,
      String selectedRating) async {
    var url = BASE_URL +
        '/api/filter_course?selected_category=$selectedCategory&selected_price=$selectedPrice&selected_level=$selectedLevel&selected_language=$selectedLanguage&selected_rating=$selectedRating';
    print(url);
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }
      print(extractedData);

      _items = buildCourseList(extractedData);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> fetchMyWishlist() async {
    var url = BASE_URL + '/api/my_wishlist?auth_token=$authToken';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }
      // print(extractedData);
      _items = buildCourseList(extractedData);
      print(_items);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  List<Course> buildCourseList(List extractedData) {
    final List<Course> loadedCourses = [];
    extractedData.forEach((courseData) {
      loadedCourses.add(Course(
        id: int.parse(courseData['id']),
        title: courseData['title'],
        thumbnail: courseData['thumbnail'],
        price: courseData['price'],
        instructor: courseData['instructor_name'],
        rating: courseData['rating'],
        totalNumberRating: courseData['number_of_ratings'],
        numberOfEnrollment: courseData['total_enrollment'],
        shareableLink: courseData['shareable_link'],
        courseOverviewProvider: courseData['course_overview_provider'],
        courseOverviewUrl: courseData['video_url'],
      ));
      // print(catData['name']);
    });
    return loadedCourses;
  }

  Future<void> toggleWishlist(int courseId, bool removeItem) async {
    var url = BASE_URL +
        '/api/toggle_wishlist_items?auth_token=$authToken&course_id=$courseId';

    if (!removeItem) {
      _courseDetailsitems.first.isWishlisted
          ? _courseDetailsitems.first.isWishlisted = false
          : _courseDetailsitems.first.isWishlisted = true;
      notifyListeners();
    }
    try {
      final response = await http.get(url);
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'removed') {
        if (removeItem) {
          final existingMyCourseIndex =
              _items.indexWhere((mc) => mc.id == courseId);

          _items.removeAt(existingMyCourseIndex);
          notifyListeners();
        } else {
          _courseDetailsitems.first.isWishlisted = false;
        }
      } else if (responseData['status'] == 'added') {
        if (!removeItem) {
          _courseDetailsitems.first.isWishlisted = true;
        }
      }
      // notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> fetchCourseDetailById(int courseId) async {
    var url = BASE_URL + '/api/course_details_by_id?course_id=$courseId';

    if (authToken != null) {
      url = BASE_URL +
          '/api/course_details_by_id?auth_token=$authToken&course_id=$courseId';
    }

    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as List;
      if (extractedData == null) {
        return;
      }

      final List<CourseDetail> loadedCourseDetails = [];
      extractedData.forEach((courseData) {
        loadedCourseDetails.add(CourseDetail(
          courseId: int.parse(courseData['id']),
          courseIncludes:
              (courseData['includes'] as List<dynamic>).cast<String>(),
          courseRequirements:
              (courseData['requirements'] as List<dynamic>).cast<String>(),
          courseOutcomes:
              (courseData['outcomes'] as List<dynamic>).cast<String>(),
          isWishlisted: courseData['is_wishlisted'],
          isPurchased: (courseData['is_purchased'] is int)
              ? courseData['is_purchased'] == 1 ? true : false
              : courseData['is_purchased'],
          mSection:
              buildCourseSections(courseData['sections'] as List<dynamic>),
        ));
      });
      // print(loadedCourseDetails.first.courseOutcomes.last);
      // _items = buildCourseList(extractedData);
      _courseDetailsitems = loadedCourseDetails;
      // _courseDetail = loadedCourseDetails.first;
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  List<Section> buildCourseSections(List extractedSections) {
    final List<Section> loadedSections = [];

    extractedSections.forEach((sectionData) {
      loadedSections.add(Section(
        id: int.parse(sectionData['id']),
        numberOfCompletedLessons: sectionData['completed_lesson_number'],
        title: sectionData['title'],
        totalDuration: sectionData['total_duration'],
        lessonCounterEnds: sectionData['lesson_counter_ends'],
        lessonCounterStarts: sectionData['lesson_counter_starts'],
        mLesson: buildCourseLessons(sectionData['lessons'] as List<dynamic>),
      ));
    });
    // print(loadedSections.first.title);
    return loadedSections;
  }

  List<Lesson> buildCourseLessons(List extractedLessons) {
    final List<Lesson> loadedLessons = [];

    extractedLessons.forEach((lessonData) {
      loadedLessons.add(Lesson(
        id: int.parse(lessonData['id']),
        title: lessonData['title'],
        duration: lessonData['duration'],
        lessonType: lessonData['lesson_type'],
      ));
    });
    // print(loadedLessons.first.title);
    return loadedLessons;
  }
}
