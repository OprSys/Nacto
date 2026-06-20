import std/tables

import hardware/disk as NactoDisk

const VM_SIZE* = 16
const HIGH* = 32
const LOW* = 512

type
    ProcessRoutine* = proc(procobj: ProcessObject): int

    OpenFileEntry* = ref object
        File*: NactoDisk.DiskTypes.File

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
        Vm*: array[VM_SIZE, int]
        FileDescriptors*: seq[OpenFileEntry]
        RunningProcessString*: seq[string]
        CustomInstrs*: Table[string, CustomInstrObject]
        ReturnBack*: seq[int]
        CurrentCustomInstr*: seq[CustomInstrObject]
        LRAM*: array[HIGH, array[LOW, int]]

    ProcessObject* = ref object
        Name*: string
        PathOrigin*: string
        Id*: int
        ProcessState*: ProcessState