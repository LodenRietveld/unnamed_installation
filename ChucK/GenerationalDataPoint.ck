public class GenerationalDataPoint {
    Float value;
    Vector bounds;
    int paramater_value_curve; //todo
    string name;

    fun void init(string name, float min, float max){
        set_name(name);
        set_bounds(min, max);
    }

    fun float get_value(){
        return value.val;
    }

    fun void set_name(string name){
        name => this.name;
    }

    fun void set_value(float value){
        value => this.value.val;
    }

    fun void set_bounds(float min, float max){
        min => bounds.x;
        max => bounds.y;
    }
}
