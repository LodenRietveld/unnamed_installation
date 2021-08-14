public class Lock {
    Event lock_wait;
    int lock_in_use;

    fun void take(){
        if (lock_in_use){
            lock_wait => now;
        }

        1 => lock_in_use;
    }

    fun void release(){
        lock_wait.signal();

        0 => lock_in_use;
    }
}
