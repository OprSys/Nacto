import std/tables

type
    ProcessRoutine* = proc(procobj: ProcessObject): int

    CustomInstrArgumentObject* = ref object
        Name*: string
        Value*: int

    CustomInstrObject* = ref object
        Name*: string
        StartPC*: int
        EndPC*: int
        Arguments*: seq[CustomInstrArgumentObject]

    ProcessState* = ref object
        ProgramCounter*: int
        RunningProcess*: ProcessRoutine
        IsRunning*: bool
        Vm*: array[8, int]
        RunningProcessString*: seq[string]
        CustomInstrs*: Table[string, CustomInstrObject]
        ReturnBack*: int
        CurrentCustomInstr*: CustomInstrObject

    ProcessObject* = ref object
        Name*: string
        PathOrigin*: string
        Id*: int
        ProcessState*: ProcessState