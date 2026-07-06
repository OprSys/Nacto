import process/procapi as ProcApi
import cpu/vinstr_registry
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if procobj.ProcessState.ReturnStack.len == 0:
        ErrorApi.ThrowError(ErrorApi.newerr(
            "no prior GO instructions were executed",
            ErrorApi.SysErr.ErrorSeverity.Fatal,
            ErrorApi.ErrTypes.CATEGORY_CPU,
            ErrorApi.ErrTypes.CPU_NOPRIORGO
        ))
    procobj.ProcessState.ProgramCounter = procobj.ProcessState.ReturnStack.pop()
    return 0

register("RET", execute)