import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import hardware/ram as RAM
import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let highram = args[1]
    let lowram = args[2]

    let regint = parseInt(reg)
    let highramint = parseInt(highram)
    let lowramint = parseInt(lowram)

    if regint < LIMITS.LIM_MINIMUM or regint > LIMITS.LIM_MAXIMUM:
        ErrorApi.ThrowError(ErrorApi.newerr("register value exceeds allowed limits", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))

    procobj.ProcessState.Vm[regint] = RAM.GetAddr(highramint, lowramint)
    return 0

register("LOAD", execute)