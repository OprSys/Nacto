import std/strutils

import process/procapi as ProcApi
import cpu/vinstr_registry

import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    let reg = args[0]
    let n1 = args[1]
    let n2 = args[2]

    let n1int = parseInt(n1)
    let n2int = parseInt(n2)

    if n2int == 0:
        ErrorApi.ThrowError(ErrorApi.newerr("division by zero", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_DIVBYZERO))
    let answer = n1int div n2int

    discard vinstr_registry.lookup("SETVAL")(@[reg, $answer], procobj)
    return 0

register("DIV", execute)
