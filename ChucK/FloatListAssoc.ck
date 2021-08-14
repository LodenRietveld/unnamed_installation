public class FloatListAssoc {
	0 => int len;
	float vals[1];
	
	fun void add(string key, float val){
		float _t_vals[len+1];
		if (len > 0){
			for (int i; i < len; i++){
				vals[i] => _t_vals[i];
			}
			val => _t_vals[len];
		} else if (len == 0){
			[val] @=> vals;
		}
		
		len => vals[key];
		_t_vals @=> vals;
		len++;
	}
	
	
	
	fun void add(float f[]){
		len + f.cap() => int new_len;
		float _t_vals[new_len];
		
		if (len > 0){
			for (int i; i < new_len; i++){
				if (i < len){
					vals[i] => _t_vals[i];
				} else {
					f[i - len] => _t_vals[i];
				}
			}
			
			new_len => len;
		} else {
			f @=> vals;
			0 => vals["1"];
			1 => vals["3"];
			2 => vals["5"];
			3 => len;
		}
	}
	
	
	
	fun float get(string el){
		if (vals[el] != 0.){
			return vals[el];
		} else {
			return -1.;
		}
	}
	
	fun float get(int i){
		if (i >= 0 && i < len){
			return vals[i];
		} else {
			return -1.;
		}
	}
	
	fun int length(){
		return len;
	}
	
	fun int delete(string el){
		float _t_vals[len - 1];
		int new_idx;
		int found;
		
		if (vals[el] != 0.){
			vals[el] $ int => int start;
			1 => found;
			
			for (int i; i < len; i++){
				if (i != start){
					vals[i] => _t_vals[new_idx];
					new_idx++;
				}
			}
		}
		
		if (found){
			_t_vals @=> vals;
			len--;
			return 0;
		}
		
		return -1;
	}
	
	fun int modify_element(string el, float mod){
		vals[el] $ int => int idx;
		vals[idx] + mod => vals[idx];
		
		return -1;
	}
}