type
    RandomAccessMemory = ref object
        Reg: array[32, array[16, int]]

var internal_shared_state = RAM()
var RAM* = internal_shared_state
