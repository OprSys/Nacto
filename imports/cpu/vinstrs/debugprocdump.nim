import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    echo(procobj.repr)
    return 0

register("DEBUGPROCDUMP", execute)