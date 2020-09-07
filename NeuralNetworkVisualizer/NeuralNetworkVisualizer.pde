import peasy.*;
import controlP5.*; 

final int width = 1280, height = 720;

int scaleFactorY = 100;
int scaleFactorX = 100;

float f(float x, float z)
{
  return 100 * sin(0.05 * x);
}


// Neural 
NeuralNetwork nn;
int iterationsPerEpoch = 5;

// Rendering
PeasyCam cam;

// GUI
ControlP5 cp5; 

Slider learningRateSlider;
Slider iterationsPerEpochSlider;
Button pauseResumeButton;
Button resetButton;

Textfield numInputNodes, numHiddenNodes, numOutputNodes;
Button startButton;

// Others
boolean pause = false;
boolean canChangePause = true;

boolean reset = false;
boolean canReset = true;

int nInput = 2, nHidden = 32, nOutput = 1;

void init()
{
  nn = new NeuralNetwork(nInput, nHidden, nOutput);
}

void addGui()
{
  cp5 = new ControlP5(this); 
  cp5.setAutoDraw(false);
  
  learningRateSlider = cp5.addSlider("Set Learning Rate")
  .setRange(0.0001, 0.1)
  .setValue(0.02)
  .setPosition(50, 50)
  .setSize(20,100)
  .setColorValue(0xffff88ff)
  .setColorLabel(0xffdddddd);
 
  iterationsPerEpochSlider = cp5.addSlider("Set Iterations per Epoch")
  .setRange(0,1000)
  .setValue(iterationsPerEpoch)
  .setPosition(50, 250)
  .setSize(20,100)
  .setColorValue(0xffff88ff)
  .setColorLabel(0xffdddddd);
   
  pauseResumeButton = cp5.addButton("Pause")
  .setPosition(width / 2 - 80, 20)
  .setSize(60,30); 
  
  pauseResumeButton.onPress(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      if (canChangePause)
      {
        canChangePause = false;
        pause = !pause;
      }
    }
  });
  
  pauseResumeButton.onRelease(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      canChangePause = true;
    }
  });

  resetButton = cp5.addButton("Reset")
  .setPosition(width / 2 + 20, 20)
  .setSize(60,30); 
  
  resetButton.onPress(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      if (canReset)
      {
        canReset = false;
        reset = true;
      }
    }
  });
  
  resetButton.onRelease(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      canReset = true;
    }
  });
  
  PFont font = createFont("arial", 12);
  
  numInputNodes = cp5.addTextfield("Input")
  .setPosition(210, 50)
  .setSize(50, 20)
  .setText(nn.input_nodes + "")
  .setFont(font)
  .setColor(color(255, 0, 0));

  numHiddenNodes = cp5.addTextfield("Hidden")
  .setPosition(270, 50)
  .setSize(50, 20)
  .setText(nn.hidden_nodes + "")
  .setFont(font)
  .setColor(color(255, 0, 0));

  numOutputNodes = cp5.addTextfield("Output")
  .setPosition(330, 50)
  .setSize(50, 20)
  .setText(nn.output_nodes + "")
  .setFont(font)
  .setColor(color(255, 0, 0));
  
  cp5.addTextlabel("Neural Network Layers")
  .setPosition(210, 20)
  .setSize(50, 20)
  .setText("Neural Network Layers")
  .setFont(createFont("arial", 14))
  .setColor(color(255, 0, 0));

  startButton = cp5.addButton("Start")
  .setPosition(265, 100)
  .setSize(60,30); 
  
  startButton.onPress(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      if (canReset)
      {
        canReset = false;
        reset = true;
        canChangePause = true;
        pause = false;
      }
    }
  });
  
  startButton.onRelease(new CallbackListener()
  {
    public void controlEvent(CallbackEvent event)
    {
      canReset = true;
    }
  });
}

void setup()
{
  size(1280, 720, P3D);
  frameRate(60);
  cam = new PeasyCam(this,width / 2, height / 2 - 50, -100, 500);

  init();
  addGui();
}

void tick()
{
  // Parse and set Hyperparameters
  String lrValue = String.format("%.4f", learningRateSlider.getValue());
  learningRateSlider.setValueLabel(lrValue);
  nn.setLearningRate(Float.parseFloat(lrValue));
  
  iterationsPerEpoch = (int)iterationsPerEpochSlider.getValue();
  iterationsPerEpochSlider.setValueLabel(iterationsPerEpoch + "");
  
  if (pause)
    pauseResumeButton.setLabel("Resume");
  else
    pauseResumeButton.setLabel("Pause");
  if (!pause)
    trainNN();
    
  if (reset)
  {
    reset = false;
    init();
  }
  
  nInput = nn.input_nodes;
  nHidden = nn.hidden_nodes;
  nOutput = nn.output_nodes;
  
  try
  {
    nInput = Integer.parseInt(numInputNodes.getText());
    nHidden = Integer.parseInt(numHiddenNodes.getText());
    nOutput = Integer.parseInt(numOutputNodes.getText());
  }catch(NumberFormatException e)
  {
    println("Bad Number");
  }
  if (nInput == 0)
    nInput = nn.input_nodes;
  if (nHidden == 0)
    nHidden = nn.hidden_nodes;
  if (nOutput == 0)
    nOutput = nn.output_nodes;
  
  if (!numInputNodes.isFocus())  numInputNodes.setText(nInput + "");
  if (!numHiddenNodes.isFocus())  numHiddenNodes.setText(nHidden + "");
  if (!numOutputNodes.isFocus())  numOutputNodes.setText(nOutput + "");
  
  
}

void draw()
{
  tick();
  
  background(0);
  
  translate(width / 2, height / 2);
  noFill();
    
  // Create Axes
  strokeWeight(1);
  stroke(255, 0, 0);
  line(-1000, 0, 0, 1000, 0, 0);
  stroke(0, 255, 0);
  line(0, -1000, 0, 0, 1000, 0);
  stroke(0, 0, 255);
  line(0, 0, -1000, 0, 0, 1000);

  // Create Actual Graph
  strokeWeight(10);
  beginShape();
  for (int i = -100; i <= 100; i++)
  {
    for (int j = -100; j <= 100; j++)
    {
      stroke(i + 100, j + 100, -i + j); 
      vertex(i, -f(i, j), j);
    }
  }
  endShape();
  
  //Plot by nn
  stroke(100, 100);
  strokeWeight(7);
  beginShape();  
  for (int i = -100; i <= 100; i+=1)
  {
    for (int j = -100; j <= 100; j+=7)
    {
      vertex(i, -nn.predict(new float[]{(float) i / scaleFactorX, (float) j / scaleFactorX})[0] * scaleFactorY, j);
    }  
  }
  endShape();
  
  cam.beginHUD();
  cp5.draw();
  cam.endHUD();
  
}

void trainNN()
{
  for (int i = 0; i < iterationsPerEpoch; i++)
  {
    float x = (float)(Math.random() * 2 - 1) * scaleFactorX;
    float z = (float)(Math.random() * 2 - 1) * scaleFactorX;
    float y = f(x, z);
    x /= scaleFactorX;
    z /= scaleFactorX;
    y /= scaleFactorY;
    nn.train(new float[]{x, z}, new float[]{y});
  }
}