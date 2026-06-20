import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let val = args[0]
    let highlram = args[1]
    let lowlram = args[2]

    let valint = parseInt(val)
    let highlramint = parseInt(highlram)
    let lowlramint = parseInt(lowlram)

    if valint < LIMITS.LIM_MINIMUM or valint > LIMITS.LIM_MAXIMUM:
        raise newException(BINERRC.LimitExceeded, val & " is not in the range of " & $LIMITS.LIM_MINIMUM & " to " & $LIMITS.LIM_MAXIMUM)

    procobj.ProcessState.LRAM[highlramint][lowlramint] = valint
    return 0

register("PSTORE", execute)
