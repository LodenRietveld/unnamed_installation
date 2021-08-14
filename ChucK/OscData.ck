public class OscData {
	0 => int num_entities;
	0 => int port_offset;
	
	1 => int num_osc;
	1 => int num_voices;
	200 => int filter_base_freq;
	StringFuncs s;
	
	fun int[] init(int num_entities, int osc, int voices, int port_off){
		num_entities => this.num_entities;
		osc => this.num_osc;
		voices => this.num_voices;
		port_off => this.port_offset;
		
		int ids[num_entities];
		
		
		for (int i; i < num_entities; i++){
			Machine.add(F.file("osc.ck") + format_args(i)) => ids[i];
			10::ms => now;
		}
		
		return ids;
	}
	
	fun string format_args(int idx){
		return ":"+ s.str(idx) + ":" + s.str(this.num_entities - 1) + ":" + s.str(this.port_offset) + ":" + s.str(this.num_osc) + ":" + s.str(this.num_voices);
	}
	
	fun int num_ents(){
		return this.num_entities;
	}
}