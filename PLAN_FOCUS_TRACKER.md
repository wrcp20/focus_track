# FocusTrack — Plan de Proyecto
> Alternativa open-source a Rize.io · Flutter Desktop + SQLite + Claude AI

---

## 🎯 Visión General

Aplicación de escritorio que **rastrea automáticamente** el uso de apps/sitios web, categoriza actividades con IA, mide sesiones de foco, y entrega reportes de productividad — todo sin interrumpir el flujo de trabajo y con privacidad total (sin capturas de pantalla, sin keylogging).

### Diferenciadores vs Rize.io
| Feature | Rize.io | FocusTrack |
|---|---|---|
| Precio | $9.99–$39.99/mes | **Gratis / Open-source** |
| IA | Propietaria | **Claude API (configurable)** |
| Datos | Nube | **100% local (SQLite)** |
| Linux | "Próximamente" | **Soportado desde MVP** |
| Código | Cerrado | **Abierto** |

---

## 🏗 Stack Tecnológico

### Core
| Capa | Tecnología |
|---|---|
| UI Framework | Flutter Desktop (Windows/macOS/Linux) |
| Base de datos | SQLite vía `sqflite_common_ffi` |
| Estado | Riverpod 2.x (más robusto que Provider para este caso) |
| IA / Categorización | Claude API (`anthropic` Dart SDK) |
| Gráficas | `fl_chart` |
| Notificaciones | `flutter_local_notifications` |
| Monitoreo de ventanas | FFI nativo (Win32 / Cocoa / X11) |
| System tray | `tray_manager` |
| Startup automático | `launch_at_startup` |

### Monitoreo del Sistema (la parte crítica)
- **Windows**: `dart:ffi` → `GetForegroundWindow()` + `GetWindowText()` + `GetProcessImageFileName()` (Win32 API)
- **macOS**: Method Channel → `NSWorkspace.shared.frontmostApplication` (Swift)
- **Linux**: Method Channel → `xdotool getactivewindow` o `_NET_ACTIVE_WINDOW` via X11

---

## 🗄 Esquema de Base de Datos

```sql
-- Sesiones de actividad rastreadas automáticamente
CREATE TABLE activity_sessions (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  app_name      TEXT    NOT NULL,           -- "Google Chrome", "VS Code"
  window_title  TEXT,                       -- "Stack Overflow - How to..."
  url           TEXT,                       -- Solo para navegadores
  started_at    TEXT    NOT NULL,
  ended_at      TEXT,
  duration_sec  INTEGER,
  category_id   INTEGER REFERENCES categories(id) ON DELETE SET NULL,
  is_productive INTEGER NOT NULL DEFAULT 1  -- 1=productivo, 0=distracción
);

-- Categorías de actividad
CREATE TABLE categories (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,             -- "Programación", "Reuniones"
  color       TEXT    NOT NULL,
  icon        TEXT    NOT NULL,
  is_default  INTEGER NOT NULL DEFAULT 0,
  productive  INTEGER NOT NULL DEFAULT 1
);

-- Reglas de categorización automática
CREATE TABLE tracking_rules (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  pattern     TEXT    NOT NULL,             -- "code.visualstudio.com", "VS Code"
  match_type  TEXT    NOT NULL,             -- 'app', 'url', 'title'
  category_id INTEGER NOT NULL REFERENCES categories(id),
  priority    INTEGER NOT NULL DEFAULT 0
);

-- Sesiones de foco (Pomodoro / manual)
CREATE TABLE focus_sessions (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  started_at   TEXT    NOT NULL,
  ended_at     TEXT,
  target_min   INTEGER NOT NULL DEFAULT 25,
  completed    INTEGER NOT NULL DEFAULT 0,
  notes        TEXT
);

-- Objetivos diarios
CREATE TABLE daily_goals (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  date         TEXT    NOT NULL UNIQUE,     -- "2026-03-23"
  target_hours REAL    NOT NULL DEFAULT 8.0,
  focus_target INTEGER NOT NULL DEFAULT 4   -- sesiones de foco objetivo
);

-- Preferencias
CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

---

## 🏛 Arquitectura (Clean Architecture)

```
lib/
├── core/
│   ├── constants/          # Colores, duraciones, keys de settings
│   ├── services/
│   │   ├── window_tracker_service.dart   # Polling de ventana activa
│   │   ├── browser_extension_server.dart # HTTP local para extensión
│   │   └── claude_ai_service.dart        # Categorización con IA
│   └── utils/
│       └── duration_formatter.dart
│
├── data/
│   ├── datasources/
│   │   ├── activity_session_datasource.dart
│   │   ├── category_datasource.dart
│   │   ├── tracking_rule_datasource.dart
│   │   ├── focus_session_datasource.dart
│   │   └── settings_datasource.dart
│   ├── models/             # TaskModel, CategoryModel, etc. (toMap/fromMap)
│   └── repositories/       # Implementaciones concretas
│
├── domain/
│   ├── entities/           # ActivitySession, Category, FocusSession, Goal
│   ├── repositories/       # Interfaces abstractas
│   └── usecases/
│       ├── get_daily_report.dart
│       ├── auto_categorize_activity.dart
│       └── calculate_focus_score.dart
│
└── presentation/
    ├── providers/           # Riverpod providers
    ├── pages/
    │   ├── dashboard_page.dart      # Vista principal
    │   ├── timeline_page.dart       # Timeline del día
    │   ├── focus_page.dart          # Pomodoro + sesiones de foco
    │   ├── reports_page.dart        # Gráficas y estadísticas
    │   ├── categories_page.dart     # Gestión de categorías y reglas
    │   └── settings_page.dart
    └── widgets/
        ├── activity_timeline.dart
        ├── productivity_ring.dart
        ├── focus_timer_widget.dart
        └── app_usage_bar.dart
```

---

## 📋 Fases de Desarrollo

### Fase 0 — Fundación (1–2 semanas)
- [ ] Inicializar proyecto Flutter Desktop (`flutter create --platforms=windows,macos,linux`)
- [ ] Configurar Clean Architecture + Riverpod
- [ ] Implementar `DatabaseHelper` con esquema completo
- [ ] CRUD de `Category` y `TrackingRule`
- [ ] Pantalla de Settings básica (clave API de Claude, horas laborales)

### Fase 1 — MVP: Rastreo Automático (2–3 semanas)
- [ ] `WindowTrackerService` — polling cada 5s de ventana activa
  - Win32 FFI (`user32.dll` → `GetForegroundWindow`)
  - Method channel para macOS (Swift) y Linux (bash/X11)
- [ ] Detectar cambios de ventana → crear/cerrar `ActivitySession`
- [ ] Reglas de categorización manual (pattern matching)
- [ ] System tray icon con estado en tiempo real
- [ ] `DashboardPage` — resumen del día actual
- [ ] `TimelinePage` — vista cronológica de sesiones

### Fase 2 — Sesiones de Foco (1–2 semanas)
- [ ] `FocusPage` con temporizador Pomodoro configurable (25/5, 50/10, custom)
- [ ] Bloqueo de apps distractoras durante foco (lista configurable)
- [ ] Notificaciones: inicio de pausa, fin de pausa, sesión completada
- [ ] Historial de sesiones de foco
- [ ] `FocusQualityScore` — métrica basada en interrupciones y duración real

### Fase 3 — Reportes y Analíticas (2 semanas)
- [ ] `ReportsPage` con:
  - Gráfica de torta: distribución de tiempo por categoría
  - Gráfica de barras: horas productivas por día (semana/mes)
  - Línea de tiempo: tendencia de foco
  - Top apps/sitios más usados
- [ ] Reporte diario exportable (PDF / CSV)
- [ ] Objetivos diarios con indicador de progreso
- [ ] Racha de días productivos (streak)

### Fase 4 — IA con Claude (1–2 semanas)
- [ ] `ClaudeAIService` — envía nombre de app + título de ventana → obtiene categoría sugerida
- [ ] Auto-categorización al detectar app sin regla (modal de confirmación)
- [ ] Aprendizaje de reglas: si el usuario confirma 3 veces la misma categoría, se crea regla automática
- [ ] Resumen de productividad generado por IA ("Hoy te enfocaste 4h en código, tuviste 3 interrupciones por redes sociales...")
- [ ] Modo offline: fallback a categorización por keywords si no hay API key

### Fase 5 — Extensión de Navegador (2–3 semanas)
- [ ] Extensión Chrome/Firefox (JS) que reporta URL activa vía HTTP local (localhost:27432)
- [ ] `BrowserExtensionServer` en la app — servidor HTTP local con `shelf`
- [ ] Categorización de URLs (YouTube = entretenimiento, GitHub = código, etc.)

### Fase 6 — Features Avanzados (futuro)
- [ ] Integración con Google Calendar / Outlook (mostrar reuniones en timeline)
- [ ] Modo equipo / compartir reportes
- [ ] Exportación a Toggl / Clockify
- [ ] Widget de escritorio (Windows: comWidget, macOS: ScreenSaver widget)
- [ ] Modo privado (pausar tracking temporalmente con hotkey global)

---

## 🔑 Decisiones Técnicas Clave

### 1. Polling vs Hooks para monitoreo
**Decisión: Polling cada 5 segundos**
- Pro: Simple, multiplataforma, no requiere permisos especiales
- Contra: Pequeña imprecisión (máx 5s de error en inicio/fin de sesión)
- Alternativa futura: Event hooks nativos (más preciso pero complejo)

### 2. Categorización sin AI (offline)
Antes de llamar a Claude, aplicar en orden:
1. Reglas exactas de la DB (más rápido, sin costo)
2. Keywords predefinidas por categoría defecto
3. Claude API (solo para apps desconocidas)

### 3. Privacidad
- `window_title` puede contener info sensible (nombre de archivo, URL completa)
- Opción en Settings: "No registrar títulos de ventana"
- Nunca capturar pantalla, keystrokes, ni contenido de ventana
- Todos los datos 100% locales — sin servidor externo (excepto Claude API si se usa)

### 4. Extensión de navegador
La app Flutter abre un servidor HTTP local en `localhost:27432`.
La extensión hace `POST /activity` con `{ url, title, favicon }` cada vez que cambia la pestaña activa.
Esto evita necesitar el título de ventana del sistema para detectar sitios web específicos.

---

## 📐 Modelo de Datos — Entidades Principales

```dart
class ActivitySession {
  final int? id;
  final String appName;
  final String? windowTitle;
  final String? url;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSec;
  final int? categoryId;
  final bool isProductive;
}

class TrackingRule {
  final int? id;
  final String pattern;      // "VS Code", "github.com"
  final String matchType;    // 'app' | 'url' | 'title'
  final int categoryId;
  final int priority;
}

class FocusSession {
  final int? id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int targetMinutes;
  final bool completed;
  final String? notes;
}

// FocusQualityScore (calculado, no persistido)
class FocusQuality {
  final double score;        // 0.0 – 100.0
  final int interruptions;   // cambios de app durante foco
  final Duration realFocus;  // tiempo sin distracciones
  final Duration planned;    // duración objetivo
}
```

---

## 🎨 UI / UX Reference

```
┌─────────────────────────────────────────────────────────────┐
│  FocusTrack                              [_] [□] [×]        │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                   │
│ 📊 Hoy   │   Lunes 23 Mar · 6h 42m trabajadas              │
│          │   ████████████░░░░░░  84% objetivo               │
│ 🎯 Foco  │                                                   │
│          │   Categorías de hoy                              │
│ 📅 Línea │   ████ Programación    3h 20m  (49%)             │
│          │   ██   Reuniones        1h 15m  (19%)            │
│ 📈 Report│   █    Documentación    45m     (11%)            │
│          │   ░░   Redes Sociales   22m      (5%)            │
│ 🏷 Categ │                                                   │
│          │   Focus Score: 78 / 100 ▲ +12 vs ayer           │
│ ⚙ Config │                                                   │
│          │   [▶ Iniciar Sesión de Foco]                     │
└──────────┴──────────────────────────────────────────────────┘
```

---

## ⚡ Quick Start (MVP mínimo funcional)

Para tener algo que muestre datos reales en 1 semana:

1. **WindowTracker** — FFI Win32, polling 5s, guarda en SQLite
2. **Dashboard** — lista de apps usadas hoy con duración
3. **Categorías hardcoded** — 5 categorías por defecto (Código, Navegación, Comunicación, Diseño, Otro)
4. **System tray** — muestra "Rastreando: VS Code · 1h 23m"

Sin AI, sin Pomodoro, sin reportes. Solo tracking automático visible.

---

## 📁 Archivos de Referencia del Proyecto Actual

Este plan parte del TODO App existente en este mismo repositorio:
- Arquitectura Clean Architecture ya establecida → reutilizable
- `DatabaseHelper` con SQLite → extender con nuevas tablas
- `CategoryProvider` → base para `ActivityCategoryProvider`
- `sqflite_common_ffi` + `sqflite_common_ffi_web` ya configurados

---

*Última actualización: 2026-03-23*
