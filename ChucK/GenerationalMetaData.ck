public class GenerationalMetaData {
	int random_number_of_parameters_curve[256];
	0.6 => static float random_influence_range;
	0.025 => static float other_influence_range;
	other_influence_range / 5 => static float other_influence_range_step;

	fun void generate_param_curve(int number_of_parameters){
		for (int i; i < 255; i++){
			Math.floor(1 + (Math.pow(i / 255., 3) * ((number_of_parameters - 1) $ float))) $ int => random_number_of_parameters_curve[i];
		}
	}
}
