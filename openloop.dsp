process(x,y) = masterLooper(x), slaveLooper(y) ;
//stereoMasterLooper;

//----------------------------------------------------------------------------------------------
//////////////// constants
//----------------------------------------------------------------------------------------------
maxLength = 1048576;
halfLength = maxLength/2;
//262144; //pow(2,18);
fadeLength = 16384;
//----------------------------------------------------------------------------------------------
//////////////// UI control elements
//----------------------------------------------------------------------------------------------
StartStop1 = button("../1"): startPulse;
StartStop2 = button("../2"): startPulse;
//----------------------------------------------------------------------------------------------
////////////////some functions to use in controlling loop lengths
//----------------------------------------------------------------------------------------------
sampleAndHold(hold) = select2((hold!=0):int) ~ _;
FlipFlop(bit) = sampleAndHold(bit)~_==0 ;
setUnset(set,unset) = set & not(unset):(select2((set|unset),_,_)~_);
not = select2(_,1,0);
timer(pulse) = (pulse,(+(1)~((%(maxLength)):(startPulse(pulse)==1,_,0:select2))<:sampleAndHold(stopPulse(pulse)),_)):select2; //how many samples is pulse high?
startPulse= _ <: _, mem: - : >(0);
stopPulse = (_==0):startPulse;
round = _+0.5:floor;
//----------------------------------------------------------------------------------------------
////////////////  masterLooper stereoMasterLooper
//----------------------------------------------------------------------------------------------
masterIsWriting = FlipFlop(StartStop1);
//:hbargraph("../h:masterLoop/recording", 0, 1);
//(_+1,masterLoopLength : %) ~ _;
masterLoopLength   =
select2(masterIsWriting | (timer(masterIsWriting)<2),
  timer(masterIsWriting):sampleAndHold(stopPulse(masterIsWriting):not),
  maxLength )
:min(maxLength):max(0)
;
masterPosition = ((_*not(startPulse(masterIsWriting)),masterLoopLength) : %) ~ (_+1);
//-----------------------------------------------
masterWriteIndex =  
select2(masterIsWriting,
  (maxLength  +1),
  masterPosition
);
masterReadIndex =  not(masterIsWriting) * masterPosition:hbargraph("../h:masterLoop/play", 0, maxLength):int ;
//-----------------------------------------------
masterPostLoopWriteIndex = (masterWriteIndex@masterLoopLength):min(fadeLength + 1);
masterPostLoopReadIndex = min(masterReadIndex,fadeLength) * not(masterIsWriting);
masterPreLoopWriteIndex = min(masterWriteIndex,(fadeLength + 1));
masterPreLoopReadIndex = (masterReadIndex - masterLoopLength + fadeLength) :max(0) * not(masterIsWriting);

//-----------------------------------------------
masterControls(x)        = maxLength  +1, 0.0 , masterWriteIndex        , x , masterReadIndex;
masterPostLoopControls(x)  = fadeLength +1, 0.0 , masterPostLoopWriteIndex  , x , masterPostLoopReadIndex;
masterPreLoopControls(x) = fadeLength +1, 0.0 , masterPreLoopWriteIndex , x@fadeLength , masterPreLoopReadIndex;
//-----------------------------------------------
masterPostLoop(x)  = masterPostLoopControls(x)  : rwtable * masterPostLoopVolume
with {
  masterPostLoopVolume = (fadeLength - min(masterReadIndex, fadeLength)) / fadeLength;
};
masterPreLoop(x) = masterPreLoopControls(x) : rwtable * masterPreLoopVolume
with {
  masterPreLoopVolume = (masterReadIndex - masterLoopLength + fadeLength) / fadeLength :max(0);
};
masterLoop(x)    = masterControls(x)        : rwtable * fadeVolume
with {
  fadeVolume = (masterLoopLength -  masterReadIndex - 1):min(fadeLength) / fadeLength :max(0);
  fadeVolum = select3(
    (masterReadIndex > fadeLength) + (masterReadIndex >  (masterLoopLength - fadeLength)),
    masterReadIndex,
    fadeLength,
    masterLoopLength - masterReadIndex
    )
  /fadeLength;
};
//-----------------------------------------------
masterLooper(x) = masterLoop(x) + masterPreLoop(x);
///masterPostLoop(x) + 
stereoMasterLooper(x,y) =  masterLooper(x), masterLooper(y);
//----------------------------------------------------------------------------------------------
//////////////// slaveLooper
//----------------------------------------------------------------------------------------------
slaveLooper(x) = slaveLoop(x) + slavePreLoop(x);
//-----------------------------------------------
slaveLoop(x)    = slaveControls(x)        : rwtable * fadeVolume
with {
  fadeVolume = (slaveLoopLength -  slaveReadIndex - 1):min(fadeLength) / fadeLength :max(0);
};

slavePreLoop(x) = slavePreLoopControls(x) : rwtable * fadeVolume
with {
  fadeVolume = (slaveReadIndex - slaveLoopLength + fadeLength) / fadeLength :max(0);
};
//-----------------------------------------------

slaveControls(x)        = maxLength  +1, 0.0 , slaveWriteIndex        , x            , slaveReadIndex;
slavePreLoopControls(x) = fadeLength +1, 0.0 , slavePreLoopWriteIndex , x@fadeLength , slavePreLoopReadIndex;
slaveLoopLength = 
  int(max(masterLoopLength, (round(slaveTimer/masterLoopLength)*masterLoopLength)):max(0):min(maxLength)); //(todo:remove max(0):min(maxLength)
slaveTimer   = timer(slaveIsWriting) ; //slavePosition :sampleAndHold(not(slaveWantsWriting));
  /*select2(slaveIsWriting | (timer(slaveIsWriting)<2),*/
    /*timer(slaveIsWriting),*/
    /*maxLength )*/
  /*:min(maxLength):max(0)*/
/*;*/
slaveReadIndex =  not(slaveIsWriting) * slavePosition:hbargraph("../h:slaveLoop/slavePlay", 0, maxLength):int ;
//-----------------------------------------------
slaveWriteIndex  = 
  select2(slaveIsWriting,
    (maxLength  +1),
    slavePosition
  );
slavePreLoopWriteIndex = min(slaveWriteIndex,(fadeLength + 1));
slavePreLoopReadIndex =  fadeLength + 1; // (slaveReadIndex - slaveLoopLength + fadeLength) :max(0) * not(slaveIsWriting)
slaveWantsWriting = FlipFlop(StartStop2):hbargraph("../h:slaveLoop/SW", 0, 1);
slaveIsWriting = slaveWantsWriting | (slaveWantsWriting:sampleAndHold(masterReadIndex));

slavePosition = ((_*not(reset),slaveLoopLength) : %) ~ (_+1):hbargraph("../h:slaveLoop/pos", 0, maxLength):int
  with {
    reset = not(setUnset(set,unset):hbargraph("../h:slaveLoop/SU", 0, 1)>0) & (masterReadIndex == 0) & masterIsReading;
    //setUnset(set,unset) & (masterReadIndex == 0) & masterIsReading;
      /*select2(FlipFlop((slaveWantsWriting:startPulse & firstHalf) & slaveWantsWriting:stopPulse)  ,*/
      /*(masterReadIndex == 0) & masterIsReading*/
        /*// start writing when master is fadeLength samples beffore 0:*/
        /*//((masterReadIndex + fadeLength) % slaveLoopLength)  == 0*/
      /*);*/
    set = (slaveWantsWriting:startPulse & firstHalf) | (masterReadIndex == 2 & slaveWantsWriting);
    unset = stopPulse(slaveWantsWriting);
  } ;
//-----------------------------------------------
// -as soon as we start playing the master, we start recording the slave (+ preloop for fade)
// -if we pres slave-rec in the first half, we don't reset slavePosition in the next round,
// -if we pres slave-rec in the second half, we reset, but stop resetting from then on,
firstHalf = masterReadIndex < (masterLoopLength/2);
masterIsReading = masterWriteIndex > maxLength;


// stopReset = 

////////////////     dual buffer method:

// start recording together when master starts playing
// stop resetting
