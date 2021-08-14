public class GenerationalDataPoint {
    Float value;
    Vector bounds;
    int paramater_value_curve; //todo
    string name;

    fun void init(string name, float min, float max){
        set_name(name);
        set_bounds(min, max);
        set_bound_range();
    }

    fun float get_value(){
        return value.val;
    }

    fun string get_name(){
        return name;
    }

    fun float[] get_bounds(){
        return [bounds.x, bounds.y, bounds.z];
    }

    fun float get_normalized(){
        return (value.val - bounds.x) / bounds.y;
    }

    fun void set_name(string name){
        name => this.name;
    }

    fun void set_value(float new_value){
        if (new_value <= bounds.x){
            bounds.x => value.val;
        } else if (new_value >= bounds.y){
            bounds.y => value.val;
        } else {
            new_value => this.value.val;
        }
    }

    fun void mutate_set_value(float mutate_range){
        value.val + (bounds.z * Math.random2f(-mutate_range, mutate_range)) => float new_value;

        set_value(new_value);
    }

    fun void set_bound_range(){
        Math.fabs(bounds.y - bounds.x) => bounds.z;
    }

    fun void set_bounds(float min, float max){
        min => bounds.x;
        max => bounds.y;
    }

    fun void set_random(){
        Math.random2f(bounds.x, bounds.y) => value.val;
    }
}
