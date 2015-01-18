//////////////// constants
maxLength = 1048576;
//262144; //pow(2,18);
fadeLength = 16384;
//////////////// UI control elements
StartStop1 = button("../1"): startPulse;
////////////////some functions to use in controlling loop lengths
sampleAndHold(hold) = select2((hold!=0):int) ~ _;
FlipFlop(bit) = sampleAndHold(bit)~_==0 ;
not = select2(_,1,0);
timer(pulse) = (pulse,(+(1)~((%(maxLength)):(startPulse(pulse)==1,_,0:select2))<:sampleAndHold(stopPulse(pulse)),_)):select2; //how many samples is pulse high?
startPulse= _ <: _, mem: - : >(0);
stopPulse = (_==0):startPulse;
round = _+0.5:floor;
// the pointer displays
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
masterWriteIndex  =  masterIsWriting * masterPosition ;
masterReadIndex =  not(masterIsWriting) * masterPosition:hbargraph("../h:masterLoop/play", 0, maxLength):int ;
//-----------------------------------------------
masterFadeInWriteIndex = (masterWriteIndex@masterLoopLength):min(fadeLength);
masterFadeInReadIndex = min(masterReadIndex@masterLoopLength,fadeLength) * not(masterIsWriting);
masterFadeOutWriteIndex = min(masterWriteIndex,fadeLength);
masterFadeOutReadIndex = (masterReadIndex - masterLoopLength + fadeLength) :max(0) * not(masterIsWriting);

//-----------------------------------------------
masterControls(x)        = maxLength  , 0.0 , masterWriteIndex        , x , masterReadIndex;
masterFadeInControls(x)  = fadeLength , 0.0 , masterFadeInWriteIndex  , x , masterFadeInReadIndex;
masterFadeOutControls(x) = fadeLength , 0.0 , masterFadeOutWriteIndex , x@fadeLength , masterFadeOutReadIndex;
//-----------------------------------------------
masterFadeIn(x)  = masterFadeInControls(x)  : rwtable * masterFadeInVolume
with {
  masterFadeInVolume = (fadeLength - min(masterReadIndex, fadeLength)) / fadeLength;
};
masterFadeOut(x) = masterFadeOutControls(x) : rwtable * masterFadeOutVolume
with {
  masterFadeOutVolume = (masterReadIndex - masterLoopLength + fadeLength) / fadeLength :max(0);
};
masterLoop(x)    = masterControls(x)        : rwtable //* fadeVolume
with {
  fadeVolume = select3(
    (masterReadIndex > fadeLength) + (masterReadIndex >  (masterLoopLength - fadeLength)),
    masterReadIndex,
    fadeLength,
    masterLoopLength - masterReadIndex
    )
  /fadeLength;
};
//-----------------------------------------------
masterLooper(x) = masterFadeIn(x) + masterLoop(x) + masterFadeOut(x);
//-----------------------------------------------
stereoMasterLooper(x,y) =  masterLooper(x), masterLooper(y);
process =  stereoMasterLooper;

