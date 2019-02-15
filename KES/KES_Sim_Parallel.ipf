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

#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.
#pragma version = 20190123


//-----------------------------------------------
//
function simSet_FullSimPrl(setData, setEntries, simM, setM, [hostPrg])  
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT SetProgDataT &hostPrg;

	variable noHostPrg;
	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT SetProgDataT locPrg;
		defaultSetPrg(locPrg, 0, setEntries.count, "")
		return simSet_FullSimPrlPrg(setData, setEntries, simM, setM, locPrg);
	else // progress dialog is hosted
		defaultSetPrg(hostPrg, 1, setEntries.count, "")
		return simSet_FullSimPrlPrg(setData, setEntries, simM, setM, hostPrg);
	endif
end

//-----------------------------------------------
//
function simSet_FullSimPrlPrg(setData, setEntries, simM, setM, hostPrg)  
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT SetProgDataT &hostPrg;


	variable i, dummy
	
	string StOutWaveN = setData.dataFldr+setData.commName+"_RES";
	make  /O  /N=(setEntries.count, 10) $StOutWaveN
	wave  StOWave =  $StOutWaveN;
	StOWave[][]=NaN;
	StOWave[][4,5]=0;
	
	// prepare set
	variable points_total;
	for (i=0; i<setEntries.count; i+=1) 
		if (simM.doSimWSetup) 	// prepare wave
			simM.theSimWSetupF(setData, setEntries.sims[i]) 
			setEntries.sims[i].text += "=>"+setEntries.sims[i].name+" ";				
		endif
		points_total += dimsize(setEntries.sims[i].SWave, 0)
		
		string result = checkSimInput(setEntries.sims[i].SWave, setEntries.sims[i].CWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW) 
		if (strlen(result))
			print result;
			setData.error = i;
			return -1;
		endif
		
		string tmpName = setEntries.sims[i].name + "_Rx"
		make  /O /N=(0,(dimSize(setEntries.sims[i].CWave,1)+1),2) $tmpName
		wave setEntries.sims[i].RxnsTmp = $tmpName
		setEntries.sims[i].RxnsTmp[][][] = -1;

		string  resStr = appendRxnsTable(setEntries.sims[i].RxnsTmp, setEntries.sims[i].GRxnsW, setEntries.sims[i].CWave, setEntries.sims[i].PWave[2], 0);
		if (strlen(resStr) > 0)
			print resStr;
			setData.error = i;
			return -1;
		endif
	
		resStr = appendRxnsTable(setEntries.sims[i].RxnsTmp, setEntries.sims[i].ERxnsW, setEntries.sims[i].CWave, setEntries.sims[i].PWave[2], 1);
		if (strlen(resStr) > 0)
			print resStr;
			setData.error = i;
			return -1;
		endif
		
		if (dimsize(setEntries.sims[i].RxnsTmp, 0) <=0)
			wave theW =setEntries.sims[i].RxnsTmp  
			killwaves /Z theW
			wave setEntries.sims[i].RxnsTmp = $""
		endif
		variable cN = dimsize(setEntries.sims[i].CWave, 1);
		if (DoDbg)
			string dbgWN = setEntries.sims[i].name +"_dbg" 
			if (waveexists($dbgWN))
	 			redimension /N=(DbgLen, DbgCom + DbgM*cN) $dbgWN
			else 
				make /O /N=(DbgLen, DbgCom) $dbgWN
			endif
			wave setEntries.sims[i].LogWave = $dbgWN;
		else
			wave setEntries.sims[i].LogWave = NULL;
		endif
	endfor	

	Variable setGroupID= ThreadGroupCreate(setM.setNThreads > 0 ? setM.setNThreads : 1)
	hostPrg.set_points = points_total;
	hostPrg.thGroupId = setGroupID;
	SetProgressStart(hostPrg); 

	// perform sim 	
	variable killFlag = 0;
	Variable threadGroupStatus;
	
	if (simM.doSimWSetup)
		for (i=0; i<setEntries.count; i+=1) 
			if (setM.setNThreads > 0)
				Variable threadIndex;
				do
					threadIndex = ThreadGroupWait(setGroupID,-2) - 1
					if (threadIndex < 0)// Let threads run a while
						threadGroupStatus=waitForThreadGroup(setGroupID, StOWave, hostPrg, 100)
						killFlag = doSetProgressUpdate(hostPrg); 
					endif
				while (!killFlag &&  threadIndex < 0)
				if (!killFlag && threadIndex >= 0) // 
					FUNCREF  SimSetupProto prepF = simM.prepSimSpecificF;
					FUNCREF SimRatesProto ratesF = simM.theSimRatesF;
					// parallel set uses sequential integration
					ThreadStart setGroupID, threadIndex,  Sim_Core_Seq(	setEntries.sims[i].SWave, 	setEntries.sims[i].CWave, setEntries.sims[i].PWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW, setEntries.sims[i].RxnsTmp, prepF, ratesF, StOWave, i, setEntries.sims[i].LogWave) 
					hostPrg.set_curr_sim_in +=1;
				else
					break
				endif 
			else
				killFlag = doSetProgressUpdate(hostPrg); 
				// this needs to be modified to conform to the single sim verions before two methods can be merged
//				Sim_Core_MT(	setEntries.sims[i].SWave, 	setEntries.sims[i].CWave, setEntries.sims[i].PWave, setEntries.sims[i].ERxnsW, setEntries.sims[i].GRxnsW, setEntries.sims[i].RxnsTmp, prepF, ratesF, StOWave, i, setEntries.sims[i].LogWave) 
				hostPrg.set_curr_sim_in +=1;			
			endif
		endfor
		if (setM.setNThreads > 1 &&  !killFlag) // wait for completion 
			do
				threadGroupStatus=waitForThreadGroup(setGroupID, StOWave, hostPrg, 100)
				killFlag = doSetProgressUpdate(hostPrg); 
			while(!killFlag && threadGroupStatus != 0)
		endif
	endif;
	SetProgressStop(hostPrg)
	
	// process results
	variable cpuTime = 0;
	for (i=0; i<setEntries.count; i+=1) 
		// retreive sim output
		string flags = ""
		string OutStr; 
		sprintf OutStr, "Simulation time: %0.2f sec for %.3g steps (%0.2fus/step) over %u output points; Parallel, IntThr=%u; %s", ( StOWave[i][2]), StOWave[i][3],( StOWave[i][2])*1e6 /StOWave[i][3], StOWave[i][4], simM.simNThreads, flags
		cpuTime += StOWave[i][2];
		setEntries.sims[i].text += outStr;
	
		 if (simM.doSimWProcess) // continue to process data
			WAVE setEntries.sims[i].ProcSWave = simM.theSimWProcessF("_i", setEntries.sims[i]) 
			setEntries.sims[i].text += "=> " + nameofwave(setEntries.sims[i].ProcSWave)
		else
			WAVE setEntries.sims[i].ProcSWave =setEntries.sims[i].SWave; 
		endif 
		 
		 if (setM.doSetOutAssign) // continue to save results
			setM.theSetResultAssignF(setData, setEntries.sims[i]) 
		endif 
		setEntries.sims[i].text = setM.offset + setEntries.sims[i].text
	endfor	
	
	string summaryText;
	if (setM.setNThreads > 1)
		sprintf summaryText, "Set real time %0.2f sec for %0.2f sec CPU time; x%0.1f over %g threads", (hostPrg.set_stop_time - hostPrg.set_start_time ), cpuTime, cpuTime/(hostPrg.set_stop_time - hostPrg.set_start_time ), setM.setNThreads
	else
		sprintf summaryText, "Set real time %0.2f sec, single thread;"
	endif; 
	if (hostPrg.aborted > 0)
		summaryText += " =Aborted= ";
	endif 
	setData.text += "\r"+setM.offset+summaryText;
	if (hostPrg.thGroupId > 0)
		dummy= ThreadGroupRelease(hostPrg.thGroupId)
	endif
	
	// clean up output waves!
	killwaves /Z StOWave
end

//-----------------------------------------------
//
function waitForThreadGroup(groupID, StOWave, hostPrg, wait)	
	variable groupID
	STRUCT SetProgDataT &hostPrg;
	wave StOWave;
	variable wait
	
	Variable threadGroupStatus = ThreadGroupWait(groupID,wait)
	variable count = dimsize(StOWave, 0);
	variable i;
	
	// check on total returns and current count and update
	variable completedSims = 0;
	variable totalPoints = 0 ;
	variable completedSteps = 0 ;
	variable completedPoints = 0;
	for (i=0; i < count; i+=1)
		completedSims += (StOWave[i][9] > 0 ) ? 1 : 0;
		totalPoints += StOWave[i][3]; 
		completedSteps += StOWave[i][4]; 
		completedPoints += StOWave[i][5]; 
	endfor
	hostPrg.set_curr_sim_out = completedSims
	hostPrg.set_curr_sim_in = hostPrg.set_sims - completedSims;
	hostPrg.set_curr_s = completedSteps
	hostPrg.set_curr_i = completedPoints
	return threadGroupStatus;
end

//----------------------------------------------------------
// thread safe verison with I/O
// called by simSet_FullSimPrlPrg
//
threadsafe function Sim_Core_Seq(SWave, CWave, PWave, ERxnsW, GRxnsW, RxnsTmp, prepSimSpecificF, theSimRatesF, OWave, idx, LogWave ) 
	wave SWave, CWave, PWave;
	wave /WAVE GRxnsW, ERxnsW;
	wave RxnsTmp;
	FUNCREF SimRatesProto theSimRatesF;
	FUNCREF SimSetupProto prepSimSpecificF;
	wave OWave
	variable idx 
	wave LogWave
	

	string commName = nameofwave(SWave);
	
	OWave[idx][9] = 0 // sim started
		
	variable i, cN = dimsize(CWave, 1); // number of mediators in the wave

	// generic setup method first...
	STRUCT simTmpDataT tmpData;
	string result = prepSimTmp(commName, cN, tmpData) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -1;
	endif
	
	// now call model-specific setup function from template
	prepSimSpecificF(SWave, CWave, ERxnsW, GRxnsW, PWave, tmpData) 

 	result = prepSimRxns(commName, cN, tmpData,  GRxnsW, ERxnsW,CWave, PWave) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -1;
	endif	

	result = prepSimAliases(commName, cN, tmpData, CWave) 
	if (strlen(result))
		print result;
		OWave[idx][8] = 1;
		return -1;
	endif	
	
	variable DoDbg = 0;
	if (waveexists(LogWave))
	 	redimension /N=(DbgLen, DbgCom + DbgM*cN) LogWave
 		DoDbg = 1;
	endif
	LogWave = 0;
	
		
	// ~~~~~~~~~~~~~~~ simulation prep  ~~~~~~~~~~~~~~~ 
	variable NPnts =DimSize(SWave,0);
	variable curr_i = 1; // reference to this or latest output data index
	variable curr_t = SWave[0][0];
	variable curr_E = SWave[0][1]; // this value should be calculated from this and next discrete potential considering progress of simulation time
	variable curr_s = 0;

	
	// group prep must be done before sim is advanced!
	InitAliasGroup(tmpData.AliasW, tmpData.TWave) 
	
	STRUCT RKStats theStats;
	advanceSim(0, theStats, SWave, tmpData.TWave) // set initial entry 

	// check execution time
	variable startTime = DateTime;
	OWave[idx][0] = startTime
	OWave[idx][3] = NPNts

	variable SimStep = SWave[1][0]; // attempt to sim to the next step
	do
		DoDbg = DoDbg && (curr_s < DbgLen);
		if  (curr_s == DbgLen)
			string dbgcode = "end dbg"
		endif 

		// interpolate current potential
		variable next_S_t = SWave[curr_i][0];
		variable prev_S_t = SWave[curr_i-1][0];

		curr_E = SWave[curr_i-1][1] + (SWave[curr_i][1] - SWave[curr_i-1][1]) * ((curr_t - prev_S_t) / (next_S_t - prev_S_t))

		// do the sim...
		RK4RatesSeq(PWave, CWave, tmpData.RSolW, tmpData.RKSolW, tmpData.TWave, tmpData.RKWave, curr_E, simStep, next_S_t - curr_t, curr_s, theStats) ;

		// check for aliases here; Concentration of all aliases should be the same, rates should be the same
		tmpData.RKWave[][3][][0] = 0; // flag
		
		// integrate group data here
		CombAliasGroup(tmpData.AliasW, tmpData.RKWave) 

		// update temp values with the result of sim
		tmpData.TWave[1,4][] = tmpData.RKWave[p-1][0][q][0] + tmpData.RKWave[p-1][4][q][0];
		tmpData.TWave[7,10][]  = tmpData.RKWave[p-7][4][q][0]; // calculated rate of change
		tmpData.TWave[11,14][] += tmpData.RKWave[p-11][4][q][0]; 
		// simulation of individual steps is done and saved in tmpData.TWave

		if  (DoDbg)	
			reportDbgCommon(LogWave, curr_s, curr_t, curr_i, SimStep, theStats);
			reportDbgComponent(LogWave, curr_s, tmpData.TWave);
		endif
		
		curr_t += SimStep; 
		if (curr_t >= next_S_t) // time to save data
			advanceSim(curr_i, theStats, SWave, tmpData.TWave);
			curr_i +=1;
		endif 
		
		reportProgress(curr_i, curr_t, curr_s, theStats, curr_t >= next_S_t ? 1 : 0)
		
		curr_s +=1;
		OWave[idx][4] = curr_s; 
		OWave[idx][5] = curr_i; 
	while (curr_i< NPnts)

	
	// clean up and report
	string flags = "";
	if (strlen(flags)) 
		flags = "Flags: "+flags;
	endif
	wave TWave = tmpData.TWave
	killWaves /Z TWave

	variable stopTime = DateTime; 
	OWave[idx][2] = stopTime - startTime
	OWave[idx][1] = stopTime;
	OWave[idx][7] = 0 // not implemented yet stats.flags;
	OWave[idx][8] = 0 // no error stats.error;
	OWave[idx][9] = 1 // sim complete
	
	if (waveexists(RxnsTmp))
		RxnsTmp=NaN;
		RxnsTmp[, dimsize(tmpData.RSolW,0)-1][, dimsize(tmpData.RSolW,1)-1][] = tmpData.RSolW[p][q][r]
	endif
end


//========================================================================
// main entry point - single thread only
// this function must be threadsafe and cannot be replaced by RK4RatesPrl
//
threadsafe  function RK4RatesSeq(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, curr_E, simStep,  maxStep, StepsCount, theStats) 
	// adjusts sim step, all rates are in TWave
	wave PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E, &simStep;
	variable maxStep; 
	variable StepsCount;
	STRUCT RKStats &theStats;
	wave RxInWave, RxRKWave
	
	variable RK_steps_count = 0,  RK_rates_count = 0;
	
	variable cN = dimsize(CWave, 1);
	variable i,j; //, j, k;	

	string RK4TmpWN = "tmp_RK4"
	wave RK4TmpW = $RK4TmpWN;
	variable RK_order = 4;
	
	RKPrepCmps(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E);

	variable sol_height = PWave[10]; 
	variable RK4_time_step = PWave[20];
	variable RKStep = 0;
	variable Euler_done = 0;

	// attempt to boost the time
	simStep *= RK4_time_step;
	if (maxStep > 0 && simStep > maxStep)
		simStep = maxStep;
	endif 
	
	
	for (RKStep=0 ; RKStep<4; RKStep+=1)
		if (RKStep > 0 || !Euler_done)
			RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) ;
			Euler_done = 1;
			RK_rates_count +=1;
		endif;

		if (RKStep == RK_Order -1)
				if (finishRK(RK_Order, RKWave, PWave, TWave, simStep, theStats))
					continue;
				endif	// else do it over....
				RKStep = 0; // values of C0_i do not change with iteration! simply restart with smaller step
		endif
		RK_steps_count += stepRK(RK_Order, RKStep, RKWave, PWave, TWave, simStep,  theStats);
	endfor 

	RKWave[][1][][0] =  RKWave[p][0][r][0] + RKWave[p][RK_order][r][0] 
	RKWave[][2][][0] =  RKWave[p][RK_order][r][0] / RKWave[p][0][r][0]; 
	// p is the form of this component (Ox, Rd, sol, el);
	// q is RK order
	// r is individual component
	
	// RKWave[][0][i][0] contains C0
	// RKWave[][1][i][0] contains C(+1) for this simStep
	// RKWave[][2][i][0] contains dC/C for this simStep
	// RKWave[][RKOrder][i][0] contains dC for this simStep
	
	RKPostCmps(RK_order, CWave,  TWave, RKWave) 
	theStats.steps_count = RK_steps_count;
	theStats.rates_count = RK_rates_count;
	theStats.steps_count_cum += RK_steps_count;
	theStats.rates_count_cum += RK_rates_count;
	theStats.counter +=1;
end


