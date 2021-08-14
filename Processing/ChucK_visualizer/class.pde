class OscillatorValues {
  int num_oscillators;
  float w, w_per_osc;
  float x_off;
  float oscillator_values[];
  
  
  OscillatorValues(int num_oscillators, float w, float x_offset){
    this.num_oscillators = num_oscillators;
    this.w = w;
    this.w_per_osc = w / num_oscillators;
    this.x_off = x_offset;
    oscillator_values = new float[num_oscillators];
  }
  
  void set(int index, float value){
    oscillator_values[index] = value;
  }
  
  private float _x_pos(int index){
    return x_off + ((index % num_oscillators) * w_per_osc) + 20;
  }
  
  private float _y_pos(int index){
    return height - (oscillator_values[index % num_oscillators] * height);
  }
  
  void draw(){
    stroke(#a3cad1);
    for (int i = 0; i < num_oscillators; i++){
      line(_x_pos(i), _y_pos(i), _x_pos(i+1),  _y_pos(i+1));
    }
  }
}
