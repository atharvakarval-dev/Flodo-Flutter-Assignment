# Flodo - Premium Task Manager

Flodo is a local-first Flutter task management app focused on clarity, speed, and polished interaction design.

## Setup Instructions

1. Install latest stable Flutter SDK and ensure `flutter` is on your PATH.
2. From project root, install packages:
   - `flutter pub get`
3. Run app:
   - `flutter run`

## Architecture Decisions

- **Pattern:** Clean Architecture with strict boundaries:
  - `data`: local persistence and repository implementation
  - `domain`: entities, repository contract, use cases
  - `presentation`: screens, widgets, Riverpod providers
- **State management:** Riverpod for predictable state flow and testable composition.
- **Persistence:** Hive local database (no backend) for offline-first behavior.
- **Draft persistence:** `SharedPreferences` stores form draft and restores it after navigation/background.

## Design Philosophy

The UI follows Apple-level product principles:

- clear visual hierarchy with restrained typography
- generous, consistent spacing on an 8pt rhythm
- subtle depth and soft card surfaces
- high signal-to-noise interfaces (minimal clutter)
- smooth transitions and responsive touch feedback

Material 3 is used as a foundation, then refined with custom theme, density, and component styling.

## Feature Coverage

- Task list with premium cards
- Title, due date, and status badge (ToDo / In Progress / Done)
- Blocked tasks:
  - reduced opacity
  - disabled interactions
  - blocker hint text
- Create/edit task form:
  - title, description, date picker, status, blocked-by
- Full local CRUD (create/update/delete/read)
- Search + status filter combination
- Create/update async simulation:
  - 2-second delay
  - save button disabled
  - loading indicator
- Animated list transitions and route transitions
- Thoughtful empty state

## Stretch Goal: Debounced Search + Highlight

- Search input updates immediately for UX feedback.
- Filtering uses a **300ms debounce** to avoid jittery updates.
- Matched title text is highlighted inline in each card.

## State Management Reasoning

Riverpod was selected because:

- providers are composable and explicit
- async state and streams are first-class
- clean integration with use case boundaries
- avoids implicit mutable globals

Core providers include:

- `taskListStreamProvider`
- `filteredTasksProvider`
- `blockedTaskIdsProvider`
- `taskFormDraftProvider`
- debounced query + status filter providers

## Project Structure

```text
lib/
  core/
    constants/
    theme/
    utils/
  features/
    tasks/
      data/
        models/
        datasources/
        repositories/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        screens/
        widgets/
        providers/
  main.dart
```

## AI Usage Report

- AI assisted with:
  - initial project scaffolding
  - clean architecture layering
  - UI component implementation
  - README and setup documentation
- All generated code should be reviewed and validated in your runtime/device matrix before production release.
# Flodo-Flutter-Assignment
