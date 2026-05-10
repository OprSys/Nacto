import process/types/proctypes as ProcTypes
export ProcTypes

var Processes: seq[ProcTypes.ProcessObject] = @[]

proc CreateProcess*(name: string, origin: string): ProcTypes.ProcessObject =
    var procstate: ProcTypes.ProcessState = ProcTypes.ProcessState(ProgramCounter: 0, RunningProcess: nil, IsRunning: false)
    var procobj: ProcTypes.ProcessObject = ProcTypes.ProcessObject(Name: name, PathOrigin: origin, Id: Processes.len+1, ProcessState: procstate)
    return procobj

proc LinkProcess*(procobj: ProcTypes.ProcessObject): void =
    Processes.add(procobj)
    return