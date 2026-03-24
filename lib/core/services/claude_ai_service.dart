import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de IA usando Claude API (Anthropic).
/// Proporciona:
///   - categorizeApp(): keyword fallback offline + Claude API para apps desconocidas
///   - generateDailySummary(): resumen motivador de la jornada
class ClaudeAIService {
  static const _apiBase = 'https://api.anthropic.com/v1/messages';
  static const _apiVersion = '2023-06-01';
  // Haiku para categorización rápida y barata; Opus para resúmenes de calidad
  static const _catModel = 'claude-haiku-4-5';
  static const _summaryModel = 'claude-opus-4-6';

  final String? apiKey;

  const ClaudeAIService(this.apiKey);

  bool get hasApiKey => apiKey != null && apiKey!.trim().isNotEmpty;

  // ── Keyword fallback (sin API, gratis) ─────────────────────────────────────

  ({String category, bool isProductive})? _keywordMatch(
      String appName, String? windowTitle, {String? url}) {
    final lower = appName.toLowerCase();
    final title = (windowTitle ?? '').toLowerCase();
    final u = (url ?? '').toLowerCase();

    // ── URL-specific matching (más preciso que app name) ────────────────────
    if (u.isNotEmpty) {
      const codeUrls = [
        'github.com', 'gitlab.com', 'bitbucket.org', 'stackoverflow.com',
        'developer.mozilla.org', 'docs.flutter.dev', 'pub.dev',
        'npmjs.com', 'pypi.org', 'crates.io', 'pkg.go.dev',
        'codepen.io', 'jsfiddle.net', 'codesandbox.io', 'replit.com',
        'leetcode.com', 'hackerrank.com', 'codeforces.com',
      ];
      if (codeUrls.any(u.contains)) {
        return (category: 'Programación', isProductive: true);
      }

      const productivityUrls = [
        'notion.so', 'docs.google.com', 'sheets.google.com',
        'slides.google.com', 'drive.google.com', 'trello.com',
        'asana.com', 'clickup.com', 'linear.app', 'monday.com',
        'airtable.com', 'basecamp.com', 'confluence.atlassian.com',
        'jira.atlassian.com', 'figma.com', 'miro.com',
      ];
      if (productivityUrls.any(u.contains)) {
        return (category: 'Productividad', isProductive: true);
      }

      const commUrls = [
        'mail.google.com', 'outlook.live.com', 'outlook.office.com',
        'meet.google.com', 'zoom.us', 'teams.microsoft.com',
        'web.telegram.org', 'web.whatsapp.com', 'slack.com',
        'discord.com', 'mattermost.com',
      ];
      if (commUrls.any(u.contains)) {
        return (category: 'Comunicación', isProductive: true);
      }

      const entertainmentUrls = [
        'youtube.com', 'netflix.com', 'twitch.tv', 'hulu.com',
        'disneyplus.com', 'primevideo.com', 'crunchyroll.com',
        'plex.tv', 'open.spotify.com',
      ];
      if (entertainmentUrls.any(u.contains)) {
        return (category: 'Entretenimiento', isProductive: false);
      }

      const socialUrls = [
        'twitter.com', 'x.com', 'facebook.com', 'instagram.com',
        'tiktok.com', 'reddit.com', 'pinterest.com', 'tumblr.com',
        'mastodon.social', 'threads.net', 'linkedin.com',
      ];
      if (socialUrls.any(u.contains)) {
        return (category: 'Redes Sociales', isProductive: false);
      }
    }

    const codeApps = [
      'code', 'vscode', 'visual studio', 'intellij', 'android studio',
      'xcode', 'vim', 'nvim', 'neovim', 'sublime', 'cursor', 'fleet',
      'rider', 'clion', 'webstorm', 'datagrip', 'pycharm', 'goland',
      'rubymine', 'phpstorm', 'atom', 'brackets', 'notepad++', 'emacs'
    ];
    if (codeApps.any(lower.contains)) {
      return (category: 'Programación', isProductive: true);
    }

    const officeApps = [
      'word', 'excel', 'powerpoint', 'sheets', 'docs', 'slides',
      'notion', 'obsidian', 'onenote', 'confluence', 'jira', 'trello',
      'asana', 'clickup', 'linear', 'monday', 'airtable', 'basecamp'
    ];
    if (officeApps.any((k) => lower.contains(k) || title.contains(k))) {
      return (category: 'Productividad', isProductive: true);
    }

    const commApps = [
      'slack', 'teams', 'discord', 'zoom', 'skype', 'telegram',
      'whatsapp', 'outlook', 'thunderbird', 'mail', 'gmail',
      'meet', 'webex', 'mattermost', 'signal'
    ];
    if (commApps.any(lower.contains)) {
      return (category: 'Comunicación', isProductive: true);
    }

    const designApps = [
      'figma', 'sketch', 'photoshop', 'illustrator', 'canva',
      'affinity', 'blender', 'inkscape', 'gimp', 'procreate', 'framer',
      'zeplin', 'invision', 'principle', 'origami'
    ];
    if (designApps.any(lower.contains)) {
      return (category: 'Diseño', isProductive: true);
    }

    const entertainmentKeywords = [
      'youtube', 'netflix', 'twitch', 'hulu', 'disney', 'spotify',
      'vlc', 'media player', 'prime video', 'crunchyroll', 'plex'
    ];
    if (entertainmentKeywords.any((k) => lower.contains(k) || title.contains(k))) {
      return (category: 'Entretenimiento', isProductive: false);
    }

    const socialKeywords = [
      'twitter', 'facebook', 'instagram', 'tiktok', 'reddit',
      'x.com', 'snapchat', 'pinterest', 'tumblr', 'mastodon'
    ];
    if (socialKeywords.any((k) => lower.contains(k) || title.contains(k))) {
      return (category: 'Redes Sociales', isProductive: false);
    }

    const browserApps = [
      'chrome', 'firefox', 'edge', 'safari', 'opera', 'brave', 'arc', 'vivaldi'
    ];
    if (browserApps.any(lower.contains)) {
      return (category: 'Navegación', isProductive: true);
    }

    return null;
  }

  // ── Categorización con Claude API ─────────────────────────────────────────

  /// Retorna la categoría y si es productiva.
  /// Primero intenta keyword matching offline; si no hay match, llama a Claude.
  Future<({String category, bool isProductive})?> categorizeApp(
      String appName, String? windowTitle, List<String> availableCategories,
      {String? url}) async {
    // 1. Keyword fallback (sin costo, instantáneo)
    final fallback = _keywordMatch(appName, windowTitle, url: url);
    if (fallback != null) return fallback;

    // 2. Claude API (solo si hay API key)
    if (!hasApiKey) return null;

    final catList = availableCategories.take(10).join(', ');
    final prompt = '''Categoriza esta aplicación para un tracker de productividad.

App: $appName
Título de ventana: ${windowTitle ?? 'N/A'}
URL: ${url ?? 'N/A'}
Categorías disponibles: $catList

Responde SOLO con JSON válido (sin markdown): {"category": "nombre", "is_productive": true}
Elige la categoría más apropiada de la lista. Si ninguna encaja, elige la más cercana.''';

    try {
      final resp = await http
          .post(
            Uri.parse(_apiBase),
            headers: {
              'x-api-key': apiKey!,
              'anthropic-version': _apiVersion,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': _catModel,
              'max_tokens': 100,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final text =
            (data['content'] as List).first['text'] as String;
        final clean =
            text.replaceAll(RegExp(r'```json?|```'), '').trim();
        final json = jsonDecode(clean) as Map<String, dynamic>;
        return (
          category: json['category'] as String,
          isProductive: (json['is_productive'] as bool?) ?? true,
        );
      }
    } catch (_) {}
    return null;
  }

  // ── Resumen diario con Claude API ─────────────────────────────────────────

  /// Genera un resumen motivador de la jornada en español (máx. 3 oraciones).
  Future<String?> generateDailySummary({
    required String date,
    required Duration totalTime,
    required Duration productiveTime,
    required int focusSessionCount,
    required List<String> topApps,
  }) async {
    if (!hasApiKey) return null;

    final totalPct = totalTime.inSeconds > 0
        ? (productiveTime.inSeconds * 100 / totalTime.inSeconds).round()
        : 0;

    final prompt = '''Genera un resumen breve y motivador de esta jornada laboral en español. Máximo 3 oraciones cortas.

Fecha: $date
Tiempo activo: ${_fmtDuration(totalTime)}
Tiempo productivo: ${_fmtDuration(productiveTime)} ($totalPct%)
Sesiones de foco completadas: $focusSessionCount
Apps más usadas: ${topApps.take(4).join(', ')}

Sé directo, positivo y útil. Menciona un logro concreto y una sugerencia de mejora.''';

    try {
      final resp = await http
          .post(
            Uri.parse(_apiBase),
            headers: {
              'x-api-key': apiKey!,
              'anthropic-version': _apiVersion,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': _summaryModel,
              'max_tokens': 250,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['content'] as List).first['text'] as String;
      }
    } catch (_) {}
    return null;
  }

  String _fmtDuration(Duration d) =>
      '${d.inHours}h ${d.inMinutes % 60}m';
}
