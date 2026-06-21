import process/procapi as ProcApi
import cpu/vinstr_registry
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if procobj.ProcessState.ReturnBack.len == 0:
        ErrorApi.ThrowError(ErrorApi.newerr("IEND with no matching ICALL", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_NOINSTR))
    let retAddr = procobj.ProcessState.ReturnBack.pop()
    discard procobj.ProcessState.CurrentCustomInstr.pop()
    discard vinstr_registry.lookup("JMP")(@[$retAddr], procobj)
    return 0

register("IEND", execute)