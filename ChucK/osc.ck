class InternalOscData {
	0 => int index;
	0 => int num_other_entities;
	0 => int port_offset;
	-1 => int port_in;
	OscSend @ osc_senders[];
	Lock target_lock[];
	int port_out[];

	1 => int num_notes;
	1 => int num_voices;
	1 => int num_osc;
	0.05 => float detune;
	0 => int arpeggiating;
}

0 => int DEBUG;
1 => int DEBUG_ON;

InternalOscData iod;
OscRecv osc_in;

[[60, 63, 67, 70], [63, 67, 70, 74], [67, 70, 74, 75], [48, 51, 55, 58]] @=> int note_options[][];

[60, 63, 67, 70] @=> int notes[];

if (me.args() == 5){
	Std.atoi(me.arg(0)) => iod.index;
	Std.atoi(me.arg(1)) => iod.num_other_entities;
	Std.atoi(me.arg(2)) => iod.port_offset;
	Std.atoi(me.arg(3)) => iod.num_notes;
	Std.atoi(me.arg(4)) => iod.num_voices;
	iod.num_notes * iod.num_voices => iod.num_osc;

	iod.port_offset + iod.index => iod.port_in => osc_in.port ;

	new OscSend[iod.num_other_entities] @=> iod.osc_senders;
	new int[iod.num_other_entities] @=> iod.port_out;
	new Lock[iod.num_other_entities] @=> iod.target_lock;

	0 => int other_entity_idx;

	for (int i; i < iod.num_other_entities + 1; i++){
		if (i == iod.index){
			continue;
		}

		iod.port_offset + i => iod.port_out[other_entity_idx];
		iod.osc_senders[other_entity_idx].setHost("localhost", iod.port_out[other_entity_idx]);

		other_entity_idx++;
	}

	note_options[iod.index] @=> notes;
	<<< "Created entity with index: " + Std.itoa(iod.index) + " and port: " + Std.itoa(iod.port_in) >>> ;
}

GenerationalData dna;
dna.generate_osc_string() => string dna_string;

(iod.index == 0) => int is_main;

int visualizer_in_use;
Lock visualizer_lock;
Event visualizer_wait_event;
OscSend visualizer;
visualizer.setHost("localhost", 6901);
dna.generate_visualizer_osc_string() => string visualizer_string;
0 => int send_to_visualizer;


Event arpeggio_switch_event;

Float @ filter_range[iod.num_osc];
Event filter_update_lock[iod.num_osc];
Float filter_base[iod.num_notes];
Float pitch_offset;

0. => pitch_offset.val;

float filter_env_range[iod.num_notes];

SawOsc saw[iod.num_osc];
SqrOsc sqr[iod.num_osc];
Noise noise[iod.num_osc];

0. => float noise_amt;

LPF filter[iod.num_notes];
ADSR env[iod.num_notes];
float total_env_time;

Gain g => Echo e1 => Dyno d1 => dac;

d1.limit();

0.3 => e1.mix;
Math.random2f(100, 500)::ms => e1.delay;

0.9 / (iod.num_osc * (iod.num_other_entities+1)) => float max_gain;

for (0 => int i; i < iod.num_notes; i++){
	for (int j; j < iod.num_voices; j++){
		saw[(i * iod.num_voices) + j] => filter[i] => env[i] => g;
		sqr[(i * iod.num_voices) + j] => filter[i];
		noise[(i * iod.num_voices) + j] => blackhole;
		0. => sqr[(i * iod.num_voices) + j].gain;
	}

	200 => filter_base[i].val => filter[i].freq;
	max_gain => saw[i].gain;
    (500::ms, 1500::ms, 0., 200::ms) => env[i].set;

	new Float @=> filter_range[i];
	0. => filter_range[i].val;
}

0.5 => g.gain;

osc_in.listen();

osc_in.event("/filter_range,i,f") @=> OscEvent filter_range_event;
osc_in.event("/pitch_glide,f") @=> OscEvent pitch_glide_event;
osc_in.event("/env,i") @=> OscEvent env_event;
osc_in.event(dna_string) @=> OscEvent dna_event;
osc_in.event("/setup_req,s") @=> OscEvent visualizer_setup_event;

fun void process_dna_event(){
	int idx;
	float values[dna.number_of_parameters];

	while(true){
		dna_event => now;

		while(dna_event.nextMsg() != 0){
			0 => idx;
			while(idx < dna.number_of_parameters){
				dna_event.getFloat() => values[idx];
				idx++;
			}

			//pop off value used to determine timing:
			dna_event.getInt();
		}

		dna.mutate_towards(values);

		if (DEBUG && is_main){
			<<< "Received DNA message at " + Std.itoa(iod.port_in) >>>;
			<<< dna.print_all() >>>;
		}

		spork ~ apply_dna_change_and_mutate_other();
	}
}


fun void apply_dna_change_and_mutate_other(){
	dna.mutate_speed => now;
	Math.random2(0, iod.num_other_entities - 1) => int target;

	iod.osc_senders[target] @=> OscSend osc_target;

	take_lock(target);
	osc_target.startMsg(dna_string);

	if (dna.should_add_random_mutation()){
		dna.random_param_mutate();
	}

	0 => total_env_time;

	for (int i; i < dna.number_of_parameters; i++){
		dna.get(i) => float val;
		if (i < dna.FILTER_FREQ){
			val +=> total_env_time;
		}
		apply_dna(i, val);
		osc_target.addFloat(val);
	}

	osc_target.addInt(0);
	release_lock(target);
}

fun void apply_dna(int index, float value){
	if (index == dna.ATTACK){
		for (int i; i < iod.num_notes; i++){
			value::ms => env[i].attackTime;
		}
	} else if (index == dna.DECAY){
		for (int i; i < iod.num_notes; i++){
			value::ms => env[i].decayTime;
		}
	} else if (index == dna.SUSTAIN){
		for (int i; i < iod.num_notes; i++){
			value => env[i].sustainLevel;
		}
	} else if (index == dna.RELEASE){
		for (int i; i < iod.num_notes; i++){
			value::ms => env[i].releaseTime;
		}
	} else if (index == dna.FILTER_FREQ){
		for (int i; i < iod.num_notes; i++){
			value => filter_base[i].val;
		}
	} else if (index == dna.FILTER_ENV_AMT){
		for (int i; i < iod.num_notes; i++){
			value => filter_env_range[i];
		}
	} else if (index == dna.OSC_WAVEFORM){
		value * max_gain => float saw_gain;
		(1. - value) * max_gain => float sqr_gain;
		for (int i; i < iod.num_notes; i++){
			saw_gain => saw[i].gain;
			sqr_gain => sqr[i].gain;
		}
	} else if (index == dna.NOISE_FM_AMT){
		value => noise_amt;
	}
}



fun void update_pitch_glide(){
	0. => float pitch_glide;

	while (true){
		pitch_glide_event => now;

		while(pitch_glide_event.nextMsg() != 0){
			pitch_glide_event.getFloat() => pitch_glide;
		}

		spork ~ Slide.slide_to(pitch_offset, pitch_glide, 1000::ms);
	}
}


fun void update_filter_freq(){
	while (true){
		for (0 => int i; i < iod.num_notes; i++){
			filter_base[i].val + (env[i].value() * filter_env_range[i]) => float new_filter_freq;

			if (new_filter_freq > 21000){
				21000 => new_filter_freq;
			} else if (new_filter_freq < 0){
				0 => new_filter_freq;
			}
			new_filter_freq => filter[i].freq;
		}
		1::samp => now;
	}
}




fun void update_pitch(){
	1. / iod.num_voices => float detune_step;
	while (true){
		for (0 => int i; i < iod.num_osc; i++){
			-0.5 + (((i % iod.num_voices) * detune_step) * iod.detune) => float detune_this_osc;
			i / iod.num_voices => int note;
			notes[note] + pitch_offset.val + detune_this_osc => Std.mtof => float intermediate_freq;
			intermediate_freq + (noise[i].last() * noise_amt * intermediate_freq) => saw[i].freq => sqr[i].freq;
		}

		10::ms => now;
	}
}

fun void switch_arpeggiating(){

}

fun void handle_env_msg(){
	int note_idx;
	1 => int once;
	while (true){
		env_event => now;
		while(env_event.nextMsg() != 0){
			env_event.getInt() => note_idx;
		}

		if (DEBUG || DEBUG_ON){
			<<< "Received note on message at " + Std.itoa(iod.port_in) >>> ;
			<<< "Note index: " + Std.itoa(note_idx) >>>;
		}


		if (note_idx > -1 && note_idx < iod.num_notes){
			for (int i; i < iod.num_voices; i++){
				env[(note_idx * iod.num_voices) + i].keyOff();
				env[(note_idx * iod.num_voices) + i].keyOn();
			}
		} else if (note_idx == -2){
			for (0 => int i; i < iod.num_notes; i++){
				env[i].keyOff();
				env[i].keyOn();
			}
		} else if (note_idx == 420){
			for (0 => int i; i < iod.num_notes; i++){
				env[i].keyOff();
			}
		}

		if (iod.num_other_entities > 0){
			spork ~ cascade_env_msg(note_idx, Math.random2f(total_env_time / 2, total_env_time / 2));
		}

	}
}

fun int[] unique_random_order(int length, int array[]){
    if (length > 1)
    {
        for (int i; i < length - 1; i++)
        {
          (i + Math.random() / ((Math.pow(2, 32) / 2) / (length - i) + 1)) $ int => int j;
          array[j] => int t;
          array[i] => array[j];
          t => array[i];
        }
    }

	return array;
}

fun void arp_off(float delay_time){
	for (int i; i < iod.num_notes; i++){
		env[i].keyOff();
		delay_time::ms => now;
	}
}

fun void cascade_env_msg(int note_idx, float delay){
	int order[iod.num_notes];

	for (int i; i < iod.num_notes; i++){
		i => order[i];
	}

	unique_random_order(iod.num_notes, order) @=> order;

	Math.random2(1, 8) => int delay_step;
	 delay_step > 1 => int slow_off;

	if (slow_off){
		delay / delay_step => float delay_part;
		(delay_part * (delay_step - 1))::ms => now;
		spork ~ arp_off(delay_part / iod.num_notes);
	} else {
		delay::ms => now;
	}

	Math.random2(0, iod.num_other_entities-1) => int target;

	take_lock(target);

	iod.osc_senders[target].startMsg("/env,i");

	if (note_idx != -2 && Math.random2f(0, note_idx) > note_idx / 2.){
		iod.osc_senders[target].addInt(Math.random2(0, iod.num_notes - 1));
	} else {
		iod.osc_senders[target].addInt(-2);
	}

	release_lock(target);

	if (DEBUG || DEBUG_ON){
		<<< "Cascading /env message to entity at port: " + iod.port_out[target] >>>;
	}
}


fun void dna_to_visualizer(){
	float norm_dna[dna.number_of_parameters];

	while(1){
		if (send_to_visualizer){
			visualizer.startMsg(visualizer_string);
			visualizer.addInt(iod.index);

			dna.get_normalized_array() @=> norm_dna;

			for (int i; i < dna.number_of_parameters; i++){
				visualizer.addFloat(norm_dna[i]);
			}

			100::ms => now;
		} else {
			visualizer_wait_event => now;
		}

	}
}

fun void visualizer_setup(){
	while(1){
		visualizer_setup_event => now;

		<<< "woken up" >>>;

		while(visualizer_setup_event.nextMsg() != 0){
			visualizer_setup_event.getString() => string msg;
			if (msg == "ints"){
				take_lock(visualizer_lock);

				<<< "Sending ints setup" >>>;
				<<< "TypeTag: /setup_req,s,i,i" >>>;
				<<< "Adding ints: " + Std.itoa(iod.num_other_entities + 1) >>>;
				<<< "Adding ints: " + Std.itoa(dna.number_of_parameters) >>>;

				visualizer.startMsg("/setup_req,s,i,i");
				visualizer.addString("ints");
				visualizer.addInt(iod.num_other_entities + 1);
				visualizer.addInt(dna.number_of_parameters);

				release_lock(visualizer_lock);
			} else if (msg == "names"){
				take_lock(visualizer_lock);

				<<< "Sending names setup" >>>;

				<<< "TypeTag: " + dna.get_name_typetag("/setup_req,s") >>>;

				visualizer.startMsg(dna.get_name_typetag("/setup_req,s"));
				visualizer.addString("names");
				dna.get_names() @=> string names[];
				for (int i; i < dna.number_of_parameters; i++){
					visualizer.addString(names[i]);
					<<< "Adding name: " + names[i] >>>;
				}

				release_lock(visualizer_lock);
			} else if (msg == "done"){
				take_lock(visualizer_lock);

				visualizer.startMsg("/setup_req,s");
				visualizer.addString("done_ack");

				release_lock(visualizer_lock);

				1 => send_to_visualizer;
				visualizer_wait_event.broadcast();
			} else if (msg == "stop"){
				0 => send_to_visualizer;
			}


		}
	}
}


fun void arpeggiate(){
	while(1){
		if (iod.arpeggiating){
			for (int i; i < iod.num_notes; i++){
				env[i].keyOn();
			}

			dna.get(ATTACK)::ms => now;

			for (int i; i < iod.num_notes; i++){
				env[i].keyOn();
			}

			dna.get(RELEASE)::ms => now;
		} else {
			arpeggio_switch_event => now;
		}
	}
}


fun void take_lock(int idx){
	iod.target_lock[idx].take();
}

fun void release_lock(int idx){
	iod.target_lock[idx].release();
}

fun void take_lock(Lock l){
	l.take();
}

fun void release_lock(Lock l){
	l.release();
}


fun void set_notes(int notes[], SawOsc @oscs[]){
    for (0 => int i; i < iod.num_osc; i++){
		i / iod.num_voices => int note;
        notes[note] => Std.mtof => oscs[i].freq => filter[note].freq => filter_env_range[note];
		2 *=> filter_env_range[note];
    }
}

fun void set_notes(int notes[], SqrOsc @oscs[]){
	for (0 => int i; i < iod.num_osc; i++){
		i / iod.num_voices => int note;
		notes[note] => Std.mtof => oscs[i].freq => filter[note].freq => filter_env_range[note];
		2 *=> filter_env_range[note];
	}
}

fun void start_envs(){
	for (0 => int i; i < iod.num_osc; i++){
		1 => env[i].keyOn;
	}
}

spork ~ handle_env_msg();
spork ~ update_pitch_glide();
spork ~ update_pitch();
spork ~ update_filter_freq();
spork ~ process_dna_event();
spork ~ dna_to_visualizer();
spork ~ visualizer_setup();
spork ~ arpeggiate();

set_notes(notes, saw);
set_notes(notes, sqr);

if (is_main){
	apply_dna_change_and_mutate_other();
}

while (true){
    1000::ms => now;
}
