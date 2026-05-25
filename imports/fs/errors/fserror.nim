type
    FSError* = object of CatchableError
        IsFatal*: bool