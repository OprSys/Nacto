import std/strutils

import process/procapi as ProcApi
import process/types/proctypes as ProcTypes
import cpu/vinstr_registry

import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let highslot = parseInt(args[0])
    let countto = parseInt(args[1])

    if highslot < 0 or highslot >= ProcTypes.HIGH:
        ErrorApi.ThrowError(ErrorApi.newerr("LRAM high slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

    let values = args[2..^1]
    let count = values.len

    if count > ProcTypes.LOW:
        ErrorApi.ThrowError(ErrorApi.newerr("LRAM low slot out of bounds", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

    for i in 0..<count:
        let val = parseInt(values[i])
        if val < LIMITS.LIM_MINIMUM or val > LIMITS.LIM_MAXIMUM:
            ErrorApi.ThrowError(ErrorApi.newerr("data value exceeds allowed limits", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))
        procobj.ProcessState.LRAM[highslot][i] = val

    discard vinstr_registry.lookup("SETVAL")(@[$countto, $count], procobj)
    return 0

register("DATA", execute)