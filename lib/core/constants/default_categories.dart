/// Categorías predefinidas que se insertan al crear la DB
const List<Map<String, dynamic>> kDefaultCategories = [
  {
    'name': 'Programación',
    'color': '#6366F1',
    'icon': 'code',
    'productive': 1,
  },
  {
    'name': 'Reuniones',
    'color': '#8B5CF6',
    'icon': 'meeting',
    'productive': 1,
  },
  {
    'name': 'Comunicación',
    'color': '#06B6D4',
    'icon': 'chat',
    'productive': 1,
  },
  {
    'name': 'Diseño',
    'color': '#F59E0B',
    'icon': 'design',
    'productive': 1,
  },
  {
    'name': 'Navegación',
    'color': '#10B981',
    'icon': 'browser',
    'productive': 1,
  },
  {
    'name': 'Redes Sociales',
    'color': '#EC4899',
    'icon': 'social',
    'productive': 0,
  },
  {
    'name': 'Entretenimiento',
    'color': '#F97316',
    'icon': 'entertainment',
    'productive': 0,
  },
  {
    'name': 'Otro',
    'color': '#6B7280',
    'icon': 'other',
    'productive': 1,
  },
];

/// Reglas de categorización automática por defecto
const List<Map<String, dynamic>> kDefaultRules = [
  // Programación
  {'pattern': 'visual studio code', 'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'code.exe',           'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'android studio',     'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'intellij',           'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'pycharm',            'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'xcode',              'match_type': 'app', 'category_name': 'Programación', 'priority': 10},
  {'pattern': 'github.com',         'match_type': 'url', 'category_name': 'Programación', 'priority': 8},
  {'pattern': 'gitlab.com',         'match_type': 'url', 'category_name': 'Programación', 'priority': 8},
  {'pattern': 'stackoverflow.com',  'match_type': 'url', 'category_name': 'Programación', 'priority': 8},

  // Comunicación
  {'pattern': 'slack',              'match_type': 'app', 'category_name': 'Comunicación', 'priority': 10},
  {'pattern': 'microsoft teams',    'match_type': 'app', 'category_name': 'Reuniones',    'priority': 10},
  {'pattern': 'zoom',               'match_type': 'app', 'category_name': 'Reuniones',    'priority': 10},
  {'pattern': 'meet.google.com',    'match_type': 'url', 'category_name': 'Reuniones',    'priority': 10},
  {'pattern': 'mail.google.com',    'match_type': 'url', 'category_name': 'Comunicación', 'priority': 8},
  {'pattern': 'outlook',            'match_type': 'app', 'category_name': 'Comunicación', 'priority': 8},

  // Diseño
  {'pattern': 'figma',              'match_type': 'app', 'category_name': 'Diseño', 'priority': 10},
  {'pattern': 'figma.com',          'match_type': 'url', 'category_name': 'Diseño', 'priority': 10},
  {'pattern': 'photoshop',          'match_type': 'app', 'category_name': 'Diseño', 'priority': 10},
  {'pattern': 'illustrator',        'match_type': 'app', 'category_name': 'Diseño', 'priority': 10},

  // Redes Sociales
  {'pattern': 'twitter.com',        'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},
  {'pattern': 'x.com',              'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},
  {'pattern': 'facebook.com',       'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},
  {'pattern': 'instagram.com',      'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},
  {'pattern': 'linkedin.com',       'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},
  {'pattern': 'reddit.com',         'match_type': 'url', 'category_name': 'Redes Sociales', 'priority': 10},

  // Entretenimiento
  {'pattern': 'youtube.com',        'match_type': 'url', 'category_name': 'Entretenimiento', 'priority': 10},
  {'pattern': 'netflix.com',        'match_type': 'url', 'category_name': 'Entretenimiento', 'priority': 10},
  {'pattern': 'spotify',            'match_type': 'app', 'category_name': 'Entretenimiento', 'priority': 8},
];
