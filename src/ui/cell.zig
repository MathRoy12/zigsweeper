const rl = @import("raylib");

const cell_state = enum { Hidden, Revealed, Flaged, WasMine, WrongFlag };
pub const cell_value = enum { One, Two, Three, Four, Five, Six, Seven, Eight, Mine, Empty };

var texts: [14]rl.Texture2D = [_]rl.Texture2D{undefined} ** 14;

const is_initialized = false;

pub const Cell = struct {
    state: cell_state,
    value: cell_value,

    _rect: rl.Rectangle,

    pub fn Init(value: cell_value, x: f32, y: f32) Cell {
        const rect: rl.Rectangle = .{
            .x = x,
            .y = y,
            .height = 40,
            .width = 40,
        };

        return Cell{ .state = .Hidden, .value = value, ._rect = rect };
    }

    pub fn InitCellText() !void {
        texts[0] = try rl.loadTexture("ressource/img/One.png");
        texts[1] = try rl.loadTexture("ressource/img/Two.png");
        texts[2] = try rl.loadTexture("ressource/img/Three.png");
        texts[3] = try rl.loadTexture("ressource/img/Four.png");
        texts[4] = try rl.loadTexture("ressource/img/Five.png");
        texts[5] = try rl.loadTexture("ressource/img/Six.png");
        texts[6] = try rl.loadTexture("ressource/img/Seven.png");
        texts[7] = try rl.loadTexture("ressource/img/Eight.png");
        texts[8] = try rl.loadTexture("ressource/img/Mine.png");
        texts[9] = try rl.loadTexture("ressource/img/Empty.png");
        texts[10] = try rl.loadTexture("ressource/img/Cell.png");
        texts[11] = try rl.loadTexture("ressource/img/Flag.png");
        texts[12] = try rl.loadTexture("ressource/img/WasMine.png");
        texts[13] = try rl.loadTexture("ressource/img/WrongFlag.png");
    }

    fn getText(self: *Cell) rl.Texture2D {
        return switch (self.state) {
            .Hidden => texts[10],
            .Revealed => texts[@intFromEnum(self.value)],
            .Flaged => texts[11],
            .WasMine => texts[12],
            .WrongFlag => texts[13],
        };
    }

    pub fn Reveal(self: *Cell) cell_value {
        if (self.state == .Hidden) {
            self.state = .Revealed;
        }

        return self.value;
    }

    pub fn Flag(self: *Cell) void {
        if (self.state == .Hidden) self.state = .Flaged;
    }

    pub fn Draw(self: *Cell) void {
        const text: rl.Texture2D = self.getText();
        rl.drawTexture(text, @intFromFloat(@round(self._rect.x)), @intFromFloat(@round(self._rect.y)), rl.Color.white);
    }
};
