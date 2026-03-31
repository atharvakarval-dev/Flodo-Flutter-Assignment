# Flodo — Task Management App

A local-first Flutter task manager built for the Flodo AI take-home assignment. Focused on clean architecture, polished UI/UX, and reactive state management.

---

## Track & Stretch Goal

- **Track chosen:** Track B — Mobile Specialist (Flutter + local persistence, no backend)
- **Stretch goal chosen:** Debounced Autocomplete Search with inline text highlighting

---

## Setup Instructions

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | 3.10.0 or later (stable channel) |
| Dart SDK | 3.0.0 or later (bundled with Flutter) |
| Android Studio / Xcode | For emulator or physical device |

### Steps

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd task
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   # On a connected device or emulator
   flutter run

   # Target a specific platform explicitly
   flutter run -d android
   flutter run -d ios
   ```

4. **Build a release APK (optional)**
   ```bash
   flutter build apk --release
   ```

> No environment variables, API keys, or backend setup required. All data is stored locally via SharedPreferences.

---

## Architecture

Clean Architecture with strict layer boundaries:

```
lib/
  core/
    constants/        # AppColors, AppSpacing
    theme/            # AppTheme (Material 3 + custom overrides)
    utils/            # Debouncer, DateFormatter
  features/
    tasks/
      data/
        datasources/  # TaskLocalDataSourceImpl (SharedPreferences)
        models/       # TaskModel (JSON serialization)
        repositories/ # TaskRepositoryImpl
      domain/
        entities/     # TaskEntity, TaskStatus, TaskPriority, TaskGroup
        repositories/ # TaskRepository (abstract contract)
        usecases/     # CreateTask, UpdateTask, DeleteTask, GetTasks
      presentation/
        providers/    # Riverpod providers + TasksNotifier
        screens/      # HomeScreen, TaskListScreen, TaskFormScreen, OnboardingScreen
        widgets/      # TaskCardWidget, HighlightedText, StatusBadge, etc.
  main.dart
```

**State management:** Riverpod — providers are composable, async-first, and integrate cleanly with use case boundaries.

**Persistence:** SharedPreferences — tasks serialized as JSON, draft form state persisted separately.

---

## Features Implemented

### Core Requirements
- Full CRUD — create, read, update, delete tasks
- Task fields: title, description, due date, status (To-Do / In Progress / Done)
- Blocked By — optional dropdown to select a blocker task; blocked state is **derived at runtime**, not stored
- Blocked task cards: reduced opacity, lock icon, Blocked badge — auto-clears when blocker is marked Done or deleted
- Draft persistence — form state saved on app background (`AppLifecycleState.paused`) and on back navigation; restored on next open
- 2-second async simulation on create and update — save button stays purple, shows spinner, ignores double-taps
- Search by title with status filter chips

### Stretch Goal — Debounced Search + Highlight
- Search input updates the UI immediately for responsiveness
- Actual filter logic is debounced 300ms via a `Debouncer` utility class
- Matched characters are highlighted inline in task titles using a custom `HighlightedText` widget

---

## Key Technical Decisions

**Blocked state is derived, not stored**

There is no `blocked` value in the `TaskStatus` enum. Instead, `blockedTaskIdsProvider` computes at runtime which task IDs have a blocker that exists and is not yet Done:

```dart
final activeBlockerIds = tasks
    .where((t) => t.status != TaskStatus.done)
    .map((t) => t.id)
    .toSet();

return tasks
    .where((t) => t.blockedById != null && activeBlockerIds.contains(t.blockedById))
    .map((t) => t.id)
    .toSet();
```

This means:
- Marking a blocker Done → dependent task unblocks instantly, zero manual state updates
- Deleting a blocker → dependent task also unblocks (deleted ID is no longer in `activeBlockerIds`)

**Bottom sheet pickers instead of dropdowns**

Flutter's `DropdownButton` inside a `SingleChildScrollView` causes overlay positioning issues and renders a dark Material scrim that clashes with the white card UI. Both the Task Group and Blocked By selectors use `showModalBottomSheet` instead — white background, rounded corners, no overlay, consistent with the app's design language.

---

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `shared_preferences` | Local persistence |
| `google_fonts` | Lexend Deca + Manrope typography |
| `flutter_animate` | List item entrance animations |
| `intl` | Date formatting |
| `uuid` | Task ID generation |

---

## AI Usage Report

### Tools used
Amazon Q Developer (IDE plugin) — used throughout the entire development session via chat.

### What AI helped with

- **Initial scaffolding** — Clean Architecture folder structure, abstract repository contract, use case boilerplate
- **Riverpod providers** — `AsyncNotifier` pattern for `TasksNotifier`, derived `blockedTaskIdsProvider`, `filteredTasksProvider` with debounce
- **UI implementation** — Timeline card layout, bottom sheet pickers, status/priority segmented selectors, blurred background widget
- **Bug fixes** — Navigation stack blank screen bug (pushReplacement vs push), blocked state re-triggering on blocker deletion, `DropdownButton` overlay issue in scroll context
- **Theme** — Material 3 `inputDecorationTheme` fix to remove dark overlay on focused text fields (`fillColor: Colors.white`, `disabledBackgroundColor` on buttons)

### Example of AI giving bad code — and how it was fixed

**Problem:** AI initially implemented `blockedTaskIdsProvider` using a negative check:

```dart
// AI-generated (buggy)
final doneIds = tasks.where((t) => t.status == TaskStatus.done).map((t) => t.id).toSet();
return tasks
    .where((t) => t.blockedById != null && !doneIds.contains(t.blockedById))
    .map((t) => t.id)
    .toSet();
```

**Bug:** If the blocker task was deleted, its ID was absent from `doneIds`, so `!doneIds.contains(...)` evaluated to `true` — the dependent task became blocked again even though its blocker no longer existed.

**Fix:** Switched to a positive existence check against tasks that are alive and not done:

```dart
// Fixed
final activeBlockerIds = tasks
    .where((t) => t.status != TaskStatus.done)
    .map((t) => t.id)
    .toSet();
return tasks
    .where((t) => t.blockedById != null && activeBlockerIds.contains(t.blockedById))
    .map((t) => t.id)
    .toSet();
```

This correctly handles both the "blocker marked Done" and "blocker deleted" cases with a single condition.

### Most helpful prompt

> "The task group dropdown has icon duplication — the selected item's icon badge shows inside the dropdown button area AND I have a separate icon badge on the left of the row. Also the dropdown opens with a dark Material overlay that looks disconnected from the white card UI. Fix both."

This prompt was specific about two distinct problems and their visual symptoms, which led directly to the bottom sheet picker solution rather than a surface-level CSS tweak.
