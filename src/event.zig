pub const Event = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
    resize: struct { u16, u16 },
    FocusGained,
    FocusLost,
};

pub const MouseEvent = struct {
    kind: MouseEventKind,
    column: u16,
    row: u16,
    modifier: KeyModifiers,
};

pub const MouseEventKind = union(enum) {
    /// Mouse button pressed down
    Down: MouseButton,
    /// Mouse button released
    Up: MouseButton,
    /// Mouse moved while pressing the MouseButton
    Drag: MouseButton,
    Moved,
    ScrollDown,
    ScrollUp,
    ScrollLeft,
    ScrollRight,
};

pub const MouseButton = enum {
    Left,
    Right,
    Middle,
    Unknown,
};

pub const KeyEvent = struct {
    code: KeyCode,
    modifier: KeyModifiers = .{},
    kind: KeyKind = .Press,
    state: KeyState = .{},
};

pub const KeyState = packed struct {
    NumLock: bool = false,
    KeyPad: bool = false,
    CapsLock: bool = false,
};

pub const KeyKind = union(enum) {
    Press,
    Repeat: u16,
    Release,
};

pub const KeyCode = union(enum) {
    Backspace,
    Enter,
    Left,
    Right,
    BackTab,
    Up,
    Down,
    Home,
    End,
    PageUp,
    PageDown,
    Tab,
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
    MediaPlay,
    MediaPause,
    MediaPlayPause,
    MediaReverse,
    MediaStop,
    MediaFastForward,
    MediaRewind,
    MediaTrackNext,
    MediaTrackPrevious,
    MediaRecord,
    MediaLowerVolume,
    MediaRaiseVolume,
    MediaMuteVolume,
    KeyModifier: KeyModifierCode,
};

pub const KeyModifierCode = enum {
    LeftShift,
    LeftControl,
    LeftAlt,
    LeftSuper,
    LeftHyper,
    LeftMeta,
    RightShift,
    RightControl,
    RightAlt,
    RightSuper,
    RightHyper,
    RightMeta,
    IsoLevel3Shift,
    IsoLevel5Shift,
};

pub const KeyModifiers = packed struct { Shift: bool = false, Control: bool = false, Alt: bool = false, Super: bool = false, Hyper: bool = false, Meta: bool = false };
