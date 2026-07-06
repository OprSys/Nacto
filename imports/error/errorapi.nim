import error/types/syserr as SysErr
import error/types/errtypes as ErrTypes
export SysErr
export ErrTypes

proc newerr*(reason: string, severity: SysErr.ErrorSeverity, category: int, kind: int): ref SysErr.SysError =
    var context = SysErr.ErrorContext()
    context.ErrSeverity = severity
    context.ErrCategory = category
    context.ErrKind = kind
    ##context.ErrPC = 69420
    # Caller sets PC, not here
    new(result)
    result.Reason = reason
    result.Context = context


proc format*(error: ref SysErr.SysError, alsousehumanreadablestring: bool): string =
    var severitystr: string
    var reasonstr: string
    var errcodestr: string
    var errpcstring: string
    errpcstring = $error.Context.ErrPC
    case error.Context.ErrSeverity
    of SysErr.ErrorSeverity.Error:
        severitystr = "ERROR"
    of SysErr.ErrorSeverity.Fatal:
        severitystr = "FATAL"
    else:
        severitystr = "UNK"
    if alsousehumanreadablestring:
        reasonstr = error.Reason
    else:
        reasonstr = ""
    errcodestr = $error.Context.ErrCategory & ";" & $error.Context.ErrKind
    result = "[" & severitystr & "] " & errcodestr & "\n" & reasonstr

proc ThrowError*(error: ref SysErr.SysError): void =
    raise error