//! This file contains data structures representing events

/// An union enum of different types of events.
///
/// Note: On unix, some of these events cannot be reported without kitty's enhancement flags.
pub const Event = union(enum) {
    Key: KeyEvent,
    Mouse: MouseEvent,
    Resize: struct { u16, u16 },
    FocusGained,
    FocusLost,
};

/// Represents a Mouse Event.
pub const MouseEvent = struct {
    kind: MouseEventKind,
    column: u16,
    row: u16,
    modifier: KeyModifiers,
};

/// This structure holds the possible mouse events.
pub const MouseEventKind = union(enum) {
    /// Mouse button pressed down.
    Down: MouseButton,

    /// Mouse button released.
    Up: MouseButton,

    /// Mouse moved while pressing a MouseButton.
    Drag: MouseButton,

    Moved,

    ScrollDown,
    ScrollUp,
    ScrollLeft,
    ScrollRight,
};

/// Represents a mouse button.
pub const MouseButton = enum { Left, Right, Middle, Unknown };

/// Represents a key event.
pub const KeyEvent = struct {
    code: KeyCode,
    modifier: KeyModifiers = .{},
    kind: KeyKind = .Press,
    state: KeyState = .{},
};

/// Store extra state info about a key event.
///
/// Note: on unix this can only be read with `DISAMBIGUATE_ESCAPE_CODES` enabled.
pub const KeyState = packed struct {
    NumLock: bool = false,
    KeyPad: bool = false,
    CapsLock: bool = false,
};

/// Represents the kind of key click.
pub const KeyKind = union(enum) {
    Press,
    Repeat: u16,
    Release,
};

/// Represents a key.
pub const KeyCode = union(enum) {
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
    Delete,
    Insert,

    /// Function keys
    F: u8,

    /// A character
    Char: u21,

    /// Unknown key
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

/// Represents a modifer key.
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

/// Represent the modifiers of a key.
pub const KeyModifiers = packed struct {
    Shift: bool = false,
    Control: bool = false,
    Alt: bool = false,
    Super: bool = false,
    Hyper: bool = false,
    Meta: bool = false,
};
