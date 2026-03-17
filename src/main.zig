const std = @import("std");
const rl = @import("raylib");

const Cell = @import("ui/cell.zig").Cell;

const width = 1200;
const height = 640;

const mine_spacing: i32 = 45;
const padding: i32 = 78;

var grid: [30][16]*Cell = [_][16]*Cell{[_]*Cell{undefined} ** 16} ** 30;

const game_state = enum { Idle, Playing, Won, Lose };
var currentState: game_state = .Idle;

var alloc: std.mem.Allocator = undefined;

var mouseX: u64 = undefined;
var mouseY: u64 = undefined;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    alloc = arena.allocator();

    rl.initWindow(width, height, "zigsweeper");
    defer rl.closeWindow();

    try InitGame();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        switch (currentState) {
            .Idle => {
                //std.debug.print("starting Idle \n", .{});
                IdleLoop() catch rl.closeWindow();
            },
            .Playing => {
                PlayingLoop();
            },
            .Won => {},
            .Lose => {},
        }
    }
}

pub fn InitGame() !void {
    const icon = try rl.loadImage("ressource/Mine.png");
    defer rl.unloadImage(icon);
    rl.setWindowIcon(icon);

    rl.setTargetFPS(60);

    try Cell.InitCellText();
    for (0..30) |x| {
        for (0..16) |y| {
            //std.debug.print("creatingCell {any} {any} \n", .{ x, y });
            grid[x][y] = try alloc.create(Cell);
            grid[x][y].Init(.Empty, @floatFromInt(x * 40), @floatFromInt(y * 40));
        }
    }
}

pub fn InitGrid(clickedCellX: u64, clickedCellY: u64, nbMine: u16) !void {
    //initialiser toute les Cell à Empty
    for (0..30) |x| {
        for (0..16) |y| {
            //std.debug.print("creatingCell {any} {any} \n", .{ x, y });
            grid[x][y].value = .Empty;
        }
    }

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    const rng = prng.random();
    var nbMineSet: u16 = 0;

    var x: u8 = undefined;
    var y: u8 = undefined;
    var cellValue: u8 = undefined;
    var currentCell: *Cell = undefined;
    var nearCellCpt: u8 = undefined;

    mine_set: while (nbMine != nbMineSet) {
        x = rng.intRangeLessThan(u8, 0, 30);
        y = rng.intRangeLessThan(u8, 0, 16);

        //if cell to close of first clicked cell change mine
        if (x >= @as(i65, clickedCellX) - 2 and x <= @as(i65, clickedCellX) + 2 and y >= @as(i65, clickedCellY) - 2 and y <= @as(i65, clickedCellY) + 2) continue :mine_set;

        currentCell = grid[x][y];

        if (currentCell.value == .Mine) continue :mine_set;
        nearCellCpt = 0;
        var i: i16 = @as(i16, x) - 1;
        var j: i16 = undefined;
        while (i <= x + 1) : (i += 1) {
            j = @as(i16, y) - 1;
            mine_count: while (j <= y + 1) : (j += 1) {
                if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :mine_count;
                if (grid[@intCast(i)][@intCast(j)].value == .Mine)
                    nearCellCpt += 1;
                //reject mine choici if more than 4 mine is adjacant
                if (nearCellCpt > 4) continue :mine_set;
            }
        }

        currentCell.value = .Mine;

        i = @as(i16, x) - 1;
        while (i <= x + 1) : (i += 1) {
            j = @as(i16, y) - 1;
            update_count: while (j <= y + 1) : (j += 1) {
                if ((i < 0 or i >= 30 or j < 0 or j >= 16) or grid[@intCast(i)][@intCast(j)].value == .Mine) continue :update_count;

                //augmenter la valeur de la cellule de 1 mine proche
                //const f = grid[@intCast(i)][@intCast(j)].value;
                //var p: u8 = @intFromEnum(f);
                //p += 1;

                cellValue = @intFromEnum(grid[@intCast(i)][@intCast(j)].value);
                grid[@intCast(i)][@intCast(j)].value = @enumFromInt(cellValue + 1);
            }
        }
        nbMineSet += 1;
    }
}

pub fn IdleLoop() !void {
    for (0..grid.len) |x| {
        for (0..grid[x].len) |y| {
            grid[x][y].Draw();
        }
    }
    if (!rl.isMouseButtonReleased(rl.MouseButton.left)) return;

    mouseX = @intCast(rl.getMouseX());
    mouseY = @intCast(rl.getMouseY());

    try InitGrid(@divTrunc(mouseX, 40), @divTrunc(mouseY, 40), 99);

    for (0..grid.len) |x| {
        for (0..grid[x].len) |y| {
            _ = grid[x][y].Reveal();
        }
    }

    currentState = .Playing;
}

pub fn PlayingLoop() void {
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
