public class ParabolicCurve extends ParameterCurve {
    fun void initialize_curve(){
        new float[resolution] @=> curve;
        for (int i; i < resolution; i++){
            Math.pow(i / (resolution $ float), 2) => curve[i];
        }
    }
}
