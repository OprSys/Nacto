type
    InvalidInstruction* = object of CatchableError
        InstrName*: string