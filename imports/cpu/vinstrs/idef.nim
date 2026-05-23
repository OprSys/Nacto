import std/sequtils
import std/tables

import process/procapi as ProcApi
import cpu/vinstr_registry

import cpu/errors/all as BINERRC

proc execute*(args: seq[string], procobj: ProcApi.ProcTypes.ProcessObject): int =
    if args.len < 1:
        raise newException(BINERRC.InvalidSyntax, "too few arguments (< 1)")
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
        raise newException(BINERRC.InvalidSyntax, "expected `IEND` instruction")
    var mendpc = endpc+1
    if mendpc > procobj.ProcessState.RunningProcessString.len:
        mendpc = procobj.ProcessState.RunningProcessString.len
    discard vinstr_registry.lookup("JMP")(@[$mendpc], procobj)
    
    var custominstr = ProcApi.ProcTypes.CustomInstrObject(
        Name: instrname,
        StartPC: startpc,
        EndPC: endpc,
        Arguments: if use_args: args.mapIt(ProcApi.ProcTypes.CustomInstrArgumentObject(Name: it)) else: @[]
    )
    procobj.ProcessState.CustomInstrs[instrname] = custominstr
    return 0

register("IDEF", execute)