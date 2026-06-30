// lib/features/home/quick_links_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =========================================================
// 1. QUICK LINK MODEL
// එක Shortcut එකක තියෙන විස්තර (නම, ලින්ක් එක, අයිකන් එක, පාට)
// =========================================================
class QuickLink {
  final String id;
  final String name;
  final String url;
  final int iconCode; 
  final int colorValue; 

  QuickLink({
    required this.id,
    required this.name,
    required this.url,
    required this.iconCode,
    required this.colorValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  factory QuickLink.fromMap(Map<String, dynamic> map) {
    return QuickLink(
      id: map['id'],
      name: map['name'],
      url: map['url'],
      iconCode: map['iconCode'],
      colorValue: map['colorValue'],
    );
  }
}

// =========================================================
// 2. QUICK LINKS NOTIFIER
// ඇඩ් කරන, මකන, එඩිට් කරන ප්‍රධාන ලොජික් එක
// =========================================================
class QuickLinksNotifier extends StateNotifier<List<QuickLink>> {
  QuickLinksNotifier() : super([]) {
    _loadLinks();
  }

  // --- අලුත් වෙනස: .value වෙනුවට .toARGB32() යොදා ඇත ---
  final List<QuickLink> _defaultLinks = [
    QuickLink(id: '1', name: 'YouTube', url: 'https://m.youtube.com', iconCode: Icons.play_circle_filled.codePoint, colorValue: Colors.red.toARGB32()),
    QuickLink(id: '2', name: 'Facebook', url: 'https://m.facebook.com', iconCode: Icons.facebook.codePoint, colorValue: Colors.blue.toARGB32()),
    QuickLink(id: '3', name: 'Instagram', url: 'https://www.instagram.com', iconCode: Icons.camera_alt.codePoint, colorValue: Colors.purple.toARGB32()),
    QuickLink(id: '4', name: 'TikTok', url: 'https://www.tiktok.com', iconCode: Icons.music_note.codePoint, colorValue: Colors.black.toARGB32()),
  ];

  Future<void> _loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedLinks = prefs.getString('saved_quick_links');

    if (savedLinks != null) {
      final List<dynamic> decoded = json.decode(savedLinks);
      state = decoded.map((item) => QuickLink.fromMap(item)).toList();
    } else {
      state = _defaultLinks; 
      _saveLinks(state);
    }
  }

  Future<void> addLink(String name, String url) async {
    final newLink = QuickLink(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      url: url,
      iconCode: Icons.language.codePoint, 
      // --- අලුත් වෙනස: .value වෙනුවට .toARGB32() යොදා ඇත ---
      colorValue: Colors.blueGrey.toARGB32(), 
    );
    state = [...state, newLink];
    await _saveLinks(state);
  }

  Future<void> editLink(String id, String newName, String newUrl) async {
    state = state.map((link) {
      if (link.id == id) {
        return QuickLink(id: link.id, name: newName, url: newUrl, iconCode: link.iconCode, colorValue: link.colorValue);
      }
      return link;
    }).toList();
    await _saveLinks(state);
  }

  Future<void> deleteLink(String id) async {
    state = state.where((link) => link.id != id).toList();
    await _saveLinks(state);
  }

  Future<void> _saveLinks(List<QuickLink> links) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(links.map((link) => link.toMap()).toList());
    await prefs.setString('saved_quick_links', encoded);
  }
}

// =========================================================
// 3. PROVIDER EXPORT
// =========================================================
final quickLinksProvider = StateNotifierProvider<QuickLinksNotifier, List<QuickLink>>((ref) {
  return QuickLinksNotifier();
});