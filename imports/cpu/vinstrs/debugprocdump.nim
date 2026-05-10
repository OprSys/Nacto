import process/procapi as ProcApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    echo(procobj.repr)
    return 0