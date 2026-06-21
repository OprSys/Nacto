import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let highlram = args[1]
    let lowlram = args[2]

    let regint = parseInt(reg)
    let highlramint = parseInt(highlram)
    let lowlramint = parseInt(lowlram)

    if regint < LIMITS.LIM_MINIMUM or regint > LIMITS.LIM_MAXIMUM:
        ErrorApi.ThrowError(ErrorApi.newerr("register value exceeds allowed limits", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))

    procobj.ProcessState.Vm[regint] = procobj.ProcessState.LRAM[highlramint][lowlramint]
    return 0

register("PLOAD", execute)
