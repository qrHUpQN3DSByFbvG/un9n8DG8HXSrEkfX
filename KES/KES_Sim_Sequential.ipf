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
function simSet_FullSimSeq(setData, setEntries, simM, setM, [hostPrg])  
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT SetProgDataT &hostPrg;

	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT SetProgDataT locPrg;
		defaultSetPrg(locPrg, 0, setEntries.count, "")
		return simSet_FullSimSeqPrg(setData, setEntries, simM, setM, locPrg);
	else // progress dialog is hosted
		defaultSetPrg(hostPrg, 1, setEntries.count, "");
		return simSet_FullSimSeqPrg(setData, setEntries, simM, setM, hostPrg);
	endif
end

//-----------------------------------------------
//
 function simSet_FullSimSeqPrg(setData, entries, simM, setM, hostPrg)  
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &entries;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	STRUCT SetProgDataT &hostPrg;

	string StOutWaveN = setData.dataFldr+setData.commName+"_RES";
	make  /O  /N=(entries.count, 10) $StOutWaveN
	wave  StOWave =  $StOutWaveN;
	StOWave=NaN;

	variable nMT;
	variable s

	SetProgressStart(hostPrg);
	for (s=0; s<entries.count; s+=1) 
		hostPrg.set_curr_sim_in +=1;
		if (simM.doSimWSetup) 	// prepare wave
			simM.theSimWSetupF(setData, entries.sims[s]) 
			// data have been set up, can update progress stats
			if (hostPrg.set_points == 0)
				hostPrg.set_points= dimsize(entries.sims[s].SWave, 0)*entries.count;
				doSetProgressSteps(hostPrg);				
			endif
			
			
			entries.sims[s].text += "=>"+entries.sims[s].name+" ";				
		
			string result = checkSimInput(entries.sims[s].SWave, entries.sims[s].CWave, entries.sims[s].ERxnsW, entries.sims[s].GRxnsW) 
			if (strlen(result))
				print result;
				setData.error = s;
				return -1;
			endif
		
			// perform  simulation
			FUNCREF  SimSetupProto prepF = simM.prepSimSpecificF;
			FUNCREF SimRatesProto ratesF = simM.theSimRatesF;			 
	
			doSetProgressUpdate(hostPrg);
			// sequential sim uses parallel integration
		   Sim_Core_PrlW(entries.sims[s], prepF, ratesF,  StOWave, s, simM.simNThreads, hostPrg) 
		   string flags = "" // retreive form stats structure
			string OutStr; 
			sprintf OutStr, "Simulation time: %0.2f sec for %.3g steps (%0.2fus/step) over %u output points; Sequential, IntThr=%u; %s", ( StOWave[s][2]), StOWave[s][3],( StOWave[s][2])*1e6 /StOWave[s][3], StOWave[s][4], simM.simNThreads, flags
			entries.sims[s].text += outStr;
			hostPrg.set_curr_s += StOWave[s][4]; 
			hostPrg.set_curr_i += StOWave[s][5]
		endif
		hostPrg.set_curr_sim_out +=1;
		doSetProgressUpdate(hostPrg);
		 
		 if (simM.doSimWProcess) // continue to process data
			WAVE entries.sims[s].ProcSWave = simM.theSimWProcessF("_i", entries.sims[s]) 
			entries.sims[s].text += "=> " + nameofwave(entries.sims[s].ProcSWave)
		else
			WAVE entries.sims[s].ProcSWave =entries.sims[s].SWave; 
		endif 
		 
		 if (setM.doSetOutAssign) // continue to save results
			setM.theSetResultAssignF(setData, entries.sims[s]) 
		endif 

		doSetProgressUpdate(hostPrg);
		
	endfor
	
	SetProgressStop(hostPrg);

	// do not do plotting here!
end


//-----------------------------------------------
// wrapper for wave style results reporting
//

function Sim_Core_PrlW(simData, prepSimSpecificF, theSimRatesF, OWave, idx , nMT, hostPrg)
	 STRUCT simDataT &simData;
	FUNCREF SimRatesProto theSimRatesF;
	FUNCREF SimSetupProto prepSimSpecificF;
	wave OWave;
	variable idx;
	variable nMT;
	STRUCT SetProgDataT &hostPrg;

	STRUCT simStatsT stats;
	 variable result = Sim_Core_Prl(simData, prepSimSpecificF, theSimRatesF, stats, nMT, hostPrg)

	OWave[idx][0] = stats.startTime;
	OWave[idx][1] = stats.stopTime;
	OWave[idx][2] = stats.runTime;
	OWave[idx][3] = stats.points;
	OWave[idx][4] = stats.steps;
	OWave[idx][5] = stats.points; // all complete here.... stats.compeltePoints;
//	OWave[idx][6] = ??
	OWave[idx][7] = stats.flags;
	OWave[idx][8] = stats.error;
	OWave[idx][9] = 1; // sim complete
	return result
end

//-----------------------------------------------
// worker function using structure for results reporting
//
 function Sim_Core_Prl(simData, prepSimSpecificF, theSimRatesF, stats, nMT, hostPrg)
	 STRUCT simDataT &simData;
	FUNCREF SimRatesProto theSimRatesF;
	FUNCREF SimSetupProto prepSimSpecificF;
	STRUCT simStatsT &stats;
	variable nMT;
	STRUCT SetProgDataT &hostPrg;
	
	
	variable i, cN = dimsize(simData.CWave, 1); // number of mediators in the wave

	// generic setup method first...
	STRUCT simTmpDataT tmpData;
	string result = prepSimTmp(simData.name, cN, tmpData) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -1;
	endif

	// now call model-specific setup function from template
	prepSimSpecificF(simData.SWave, simData.CWave, simData.ERxnsW, simData.GRxnsW, simData.PWave, tmpData) 

	result = prepSimRxns(simData.name, cN, tmpData,  simData.GRxnsW, simData.ERxnsW, simData.CWave, simData.PWave) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -1;
	endif	
	
	// this is currently not enabled,see MT version
	result = prepSimAliases(simData.name, cN, tmpData, simData.CWave) 
	if (strlen(result))
		print result;
		stats.error = 1;
		return -1;
	endif	

	variable DoDbg
	DoDbg = 1;

	
	// ~~~~~~~~~~~~~~~ simulation prep  ~~~~~~~~~~~~~~~ 
	variable DbgLen; 
	variable NPnts =DimSize(simData.SWave,0);
	variable curr_i = 1; // reference to this or latest output data index
	variable curr_t = simData.SWave[0][0];
	variable curr_E = simData.SWave[0][1]; // this value should be calculated from this and next discrete potential considering progress of simulation time
	variable curr_s = 0;

	// MT version does group concentrations combine here...
	// group prep must be done before sim is advanced!
	
	InitAliasGroup(tmpData.AliasW, tmpData.TWave) 
	
	STRUCT RKStats theStats;
	advanceSim(0, theStats, simData.SWave, tmpData.TWave) // set initial entry 

	// set up multithreading 
	Variable threadGroupID = (nMT > 1) ? ThreadGroupCreate(nMT) : -1
	
	// check execution time
	variable start_time = DateTime

	variable SimStep = simData.SWave[1][0]; // attempt to sim to the next step	
	variable reportPool = 0;
	do
		DbgLen = DoDbg && (curr_s < DbgLen);
		if  (curr_s == DbgLen)
			string dbgcode = "end dbg"
		endif 

		// interpolate current potential
		variable next_S_t = simData.SWave[curr_i][0];
		variable prev_S_t = simData.SWave[curr_i-1][0];
		
		curr_E = simData.SWave[curr_i-1][1] + (simData.SWave[curr_i][1] - simData.SWave[curr_i-1][1]) * ((curr_t - prev_S_t) / (next_S_t - prev_S_t))

		// do the sim...
		RK4RatesPrl(simData.PWave, simData.CWave, tmpData.RSolW, tmpData.RKSolW, tmpData.TWave, tmpData.RKWave, curr_E, simStep, next_S_t - curr_t, curr_s, theStats, threadGroupID) ;

		// sequential method processes group data here
		CombAliasGroup(tmpData.AliasW, tmpData.RKWave)
		
		
		// update temp values with the result of sim
		tmpData.TWave[1,4][] = tmpData.RKWave[p-1][0][q][0] + tmpData.RKWave[p-1][4][q][0];
		tmpData.TWave[7,10][]  = tmpData.RKWave[p-7][4][q][0]; 
		tmpData.TWave[11,14][] += tmpData.RKWave[p-11][4][q][0]; 
		// simulation of individual steps is done and saved in tmpData.TWave

		if  (DbgLen)	
			reportDbgCommon(SimData.LogWave, curr_s, curr_t, curr_i, SimStep, theStats);
			reportDbgComponent(SimData.LogWave, curr_s, tmpData.TWave);
		endif
		
		curr_t += SimStep; 
		if (curr_t >= next_S_t) // time to save data
			advanceSim(curr_i, theStats, simData.SWave, tmpData.TWave);
			curr_i +=1;
		endif 

		reportProgress(curr_i, curr_t, curr_s, theStats, curr_t >= next_S_t ? 1 : 0)

		curr_s +=1;
		reportPool +=1;
		if (reportPool >=1000)
			hostPrg.set_curr_i += reportPool;
			doSetProgressUpdate(hostPrg);
			reportPool = 0;
		endif
		
		
	while (curr_i< NPnts)
	
	Variable dummy= ( threadGroupID >= 0 ) ? ThreadGroupRelease(threadGroupID) : 0;
	
	// clean up and report
	string flags = "";
	if (strlen(flags)) 
		flags = "Flags: "+flags;
	endif
	wave TWave = tmpData.TWave
	killWaves /Z TWave

	stats.startTime = start_time
	stats.runTime = DateTime - start_time
	stats.stopTime = start_time + stats.runTime
	stats.steps = curr_s;
	stats.points =NPnts

//	if (waveexists(RxnsTmp))
//		RxnsTmp=NaN;
//		RxnsTmp[, dimsize(tmpData.RSolW,0)-1][, dimsize(tmpData.RSolW,1)-1][] = tmpData.RSolW[p][q][r]
//	endif

end



//========================================================================
// main entry point - single or parallel
//
function RK4RatesPrl(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E, simStep,  maxStep, StepsCount, theStats, threadGroupID) // adjusts sim step, all rates are in TWave
	wave PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E, &simStep;
	variable maxStep; 
	variable StepsCount;
	STRUCT RKStats &theStats;
	variable threadGroupID;
	wave RxInWave, RxRKWave;
	

	variable RK_steps_count = 0,  RK_rates_count = 0;
	
	variable cN = dimsize(CWave, 1);
	variable i,j; //, j, k;	

	string RK4TmpWN = "tmp_RK4"
	wave RK4TmpW = $RK4TmpWN;
	variable RK_order = 4;
	
	RKPrepCmps(PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave, curr_E); //, i) 

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
			if (threadGroupID >= 0)
				RKCmpRatesMT(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep, threadGroupID) ;
			else
				RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) ;
			endif 
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
	
	RKPostCmps(RK_order, CWave, TWave, RKWave) 
	theStats.steps_count = RK_steps_count;
	theStats.rates_count = RK_rates_count;
	theStats.steps_count_cum += RK_steps_count;
	theStats.rates_count_cum += RK_rates_count;
	theStats.counter +=1;
end


