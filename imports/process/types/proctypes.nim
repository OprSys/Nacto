type
    ProcessRoutine* = proc(procobj: ProcessObject): int

    ProcessState* = ref object
        ProgramCounter*: int
        RunningProcess*: ProcessRoutine
        IsRunning*: bool

    ProcessObject* = ref object
        Name*: string
        PathOrigin*: string
        Id*: int
        ProcessState*: ProcessState