import geomerative.*;

import netP5.*;
import oscP5.*;

RG rg;
RFont good_font;

OscP5 oscP5;
NetAddress first_osc;

int num_oscillators = 4;
int num_values_per_oscillator = 8;
float section_width;

boolean setup_ints_received = false, setup_names_received = false, setup_processed = false, go_next = false, processing_setup_done = false;

OscillatorValues vals[] = new OscillatorValues[num_values_per_oscillator];
String value_names[] = {"Attack", "Decay", "Sustain", "Release", "Filter frequency", "Filter env amt", "Osc waveform", "Noise FM amt"};
RShape texts[];

void setup(){
  size (1000, 200, P2D);
  pixelDensity(2);
  
  section_width = (width / (float) num_values_per_oscillator);
  first_osc = new NetAddress("127.0.0.1", 6969);
  
  background(#fff5f8);
  oscP5 = new OscP5(this, 6901);
  
  rg = new RG();
  rg.init(this);
  good_font = rg.loadFont("AppleGothic.ttf");
  rg.textFont(good_font, 15);
  
  for (int i = 0; i < num_values_per_oscillator; i++){
    vals[i] = new OscillatorValues(num_oscillators, section_width, section_width * i);
  }
  prepareExitHandler();
  
  processing_setup_done = true;
}

void draw(){
  if (!setup_processed){
    if (processing_setup_done && (frameCount % 30 == 0 || go_next)){
      go_next = false;
      recv_go();
    }
  } else {
    noStroke();
    rect(-1, -1, width+1, height+1);
    for(int i = 0; i < num_values_per_oscillator; i++){
      fill(0);
      noStroke();
      
      rg.shape(texts[i], (section_width / 2) + (section_width * i), height - 10);
      
      fill(#fff5f8);
      vals[i].draw();
    }
  }
}


void oscEvent(OscMessage msg) {
  if (msg.checkAddrPattern("/setup_req")){
    String val = msg.get(0).stringValue();
    
    if (val.equals("ints")){
      setup_ints(msg);
    } else if (val.equals("names")){
      setup_names(msg); 
    } else if (val.equals("done_ack")){
      println("Complete setup processed");
      setup_processed = true;
    }
  } else if (msg.checkAddrPattern("/osc")){
    int index = msg.get(0).intValue();
    
    for (int i = 0; i < num_values_per_oscillator; i++){
      vals[i].set(index, msg.get(i+1).floatValue());
    }
  }
}


boolean recv_go(){
  if (!setup_ints_received){
    OscMessage msg = new OscMessage("/setup_req");
    msg.add("ints");
    oscP5.send(msg, first_osc);
    println("Send request for ints");
  } else if (!setup_names_received){
    OscMessage msg = new OscMessage("/setup_req");
    msg.add("names");
    oscP5.send(msg, first_osc);
    println("Send request for names");
  } else if (setup_ints_received && setup_names_received && !setup_processed){
    OscMessage msg = new OscMessage("/setup_req");
    msg.add("done");
    oscP5.send(msg, first_osc);
    println("Send setup done");
    return true;
  }
  
  return false;
}

void setup_ints(OscMessage msg){
    num_oscillators = msg.get(1).intValue();
    num_values_per_oscillator = msg.get(2).intValue();
    
    vals = new OscillatorValues[num_values_per_oscillator];
    section_width = (width / (float) num_values_per_oscillator);
    
    for (int i = 0; i < num_values_per_oscillator; i++){
      vals[i] = new OscillatorValues(num_oscillators, section_width, section_width * i);
    }
    
    println("Received and processed ints");
    setup_ints_received = true;
    go_next = true;
}

void setup_names(OscMessage msg){
  value_names = new String[num_values_per_oscillator];
  texts = new RShape[num_values_per_oscillator];
  
  for (int i = 0; i < num_values_per_oscillator; i++){
    value_names[i] = msg.get(i+1).stringValue();
    texts[i] = rg.getText(value_names[i], "AppleGothic.ttf", 15, RG.CENTER);
  }
  
  println("Received and processed names");
  setup_names_received = true;
  go_next = true;
}


private void prepareExitHandler () {
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
   
    public void run () {
      System.out.println("SHUTDOWN HOOK");
      // application exit code here
      OscMessage msg = new OscMessage("/setup_req");
      msg.add("stop");
      oscP5.send(msg, first_osc);
    }
  }));
}
