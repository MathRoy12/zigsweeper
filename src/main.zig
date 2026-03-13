const std = @import("std");
const rl = @import("raylib");

const btn = @import("ui/button.zig");

const width = 1500;
const heigth = 800;

const mineSpacing: i32 = 45;
const padding: i32 = 78;

pub fn main() !void {
    rl.initWindow(width, heigth, "zigsweeper");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        for (0..30) |x| {
            for (0..16) |y| {
                drawSquare(padding + (mineSpacing * @as(i32, @intCast(x))), padding + (mineSpacing * @as(i32, @intCast(y))));
            }
        }
    }
}

pub fn drawSquare(x: i32, y: i32) void {
    rl.drawRectangle(x, y, 40, 40, rl.Color.gray);
}
