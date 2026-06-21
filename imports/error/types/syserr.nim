type
    ErrorSeverity* = enum
        Fatal, Error

    # ErrCategory: what type of error happened
    # ErrKind: what actual error occured
    ErrorContext* = ref object
        ErrSeverity*: ErrorSeverity
        ErrPC*: int
        ErrCategory*: int
        ErrKind*: int

    SysError* = object of CatchableError
        Reason*: string
        Context*: ErrorContext