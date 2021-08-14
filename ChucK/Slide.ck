public class Slide {
	fun static void slide_to(Float current_value, float new_value, dur t){
		
		now + t => time end;
		
		(new_value - current_value.val) / (t / 16::ms) => float step;
		
		while (now < end && Math.fabs(new_value - current_value.val) > step){
			current_value.val + step => current_value.val;
			16::ms => now;
		}
		
		new_value => current_value.val;
	}
	
	fun static void slide_to(Float current_value, float new_value, dur t, Event e){
		
		now + t => time end;
		
		(new_value - current_value.val) / (t / 16::ms) => float step;
		
		while (now < end && Math.fabs(new_value - current_value.val) > step){
			current_value.val + step => current_value.val;
			16::ms => now;
		}
		
		new_value => current_value.val;
		
		if (e != null){
			e.signal();
		}
	}
	
	
	fun static void slide_to(Float @ current_value[], int num_osc, float new_value, dur t, Event e){
		
		now + t => time end;
		
		0. => float sum_cv;
		for (0 => int i; i < num_osc; i++){
			sum_cv + current_value[i].val => sum_cv;
		}
		
		sum_cv / (num_osc $ float) => sum_cv;
		
		<<< sum_cv >>>;
		
		(new_value - sum_cv) => float step;
		
		while (now < end && Math.fabs(new_value - sum_cv) > step){	
			for (0 => int i; i < num_osc; i++){
				current_value[i].val + step => current_value[i].val;
			}
			16::ms => now;
		}
		
		for (0 => int i; i < num_osc; i++){
			new_value => current_value[i].val;
			if (e != null){
				e.signal();
			}
		}
	}
}