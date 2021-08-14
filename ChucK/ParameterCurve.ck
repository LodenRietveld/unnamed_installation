public class ParameterCurve {
    int resolution;
    float curve[];

    init(256);

    fun void init(int res){
        res => resolution;
        initialize_curve();
    }

    fun void initialize_curve(){
        return;
    };

    fun float curve_value(float normalized_value_in){
        return curve[Math.floor(normalized_value_in * resolution) $ int];
    }
}
