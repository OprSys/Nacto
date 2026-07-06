import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import hardware/ram as RAM
import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = args[0]
    let highram = args[1]
    let lowram = args[2]

    let valint = parseInt(val)
    let highramint = parseInt(highram)
    let lowramint = parseInt(lowram)

    if valint < LIMITS.LIM_MINIMUM or valint > LIMITS.LIM_MAXIMUM:
        ErrorApi.ThrowError(ErrorApi.newerr("value exceeds allowed limits", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))

    RAM.SetAddr(highramint, lowramint, valint)
    return 0

register("STORE", execute)