when defined(linux):
    import posix
    proc hasStdin*(): bool =
        var readfds: TFDSet
        var tv: Timeval
        FD_ZERO(readfds)
        FD_SET(0, readfds)
        tv.tv_sec = Time(0)
        tv.tv_usec = 0
        result = select(1, addr(readfds), nil, nil, addr(tv)) > 0
elif defined(windows):
    proc kbhit(): cint {.importc: "_kbhit", header: "<conio.h>".}
    proc hasStdin*(): bool = kbhit() != 0
else:
    {.fatal: "hasStdin is not implemented for this platform".}
