pub const Event = union(enum){
    key: KeyEvent
};

pub const KeyEvent = struct {
    code: KeyCode, 
    modifier: KeyModifiers = .{},
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
    F: u8,
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
    KeyModifier: KeyModifiers,
};

pub const KeyModifiers = packed struct{
    Shift: bool = false,
    Control: bool = false, 
    Alt: bool = false,
    _: u5 = 0,
};
