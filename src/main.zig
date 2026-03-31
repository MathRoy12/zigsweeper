const std = @import("std");
const rl = @import("raylib");

const Cell = @import("ui/cell.zig").Cell;

const width = 30;
const height = 16;

const mine_spacing: i32 = 45;
const padding: i32 = 78;

var grid: [width][height]*Cell = [_][height]*Cell{[_]*Cell{undefined} ** height} ** width;

const game_state = enum { Idle, Playing, Won, Lose };
var currentState: game_state = .Idle;

var alloc: std.mem.Allocator = undefined;

var mouseX: u64 = undefined;
var mouseY: u64 = undefined;

var remainingCell: u16 = height * width;
var totalMine: u16 = 99;

var font: rl.Font = undefined;
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    alloc = arena.allocator();

    rl.initWindow(width * 40, height * 40, "zigsweeper");
    defer rl.closeWindow();

    const icon = try rl.loadImage("ressource/Mine.png");
    defer rl.unloadImage(icon);
    rl.setWindowIcon(icon);

    rl.setTargetFPS(60);

    font = try rl.getFontDefault();

    try InitGame();

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.dark_gray);

        switch (currentState) {
            .Idle => {
                IdleLoop() catch rl.closeWindow();
            },
            .Playing => {
                PlayingLoop();
            },
            .Won => {
                wonLoop();
            },
            .Lose => {
                loseLoop();
            },
        }
    }
}

pub fn InitGame() !void {
    remainingCell = width * height;
    try Cell.InitCellText();
    for (0..width) |x| {
        for (0..height) |y| {
            grid[x][y] = try alloc.create(Cell);
            grid[x][y].Init(.Empty, @floatFromInt(x * 40), @floatFromInt(y * 40));
        }
    }
}

pub fn InitGrid(clickedCellX: u64, clickedCellY: u64, nbMine: u16) !void {
    //initialiser toute les Cell à Empty
    for (grid) |row| {
        for (row) |cell| {
            cell.value = .Empty;
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
        x = rng.intRangeLessThan(u8, 0, width);
        y = rng.intRangeLessThan(u8, 0, height);

        //if cell to close of first clicked cell change mine
        if (x > @as(i65, clickedCellX) - 2 and
            x < @as(i65, clickedCellX) + 2 and
            y > @as(i65, clickedCellY) - 2 and
            y < @as(i65, clickedCellY) + 2)
            continue :mine_set;

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
                if ((i < 0 or i >= width or j < 0 or j >= height) or grid[@intCast(i)][@intCast(j)].value == .Mine) continue :update_count;

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
        grid[x][y].state = .WasMine;
        currentState = .Lose;
        loseReveal();
    }

    if (cellValue == .Empty) {
        var i: i65 = @as(i65, x) - 1;
        var j: i65 = undefined;
        while (i <= x + 1) : (i += 1) {
            j = @as(i65, y) - 1;
            reveal_loop: while (j <= y + 1) : (j += 1) {
                if (i < 0 or i >= width or j < 0 or j >= height) continue :reveal_loop;
                RevealCell(@intCast(i), @intCast(j));
            }
        }
    }
    remainingCell -= 1;
}

pub fn IdleLoop() !void {
    drawGrid();
    if (!rl.isMouseButtonReleased(rl.MouseButton.left)) return;

    mouseX = @intCast(rl.getMouseX());
    mouseY = @intCast(rl.getMouseY());

    try InitGrid(@divTrunc(mouseX, 40), @divTrunc(mouseY, 40), totalMine);

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
                    if (i < 0 or i >= width or j < 0 or j >= height) continue :count_loop;
                    if (grid[@intCast(i)][@intCast(j)].state == .Flaged) flagCount += 1;
                }
            }
            if (flagCount == @intFromEnum(grid[cellX][cellY].value)) {
                i = @as(i65, cellX) - 1;
                while (i <= cellX + 1) : (i += 1) {
                    j = @as(i65, cellY) - 1;
                    reveal_loop: while (j <= cellY + 1) : (j += 1) {
                        if (i < 0 or i >= width or j < 0 or j >= height) continue :reveal_loop;
                        if (grid[@intCast(i)][@intCast(j)].state == .Hidden) RevealCell(@intCast(i), @intCast(j));
                    }
                }
            }
        }
        if (remainingCell == totalMine) {
            wonReveal();
            currentState = .Won;
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
                    if (i < 0 or i >= width or j < 0 or j >= height) continue :count_loop;
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
                        if (i < 0 or i >= width or j < 0 or j >= height) continue :flag_loop;
                        if (grid[@intCast(i)][@intCast(j)].state == .Hidden) grid[@intCast(i)][@intCast(j)].Flag();
                    }
                }
            }
        }
    }
    drawGrid();
}

pub fn loseReveal() void {
    for (grid) |row| {
        for (row) |cell| {
            if (cell.value == .Mine and cell.state == .Hidden)
                cell.state = .Revealed;
            if (cell.state == .Flaged and cell.value != .Mine)
                cell.state = .WrongFlag;
        }
    }
}

pub fn loseLoop() void {
    drawGrid();
    if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
        InitGame() catch {};
        currentState = .Idle;
    }
}

pub fn wonReveal() void {
    for (grid) |row| {
        for (row) |cell| {
            if (cell.state == .Hidden and cell.value == .Mine) {
                cell.state = .Flaged;
            }
        }
    }
}

pub fn wonLoop() void {
    drawGrid();

    const textSize = rl.measureTextEx(font, "You Win", 60, 2);
    const pos: rl.Vector2 = rl.Vector2{
        .x = @as(f32, @floatFromInt(rl.getScreenWidth())) / @as(f32, 2) - textSize.x / @as(f32, 2),
        .y = @as(f32, @floatFromInt(rl.getScreenHeight())) / @as(f32, 2) - textSize.y / @as(f32, 2),
    };
    rl.drawTextEx(font, "You Win", pos, 60, 2, rl.Color.green);
    if (rl.isMouseButtonReleased(rl.MouseButton.left)) {
        InitGame() catch {};
        currentState = .Idle;
    }
}

pub fn drawGrid() void {
    for (grid) |row| {
        for (row) |cell| {
            cell.Draw();
        }
    }
}
