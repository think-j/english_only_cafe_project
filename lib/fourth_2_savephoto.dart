// file: photo_management.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// You might need other imports here if PhotoItem or PhotoDataManager uses them directly,
// but for the core logic of these two classes, json and shared_preferences are key.

// --- PhotoItem Class ---
class PhotoItem {
  String filePath;
  List<String>? subPhotos;
  String? albumName;

  PhotoItem({
    required this.filePath,
    this.subPhotos,
    this.albumName,
  });

  int get totalPhotoCount => 1 + (subPhotos?.length ?? 0);

  Map<String, dynamic> toJson() => {
    'filePath': filePath,
    'subPhotos': subPhotos,
    'albumName': albumName,
  };

  factory PhotoItem.fromJson(Map<String, dynamic> json) => PhotoItem(
    filePath: json['filePath'] as String,
    subPhotos: (json['subPhotos'] as List<dynamic>?)?.map((e) => e as String).toList(),
    albumName: json['albumName'] as String?,
  );
}

// --- PhotoDataManager Class ---
class PhotoDataManager {
  static final PhotoDataManager _instance = PhotoDataManager._internal();
  factory PhotoDataManager() => _instance;

  PhotoDataManager._internal() {
    // Consider loading photos when the manager is first accessed or app starts
    // _loadPhotoItems(); // This would typically be called via initialize()
  }

  final List<PhotoItem> photoItems = [];
  String appTitle = "My Photo Albums";
  bool isEditMode = false; // If you want to persist this, add load/save logic too

  static const String _photoItemsKey = 'photo_items_key';
  static const String _appTitleKey = 'app_title_key';

  Future<void> initialize() async {
    await _loadAppTitle();
    await _loadPhotoItems();
  }

  Future<void> _savePhotoItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> photoItemsJson = photoItems.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_photoItemsKey, photoItemsJson);
    print("Photo items saved!");
  }

  Future<void> _loadPhotoItems() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? photoItemsJson = prefs.getStringList(_photoItemsKey);
    if (photoItemsJson != null) {
      photoItems.clear();
      photoItems.addAll(
          photoItemsJson.map((itemJson) => PhotoItem.fromJson(jsonDecode(itemJson)))
      );
      print("Photo items loaded: ${photoItems.length} albums");
    }
  }

  Future<void> saveAppTitle(String title) async {
    appTitle = title;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appTitleKey, title);
  }

  Future<void> _loadAppTitle() async {
    final prefs = await SharedPreferences.getInstance();
    appTitle = prefs.getString(_appTitleKey) ?? "My Photo Albums";
  }

  void addPhotoItem(PhotoItem item) {
    photoItems.add(item);
    _savePhotoItems();
  }

  void removePhotoItemAt(int index) {
    if (index >= 0 && index < photoItems.length) {
      photoItems.removeAt(index);
      _savePhotoItems();
    }
  }

  void updateAlbumName(int index, String? newName) {
    if (index >= 0 && index < photoItems.length) {
      photoItems[index].albumName = newName;
      _savePhotoItems();
    }
  }

  void addSubPhotosToItem(int index, List<String> newSubPhotoPaths) {
    if (index >= 0 && index < photoItems.length) {
      photoItems[index].subPhotos ??= [];
      photoItems[index].subPhotos!.addAll(newSubPhotoPaths);
      _savePhotoItems();
    }
  }
// Add any other methods from PhotoDataManager here
}