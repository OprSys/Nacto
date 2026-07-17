import std/strutils
import std/strformat
import std/terminal

import cpu/vinstr as VINSTRS
import process/procapi as ProcApi
import error/errorapi as ErrorApi
import system/constants
import std/tables
import fs/fsapi as FsApi
import hardware/disk as NactoDisk
export VINSTRS

proc waitforenter(): void =
    while true:
        let c = terminal.getch()
        if c == '\r' or c == '\n':
            break

proc vmToString(procobj: ProcApi.ProcTypes.ProcessObject): string =
    result = ""
    for i in 0..<procobj.ProcessState.Vm.len:
        if i > 0:
            result.add(", ")
        result.add($procobj.ProcessState.Vm[i])

proc error(e: ref ErrorApi.SysErr.SysError, procobj: ProcApi.ProcTypes.ProcessObject): void =
    e.Context.ErrPC = procobj.ProcessState.ProgramCounter
    let formatted = ErrorApi.format(e, constants.DEBUG_MODE)
    when not constants.DEBUG_MODE:
        if e.Context.ErrSeverity == ErrorApi.SysErr.ErrorSeverity.Fatal:
            echo(formatted)
            echo("vm")
            echo(vmToString(procobj))
            echo("\nproc")
            echo(procobj.Name & ":" & $procobj.Id)
    else:
        echo(formatted & "\n")
        if e.Context.ErrSeverity == ErrorApi.SysErr.ErrorSeverity.Fatal:
            echo("vm")
            echo(vmToString(procobj))
            echo("\nproc")
            echo(procobj.Name & ":" & $procobj.Id & ", " & $e.Context.ErrPC)
    if e.Context.ErrSeverity == ErrorApi.SysErr.ErrorSeverity.Fatal:
        procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Terminated
        echo("\nPress Enter to exit.")
        waitforenter()
    elif e.Context.ErrSeverity == ErrorApi.SysErr.ErrorSeverity.Error:
        when constants.DEBUG_MODE:
            procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.WaitingForInput
            echo("\nPress Enter to continue execution. However, please note that things may not go expected.")
            waitforenter()
            procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Running

proc ResolveOperand(token: string, procobj: ProcApi.ProcTypes.ProcessObject): string =
    if token.len >= 2 and token[0] == 'x':
        let regNum = parseInt(token[1..^1])

        if regNum < 0 or regNum >= ProcApi.ProcTypes.VM_SIZE:
            ErrorApi.ThrowError(ErrorApi.newerr("register index out of bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_OOB))

        return $procobj.ProcessState.Vm[regNum]

    return token

proc EvaluateInstr(base: string, args: var seq[string], procobj: ProcApi.ProcTypes.ProcessObject): void =
    if base == "-":
        return
    var ret: int = -1

    if args.len > 0:
        for i in 0..<args.len:
            args[i] = ResolveOperand(args[i], procobj)

    let handler = VINSTRS.vinstr_registry.lookup(base)
    if handler != nil:
        ret = handler(args, procobj)
    else:
        ErrorApi.ThrowError(ErrorApi.newerr("unknown instruction \"" & base & "\"", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_NOINSTR))
    return



proc tokenizeInstr*(str: string): seq[string] =
    var inGroup = false
    var cur: string
    for c in str:
        if c == '|':
            if inGroup:
                result.add(cur)
                cur.setLen(0)
                inGroup = false
            else:
                inGroup = true
        elif inGroup:
            cur.add(c)
        elif c != ' ':
            cur.add(c)
        elif cur.len > 0:
            result.add(cur)
            cur.setLen(0)
    if cur.len > 0:
        result.add(cur)

proc debugprint(msg: string, procobj: ProcApi.ProcTypes.ProcessObject): void =
    let prefix = "[" & procobj.Name & "]"
    echo(prefix & " " & msg)

proc PreRuntime*(procobj: ProcApi.ProcTypes.ProcessObject): bool =
    procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.PreRuntime
    var count = 0
    while count < procobj.ProcessState.RunningProcessString.len:
        let instr = procobj.ProcessState.RunningProcessString[count]
        if instr.startsWith("@"):
            let labelname = instr[1..^1]
            procobj.ProcessState.RunningProcessString[count] = "- /" & labelname
            var subcount = count
            var endpcfound = false
            # tfe = to find end
            for instr_tfe in procobj.ProcessState.RunningProcessString[count..^1]:
                if instr_tfe == "@\\":
                    procobj.ProcessState.RunningProcessString[subcount] = "- \\" & labelname
                    procobj.ProcessState.Labels[labelname] = (StartPC: count, EndPC: subcount)
                    endpcfound = true
                    break
                inc subcount
            if not endpcfound:
                error(ErrorApi.newerr(
                    "label \"" & labelname & "\" missing end marker",
                    ErrorApi.SysErr.ErrorSeverity.Fatal,
                    ErrorApi.ErrTypes.CATEGORY_CPU,
                    ErrorApi.ErrTypes.CPU_NOENDLBL
                ), procobj)
        let instrspl = instr.split(' ')
        case instrspl[0]
        of "INCLUDE":
            let path = instrspl[1]
            let obj = FsApi.ResolvePath(path)
            if obj == nil:
                error(ErrorApi.newerr(
                    "include file not found",
                    ErrorApi.SysErr.ErrorSeverity.Fatal,
                    ErrorApi.ErrTypes.CATEGORY_FS,
                    ErrorApi.ErrTypes.FS_NOPATH
                ), procobj)
            if obj of NactoDisk.DiskTypes.Directory:
                error(ErrorApi.newerr(
                    "cannot include a directory",
                    ErrorApi.SysErr.ErrorSeverity.Fatal,
                    ErrorApi.ErrTypes.CATEGORY_FS,
                    ErrorApi.ErrTypes.FS_INVCDO
                ), procobj)
            let includefile = cast[NactoDisk.DiskTypes.File](obj)
            if includefile.FileType != NactoDisk.DiskTypes.FT.FileTypes.ImportableBinary:
                error(ErrorApi.newerr(
                    "file is not an importable binary",
                    ErrorApi.SysErr.ErrorSeverity.Fatal,
                    ErrorApi.ErrTypes.CATEGORY_FS,
                    ErrorApi.ErrTypes.FS_INVCDO
                ), procobj)
            let lines = includefile.Data.split('\n')
            for line in lines:
                procobj.ProcessState.RunningProcessString.add(line)
            procobj.ProcessState.RunningProcessString[count] = "- INCLUDE"
        inc count

    if not procobj.ProcessState.Labels.hasKey("PRIOR"):
        error(ErrorApi.newerr(
            "no PRIOR label found",
            ErrorApi.SysErr.ErrorSeverity.Fatal,
            ErrorApi.ErrTypes.CATEGORY_CPU,
            ErrorApi.ErrTypes.CPU_NOPRIMLBL
        ), procobj)
    procobj.ProcessState.ProgramCounter = procobj.ProcessState.Labels["PRIOR"].StartPC
    procobj.ProcessState.Running = ProcApi.ProcTypes.IsRunningState.Running
    return true

proc ProcessStep*(procobj: ProcApi.ProcTypes.ProcessObject): bool =
    if procobj.ProcessState.PendingSignals.len > 0:
        let signal = procobj.ProcessState.PendingSignals.pop()
        if signal.CanBeOverridden:
            if procobj.ProcessState.Labels.hasKey(signal.Name):
                procobj.ProcessState.ReturnStack.add(procobj.ProcessState.ProgramCounter)
                procobj.ProcessState.ProgramCounter = procobj.ProcessState.Labels[signal.Name].StartPC
            else:
                case signal.Id
                of 2:
                    ProcApi.ProcTypes.SIG_TERM_default(procobj)
                    return false
                else:
                    return true
        else:
            case signal.Id
            of 1:
                ProcApi.ProcTypes.SIG_FTERM_default(procobj)
                return false
            else:
                return true
    let pc = procobj.ProcessState.ProgramCounter
    if pc >= procobj.ProcessState.RunningProcessString.len:
        error(ErrorApi.newerr("program counter exceeded program bounds", ErrorApi.SysErr.ErrorSeverity.Fatal, ErrorApi.ErrTypes.CATEGORY_CPU, ErrorApi.ErrTypes.CPU_PRGRMEND), procobj)
        return false

    let instr = procobj.ProcessState.RunningProcessString[pc]
    when constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
        echo("Instruction: " & instr)
        echo("Program counter: " & $pc)

    if instr.len == 0:
        error(ErrorApi.newerr(
            "no instruction to execute",
            ErrorApi.SysErr.ErrorSeverity.Fatal,
            ErrorApi.ErrTypes.CATEGORY_CPU,
            ErrorApi.ErrTypes.CPU_ABSENTINSTR
        ), procobj)
        return false

        
    let tokenized = tokenizeInstr(instr)

    if tokenized.len == 0:
        return true

    let base = tokenized[0]
    var args = tokenized[1..^1]

    when constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
        echo("\nInstruction RunningProcessString[" & $pc & "] tokenized.")
        echo("Token: " & $tokenized)
        echo("Base: " & base)
        echo("Arguments: " & $args)

    let prevPc = procobj.ProcessState.ProgramCounter
    let prevLen = procobj.ProcessState.RunningProcessString.len
    when constants.DEBUG_MODE and constants.DEBUG_VERBOSE:
        echo("prevPc, prevLen = " & $prevPc & ", " & $prevLen)
    try:
        when DEBUG_MODE and DEBUG_VERBOSE:
            echo("Executing instruction \"" & base & "\"...")
        EvaluateInstr(base, args, procobj)
    except ErrorApi.SysErr.SysError as e:
        error(e, procobj)

    if procobj.ProcessState.ProgramCounter == prevPc:
        if procobj.ProcessState.RunningProcessString.len == prevLen:
            if procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.Running:
                inc procobj.ProcessState.ProgramCounter
    
    return procobj.ProcessState.Running == ProcApi.ProcTypes.IsRunningState.Running
