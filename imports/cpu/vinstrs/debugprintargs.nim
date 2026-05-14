import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    for arg in args[0..^1]:
        echo(arg)
    return 0

register("DEBUGPRINTARGS", execute)