import error/types/syserr as SysError
import error/types/errtypes as ErrTypes
export SysError
export ErrTypes

import system/constants

proc newerr*(reason: string, severity: SysError.ErrorSeverity, category: int, kind: int): ref SysError.SysError =
    var context = SysError.ErrorContext()
    context.ErrSeverity = severity
    context.ErrCategory = category
    context.ErrKind = kind
    ##context.ErrPC = 69420
    # Caller sets PC, not here
    new(result)
    result.Reason = reason
    result.Context = context


proc format*(error: ref SysError.SysError, alsousehumanreadablestring: bool): string =
    var severitystr: string
    var reasonstr: string
    var errcodestr: string
    var errpcstring: string
    errpcstring = $error.Context.ErrPC
    case error.Context.ErrSeverity
    of SysError.ErrorSeverity.Error:
        severitystr = "ERROR"
    of SysError.ErrorSeverity.Fatal:
        severitystr = "FATAL"
    else:
        severitystr = "UNK"
    if alsousehumanreadablestring:
        reasonstr = error.Reason
    else:
        reasonstr = ""
    errcodestr = $error.Context.ErrCategory & ";" & $error.Context.ErrKind
    result = "[" & severitystr & "] " & errcodestr & "\n" & reasonstr

proc ThrowError*(error: ref SysError.SysError): void =
    raise error