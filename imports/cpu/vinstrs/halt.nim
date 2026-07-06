import process/procapi as ProcApi
import cpu/vinstr_registry

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Terminated
    return 0

register("HALT", execute)