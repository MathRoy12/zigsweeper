const rl = @import("raylib");

pub const ImgButton = struct {
    rect: rl.Rectangle,

    _texture: ?rl.Texture2D = null,

    fn isPressed(self: ImgButton) bool {
        const mousePos = rl.getMousePosition();
        const isCollided = rl.checkCollisionPointRec(mousePos, self.rect);
        const isLeftClickPressed = rl.isMouseButtonReleased(rl.MouseButton.left);
        const isRightClickPressed = rl.isMouseButtonReleased(rl.MouseButton.Right);

        return isCollided and (isLeftClickPressed or isRightClickPressed);
    }

    pub fn IsLeftClicked(self: ImgButton) bool {
        const mousePos = rl.getMousePosition();

        const isCollided = rl.checkCollisionPointRec(mousePos, self.rect);
        const isLeftClickReleased = rl.isMouseButtonReleased(rl.MouseButton.left);

        return isCollided and isLeftClickReleased;
    }

    pub fn IsRightClicked(self: ImgButton) bool {
        const mousePos = rl.getMousePosition();

        const isCollided = rl.checkCollisionPointRec(mousePos, self.rect);
        const isRightClickReleased = rl.isMouseButtonReleased(rl.MouseButton.right);

        return isCollided and isRightClickReleased;
    }

    pub fn SetTexture(self: ImgButton, img: rl.Image) void {
        if (self._texture) {
            rl.unloadTexture(self._texture);
        }

        const sizedImg = rl.imageResize(img, @round(self.rect.width), @round(self.rect.height));
        self._texture = rl.loadTextureFromImage(sizedImg);
    }

    pub fn Draw(self: ImgButton) void {
        rl.drawTexture(self._texture, @round(self.rect.x), @round(self.rect.y), rl.Color.white);
    }
};
