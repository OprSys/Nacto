import process/procapi as ProcApi
import cpu/vinstr_registry

import hardware/ram as RAM

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    echo RAM.RAM.repr
    return 0

register("DEBUGRAMDUMP", execute)