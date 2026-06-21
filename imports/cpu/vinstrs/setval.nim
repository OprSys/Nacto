import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let value_to_set = args[1]
    let regint = parseInt(reg)
    if regint < 0 or regint >= ProcApi.ProcTypes.VM_SIZE:
        ErrorApi.ThrowError(ErrorApi.newerr("register index out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))
    let vtsint = parseInt(value_to_set)
    if vtsint < LIMITS.LIM_MINIMUM or vtsint > LIMITS.LIM_MAXIMUM:
        ErrorApi.ThrowError(ErrorApi.newerr("value exceeds allowed limits", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))
    procobj.ProcessState.Vm[regint] = parseInt(value_to_set)
    return 0

register("SETVAL", execute)