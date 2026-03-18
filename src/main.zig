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

                cellValue = @intFromEnum(grid[@intCast(i)][@intCast(j)].value);
                grid[@intCast(i)][@intCast(j)].value = @enumFromInt(cellValue + 1);
            }
        }
        nbMineSet += 1;
    }
}

pub fn RevealCell(x: u64, y: u64) void {
    if (grid[x][y].state != .Hidden) return;

    const cellValue = grid[x][y].Reveal();

    if (cellValue == .Mine) {
        currentState = .Lose;
    }

    if (cellValue == .Empty) {
        var i: i65 = @as(i65, x) - 1;
        var j: i65 = undefined;
        while (i <= x + 1) : (i += 1) {
            j = @as(i65, y) - 1;
            reveal_loop: while (j <= y + 1) : (j += 1) {
                if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :reveal_loop;
                RevealCell(@intCast(i), @intCast(j));
            }
        }
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

    RevealCell(@divTrunc(mouseX, 40), @divTrunc(mouseY, 40));

    currentState = .Playing;
}

pub fn PlayingLoop() void {
    mouseX = @intCast(rl.getMouseX());
    mouseY = @intCast(rl.getMouseY());

    const cellX = @divTrunc(mouseX, 40);
    const cellY = @divTrunc(mouseY, 40);

    // Reveal Logic
    if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
        if (grid[cellX][cellY].state == .Hidden) {
            RevealCell(cellX, cellY);
        } else if (grid[cellX][cellY].state == .Revealed) {
            var flagCount: u64 = 0;
            var i: i65 = @as(i65, cellX) - 1;
            var j: i65 = undefined;
            while (i <= cellX + 1) : (i += 1) {
                j = @as(i65, cellY) - 1;
                count_loop: while (j <= cellY + 1) : (j += 1) {
                    if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :count_loop;
                    if (grid[@intCast(i)][@intCast(j)].state == .Flaged) flagCount += 1;
                }
            }
            if (flagCount == @intFromEnum(grid[cellX][cellY].value)) {
                i = @as(i65, cellX) - 1;
                while (i <= cellX + 1) : (i += 1) {
                    j = @as(i65, cellY) - 1;
                    reveal_loop: while (j <= cellY + 1) : (j += 1) {
                        if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :reveal_loop;
                        if (grid[@intCast(i)][@intCast(j)].state == .Hidden) RevealCell(@intCast(i), @intCast(j));
                    }
                }
            }
        }
    }

    //Flag Logic
    if (rl.isMouseButtonReleased(rl.MouseButton.right)) {
        const currentCell = grid[cellX][cellY];
        if (currentCell.state == .Hidden) {
            grid[cellX][cellY].Flag();
        } else if (currentCell.state == .Flaged) {
            grid[cellX][cellY].state = .Hidden;
        } else if (currentCell.state == .Revealed) {
            var hiddenCount: u64 = 0;
            var i: i65 = @as(i65, cellX) - 1;
            var j: i65 = undefined;
            var isHidden: bool = false;
            var isFlaged: bool = false;
            while (i <= cellX + 1) : (i += 1) {
                j = @as(i65, cellY) - 1;
                count_loop: while (j <= cellY + 1) : (j += 1) {
                    if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :count_loop;
                    isHidden = grid[@intCast(i)][@intCast(j)].state == .Hidden;
                    isFlaged = grid[@intCast(i)][@intCast(j)].state == .Flaged;

                    if (isHidden or isFlaged) hiddenCount += 1;
                }
            }
            if (hiddenCount == @intFromEnum(grid[cellX][cellY].value)) {
                i = @as(i65, cellX) - 1;
                while (i <= cellX + 1) : (i += 1) {
                    j = @as(i65, cellY) - 1;
                    flag_loop: while (j <= cellY + 1) : (j += 1) {
                        if (i < 0 or i >= 30 or j < 0 or j >= 16) continue :flag_loop;
                        if (grid[@intCast(i)][@intCast(j)].state == .Hidden) grid[@intCast(i)][@intCast(j)].Flag();
                    }
                }
            }
        }
    }

    for (0..grid.len) |x| {
        for (0..grid[x].len) |y| {
            grid[x][y].Draw();
        }
    }
}
