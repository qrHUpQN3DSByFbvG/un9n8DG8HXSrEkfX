// Copyright © 2019, Denis A. Proshlyakov, dapro@chemistry.msu.edu
// This file is part of Kin-E-Sim project. 
// For citation, attribution and illustrations see <[PLACEHOLDER FOR PERMALINK TO THE ACCEPTED ARTICLE]> 
//
// Kin-E-Sim is free software: you can redistribute it and/or modify it under the terms of 
// the GNU General Public License version 3 as published by the Free Software Foundation.
//
// Kin-E-Sim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied 
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with this file.  If not, see <https://www.gnu.org/licenses/>.

#pragma rtGlobals=3		// Use modern global access method and strict wave access.



//**************************************************************************************************************************************
//
//								Implementation of standard template methods
//
//**************************************************************************************************************************************

// SWaveN - see Sim_Core procedure 
//			Simulation wave name; this wave is created and simulation range is set, output is stored in the same wave
//
// PWaveN -  see Sim_Core procedure 
//			General parameters wave name; this wave is input only; 
//
// CWaveN -  see Sim_Core procedure 
//			Mediators parameters wave name; 
//
// NPVWaveN - 1Dim, 15 points 
//		Sim parameters are saved as follows:
// 			NPVWave[0] - FromE - initial potential
// 			NPVWave[1] - ToE - final potential
// 			NPVWave[2] - StepsE - number of steps
//					integer value - stops simulation at ToE
//					real value with any decimal part - return to the FromE
// 			NPVWave[3] - RefE - reference potential
// 			NPVWave[4] - low_time
// 			NPVWave[5] - low_pnts
// 			NPVWave[6] - rise_time
// 			NPVWave[7] - rise_pnts
// 			NPVWave[8] - high_time
// 			NPVWave[9] - high_pnts
// 			NPVWave[10] - resereved
// 			NPVWave[11] - resereved
// 			NPVWave[12] - integration delay
// 			NPVWave[13] - integration span
// 			NPVWave[14] - resereved
// 			NPVWave[15] - resereved
// 			NPVWave[16] - special component - for possible further analysis


// 			JParWave[0] - flags
//							0 - normal calculation
//							1 - integrate & assemble
//							2 - assemble

// 			JParWave[6] - set method
//							0 - vary analyte E
//							1 - vary mediator 0 E
//							2 - vary mediator 1 E
//							......
// 			PWave[1] - bi-directional 
//							0 - single direction
//							1 - forward and reverse (flip signs of NPV papams)


Function NernstNPVOx(w,Eapp) : FitFunc
	Wave w
	Variable Eapp

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ //	return w[0]+w[1]/(1+exp(-w[3]*38.94*(w[2]-Eapp)))
	//CurveFitDialog/ 
	//CurveFitDialog/ f(Eapp) = offs+ampl/(1+exp(n*38.94*(E0-Eapp)))
	//CurveFitDialog/ 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Eapp
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = offs
	//CurveFitDialog/ w[1] = ampl0
	//CurveFitDialog/ w[2] = E0
	//CurveFitDialog/ w[3] = n0
	//CurveFitDialog/ w[4] = ampl1
	//CurveFitDialog/ w[5] = E1
	//CurveFitDialog/ w[6] = n1
//	return w[0]+w[1]/(1+exp(w[3]*38.94*(w[2]-Eapp)))

	
	return w[0]+w[1]*(-(1-1/(1+exp(w[3]*38.94*(w[2]-Eapp)))) +w[4] *(1- 1/(1+exp((w[3]+w[6])*38.94*(w[2]-w[5]-Eapp))))) 
//	return w[0]+w[1]*(1/(1+exp(w[3]*38.94*(w[2]-Eapp))) - w[4]/(1+exp((w[3]+w[6])*38.94*(w[2]+w[5]-Eapp))) )
	
End


Function NernstNPVRd(w,Eapp) : FitFunc
	Wave w
	Variable Eapp

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ //	return w[0]+w[1]/(1+exp(-w[3]*38.94*(w[2]-Eapp)))
	//CurveFitDialog/ 
	//CurveFitDialog/ f(Eapp) = offs+ampl/(1+exp(n*38.94*(E0-Eapp)))
	//CurveFitDialog/ 
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ Eapp
	//CurveFitDialog/ Coefficients 7
	//CurveFitDialog/ w[0] = offs
	//CurveFitDialog/ w[1] = ampl0
	//CurveFitDialog/ w[2] = E0
	//CurveFitDialog/ w[3] = n0
	//CurveFitDialog/ w[4] = ampl1
	//CurveFitDialog/ w[5] = E1
	//CurveFitDialog/ w[6] = n1
//	return w[0]+w[1]/(1+exp(w[3]*38.94*(w[2]-Eapp)))

	
	return w[0]+w[1]*(1/(1+exp(w[3]*38.94*(w[2]-Eapp))) - w[4]/(1+exp((w[3]+w[6])*38.94*(w[2]+w[5]-Eapp))) )
	
End


//**************************************************************************************************************************************
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  individual NPV simulation (Sim level) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

// ~~~~~~~~~~ Single NPV simulation preparation ~~~~~~~~~~
// proto: simWSetupProto
threadsafe  function prepNPVSimW(setData, simData) 
	STRUCT simSetDataT &setData;
	STRUCT simDataT &simData;

	string thisKillName =  setData.commName 
	string thisSimNameS = simData.name;
	variable FromE = simData.MWave[0];
	variable ToE = simData.MWave[1];
	variable RefE = simData.MWave[3];
	variable StepsE = simData.MWave[2]; // pulse steps: 
									// 1- single step
									// n - nsteps of (ToE - FromE) / (NSteps -1) increments
	variable theDir = simData.direction;
	if (theDir < 0) // reverse of bidir
		FromE *= -1;
		ToE *= -1;
		RefE *= -1;
	elseif (theDir > 0) // forward of bidir
	
	else // unidir
	endif
	
	if (theDir !=0)
		if (RefE > 0)
			simData.CWave[0][] = simData.CWave[0][q] + simData.CWave[1][q];	
			simData.CWave[1][] = 0;
		else
			simData.CWave[1][] = simData.CWave[0][q] + simData.CWave[1][q];	
			simData.CWave[0][] = 0;
		endif
	endif 
	
	variable low_time = simData.MWave[4]; // sec to rise
	variable low_pnts = simData.MWave[5]; // points to rise; last point is start of the rise
	variable rise_time = simData.MWave[6]; // duration of rise
	variable rise_pnts = simData.MWave[7]; // points during; first and last points are RefE and ToE
	variable high_time = simData.MWave[8]; // duration of pulse
	variable high_pnts = simData.MWave[9]; // points during pulse; first  point is the end  of the rise

	variable fullCycles = trunc(StepsE);
	variable lastE; 
	if  (StepsE != fullCycles) 
		lastE = 0; // FromE
	else
		lastE=1; //ToE;
	endif
	
	variable NPnts = (low_pnts + 2*rise_pnts + high_pnts - 4)*fullCycles - rise_pnts+2; // two points are shared betweed pairs or regions
	if ( lastE == 0)
		NPnts += low_pnts + rise_pnts -2;
	endif
	
	// Set up sim wave
	make /O /N=(NPnts, 14) $thisSimNameS
	wave SWave = $thisSimNameS;
	wave simData.SWave = SWave;
	// calculate time calibration
	
	variable currStep = 0;
	variable EStep = (ToE - FromE) / (fullCycles -1);
	variable currE = FromE; //+EStep

	variable lowStartN, lowStartT, riseStartN, riseStartT,  highStartN, highStartT, dropStartN, dropStartT, cycleEndN, cycleEndT;
	lowStartT = 0;
	lowStartN  = 0; 
	do 
		riseStartN =  lowStartN + low_pnts; 
		riseStartT = lowStartT + low_time;
		highStartN = riseStartN+rise_pnts -1;
		highStartT = riseStartT + rise_time;
		dropStartN = highStartN + high_pnts-1;
		dropStartT = highStartT + high_time;
		cycleEndN = dropStartN +rise_pnts -2;
		cycleEndT = dropStartT + rise_time; 
		
		currStep += 1;

		SWave[lowStartN,riseStartN-1][0]= lowStartT + (p - lowStartN) * low_time / (low_pnts -1); 
		SWave[lowStartN,riseStartN-1][1]= RefE; 

		if (currStep < StepsE || lastE) // rise and ToE are present only in full cycles
			SWave[riseStartN,highStartN - 1][0]=riseStartT + (p - riseStartN+1 )*(rise_time)/(rise_pnts-1);
			SWave[riseStartN,highStartN - 1][1]=RefE + (p - riseStartN+1 )*(currE - RefE)/(rise_pnts-1);

			SWave[highStartN,dropStartN-1][0]=highStartT + (p - highStartN +1  )*high_time/(high_pnts -1);
			SWave[highStartN,dropStartN-1][1]=currE;
		endif 
		if (currStep < StepsE) // drop is present only in full cycles or if half-cycle follows
			SWave[dropStartN,cycleEndN-1 ][0]=dropStartT + (p - dropStartN+1 )*(rise_time)/(rise_pnts-1);
			SWave[dropStartN,cycleEndN-1 ][1]= currE - (p - dropStartN+1 )*(currE - RefE)/(rise_pnts-1);
		endif
		
		lowStartT = cycleEndT;
		lowStartN = cycleEndN;
		currE +=EStep;
	while (currStep < StepsE);
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  data integration ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//
constant intHead = 1;
constant intFoot = 4;
constant intComp = 2;

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// this function integrates results of simulation and places integrated values into a reduced matix wave
//

// proto: simWProcessProto
threadsafe function /WAVE Int_Med_NPV04W(ResultWNSuffix, simData) 
	string ResultWNSuffix
	STRUCT simDataT &simData;
	
	wave NPVWave = simData.MWave;
	wave SWave = simData.SWave;
	variable iteration;

	string IWaveN = nameofwave(SWave) + "_i"; //ResultWNSuffix
	
	variable currStep = 0;
	variable StepsE = NPVWave[2]; // pulse steps: 
					// 1- single step
					// n - nsteps of (ToE - FromE) / NSteps increments

	variable low_time = NPVWave[4]; // sec to rise
	variable low_pnts = NPVWave[5]; // points to rise; last point is start of the rise
	variable rise_time = NPVWave[6]; // duration of rise
	variable rise_pnts = NPVWave[7]; // points during; first and last points are FromE and ToE
	variable high_time = NPVWave[8]; // duration of pulse
	variable high_pnts = NPVWave[9]; // points during pulse; first  point is the end  of the rise
	variable iDelay = 	NPVWave[12];
	variable iDuration = NPVWave[13];

	variable fullCycles = trunc(StepsE);
	variable lastE; 
	if  (StepsE != fullCycles) 
		lastE = 0; // RefE
	else
		lastE=1; //ToE;
	endif

	variable cN = dimsize(simData.CWave, 1)
	// Set up integration wave
	make /O /N=(fullCycles*2 + (1-lastE), intHead + intFoot + cN*intComp) $IWaveN
	wave simData.ProcSWave = $IWaveN
	wave IWave = simData.ProcSWave
	
	NPVWave[12] = iDelay;
	NPVWave[13] = iDuration;
	
	variable riseStartN, riseStartT,  highStartN, highStartT, dropStartN, dropStartT, cycleEndN, cycleEndT;
	variable lowStartT = 0
	variable lowStartN  = 0; 
	variable iStartT,  iEndT, iStartN,  iEndN; 
	variable i, offsS, offsI; 
	do 
		riseStartN =  lowStartN + low_pnts; 
		riseStartT = lowStartT + low_time;
		
		iStartT = lowStartT + iDelay;
		iEndT = iStartT + iDuration;
		if (iEndT >= riseStartT)
			iEndT = riseStartT;
		endif
		if (iStartT > iEndT )
			iStartT = iEndT;
		endif
		iStartN = round(lowStartN + (iStartT  - lowStartT) * (low_pnts -1) / low_time ); 
		iEndN = round (lowStartN + (iEndT  - lowStartT) * (low_pnts -1) / low_time ); 
		IWave[CurrStep*2][0] = average_rows(SWave, 1, iStartN, iEndN); //step potential;
		offsI = intHead;
		for (i=0; i< cN; i+=1, offsI += intComp)
			offsS = S_C_Offs + S_C_Num * i;
			if (numtype(SWave[0][offsS+2]) == 0 )
				IWave[CurrStep*2][offsI+0] = average_rows(SWave, offsS+0, iStartN, iEndN) + average_rows(SWave, offsS+2, iStartN, iEndN); 
				IWave[CurrStep*2][offsI+1] = average_rows(SWave, offsS+1, iStartN, iEndN) + average_rows(SWave, offsS+3, iStartN, iEndN); 
			else
				IWave[CurrStep*2][offsI+0] = average_rows(SWave, offsS+0, iStartN, iEndN); 
				IWave[CurrStep*2][offsI+1] = average_rows(SWave, offsS+1, iStartN, iEndN); 
			endif
		endfor 
		IWave[CurrStep*2][offsI] = iStartN;
		IWave[CurrStep*2][offsI+1] = iEndN;
		IWave[CurrStep*2][offsI+2] = iStartT;
		IWave[CurrStep*2][offsI+3] = iEndT;

		if (currStep +1  < StepsE || lastE ) // do if this is the last full cycle of half cycle follows
			highStartN = riseStartN+rise_pnts -1;
			highStartT = riseStartT + rise_time;
			dropStartN = highStartN + high_pnts-1;
			dropStartT = highStartT + high_time;

			iStartT = highStartT + iDelay;
			iEndT = iStartT + iDuration;
			if (iEndT >= dropStartT)
				iEndT = dropStartT;
			endif
			if (iStartT > iEndT )
				iStartT = iEndT;
			endif
			iStartN = round(highStartN + (iStartT  - highStartT) * (high_pnts -1) / high_time ); 
			iEndN = round (highStartN + (iEndT  - highStartT) * (high_pnts -1) / high_time) ;  

			IWave[CurrStep*2+1][0] = average_rows(SWave, 1, iStartN, iEndN); // FromE + (ToE-FromE) * ;
			offsI = intHead;
			for (i=0; i< cN; i+=1, offsI += intComp)
				offsS = S_C_Offs + S_C_Num * i;
				if (numtype(SWave[0][offsS+2]) == 0 )
					IWave[CurrStep*2+1][offsI+0] = average_rows(SWave, offsS+0, iStartN, iEndN) + average_rows(SWave, offsS+2, iStartN, iEndN);
					IWave[CurrStep*2+1][offsI+1] = average_rows(SWave, offsS+1, iStartN, iEndN) + average_rows(SWave, offsS+3, iStartN, iEndN);
				else
					IWave[CurrStep*2+1][offsI+0] = average_rows(SWave, offsS+0, iStartN, iEndN);
					IWave[CurrStep*2+1][offsI+1] = average_rows(SWave, offsS+1, iStartN, iEndN);
				endif
			endfor 
			IWave[CurrStep*2+1][offsI+0] = iStartN;
			IWave[CurrStep*2+1][offsI+1] = iEndN;
			IWave[CurrStep*2+1][offsI+2] = iStartT;
			IWave[CurrStep*2+1][offsI+3] = iEndT;

			cycleEndN = dropStartN +rise_pnts -2;
			cycleEndT = dropStartT + rise_time; 

			lowStartT = cycleEndT;
			lowStartN = cycleEndN;
		endif
		currStep += 1;
	while (currStep < StepsE);
	return IWave;	
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//     service function
//
threadsafe function average_rows(theWave, theCol, fromN, toN)
	wave theWave;
	variable theCol, fromN, toN;
	
	if (fromN > toN)
		variable tmp = fromN;
		fromN = toN;
		toN = tmp;
	endif
	
	variable ave = 0;
	variable i;
	for (i = fromN; i<= toN; i+=1)
		ave += theWave[i][theCol];
	endfor 
	ave /= toN - fromN +1;
	return ave;
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	2D Graph single NPV sim 
// 

// proto: simPlotBuildProto
function simPlotBuild_NPVSimple (plotNameS, theSim, theSet) 
	string plotNameS // name of the plot/window
	STRUCT simSetDataT &theSet;
	STRUCT simDataT &theSim;

	string plotN;
	sprintf plotN, "%s_C%02d",  plotNameS, theSim.index; 

	if (theSim.direction > 0 )
		simNPVPlotBuild(plotN, theSim.SWave, 1, "NPV_", "f", theSim.PWave, theSim.CWave)  
	elseif (theSim.direction < 0 )
		simNPVPlotBuild(plotN, theSim.SWave, -1,  "NPV_", "r", theSim.PWave, theSim.CWave) 	
	else 
		simNPVPlotBuild(plotN, theSim.SWave, 0, "NPV_", "", theSim.PWave, theSim.CWave) 
	endif 
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	2D Graph single NPV sim 
// 
// service, called from simPlotBuild_NPVSimple
function simNPVPlotBuild(plotN, NPVSimW, direction, commTraceN, nameSuffix, NPVParW, CWave)
	string plotN // name of the plot
	wave  NPVSimW // wave that contains simulated data
	string  commTraceN; // common name for traces
	variable direction; // forward or reverse
	wave  NPVParW; // wave containing NPV parameters 
	wave CWave; // components
	string nameSuffix; // suffix to append to names (i.e. "f" or "r" or blank)
	

	DoWindow /F $plotN   
	if (V_flag == 0) // no such window...
		string wTitle = "\""+plotN+"\""
		Display /B /L /N=$plotN as plotN
	endif 
	Legend /W=$plotN /B=1/C/N=theLegend/F=0/M/A=RB/X=50/Y=-50

	variable cN = dimsize(CWave,1);
	variable i; 
	variable lstyle = direction > 0 ? 0 : 2;
	string traceList = TraceNameList(plotN, ";", 1);
	
	// overall 
	string traceN = commTraceN+"Eapp"+nameSuffix;

	if (findListItem(traceN,traceList) == -1) // trace is not on the list
		AppendToGraph  /R  /W=$plotN  NPVSimW[*][1]/TN=$traceN vs NPVSimW[*][0]
	endif
	ModifyGraph  /W=$plotN rgb($traceN)=(0, 0, 0), lstyle($traceN)=(lstyle)
	
	for (i=0; i < cN; i+=1)
		string traceLabel = GetDimLabel(CWave, 1, i);
		if (strlen(traceLabel))
			traceLabel = "_" + traceLabel;
		endif
		sprintf traceN, "%s%02d%s%s", commTraceN, i, nameSuffix, traceLabel
		if (findListItem(traceN,traceList) == -1) // trace is not on the list
			AppendToGraph   /W=$plotN  NPVSimW[*][S_C_Offs + i*S_C_Num+0]/TN=$traceN vs NPVSimW[*][0]
		endif
		variable r = 0 , g = 0 , b = 0 ;
		variable relColor = i/(cN -1) 
		switch (direction)
			case -1: // reduction
			case 1: // oxidation
			case 0: //uni-directional
				r = 65535 * relColor;
				b = 65535 * (1 - relColor);
			default:	
				break;
		endswitch
		ModifyGraph  /W=$plotN rgb($traceN)=(r, g, b), lstyle($traceN)=(lstyle)
	endfor
	
	Label /W=$plotN right "E\\Bapp\\M / V"
	Label /W=$plotN bottom "time / s"
	Label /W=$plotN left "[C\\Bi\\M] \\E"
	
	string plotLabel
	sprintf plotLabel, "Sim:%s\rmore info here...", nameofwave(NPVSimW)
	TextBox/C/N=PlotLbl/F=0/M/B=1/A=RT/X=50/Y=50 plotLabel
end	




//**************************************************************************************************************************************
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  1D group of NPV simulations (Set level) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// example of set setup function that varies the potential of specified component
//
//  proto: setInputSetupProto
threadsafe function /S setInSetup_CE0(setData, setEntries)
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	
	variable Set_From =  setData.JParWave[2];
	variable Set_To =  setData.JParWave[3];
	variable Set_Steps =  setData.JParWave[4];
	variable C2Vary = setData.JParWave[6] ;

	if (Set_Steps > 1)
		setData.setValueClb = Set_From + p * (Set_To - Set_From) / (Set_Steps-1);
	else
		setData.setValueClb = Set_From;
		setData.JParWave[3] =setData.JParWave[2];
	endif
	

	string result;
	if (C2Vary >=0 && C2Vary < dimsize(setData.CWave, 1)) // sims must conain at least one entry
		sprintf result, "Set varying E0 of C%02u  from %g to %g over %u  steps", C2Vary, Set_From, Set_To, Set_Steps
	else
		result = "Incorrect set mode!"
	endif
	return result;
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: setInputAssignProto

threadsafe function setInAssign_CE0(setData, setEntries)
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;

	// retrieve set param from the job file
	variable C2Vary = setData.JParWave[6] ;

	variable i;
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name

		// CWave & RWave are duplicated by the fraemwork 
		// Other waves must be duplicated for threaded processing!!
		// duplicate /O setData.PWave $(tgtSimPath+"P")
		// WAVE setEntries.sims[i].PWave = $(tgtSimPath+"P")
		
		// update information string to reflect the assignement
		variable theVal = setData.setValueClb[setEntries.sims[i].group]
		if (setEntries.sims[i].direction != 0)
			theVal *= setEntries.sims[i].direction;
		endif 
		string info; 
		sprintf info "Sim for E(C%d)=%0.2gV; ",  C2Vary, theVal;
		setEntries.sims[i].text += info; 
		
		// perform the assignement as needed
		setEntries.sims[i].CWave[2][C2Vary] = theVal;
	endfor
end 


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// example of set function that prepares output wave to store results of component potential variation
//
// this function will prepare one or two 2D wave(s) to store integrated NPV values with one row per sim
//
//  proto: setResultSetupProto
function setOutSetup_NPV_CE0(theParams, groupEntries) 
	STRUCT simSetDataT &theParams;
	STRUCT simSetDataArrT &groupEntries;
	
	string setResultWN = theParams.rootFldr+theParams.commName; // common name for the set....
	
	variable Set_Steps = dimsize(theParams.setValueClb, 0); // Number of steps in this set; also can be calculated from JParWave

	variable BiDir = theParams.PWave[1] ;
	variable cN = dimsize(theParams.CWave, 1);
	
	variable NPV_steps = theParams.MWave[2];

	variable NPV_pnts;
	if  (NPV_steps !=  trunc(NPV_steps)) 
		NPV_pnts = trunc(NPV_steps) * 2 +1; // FromE
	else
		NPV_pnts = NPV_steps * 2; //ToE;
	endif
	
	if (BiDir != 0 )
		BiDir = 1;
		theParams.PWave[1] = 1;
	endif 

	variable FromE = theParams.MWave[0];
	variable ToE = theParams.MWave[1];
	variable StepE = (ToE - FromE) / trunc(NPV_steps-1);
	
	if (BiDir)
		make /N=(Set_Steps, NPV_pnts, cN) /O $(setResultWN + "_Oxf"), $(setResultWN + "_Rdf"), $(setResultWN + "_Oxr"), $(setResultWN + "_Rdr")
		DoMakeClb("Doesn't matter", FromE, StepE, trunc(NPV_steps), 0, 0,  SetResultWN+"_Fwd_EappClb")
		DoMakeClb("Doesn't matter", ToE, -StepE, trunc(NPV_steps), 0, 0,  SetResultWN+"_Rev_EappClb")
	else
		make /N=(Set_Steps, NPV_pnts, cN) /O $( SetResultWN + "_Ox"), $(setResultWN + "_Rd")
		DoMakeClb("Doesn't matter", FromE, StepE, trunc(NPV_steps), 0, 0,  SetResultWN+"_EappClb")
	endif 
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// example of set function that stores of component potential variation model result in summary waves
//
// this function saves inetgrated results in the output wave
//
// proto: setResultAssignProto
threadsafe function setOutAssign_NPV_CE0(setData,simData) 
	STRUCT simSetDataT &setData;
	STRUCT simDataT &simData;

	variable cN = dimsize(simData.CWave, 1);
	wave thisIntWave = simData.ProcSWave; 
	string setResultWN = (setData.rootFldr+setData.commName);
	
	variable j; 
	if (simData.direction > 0) // forward
		wave SetCWOf = $(setResultWN + "_Oxf")
		wave SetCWRf = $(setResultWN + "_Rdf")
		for (j=0; j<cN; j+=1)	
			SetCWOf[simData.group][][j] = thisIntWave[q][intHead + j*intComp];
			SetCWRf[simData.group][][j] = thisIntWave[q][intHead + j*intComp+1];
		endfor
	elseif (simData.direction < 0) // reverse
		wave SetCWOr = $(setResultWN + "_Oxr")
		wave SetCWRr = $(setResultWN + "_Rdr")
		for (j=0; j<cN; j+=1)	
			SetCWOr[simData.group][][j] = thisIntWave[q][intHead + j*intComp];
			SetCWRr[simData.group][][j] = thisIntWave[q][intHead + j*intComp+1];
		endfor
	else // unidirectional 
		wave SetCWO = $( SetResultWN + "_Ox");
		wave SetCWR = $( SetResultWN + "_Rd");
		for (j=0; j<cN; j+=1)	
			SetCWO[simData.group][][j] = thisIntWave[q][intHead + j*intComp];
			SetCWR[simData.group][][j] = thisIntWave[q][intHead + j*intComp+1];
		endfor
	endif
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// example of set function that does clean up and post-processing of component potential variation model
//
// this function calls processing of compelete sets of integrated results
//
// proto: setResultCleanupProto
function setOutCleanup_NPV_CE0(setData, setEntries, setResultWN) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	string setResultWN; // common name for the set....

	variable Set_Steps = dimsize(setData.setValueClb, 0); // Number of steps in this set; also can be calculated from JParWave
	variable BiDir = setData.PWave[1] ;
	
	
	variable NPVSteps = setData.MWave[2];
	variable FromE = setData.MWave[0];
	variable ToE = setData.MWave[1];

	variable intiDir  = (FromE <= ToE ? 1 : -1);
	if (BiDir)
		wave SetCWOf = $(setResultWN + "_Oxf")
		wave SetClbFwdW = $(setResultWN + "_Fwd_EappClb");
		processNPV(SetCWOf, SetClbFwdW,  setData.CWave, setData.setValueClb, intiDir , (setData.JParWave[6])); 
		wave SetCWOr = $(setResultWN + "_Oxr")
		wave SetClbRevW = $(setResultWN + "_Rev_EappClb");
		processNPV(SetCWOr, SetClbRevW,  setData.CWave,  setData.setValueClb, -intiDir, (setData.JParWave[6])); 
	else
		wave SetCWO = $( SetResultWN + "_Ox");
		wave SetClbW = $(setResultWN + "_EappClb");
		processNPV(SetCWO, SetClbW, setData.CWave, setData.setValueClb, intiDir, (setData.JParWave[6])); 
	endif

	// cleanup MTWaves
	variable i;
	for (i=0; i< setEntries.count; i+=1)
		if (cmpstr(GetWavesDataFolder(setEntries.sims[i].CWave, 2), GetWavesDataFolder(setData.CWave,2)))
			wave CWave = setEntries.sims[i].CWave
			killwaves /Z CWave;
		endif
		if (cmpstr(GetWavesDataFolder(setEntries.sims[i].ERxnsW,2) , GetWavesDataFolder(setData.ERxnsW,2)))
			wave /WAVE ERxnsW = setEntries.sims[i].ERxnsW
			killwaves /Z ERxnsW;
		endif
		if (cmpstr(GetWavesDataFolder(setEntries.sims[i].GRxnsW,2) , GetWavesDataFolder(setData.GRxnsW,2)))
			wave /WAVE GRxnsW = setEntries.sims[i].GRxnsW
			killwaves /Z GRxnsW;
		endif
		if (cmpstr(GetWavesDataFolder(setEntries.sims[i].PWave,2) , GetWavesDataFolder(setData.PWave,2)))
			wave PWave = setEntries.sims[i].PWave
			killwaves /Z PWave
		endif
	endfor

end


//**************************************************************************************************************************************
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  2D group of NPV simulations (Kilo level) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (kilo) set setup function that varies the  
//			 parameter lineary (meaning of the value depends on the assignment)  
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  proto: groupInputSetupProto

threadsafe function /S kiloInSetup_LinValue(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &groupEntries
	
	variable Set_From =  setData.JParWave[10];
	variable Set_To =  setData.JParWave[11];
	variable Set_Steps =  setData.JParWave[12];

	if (Set_Steps > 1)	
		setData.setValueClb = (Set_From + p * (Set_To - Set_From) / (Set_Steps-1));
	else
		setData.setValueClb =  Set_From;
		setData.JParWave[11] =setData.JParWave[10];
	endif

	string result
	sprintf result "Kiloset varying value lineary  from %d to %d in %d steps",Set_From, Set_To, Set_Steps;
	return result;
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (kilo) set setup function that varies the  
//			 parameter exponentially (meaning of the value depends on the assignment)   
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  proto: groupInputSetupProto

threadsafe function /S kiloInSetup_ExpValue(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries
	
	variable Set_From =  setData.JParWave[10];
	variable Set_To =  setData.JParWave[11];
	variable Set_Steps =  setData.JParWave[12];

	if (Set_Steps > 1)	
		setData.setValueClb = 10 ^ (Set_From + p * (Set_To - Set_From) / (Set_Steps-1));
	else
		setData.setValueClb = 10 ^ Set_From;
		setData.JParWave[11] =setData.JParWave[10];
	endif
	
	string result
	sprintf result "Kiloset varying value exponentially from 1E%d to 1E%d in %d steps",Set_From, Set_To, Set_Steps;
	return result;
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_ERxnRate(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable rxnNo = setData.JParWave[14];

	
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		// perform the assignement here as needed
		if (groupInAssign_RxnRate(setData, groupEntries.sets[i], groupEntries.sets[i].ERxnsW, rxnNo) )
			return 1;
		endif;
	endfor
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_GRxnRate(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable rxnNo = setData.JParWave[14];
	
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		// perform the assignement here as needed
		if (groupInAssign_RxnRate(setData, groupEntries.sets[i], groupEntries.sets[i].GRxnsW, rxnNo) )
			return 1;
		endif;
	endfor
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
threadsafe function  groupInAssign_RxnRate(setData, theEntry, RxnsW, rxnNo) 
	STRUCT simSetDataT &setData;
	STRUCT setDataT &theEntry
	wave /WAVE RxnsW
	variable rxnNo
	
	variable hasError = 0;
	if (waveexists(RxnsW))
		wave TDWave  = RxnsW[0];
		if (waveexists(TDWave))
			TDWave[rxnNo][0] = setData.setValueClb[theEntry.index];
		else
			hasError = 1
		endif
	else
		hasError = 1
	endif
		
	if (hasError)
		theEntry.result = -1;
		theEntry.text += "Wave for echem reactions is not found";
		setData.error = 1; 
		setData.text += " == Error: Wave for echem reactions is not found for entry #"+num2str(theEntry.index)+"==";
		return 1;
	else
		string info; 
		sprintf info "Group value rate of Rxn#%02d (%s) is set to %g ",rxnNo, GetDimLabel(TDWave, 0, rxnNo), (setData.setValueClb[theEntry.index]); ///C%02d/ 
		theEntry.text += info; 
	endif 
	return 0;
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_RateElectr(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable Ca = setData.JParWave[14];
	
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		
		// update information string to reflect the assignement
		string info; 
		sprintf info "Kilo value C%02d/electrode rate is set to %g ",Ca, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 
		
		// perform the assignement here as needed
		groupEntries.sets[i].CWave[4][Ca] = setData.setValueClb[i];
	endfor
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_BindingK(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable Ca = setData.JParWave[14];
	
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		
		// update information string to reflect the assignement
		string info; 
		sprintf info "Kilo value C%02d K binding is set to %g ",Ca, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 
		
		// perform the assignement here as needed
		groupEntries.sets[i].CWave[10][Ca] = setData.setValueClb[i];
	endfor
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_ElMaxRate(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable Ca = setData.JParWave[14];
	
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		
		// update information string to reflect the assignement
		string info; 
		sprintf info "Kilo value C%02d/electrode max rate is set to %g ",Ca, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 
		
		// perform the assignement here as needed
		groupEntries.sets[i].CWave[8][Ca] = setData.setValueClb[i];
	endfor
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  kiloInAssign_CConc(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve kilo param from the job file
	variable Ca = setData.JParWave[14];

	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		
		// update information string to reflect the assignement
		string info; 
		sprintf info  "Kilo value C%02d  concentration is set to %g ",Ca, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 
		
		// perform the assignement here as needed
		groupEntries.sets[i].CWave[1][Ca] = setData.setValueClb[i];
	endfor
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (super) set plot setup function that prepares display of  
//			 3D NPV response and 2D n & E0 deviation
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: setPlotSetupProto

function kiloPlotSetup_Rate00_01(setData, plotNameS) 
	STRUCT simSetDataT &setData;
	string plotNameS // name of the plot/window
	
	kiloNPVRespGizBuild(plotNameS+"_NPV");
	
	variable biDir= setData.PWave[1];
	if (biDir)
		kiloNPVDevPlotBuild(plotNameS+"_DevFwd"); 
		kiloNPVDevPlotBuild(plotNameS+"_DevRev"); 
	else
		kiloNPVDevPlotBuild(plotNameS+"_Dev"); 
	endif 
end

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (kilo) set plot append function that adds traces for  
//			 3D NPV response and 2D n & E0 deviation
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupPlotAppendProto

function kiloPlotAppend_Rate00_01(setData, groupEntries, plotNameS, iteration)
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;
	string plotNameS // name of the plot/window
	variable iteration // call # in this superset


	wave NPVParW = groupEntries.sets[iteration].MWave; // name of NPV parameters wave
	string thisSetNameS = groupEntries.sets[iteration].name+setData.commName; //  common name for this series
	wave JParWave = groupEntries.sets[iteration].JParWave; // name of the wave that contains set information
	wave  SetClbWave = setData.setValueClb; // wave contaning calculated set calibration

	variable totalIter  =  JParWave[12];  // out of total # calls
	variable superVal = SetClbWave[floor(iteration)]; // current calculated value

	variable plotCNum  = JParWave[16]; // not used here


	variable biDir= SetData.PWave[1];
	
	string NPVWN,  surfN; 
	// this needs info about BiDir mode!
	
	if (biDir)
		sprintf NPVWN, "%s_OxfC%02d_NPV", thisSetNameS, plotCNum
	else
		sprintf NPVWN, "%s_OxC%02d_NPV", thisSetNameS, plotCNum
	endif
	sprintf surfN "surf%02d", iteration
	kiloSetGizAppend(plotNameS+"_NPV", NPVWN, surfN, iteration)	

	string fwdNrnstWN, revNrnstWN
	
	if (biDir)
		sprintf fwdNrnstWN, "%s_Oxf_Nrnst", thisSetNameS
		sprintf revNrnstWN, "%s_Oxr_Nrnst", thisSetNameS
		kiloNPVDevPlotAppend(plotNameS+"_DevFwd", plotCNum, 1, fwdNrnstWN, surfN, iteration, totalIter);	
		kiloNPVDevPlotAppend(plotNameS+"_DevRev", plotCNum, -1, revNrnstWN, surfN, iteration, totalIter);	
	else
		sprintf fwdNrnstWN, "%s_Ox_Nrnst", thisSetNameS
		kiloNPVDevPlotAppend(plotNameS+"_Dev", plotCNum, 0, fwdNrnstWN, surfN, iteration, totalIter);	
	endif 
end



//**************************************************************************************************************************************
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  3D group of NPV simulations (Mega level) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (mega) set setup function that varies the  
//			 concentraion of a component 
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputSetupProto

threadsafe function /S megaInSetup_CConc(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;
	
	variable Set_From =  setData.JParWave[19];
	variable Set_To =  setData.JParWave[20];
	variable Set_Steps =  setData.JParWave[21];
	variable Ca = setData.JParWave[23];
	variable form = setData.JParWave[24];
	
	if (Set_Steps > 1)
		setData.setValueClb =  (Set_From + p * (Set_To - Set_From) / (Set_Steps-1));
	else
		setData.setValueClb = Set_From;
		setData.JParWave[20] =setData.JParWave[19];
	endif
	
	string result 
	sprintf result "Megaset varying [C%02d] from %g to %g in %d steps",Ca,  Set_From, Set_To, Set_Steps;
	return result
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//			 example of (mega) set assignment function that varies the  
//			 concentraion of a component 
//	
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto

threadsafe function  megaInAssign_CConc(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve mega param from the job file
	variable Ca = setData.JParWave[23];
	
	string form; 
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		// perform the assignement here as needed
		if (setData.JParWave[24] < 0) //reduced
			groupEntries.sets[i].CWave[1][Ca] = setData.setValueClb[i];
			groupEntries.sets[i].CWave[0][Ca] = 1;
			form = "rd";
		else // oxidized
			groupEntries.sets[i].CWave[0][Ca] = setData.setValueClb[i];
			groupEntries.sets[i].CWave[1][Ca] = 0;
			form = "ox";
		endif
		
		// update information string to reflect the assignement
		string info; 
		sprintf info  "Mega value [C%02d%s] is set to %g ",Ca, form, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 
	endfor
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
// proto: groupInputAssignProto
threadsafe function megaInAssign_RateElectr(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries

	// retrieve mega param from the job file
	variable Ca = setData.JParWave[23];

	string form; 
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		// update information string to reflect the assignement
		string info; 
		sprintf info  "Mega value C%02d/electrode rate is set to %g  ",Ca, (setData.setValueClb[i]);
		groupEntries.sets[i].text += info; 

		// perform the assignement here as needed
		groupEntries.sets[i].CWave[2][Ca] = setData.setValueClb[i];

	endfor
end





//**************************************************************************************************************************************
//
//								service functions for NPV processing
//
//**************************************************************************************************************************************


//=================================================
//
//
// this function is called once after simulation of entire set is complete and all results are assigned to the summary wave
//

function processNPV(theSimW, theClbW, CWave, setE0ClbW, dirNPV, SetC) 
	wave theSimW; 
	wave theClbW
	wave CWave
	wave setE0ClbW;
	variable dirNPV;
	variable SetC; // which component is varied in the set
	
	// prepare processing setvices	
	string SetNameS =  nameofwave(theSimW)
	variable cN = dimSize(theSimW, 2);	 
	variable Set_Steps = dimSize(theSimW, 0)
	variable NPVSteps = dimSize(theClbW, 0); //, FromE, StepE;

	
	variable /G V_FitTol 
	V_FitTol =  0.000001
	variable /G V_FitMaxIters
	V_FitMaxIters  = 60

 	string datWN = SetNameS+"_dat";
	string outWN = SetNameS+"_out";
	make /O /N=(NPVSteps) $datWN, $outWN
	wave datW = $datWN
	wave outW = $outWN
	
	string cWN = SetNameS+"_coef";
	make /O /N=(7) $cWN
	wave cW = $cWN



	string coefWN = SetNameS+"_Nrnst"
	make /O /N=(Set_Steps, 10, cN) $coefWN // this should vary depending on the model
	wave coefW = $coefWN
		
			
	string epsilonWN = SetNameS+"_Eps"
	make /O /N=(7) $epsilonWN // this should vary depending on the model
	wave epsilonW = $epsilonWN
	epsilonW[0] = {.000001,0.00002,.0005,.001,.01,0,0}
		
	string holdStr0 = "1011111";
	string constrW0N = SetNameS+"_Const0"
	Make/O/T/N=1 $constrW0N
	wave /T constrW0 = $constrW0N
	constrW0[0] = {"K1 > 0"}

	string holdStr1 = "1101111";
	string constrW1N = SetNameS+"_Const1"
	Make/O/T/N=2 $constrW1N
	wave /T constrW1 = $constrW1N
	constrW1[0] = {"K2 > -.5","K2 < .5"}

	string constrW2N = SetNameS+"_Const2"
	Make/O/T/N=5 $constrW2N
	wave /T constrW2 = $constrW2N
	constrW2[0] = {"K1 > 0","K2 > -.5","K2 < .5","K4 > 0","K4 < 1"}

	string constrW3N = SetNameS+"_Const3"
	Make/O/T/N=7 $constrW3N
	wave /T constrW3 = $constrW3N
	constrW3[0] = {"K1 > 0","K2 > -.5","K2 < .5","K3 > 0.5","K3 < 2.5","K4 > 0","K4 < 1"}
	
	string holdStr2 = "0001011";
	string holdStr3 = "0000011";

	// prepare data	
	 variable c;
	 string singleCWN = SetNameS+"_tmpC";

	 make /O /N=(dimsize(theSimW, 0), dimsize(theSimW, 1)) $singleCWN
	 wave singleCW = $singleCWN;
	 string cmpOutCommWN;
	 variable compE; 
	 string fitWN;
	 for (c=0; c< cN; c+=1)
	 	
	 	sprintf cmpOutCommWN, "%sC%02d_", SetNameS, c;
	 	string respFWN =  cmpOutCommWN+"NPV";
	 	string bkgFWN =  cmpOutCommWN+"Bkg";
	 	fitWN = respFWN+"Fit";
		variable waveFlag = CWave[6][c];
	 	if (!(waveFlag))  
		 	coefW[][][c] = NaN;
			 killWaves /Z $fitWN
			 killWaves /Z  $(respFWN)
			 killWaves /Z  $( bkgFWN)
	 		continue; 
	 	endif
		make /O /N=(Set_Steps, NPVSteps) $fitWN 
		wave fitW = $fitWN
	 	
	 	singleCW[][]=theSimW[p][q][c]; //theSimW
		DoSplitComponents(  "Pulse"  , singleCW,    NPVSteps  , respFWN ,   bkgFWN,   0  ,   0  ,   0  ,   0  );

		wave respFW = $(respFWN)
	
		variable i;
		variable guessE; 
		for (i=0; i < Set_Steps; i+=1)
				datW = respFW[i][p];
				cW[0] = 0;
				cW[1] = CWave[0][c]+CWave[1][c];
				if (c == SetC) // should this guess be taken from set calibraition or from CWave?
					compE = setE0ClbW[i];
				else
					compE = CWave[2][c];
				endif
				cW[2] = compE;
				guessE = compE;
				cW[3] = CWave[3][c];
				cW[4] = 0;
				cW[5] = 0.059;
				cW[6] = 2;
	
				 constrW2[1] = "K2 > "+num2str(compE - 0.3);
				 constrW2[2] = "K2 < "+num2str(compE + 0.3);
				 constrW3[1] = constrW2[1];
				 constrW3[2] = constrW2[2];
			 
				// change constraints or guessing depending on the value
				variable noUpd = 1;
				variable noProg = 2; 
				if (dirNPV > 0) // oxidation 
					cW[4] = 0.25;
					outW =  NernstNPVRd(cW,theClbW[p] )
					FuncFit  /H=holdStr0 /N=(noUpd) /W=(noProg) /Q NernstNPVRd, cW, datW  /X=theClbW  /C=constrW0 /E=epsilonW //  /D=outW
					FuncFit  /H=holdStr1 /N=(noUpd) /W=(noProg) /Q NernstNPVRd, cW, datW  /X=theClbW  /C=constrW1 /E=epsilonW   /D=outW
					FuncFit  /H=holdStr2 /N=(noUpd) /W=(noProg) /Q NernstNPVRd, cW, datW  /X=theClbW  /C=constrW2 /E=epsilonW   /D=outW
					FuncFit  /H=holdStr3 /N=(noUpd) /W=(noProg) /Q NernstNPVRd, cW, datW  /X=theClbW  /C=constrW3 /E=epsilonW  /D=outW
				else // reduction
					cW[4] =  0.25;
					outW =  NernstNPVOx(cW,theClbW[p] )
					FuncFit  /H=holdStr0  /N=(noUpd) /W=(noProg) /Q NernstNPVOx, cW, datW  /X=theClbW  /C=constrW0 /E=epsilonW //  /D=outW
					FuncFit  /H=holdStr1  /N=(noUpd) /W=(noProg) /Q NernstNPVOx, cW, datW  /X=theClbW  /C=constrW1 /E=epsilonW   /D=outW
					FuncFit  /H=holdStr2  /N=(noUpd) /W=(noProg) /Q NernstNPVOx, cW, datW  /X=theClbW  /C=constrW2 /E=epsilonW   /D=outW
					FuncFit  /H=holdStr3  /N=(noUpd) /W=(noProg) /Q NernstNPVOx, cW, datW  /X=theClbW   /C=constrW3 /E=epsilonW /D=outW
				endif; 

				wave sigmaW = $"W_sigma"

				coefW[i][0,6][c] = cW[q]
				coefW[i][7][c] =  log(1/sqrt((sigmaW[2])^2 + (sigmaW[3])^2));
				coefW[i][8][c] = cW[2] -compE;
				coefW[i][9][c] = cW[3] - CWave[3][c];
				 fitW[i][] = outW[q]
			endfor	// set steps
		endfor // components	
	killWaves /Z singleCW
	killWaves /Z epsilonW 
	killWaves /Z  constrW0, constrW1, constrW2, constrW3
	killWaves /Z  cW
	killWaves /Z  datW
	 killWaves /Z  outW
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  										Plotting service functions 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	3D Gizmo overlay setup
// 
function kiloNPVRespGizBuild(gizmoN) : GizmoPlot
	string gizmoN;
	
	// Do nothing if the Gizmo XOP is not available.
	if(exists("NewGizmo")!=4)
		DoAlert 0, "Gizmo XOP must be installed"
		return 0
	endif
	
	
	DoWindow /F $gizmoN   // /F means 'bring to front if it exists'
	if (V_flag != 0)
		return 1;
	endif 
	
	execute "NewGizmo /N="+gizmoN+" /T=\""+gizmoN+"\""
	execute "AppendToGizmo /N="+gizmoN+" Axes=boxAxes,name=axes0"
	execute "ModifyGizmo /N="+gizmoN+"  ModifyObject=axes0,property={0,axisRange,-1,-1,-1,1,-1,-1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={1,axisRange,-1,-1,-1,-1,1,-1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={2,axisRange,-1,-1,-1,-1,-1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={3,axisRange,-1,1,-1,-1,1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={4,axisRange,1,1,-1,1,1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={5,axisRange,1,-1,-1,1,-1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={6,axisRange,-1,-1,1,-1,1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={7,axisRange,1,-1,1,1,1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={8,axisRange,1,-1,-1,1,1,-1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={9,axisRange,-1,1,-1,1,1,-1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={10,axisRange,-1,1,1,1,1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={11,axisRange,-1,-1,1,1,-1,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={-1,axisScalingMode,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={-1,axisColor,0,0,0,1}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={0,ticks,3}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={1,ticks,3}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject=axes0,property={2,ticks,3}"
	execute "ModifyGizmo /N="+gizmoN+" modifyObject=axes0 property={Clipped,0}"
	execute "ModifyGizmo /N="+gizmoN+" setDisplayList=0, object=axes0"
	execute "ModifyGizmo /N="+gizmoN+" SETQUATERNION={0.227916,0.024671,-0.072894,0.970635}"
	execute "ModifyGizmo /N="+gizmoN+" autoscaling=1"
	execute "ModifyGizmo /N="+gizmoN+" currentGroupObject=\"\""
End



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	3D Gizmo overlay append layer
// 
function kiloSetGizAppend(gizmoN, theW, theN, itemN) : GizmoPlot
	string gizmoN, theW, theN;
	variable itemN
 	execute "RemoveFromGizmo /Z /N="+gizmoN+" object="+theN
 	execute "AppendToGizmo /N="+gizmoN+" Surface="+theW+",name="+theN
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject="+theN+" property={ fillMode,3}" // point cloud 4; fill 2;  wireframe 1
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject="+theN+" property={ srcMode,0}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject="+theN+" property={ surfaceCTab,Rainbow}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject="+theN+" property={ surfaceCTABAlpha, "+num2str(0.1*(10-itemN))+"}"
	execute "ModifyGizmo /N="+gizmoN+" ModifyObject="+theN+" property={ surfaceCTABScaling,4}"
	execute "ModifyGizmo /N="+gizmoN+" setDisplayList="+num2str(itemN+1)+", object="+theN+""
End






//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	2D Graph setup
// 
function kiloNPVDevPlotBuild(plotN) : Graph
	string plotN;
	DoWindow /F $plotN   // /F means 'bring to front if it exists'
	if (V_flag == 0)
		string wTitle = "\""+plotN+"\""
		Display /B /L /N=$plotN as plotN
	endif 


	TextBox /W=$plotN /C/N=text0/F=0/A=MC/X=29.37/Y=41.31 "dot size ~ confidence"
	Legend /W=$plotN /C/N=text1/F=0/M/A=MC
	end
	



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//	2D Graph append trace
// 
function kiloNPVDevPlotAppend(plotN, compNum, direction, nrnstW, traceN, itemN, itemCount)
	string plotN, nrnstW, traceN;
	variable itemN, compNum, direction, itemCount
	
	if (itemCount <= 1)
		direction = 0;
	endif

	variable r = 0 , g = 0 , b = 0 ;
	variable relColor = itemN/(itemCount -1) 
	switch (direction)
		case -1: // reduction
		case 1: // oxidation
		case 0: //uni-directional
			r = 65535 * relColor;
			b = 65535 * (1 - relColor);
		default:
			break;
	endswitch
	
	AppendToGraph   /W=$plotN  $nrnstW[*][8][compNum]/TN=$traceN vs $nrnstW[*][9][compNum]
	ModifyGraph  /W=$plotN rgb($traceN)=(r, g, b), zmrkSize($traceN)={$nrnstW[*][7][compNum],1,2.5,0.25,5}, mode($traceN)=4,marker($traceN)=8, opaque($traceN)=1
	ModifyGraph /W=$plotN zero=1
	Label /W=$plotN left "\\F'Symbol'D\\F]0E\\S0\\M"
	Label /W=$plotN bottom "\\F'Symbol'D\\F]0n"
	SetAxis /W=$plotN left -0.3,0.3;
	SetAxis /W=$plotN bottom -0.5,0.5
end	





