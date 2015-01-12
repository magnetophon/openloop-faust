


(_+1,masterLoopLenght : %) ~ _;
masterIsWriting

masterPosition = (_+1,masterLoopLenght : %) ~ _;
//-----------------------------------------------
maxLoopL = 2^18 ;
masterWritePointer  =  masterIsWriting * masterPosition ;
masterReadPointer =  not(masterIsWriting) * masterPosition ;

//-----------------------------------------------
masterControls = maxLoopL, 0.0 , masterWritePointer , _ , masterReadPointer;

//-----------------------------------------------
fadeIn = 0;
fadeOut = 0;
masterLoop = masterControls : rwtable;

//-----------------------------------------------
masterLooper = fadeIn + masterLoop + fadeOut;

//-----------------------------------------------
stereoMasterLooper =  masterLooper, masterLooper;

process = stereoMasterLooper;
