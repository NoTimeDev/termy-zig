pub const Event = union(enum){
    Key: KeyEvent,
    mouse: MouseEvent,
};

pub const MouseEvent = union(enum){
    CursorUp: u16,
    CursorDown: u16,
    CursorLeft: u16,
    CursorRight: u16,
};

pub const ModifierKeyCode = enum {
    Shift,
    Control,
    Alt,
    Super,
    Hyper,
    Meta,
};

pub const KeyCode = union(enum){
    Backspace,
    Enter,
    Left,
    Right,
    Up,
    Down,
    Home,
    End,
    PageUp,
    PageDown,
    Tab,
    BackTab,
    Delete,
    Insert,
    Fn: u8,
    Char: u21,
    Null,
    Esc,
    CapsLock,
    ScrollLock,
    NumLock,
    PrintScreen,
    Pause,
    Menu,
    KeypadBegin,
    Modifier: ModifierKeyCode,
};

pub const KeyEvent = struct {
    code: KeyCode,
    modifier: ?ModifierKeyCode = null
};
