NoteMaterialGenerator nmg;

FloatListAssoc @ f;
new FloatListAssoc @=> f;

nmg.gen_notes(36, "1min-5less-7min-9maj", f, 1);



GenerationalData d;

/* for(;true;){
	d.random_param_mutate();
	d.print_all();
	1::second => now;
} */

4 => int num_entities;
int ids[num_entities];

OscData o;
o.init(num_entities, 4, 1, 6969) @=> ids;

OscSend trig;

trig.setHost("localhost", 6969);
trig.startMsg("/env,i");

1::second => now;
trig.addInt(-2);
