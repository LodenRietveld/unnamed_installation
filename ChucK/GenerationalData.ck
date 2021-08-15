public class GenerationalData {
	0 => int DEBUG;

	0 => int ATTACK;
	1 => int DECAY;
	2 => int SUSTAIN;
	3 => int RELEASE;
	4 => int FILTER_FREQ;
	5 => int FILTER_ENV_AMT;
	6 => int OSC_WAVEFORM;
	7 => int NOISE_FM_AMT;
	8 => int ARPEGGIO_SPREAD;

	GenerationalMetaData gmd;

	0.006 => float start_random_mutation_thresh;
	0.03 => float stop_random_mutation_thresh;

	9 => int number_of_parameters;
	.1::second => dur mutate_speed;

	10 => int history_length;

	(history_length - 1) / history_length => float history_value_weight;
	1. - history_value_weight => float new_value_weight;

	float diff_history_avg[number_of_parameters];

	int mutating_to_random;
	float target_dna[number_of_parameters];
	float value_start_and_distance_to_target[number_of_parameters][2];

	GenerationalDataPoint data[number_of_parameters];
	float normalized_array[number_of_parameters];
	float normalized_scaled_array[number_of_parameters];

	set_defaults();
	initialize_to_random();
	normalize_dna_to_array();

	fun float get(int idx){
		if (idx > -1 && idx < number_of_parameters){
			return data[idx].get_value();
		} else {
			return -999999.;
		}
	}

	fun float get_scaled(int idx){
		if (idx > -1 && idx < number_of_parameters){
			return data[idx].get_scaled_value();
		} else {
			return -999999.;
		}
	}

	fun string generate_osc_string(){
		"/dna" => string out;
		for (int i; i < number_of_parameters; i++){
			out + ", f" => out;
		}

		//use this final integer to indicate index
		out + ",i" => out;

		return out;
	}

	fun string generate_visualizer_osc_string(){
		"/osc" => string out;
		",i" +=> out;
		for (int i; i < number_of_parameters; i++){
			out + ",f" => out;
		}

		return out;
	}

	fun void set(int idx, float val){
		if (idx > -1 && idx < number_of_parameters){
			data[idx].set_value(val);
			update_normalized_array(idx);
		}
	}

	fun void mutate_param_target(int idx){
		if (idx > -1 && idx < number_of_parameters){
			data[idx].mutate_get_value(gmd.random_influence_range) => target_dna[idx];

 			data[idx].get_value() => value_start_and_distance_to_target[idx][0];
			target_dna[idx] - value_start_and_distance_to_target[idx][0] => value_start_and_distance_to_target[idx][1];
		}
	}

	fun void random_param_mutate(){
		gmd.random_number_of_parameters_curve[Math.random2(0, 255)] => int mutate_count;
		int mutated[number_of_parameters];
		int idx;

		while(mutate_count > 0){
			if (Math.random2f(0, 1.) < 1. / number_of_parameters){
				if (mutated[idx]){
					(idx + 1) % number_of_parameters => idx;
					continue;
				} else {
					1 => mutated[idx];
				}

				mutate_param_target(idx);
				mutate_count--;
			}

			(idx + 1) % number_of_parameters => idx;
		}

		1 => mutating_to_random;
	}

	fun void set_mutation_target(float other_parameters[], int sender_index){
		if (!mutating_to_random) {
			other_parameters @=> target_dna;
			for (int i; i < number_of_parameters; i++){
				data[i].set_other_entity_value(sender_index, other_parameters[i]);
			}
		}
	}

	fun void mutate_step(){
		for (int i; i < number_of_parameters; i++){
			target_dna[i] => float other_parameter_val;
			data[i].get_value() => float old_param_val;
			(gmd.other_influence_range_step * other_parameter_val) + ((1. - gmd.other_influence_range_step) *  old_param_val) => float new_param_val;

			data[i].set_value(new_param_val);
			update_normalized_array(i);

			Math.fabs((difference_range(i, old_param_val, other_parameter_val) * new_value_weight) + (diff_history_avg[i] * history_value_weight)) => diff_history_avg[i];
		}
	}

	fun int should_add_random_mutation(){
		float sum;

		for (int i; i < number_of_parameters; i++){
			sum + diff_history_avg[i] => sum;
		}

		sum / number_of_parameters => float difference;
		average_target_current_difference() => float target_current_diff;

		difference < start_random_mutation_thresh => int should_mutate;
		target_current_diff < stop_random_mutation_thresh => int should_stop_mutate;

		if (DEBUG){
			<<< "Mutating to random: " + Std.itoa(mutating_to_random) + ", should_stop_mutate: " + Std.itoa(should_stop_mutate) + ", should_mutate: " + Std.itoa(should_mutate) + ", target_current_diff: " + Std.ftoa(target_current_diff, 5)>>>;
		}
 		if (mutating_to_random) {
			if (should_stop_mutate) 0 => mutating_to_random;
 			return should_mutate;
 		}

		if (should_mutate) 1 => mutating_to_random;

		return should_mutate;
	}

	fun float difference_range(int index, float old, float _new){
		float bounds[3];
		data[index].get_bounds() @=> bounds;
		return ((_new - old) - bounds[0]) / bounds[1];
	}

	fun float average_target_current_difference(){
		float sum;

		for (int i; i < number_of_parameters; i++){
			if (value_start_and_distance_to_target[i][1] == 0) continue;
			Math.fabs((data[i].get_value() - value_start_and_distance_to_target[i][0]) / value_start_and_distance_to_target[i][1]) +=> sum;
		}

		return sum / number_of_parameters;
	}

	fun void print_all(){
		float diff_sum;
		for (int i; i < number_of_parameters; i++){
			<<< data[i].get_name() + ": " + data[i].get_value() >>>;
			diff_sum + diff_history_avg[i] => diff_sum;
		}

		<<< "Difference range: " + diff_sum/number_of_parameters >>>;
	}

	fun void update_normalized_array(int i){
		data[i].get_normalized() => normalized_array[i];
		data[i].scale(normalized_array[i]) => normalized_scaled_array[i];
	}

	fun float[] normalize_dna_to_array(){
		for (int i; i < number_of_parameters; i++){
			data[i].get_normalized() => normalized_array[i];
			data[i].scale(normalized_array[i]) => normalized_scaled_array[i];
		}

		return normalized_array;
	}

	fun float[] get_normalized_array(){
		return normalized_array;
	}

	fun float[] get_normalized_scaled_array(){
		return normalized_scaled_array;
	}

	fun string get_name_typetag(string start){
		start => string out;
		for (int i; i < number_of_parameters; i++){
			",s" +=> out;
		}

		 return out;
	}
	fun string[] get_names(){
		string param_names[number_of_parameters];

		for (int i; i < number_of_parameters; i++){
			data[i].get_name() => param_names[i];
		}

		return param_names;
	}

	fun void init_data_points(int number_entities){
		for (int i; i < number_of_parameters; i++){
			data[i].set_other_entity_number(number_entities);
		}
	}

	fun void set_defaults(){
		gmd.generate_param_curve(number_of_parameters);

		ParabolicCurve curve_adsr;

		data[ATTACK].init("Attack", 0., 1000., curve_adsr);
		data[DECAY].init("Decay", 10., 10000., curve_adsr);
		data[SUSTAIN].init("Sustain", 0., 1., curve_adsr);
		data[RELEASE].init("Release", 10., 10000., curve_adsr);
		data[FILTER_FREQ].init("Filter freq", 100., 15000., curve_adsr);
		data[FILTER_ENV_AMT].init("Filter env amt", 0., 1.);
		data[OSC_WAVEFORM].init("Osc waveform", 0., 1.);
		data[NOISE_FM_AMT].init("Noise FM", 0., .05);
		data[ARPEGGIO_SPREAD].init("Arp spread", 0., 500.);
	}

	fun void initialize_to_random(){
		for(int i; i < number_of_parameters; i++){
			data[i].set_random();
			data[i].get_value() => target_dna[i];
			data[i].set_random();
		}
	}
}
