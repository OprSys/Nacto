import std/tables

import process/procapi as ProcApi
import cpu/vinstr_registry
import error/errorapi as ErrorApi

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if args.len < 1:
        ErrorApi.ThrowError(ErrorApi.newerr("IDEF requires at least a name argument", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVSYN))
    var use_args = false
    let instrname = args[0]
    let args = args[1..^1]
    if args.len > 0:
        use_args = true
    
    var fetched: seq[string] = @[]
    
    var startpc: int = procobj.ProcessState.ProgramCounter + 1
    var endpc = -1
    for i in startpc..procobj.ProcessState.RunningProcessString.len-1:
        let line = procobj.ProcessState.RunningProcessString[i]
        fetched.add(line)
        if line == "IEND":
            endpc = i
            break
    if endpc == -1:
        ErrorApi.ThrowError(ErrorApi.newerr("IDEF without matching IEND", ErrorApi.SysError.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_INVSYN))
    var mendpc = endpc+1
    if mendpc > procobj.ProcessState.RunningProcessString.len:
        mendpc = procobj.ProcessState.RunningProcessString.len
    discard vinstr_registry.lookup("JMP")(@[$mendpc], procobj)

    var customArgs: seq[ProcApi.ProcTypes.CustomInstrArgumentObject] = @[]
    if use_args:
        for a in args:
            customArgs.add(ProcApi.ProcTypes.CustomInstrArgumentObject(Name: a))

    var custominstr = ProcApi.ProcTypes.CustomInstrObject(
        Name: instrname,
        StartPC: startpc,
        EndPC: endpc,
        Arguments: customArgs
    )
    procobj.ProcessState.CustomInstrs[instrname] = custominstr
    return 0

register("IDEF", execute)