type
    ProcessRoutine* = proc(procobj: ProcessObject): int

    ProcessState* = ref object
        ProgramCounter*: int
        RunningProcess*: ProcessRoutine
        IsRunning*: bool
        Vm*: array[8, int]

    ProcessObject* = ref object
        Name*: string
        PathOrigin*: string
        Id*: int
        ProcessState*: ProcessState