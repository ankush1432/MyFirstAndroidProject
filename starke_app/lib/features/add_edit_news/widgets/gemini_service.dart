import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:starke_app/core/api/api.dart';

/// AI Service Module using Google Gemini API
/// This module contains all AI-related API calls for the application

class GeminiService {
  // static const String _geminiApiKey = "set decripted Key here"; //String.fromEnvironment("GEMINI_API_KEY");
  // static const String _geminiApiUrl = "https://generativelanguage.googleapis.com/v1beta/models";
  static const String _geminiModel = "gemini-3.1-flash-lite";
  // Or gemini-1.5-pro

  /// Helper function to call Gemini API
  static Future<Map<String, dynamic>> _callGeminiAPI(
      String prompt, String apiKey) async {
    try {
      final requestBody = {
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      };

      final url = Uri.parse(
          "${Api.geminiMetaInfoApi}$_geminiModel:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData["error"]?["message"] ?? "Failed to generate content");
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("Gemini API error: $e");
      rethrow;
    }
  }

  /// Generate meta info
  static Future<Map<String, dynamic>> generateMetaInfo(
      {required String title,
      required BuildContext context,
      String? language,
      String? languageCode,
      bool slugOnly = false,
      required String apiKey}) async {
    try {
      String languageInstruction = "";
      if (language != null && languageCode != null) {
        languageInstruction =
            "\n\nIMPORTANT: Generate all content in $language language ($languageCode). The response MUST be in same language as title.";
      }

      final prompt = """
You are an SEO expert. Generate meta title, description, keywords, and a slug for this news article titled: "$title".$languageInstruction

Return ONLY a JSON object with these fields:
- meta_title
- meta_description
- meta_keywords
- slug

Response must be valid JSON.
""";

      final response = await _callGeminiAPI(prompt, apiKey);
      final responseText =
          response["candidates"][0]["content"]["parts"][0]["text"].trim();

      try {
        return jsonDecode(responseText);
      } catch (_) {
        final match = RegExp(r"\{[\s\S]*\}").firstMatch(responseText);
        if (match != null) {
          return jsonDecode(match.group(0)!);
        }
        return {
          "meta_title": title,
          "meta_description": "Read about $title in our latest news article.",
          "meta_keywords": title.toLowerCase().split(" ").join(","),
          "slug": title
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), "-")
              .replaceAll(RegExp(r'^-|-$'), ""),
        };
      }
    } catch (e) {
      print("AI meta generation error: $e");
      // showSnackBar("Error generating meta information.\n$e", context);
      rethrow;
    }
  }

  /// Summarize description
  static Future<String> summarizeDescription(String description, String apiKey,
      {String language = "English", String languageCode = "en"}) async {
    try {
      if (description.trim().isEmpty) return "";

      final cleanContent =
          description.replaceAll(RegExp(r"<[^>]*>"), "").trim();
      if (cleanContent.isEmpty) return "";

      final prompt = """
You are a skilled content summarizer. Summarize the following news content:

Content: "$cleanContent"

Instructions:
- 200-250 words
- Maintain key facts
- Professional news style
- No explanations, only summary
- IMPORTANT: Generate in $language ($languageCode).

Summary:""";

      final response = await _callGeminiAPI(prompt, apiKey);
      final summary =
          response["candidates"][0]["content"]["parts"][0]["text"].trim();

      String finalSummary =
          summary.replaceAll(RegExp(r"^['\']+|['\']+$"), '').trim();
      return finalSummary;
    } catch (e) {
      print("Summarization error: $e");
      return description.replaceAll(RegExp(r"<[^>]*>"), "").substring(0, 150) +
          "...";
    }
  }
}
