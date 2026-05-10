import process/procapi as ProcApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    procobj.ProcessState.IsRunning = false
    return 0