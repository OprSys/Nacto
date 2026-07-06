import std/tables

import hardware/disk as NactoDisk

const VM_SIZE* = 16
const HIGH* = 32
const LOW* = 512

type
    Signal* = object
        Name*: string
        Id*: int
        CanBeOverridden*: bool

type
    IsRunningState* = enum 
        Running, Blocking, Terminated, NotStarted, PreRuntime

    OpenFileEntry* = ref object
        File*: NactoDisk.DiskTypes.File
    
    Label* = tuple[StartPC: int, EndPC: int]

    ProcessState* = ref object
        ProgramCounter*: int
        Running*: IsRunningState
        Vm*: array[VM_SIZE, int]
        FileDescriptors*: seq[OpenFileEntry]
        RunningProcessString*: seq[string]
        WasScanned*: bool
        ReturnStack*: seq[int]
        PendingSignals*: seq[Signal]
        Labels*: Table[string, Label]
        LRAM*: array[HIGH, array[LOW, int]]

    ProcessObject* = ref object
        Name*: string
        PathOrigin*: string
        Id*: int
        ProcessState*: ProcessState


const SIG_FTERM* = Signal(Name: "SIGFTERM", Id: 1, CanBeOverridden: false)
const SIG_TERM* = Signal(Name: "SIGTERM", Id: 2, CanBeOverridden: true)
const SIG_GEN1* = Signal(Name: "SIGGEN1", Id: 3, CanBeOverridden: true)
const SIG_GEN2* = Signal(Name: "SIGGEN2", Id: 4, CanBeOverridden: true)
const SIG_GEN3* = Signal(Name: "SIGGEN3", Id: 5, CanBeOverridden: true)

proc SIG_FTERM_default*(procobj: ProcessObject): void =
    procobj.ProcessState.Running = IsRunningState.Terminated

proc SIG_TERM_default*(procobj: ProcessObject): void =
    procobj.ProcessState.Running = IsRunningState.Terminated