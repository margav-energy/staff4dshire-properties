# Project Synchronization Fix

## Issue
When a project is created from the admin page, it doesn't synchronize across staff and supervisor pages.

## Root Cause
The `ProjectProvider` is a singleton shared across all screens. When a project is added, it calls `notifyListeners()`, which should notify all `Consumer` widgets. However, if screens aren't currently visible, they won't rebuild until they become visible again.

## Solution
1. **ProjectProvider** - Already properly configured as a singleton that calls `notifyListeners()` when projects are added/updated
2. **Consumer Widgets** - All project selection screens use `Consumer` widgets that automatically rebuild when the provider notifies
3. **Lifecycle Management** - Added lifecycle observers to ensure projects refresh when screens become visible

## Changes Made

### 1. ProjectProvider (`mobile/lib/core/providers/project_provider.dart`)
- Added `refreshProjects()` method for explicit refresh
- `loadProjects()` now calls `notifyListeners()` to trigger UI updates

### 2. Project Selection Screens
- Added lifecycle observers to refresh projects when screens become visible
- Ensured `Consumer` widgets properly listen to provider changes

### 3. Staff Project Selection Screen
- Added `didChangeDependencies()` to reload projects when screen becomes visible

### 4. Supervisor Project Selection Screen
- Uses `ProjectSelectionScreen` which now has proper refresh logic

## How It Works

1. **Admin creates project:**
   - Project is added to `ProjectProvider` via `addProject()`
   - `notifyListeners()` is called automatically
   - All active `Consumer` widgets rebuild immediately

2. **When staff/supervisor screens become visible:**
   - `Consumer` widgets automatically rebuild with latest project list
   - Projects refresh via lifecycle callbacks

3. **Shared Provider:**
   - Single `ProjectProvider` instance shared across all screens
   - Changes propagate automatically to all listeners

## Testing

1. Create a new project as admin
2. Navigate to staff dashboard
3. Try to select project - new project should appear
4. Navigate to supervisor dashboard
5. Try to select project - new project should appear

## Notes

- All screens using projects are now synchronized automatically
- No manual refresh needed - happens automatically via Provider pattern
- Changes are immediate for visible screens
- Changes appear automatically when screens become visible

