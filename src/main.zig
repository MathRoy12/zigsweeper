const std = @import("std");
const rl = @import("raylib");

const Cell = @import("ui/cell.zig").Cell;

const width = 1200;
const heigth = 640;

const mineSpacing: i32 = 45;
const padding: i32 = 78;

var grid: [30][16]Cell = [_][16]Cell{[_]Cell{undefined} ** 16} ** 30;

pub fn main() !void {
    rl.initWindow(width, heigth, "zigsweeper");
    defer rl.closeWindow();

    const icon = try rl.loadImage("ressource/img/Mine.png");
    defer rl.unloadImage(icon);
    rl.setWindowIcon(icon);

    rl.setTargetFPS(60);

    initGrid();
    try Cell.InitCellText();

    var mouseX: u64 = undefined;
    var mouseY: u64 = undefined;

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        mouseX = @intCast(rl.getMouseX());
        mouseY = @intCast(rl.getMouseY());

        if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
            _ = grid[@divTrunc(mouseX, 40)][@divTrunc(mouseY, 40)].Reveal();
        }

        if (rl.isMouseButtonReleased(rl.MouseButton.right)) {
            grid[@divTrunc(mouseX, 40)][@divTrunc(mouseY, 40)].Flag();
        }

        for (0..grid.len) |x| {
            for (0..grid[x].len) |y| {
                grid[x][y].Draw();
            }
        }
    }
}

pub fn initGrid() void {
    for (0..30) |x| {
        for (0..16) |y| {
            grid[x][y] = Cell.Init(.Empty, @floatFromInt(x * 40), @floatFromInt(y * 40));
        }
    }
}
