public class NoteMaterialGenerator {
	"maj" => string MOD_MAJ;
	"min" => string MOD_MIN;
	
	"less" => string MOD_LESS;
	"dim" => string MOD_DIM;
	"aug" => string MOD_AUG;
	
	[0., 1., 3., 5., 7., 8., 10.] @=> float interval_table[];
	[1., 1., 1., 1., 1., 1., 1., 1., 1., 1., 1., 1.] @=> float intonation_table[];
	
	fun float interval_to_midi(string interval){
		(Std.atoi(interval) - 1) % 7 => int interval_i;
		return interval_table[interval_i];
	}
	
	fun void process_description(float base, FloatListAssoc @ res, string interval, string mod, int is_first){
		0 => int modify_by;
		<<< "Processing " + interval + ", " + mod >>>;
		
		
		if (is_first){
			if (mod == "maj"){
				res.add([base, base + 4, base + 7]);
			} else if (mod == "min"){
				res.add([base, base + 3, base + 7]);
			} else {
				res.add(interval, base + interval_to_midi(interval));
			}
		} else {
			if (mod == "dim"){
				-1 => modify_by;
			} else if (mod == "aug" || mod == "maj"){
				1  => modify_by;
			}
			
			if (mod == "less"){
				res.delete(interval);
			} else {
				if (res.get(interval) == -1.){
					res.add(interval, base + interval_to_midi(interval) + modify_by);
				} else {
					res.modify_element(interval, modify_by);
				}
			}
		}
	}
		
	//always generate the first, third and fifth note of a chord, then specify missing with "less", diminished with "dim", augmented with "aug", minor with "min" and major with "maj"
	fun void gen_notes(int base, string tds, FloatListAssoc @ res, int first){
		tds.find("-") => int next;
		
		string rest;
		string subs;
		
		if (next + 1 >= tds.length() || next == -1){
			"" => rest;
			tds => subs;
		} else {
			tds.substring(next + 1) => rest;
			tds.substring(0, next) => subs;
		}
		
		string interval;
		string modifier;
		
		int char_idx;
		int char;
		
		while (true){
			subs.charAt(char_idx) => char;
			if (char < 48 || char > 57){
				break;
			}
			
			char_idx++;
		}
		
		subs.substring(0, char_idx) => interval;
		if (subs.length() > 1){
			subs.substring(1) => modifier;
		} else {
			"" => modifier;
		}
		
		process_description(base, res, interval, modifier, first);
		
		if (next == -1){
			return;
		}
		<<< "next iteration" >>>;
		
		gen_notes(base, rest, res, 0);
	}	
}