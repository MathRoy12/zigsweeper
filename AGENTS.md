# AGENTS.md - Coding Guidelines for Zigsweeper

This file provides instructions for agentic coding assistants working on the zigsweeper Zig project.

## Build, Lint, and Test Commands

### Build Commands
- **Build project**: `zig build`
- **Build for specific optimization**: `zig build -Doptimize=ReleaseFast`
- **Build for different target**: `zig build --target x86_64-linux-gnu`
- **Install artifacts**: `zig build` (installs to `zig-out/`)

### Running
- **Run application**: `zig build run`
- **Run with arguments**: `zig build run -- arg1 arg2`

### Testing
- **Run all tests**: `zig build test`
- **Run single test file**: Zig doesn't support running individual test blocks directly; tests are embedded in source files using `test` blocks. To test specific functionality, modify the test block in the relevant `.zig` file or create a new test file and import it.
- **Test output**: Tests run via the build system and output results to stdout

### Code Quality
- **Format check**: `zig fmt --check .` (dry-run)
- **Auto-format**: `zig fmt .` (formats all `.zig` files in current directory)
- No linter configured; rely on Zig compiler warnings

## Project Structure

```
zigsweeper/
├── src/
│   ├── main.zig          # Application entry point
│   └── ui/
│       ├── cell.zig      # Cell game logic and rendering
│       └── button.zig    # Button UI component
├── build.zig             # Build configuration
├── build.zig.zon         # Package manifest and dependencies
└── ressource/            # Assets (images)
```

## Dependencies

- **Zig**: Minimum version 0.15.2
- **raylib-zig**: Graphics library (git dependency)
- **raygui**: GUI widgets library

## Code Style Guidelines

### Imports
- Use `const` for all imports
- Group imports at the top of the file: standard library first, then external packages, then internal modules
- Example:
  ```zig
  const std = @import("std");
  const rl = @import("raylib");
  const Cell = @import("ui/cell.zig").Cell;
  ```

### Naming Conventions
- **Constants**: `snake_case` (e.g., `mineSpacing`, `padding`, `width`, `heigth`)
 **Variables**: `camelCase` (e.g., `mouseX`, `mouseY`, `grid`)
- **Functions**: `PascalCase` for public functions (e.g., `Init`, `Draw`, `Reveal`, `Flag`)
  - `camelCase` for private functions (e.g., `getText`, `isPressed`)
- **Types/Structs**: `PascalCase` (e.g., `Cell`, `ImgButton`, `CellState`, `CellValue`)
- **Enums**: `snake_case` variants (e.g., `.Hidden`, `.Revealed`, `.Flaged`)

### Formatting
- Use spaces for indentation (4 spaces per level)
- Run `zig fmt` before committing
- Maximum line length: implicit (follow readability)
- Use defer for cleanup (e.g., `defer rl.closeWindow()`)
- Place opening braces on same line

### Type Annotations
- Declare explicit types for function parameters and return values
- Use type inference for simple variable assignments where obvious
- Prefer concrete types over inference for function returns
- Use `?Type` for nullable values
- Example:
  ```zig
  pub fn Init(value: CellValue, x: f32, y: f32) Cell { ... }
  fn getText(self: *Cell) rl.Texture2D { ... }
  ```

### Structs and Methods
- Use `struct` for grouping related data and methods
- Methods should use `self` or `self: *Type` for mutable access
- Separate public methods (pub fn) from private (fn)
- Initialize structs with `.` syntax and named fields:
  ```zig
  return Cell{ .state = .Hidden, .value = value, ._rect = rect };
  ```
- Use underscore prefix for private struct fields (e.g., `_rect`, `_texture`)

### Enums
- Define enums near their usage
- Use full path in switch statements: `.Hidden`, `.Revealed`
- Consider grouping related enums at file top

### Error Handling
- Use `!Type` for functions that can fail (e.g., `!void`, `!rl.Texture2D`)
- Use try-catch pattern: `try rl.loadTexture(...)`
- Use defer for cleanup after allocations
- Propagate errors up the stack with `try` keyword

### Comments
- Write comments for non-obvious logic
- Keep comments brief and focused
- Document public functions with their purpose

## Key Patterns in Codebase

### Resource Loading
- Load textures in initialization phase (e.g., `InitCellText()`)
- Use defer to unload resources
- Store loaded resources in package-level variables

### Game Loop
- Standard raylib loop: `initWindow` → game loop with `beginDrawing`/`endDrawing` → `closeWindow`
- Use `rl.setTargetFPS()` to control frame rate

### State Management
- Use enums for state (e.g., `CellState`, `CellValue`)
- Store state in structs alongside related methods
- Use methods to mutate state (e.g., `Reveal()`, `Flag()`)

## Git Workflow

- Use meaningful commit messages
- Format code with `zig fmt` before committing
- Test locally with `zig build test` before pushing
- Keep commits focused on single logical changes

## Common Issues and Solutions

- **Assets not found**: Ensure `ressource/` path is relative to executable location
- **Type mismatch**: Explicit casting may be needed (e.g., `@intCast`, `@floatFromInt`)
- **Uninitialized values**: Always initialize array elements or use defined defaults
