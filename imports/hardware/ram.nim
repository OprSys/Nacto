type
    RandomAccessMemory = ref object
        Reg: array[32, array[16, int]]

var internal_shared_state = RandomAccessMemory()
var RAM* = internal_shared_state
