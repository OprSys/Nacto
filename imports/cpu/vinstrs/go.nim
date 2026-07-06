import std/tables
import process/procapi as ProcApi
import cpu/vinstr_registry
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let labelName = args[0]
    if not procobj.ProcessState.Labels.hasKey(labelName):
        ErrorApi.ThrowError(ErrorApi.newerr(
            "unknown label \"" & labelName & "\"",
            ErrorApi.SysErr.ErrorSeverity.Fatal,
            ErrorApi.ErrTypes.CATEGORY_CPU,
            ErrorApi.ErrTypes.CPU_NOLBL
        ))
    let label = procobj.ProcessState.Labels[labelName]
    procobj.ProcessState.ReturnStack.add(procobj.ProcessState.ProgramCounter + 1)
    procobj.ProcessState.ProgramCounter = label.StartPC
    return 0

register("GO", execute)