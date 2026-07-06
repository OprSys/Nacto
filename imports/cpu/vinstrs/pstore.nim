import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/types/limits as LIMITS
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = args[0]
    let highlram = args[1]
    let lowlram = args[2]

    let valint = parseInt(val)
    let highlramint = parseInt(highlram)
    let lowlramint = parseInt(lowlram)

    if valint < LIMITS.LIM_MINIMUM or valint > LIMITS.LIM_MAXIMUM:
        ErrorApi.ThrowError(ErrorApi.newerr("value exceeds allowed limits", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_LIMEXC))

    procobj.ProcessState.LRAM[highlramint][lowlramint] = valint
    return 0

register("PSTORE", execute)
