public class GenerationalDataPoint {
    Float value;
    float all_entity_values[];
    int num_entities;
    float average_entity_value;
    float entity_value_variance;
    Vector bounds;
    ParameterCurve @ p;
    int has_curve;
    string name;

    fun void init(string name, float min, float max, ParameterCurve @ pc){
        set_name(name);
        set_bounds(min, max);
        set_bound_range();
        pc @=> p;
        1 => has_curve;
        set_other_entity_number(num_entities);
    }

    fun void init(string name, float min, float max){
        set_name(name);
        set_bounds(min, max);
        set_bound_range();
        0 => has_curve;
        set_other_entity_number(num_entities);
    }

    fun void set_other_entity_number(int num_entities){
        num_entities => this.num_entities;
        new float[num_entities] @=> all_entity_values;
    }

    fun void set_other_entity_value(int i, float value){
        if (i < num_entities && i >= 0){
            value => all_entity_values[i];
            update_average_entity_value();
            calculate_variance();
        }
    }

    fun float get_variance(){
        return entity_value_variance;
    }

    fun void update_average_entity_value(){
        0 => average_entity_value;
        for (int i; i < num_entities; i++){
            all_entity_values[i] +=> average_entity_value;
        }

        num_entities /=> average_entity_value;
    }

    fun void calculate_variance(){
        float var_sum;

        for (int i; i < num_entities; i++){
            Math.pow(all_entity_values[i] - average_entity_value, 2) +=> var_sum;
        }

        var_sum / num_entities => entity_value_variance;
    }

    fun float get_scaled_value(){
        if (has_curve){
            return bounds.x + (bounds.y * p.curve_value(get_normalized()));
        } else {
            return value.val;
        }
    }

    fun float scale(float in){
        if (has_curve && in >= 0 && in < 1.){
            return p.curve_value(in);
        } else {
            return in;
        }
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

    fun float mutate_get_value(float mutate_range){
        value.val + (bounds.z * Math.random2f(-mutate_range, mutate_range)) => float new_value;

        return new_value;
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
