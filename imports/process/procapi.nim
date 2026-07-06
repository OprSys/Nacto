import std/tables

import process/types/proctypes as ProcTypes
export ProcTypes

var Processes*: seq[ProcTypes.ProcessObject] = @[]
var ProcessIndex*: Table[int, int] = initTable[int, int]()
var nextpid: int = 1

proc CreateProcess*(name: string, origin: string): ProcTypes.ProcessObject =
    var procstate: ProcTypes.ProcessState = ProcTypes.ProcessState(ProgramCounter: 0, Running: ProcTypes.NotStarted, ReturnStack: @[])
    var procobj: ProcTypes.ProcessObject = ProcTypes.ProcessObject(Name: name, PathOrigin: origin, Id: nextpid, ProcessState: procstate)
    inc nextpid
    return procobj

proc LinkProcess*(procobj: ProcTypes.ProcessObject): void =
    for i, p in Processes:
        if p == nil:
            Processes[i] = procobj
            ProcessIndex[procobj.Id] = i
            return
    ProcessIndex[procobj.Id] = Processes.len
    Processes.add(procobj)

proc GetProcess*(id: int): ProcTypes.ProcessObject =
    let idx = ProcessIndex.getOrDefault(id, -1)
    if idx >= 0 and idx < Processes.len:
        return Processes[idx]

proc UnlinkProcess*(id: int): void =
    let idx = ProcessIndex.getOrDefault(id, -1)
    if idx >= 0:
        Processes[idx] = nil
        ProcessIndex.del(id)

proc SendSignal*(id: int, signal: ProcTypes.Signal): void =
    var procobj = GetProcess(id)
    if procobj != nil:
        procobj.ProcessState.PendingSignals.add(signal)