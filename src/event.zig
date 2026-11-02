pub const Event = union(enum){
    key: KeyEvent,
    FocusGained,
    FocusLost,
};

pub const KeyEvent = struct {
    code: KeyCode, 
    modifier: KeyModifiers = .{},
    kind: KeyKind = .Press,
    state: KeyState = .{},
};

pub const KeyState = packed struct{
    NumLock: bool = false,
    KeyPad: bool = false,
    CapsLock: bool = false,   
};

pub const KeyKind = union(enum){
    Press,
    Repeat: u16,
    Release,
};

pub const KeyCode = union(enum){
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

pub const KeyModifiers = packed struct{
    Shift: bool = false,
    Control: bool = false, 
    Alt: bool = false,
    Super: bool = false,
    Hyper: bool = false,
    Meta: bool = false
};
