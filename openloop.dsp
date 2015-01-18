//////////////// constants
maxLength = 262144;
//pow(2,18);
//////////////// UI control elements
StartStop1 = button("../1"): startPulse;
//The master clock of the circular buffer
circularPointer = ( ((_+1)%maxLength) ~_);
RecPointer = circularPointer*masterIsWrtiting;
////////////////some functions to use in controlling loop lengths
sampleAndHold(hold) = select2((hold!=0):int) ~ _;
FlipFlop(bit) = sampleAndHold(bit)~_==0 ;
not = select2(_,1,0);
timer(pulse) = (pulse,(+(1)~((%(maxLength)):(startPulse(pulse)==1,_,0:select2))<:sampleAndHold(stopPulse(pulse)),_)):select2; //how many samples is pulse high?
startPulse= _ <: _, mem: - : >(0);
stopPulse = (_==0):startPulse;
round = _+0.5:floor;
// the pointer displays
pointer_displays(x,y) = y,x:pp_graph,rp_graph:cross(2);
masterIsWriting = FlipFlop(StartStop1);
//:hbargraph("../h:masterLoop/recording", 0, 1);
//(_+1,masterLoopLenght : %) ~ _;
masterLoopLenght   =
select2(masterIsWriting | (timer(masterIsWriting)==1),
  timer(masterIsWriting):sampleAndHold(stopPulse(masterIsWriting):not),
  maxLength );
masterPosition = (((_+1)*not(startPulse(masterIsWriting)),masterLoopLenght) : %) ~ _;
//-----------------------------------------------
masterWritePointer  =  masterIsWriting * masterPosition ;
masterReadPointer =  not(masterIsWriting) * masterPosition ;
//-----------------------------------------------
masterControls = maxLength, 0.0 , masterWritePointer , _ , masterReadPointer;
//-----------------------------------------------
fadeIn = 0;
fadeOut = 0;
masterLoop = masterControls : rwtable;
//-----------------------------------------------
masterLooper = fadeIn + masterLoop + fadeOut;
//-----------------------------------------------
stereoMasterLooper =  masterLooper, masterLooper;
process = stereoMasterLooper;

