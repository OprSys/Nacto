import std/strutils

import process/procapi as ProcApi
import process/types/proctypes as ProcTypes
import cpu/vinstr_registry

import cpu/errors/all as BINERRC
import cpu/types/limits as LIMITS

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let highslot = parseInt(args[0])
    let countto = parseInt(args[1])

    if highslot < 0 or highslot >= ProcTypes.HIGH:
        raise newException(BINERRC.OutOfBounds, "RAM high-level slot " & $highslot & " is not in the range of 0 to " & $(ProcTypes.HIGH - 1))

    let values = args[2..^1]
    let count = values.len

    if count > ProcTypes.LOW:
        raise newException(BINERRC.OutOfBounds, "too many values for a single highslot (" & $count & " > " & $ProcTypes.LOW & ")")

    for i in 0..<count:
        let val = parseInt(values[i])
        if val < LIMITS.LIM_MINIMUM or val > LIMITS.LIM_MAXIMUM:
            raise newException(BINERRC.LimitExceeded, values[i] & " is not in the range of " & $LIMITS.LIM_MINIMUM & " to " & $LIMITS.LIM_MAXIMUM)
        procobj.ProcessState.LRAM[highslot][i] = val

    procobj.ProcessState.Vm[countto] = count
    return 0

register("DATA", execute)
