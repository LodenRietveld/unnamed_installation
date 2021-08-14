public class GenerationalData {
	Float attack_lerp;
	0 => int ATTACK;
	Float decay_lerp;
	1 => int DECAY;
	Float sustain_lerp;
	2 => int SUSTAIN;
	Float release_lerp;
	3 => int RELEASE;

	Float filter_freq_lerp;
	4 => int FILTER_FREQ;
	Float filter_env_amt_lerp;
	5 => int FILTER_ENV_AMT;

	Float osc_waveform_lerp;
	6 => int OSC_WAVEFORM;

	//NEW DATA TYPE FOR GENERATION DATA POINTS, SET PARAMETER VALUE CURVE
	//noise should be very low most of the time but it could be cool to have it at a high value
	//need scaling to get a lot of detail in the low end but also allow high values
	Float noise_fm_amt_lerp;
	7 => int NOISE_FM_AMT;

	Float arpeggio_spread;
	8 => int ARPEGGIO_SPREAD;


	Vector ATTACK_BOUNDS;
	Vector DECAY_BOUNDS;
	Vector SUSTAIN_BOUNDS;
	Vector RELEASE_BOUNDS;

	Vector FILTER_FREQ_BOUNDS;
	Vector FILTER_ENV_AMT_BOUNDS;

	Vector OSC_WAVEFORM_BOUNDS;
	Vector NOISE_FM_AMT_BOUNDS;

	Vector ARPEGGIO_SPREAD_BOUNDS;

	GenerationalMetaData gmd;

	0.0015 => float start_random_mutation_thresh;

	9 => int number_of_parameters;
	.1::second => dur mutate_speed;

	10 => int history_length;

	(history_length - 1) / history_length => float history_value_weight;
	1. - history_value_weight => float new_value_weight;

	float diff_history_avg[number_of_parameters];

	[attack_lerp, decay_lerp, sustain_lerp, release_lerp, filter_freq_lerp, filter_env_amt_lerp, osc_waveform_lerp, noise_fm_amt_lerp] @=> Float@ pointer_to_named_data[];
	[ATTACK_BOUNDS, DECAY_BOUNDS, SUSTAIN_BOUNDS, RELEASE_BOUNDS, FILTER_FREQ_BOUNDS, FILTER_ENV_AMT_BOUNDS, OSC_WAVEFORM_BOUNDS, NOISE_FM_AMT_BOUNDS] @=> Vector@ BOUNDS[];
	["Attack", "Decay", "Sustain", "Release", "Filter frequency", "Filter envelope amount", "Oscillator waveform", "Noise FM amount"] @=> string param_names[];
	float normalized_array[number_of_parameters];


	set_defaults();
	initialize_to_random();
	normalize_dna_to_array();

	fun float get(int idx){
		if (idx > -1 && idx < number_of_parameters){
			return pointer_to_named_data[idx].val;
		} else {
			return -999999.;
		}
	}

	fun string generate_osc_string(){
		"/dna" => string out;
		for (int i; i < number_of_parameters; i++){
			out + ", f" => out;
		}

		//use this final integer to control when to send the message
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
			val => pointer_to_named_data[idx].val;
			update_normalized_array(idx);
		}
	}

	fun void mutate_param(int idx){
		if (idx > -1 && idx < number_of_parameters){
			pointer_to_named_data[idx].val + (BOUNDS[idx].z * Math.random2f(-gmd.random_influence_range, gmd.random_influence_range)) => pointer_to_named_data[idx].val;

			if (pointer_to_named_data[idx].val < BOUNDS[idx].x){
				BOUNDS[idx].x => pointer_to_named_data[idx].val;
			} else if (pointer_to_named_data[idx].val > BOUNDS[idx].y){
				BOUNDS[idx].y => pointer_to_named_data[idx].val;
			}

			update_normalized_array(idx);
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

				mutate_param(idx);
				mutate_count--;
			}

			(idx + 1) % number_of_parameters => idx;
		}
	}

	fun void mutate_towards(float other_parameters[]){
		for (int i; i < number_of_parameters; i++){
			other_parameters[i] => float other_parameter_val;
			pointer_to_named_data[i].val => float old_param_val;
			(gmd.other_influence_range * other_parameter_val) + ((1. - gmd.other_influence_range) *  old_param_val) => float new_param_val;

			if (new_param_val <= BOUNDS[i].x){
				BOUNDS[i].x => new_param_val;
			} else if (new_param_val >= BOUNDS[i].y){
				BOUNDS[i].y => new_param_val;
			}

			new_param_val => pointer_to_named_data[i].val;

			update_normalized_array(i);

			Math.fabs((difference_range(i, old_param_val, other_parameter_val) * new_value_weight) + (diff_history_avg[i] * history_value_weight)) => diff_history_avg[i];
		}
	}

	fun int should_add_random_mutation(){
		float sum;

		for (int i; i < number_of_parameters; i++){
			sum + diff_history_avg[i] => sum;
		}
		return sum / number_of_parameters < start_random_mutation_thresh;
	}

	fun float difference_range(int index, float old, float _new){
		return ((_new - old) - BOUNDS[index].x) / BOUNDS[index].y;
	}

	fun void set_attack(float val){
		val => attack_lerp.val;
	}

	fun void set_decay(float val){
		val => decay_lerp.val;
	}

	fun void set_sustain(float val){
		val => sustain_lerp.val;
	}

	fun void set_release(float val){
		val => release_lerp.val;
	}

	fun void set_filter_freq(float val){
		val => filter_freq_lerp.val;
	}

	fun void set_filter_env_amt(float val){
		val => filter_env_amt_lerp.val;
	}

	fun void set_osc_waveform(float val){
		val => osc_waveform_lerp.val;
	}

	fun void set_noise_fm_amt(float val){
		val => noise_fm_amt_lerp.val;
	}

	fun void print_all(){
		float diff_sum;
		for (int i; i < number_of_parameters; i++){
			<<< param_names[i] + ": " + pointer_to_named_data[i].val >>>;
			diff_sum + diff_history_avg[i] => diff_sum;
		}

		<<< "Difference range: " + diff_sum/number_of_parameters >>>;
	}

	fun void update_normalized_array(int i){
		(pointer_to_named_data[i].val - BOUNDS[i].x) / BOUNDS[i].y => normalized_array[i];
	}

	fun float[] normalize_dna_to_array(){
		for (int i; i < number_of_parameters; i++){
			(pointer_to_named_data[i].val - BOUNDS[i].x) / BOUNDS[i].y => normalized_array[i];
		}

		return normalized_array;
	}

	fun float[] get_normalized_array(){
		return normalized_array;
	}

	fun string get_name_typetag(string start){
		start => string out;
		for (int i; i < number_of_parameters; i++){
			",s" +=> out;
		}

		 return out;
	}
	fun string[] get_names(){
		return param_names;
	}


	fun void set_defaults(){
		gmd.generate_param_curve(number_of_parameters);

		0. =>           ATTACK_BOUNDS.x;
		1000. =>        ATTACK_BOUNDS.y;
		10. =>          DECAY_BOUNDS.x;
		10000. =>       DECAY_BOUNDS.y;
		0. =>           SUSTAIN_BOUNDS.x;
		1. =>           SUSTAIN_BOUNDS.y;
		10. =>          RELEASE_BOUNDS.x;
		10000. =>       RELEASE_BOUNDS.y;
		100. =>         FILTER_FREQ_BOUNDS.x;
		15000. =>       FILTER_FREQ_BOUNDS.y;
		0. =>           FILTER_ENV_AMT_BOUNDS.x;
		1. =>           FILTER_ENV_AMT_BOUNDS.y;
		0. =>           OSC_WAVEFORM_BOUNDS.x;
		1. =>           OSC_WAVEFORM_BOUNDS.y;
		0. =>           NOISE_FM_AMT_BOUNDS.x;
		.05 =>           NOISE_FM_AMT_BOUNDS.y;


		for (int i; i < number_of_parameters; i++){
			Math.fabs(BOUNDS[i].y - BOUNDS[i].x) => BOUNDS[i].z;
		}
	}

	fun void initialize_to_random(){
		for(int i; i < number_of_parameters; i++){
			Math.random2f(BOUNDS[i].x, BOUNDS[i].y) => pointer_to_named_data[i].val;
		}
	}
}
