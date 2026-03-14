const rl = @import("raylib");
const btn = @import("button.zig");

pub const CellValue = enum { One, Two, Three, Four, Five, Six, Seven, eight, Empty, Mine };

fn imgFromCellValue() rl.Image {}

pub const Cell = struct {
    value: CellValue,
    button: btn.ImgButton,
};
