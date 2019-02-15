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

#pragma IgorVersion=8.0

strconstant cKESVer = "1.6.7a"



variable sim_points
variable sim_curr_i;
variable sim_curr_step;
variable sim_i_step; // step# in this i
variable sim_curr_t;
variable sim_last_update;
variable sim_start;



constant maxSims=64

constant TWaveLen = 50  
constant S_C_Offs = 10 // offset of 1st component in the SimWave
constant S_C_Num = 8 // number of parameters per component

constant  DbgCom =9
constant  DbgM = 24 
constant  DbgLen = 150000 
constant  DoDbg = 1; // on/off flag for debug logging
constant  DoDbgUpdate = 0;



//-------------------------------------------------------------------
//
//
structure simStatsT
	variable startTime;
	variable stopTime;
	variable runTime;
	variable steps;
	variable points;
	variable flags;
	variable error;
endstructure


//-------------------------------------------------------------------
// This datafield is for use in a single simulation
//
structure simDataT
	string name; // object name of this sim
	wave PWave
	wave CWave
	wave MWave
	wave /WAVE ERxnsW
	wave /WAVE GRxnsW;
	wave RxnsTmp
	wave LogWave;

	variable direction; 	// 0 - no dir
								// >0 positive, forward
								// <0 negative, reverse
	variable index; // position of this sim in the set
	variable group; // this may be the same as position in the set or may inidicate index of plot etc...
	// output
	string text;
	variable result; 

	// output waves 					
	wave SWave;
	wave ProcSWave;
endstructure

//-------------------------------------------------------------------
//
structure simSetDataArrT
	variable count;
	STRUCT simDataT sims[maxSims];
endstructure


//-------------------------------------------------------------------
// This datafield is for use in a single sub-set
//
structure setDataT
	string name; // object name of this sim
	string folder; // location of the sub-set
	wave JParWave
	wave MWave
	wave PWave
	wave CWave
	wave /WAVE ERxnsW
	wave /WAVE GRxnsW;
	
	wave /T JListWave

	variable index; // position of this sim in the set

	// output
	string text;
	variable result; 
endstructure

//-------------------------------------------------------------------
//
structure setSetDataArrT
	variable count;
	STRUCT setDataT sets[maxSims];
endstructure



//-------------------------------------------------------------------
// This datafield is for internal use by RK4 integrator
//
structure simTmpDataT
	// service waves
	wave TWave;
	wave RKWave;
	wave RKTmpWave; 
	wave RSolW;
	wave RKSolW;
	wave AliasW;
endstructure


//-------------------------------------------------------------------
//
structure RKStats
	variable lim_code_inner;
	variable lim_code_outer;
	variable lim_rel_outer;
	variable lim_rel_inner;
	variable steps_count;
	variable rates_count;
	variable steps_count_cum;
	variable rates_count_cum;
	variable counter;
endstructure



//-------------------------------------------------------------------
//
structure simSetDataT
	string commName;
	string text;
	variable error;
	string rootFldr; // where this set was executed
	string dataFldr; // where subset data are stored
	variable biDir;
	
	wave setValueClb
	// ancestor waves, sim entries may modify them
	wave MWave
	wave PWave
	wave CWave
	wave JParWave
	wave /WAVE ERxnsW
	wave /WAVE GRxnsW;
endstructure


//-------------------------------------------------------------------
//
structure simMethodsT
	variable simNThreads;

	FUNCREF SimSetupProto prepSimSpecificF; 
	FUNCREF SimRatesProto theSimRatesF; 

	FUNCREF simWSetupProto theSimWSetupF; // jobListW[7];
	variable doSimWSetup;
	
	FUNCREF simWProcessProto theSimWProcessF; // jobListW[8];
	variable doSimWProcess;
	
		
	FUNCREF simPlotBuildProto theSimPlotBuildF; // jobListW[17]
	variable doSimPlotBuild;
endstructure

//-------------------------------------------------------------------
//

structure setMethodsT
	string text;
	string modeName;
	string offset;
	
	variable setNThreads;
	
	FUNCREF setInputSetupProto theSetInSetupF;  // jobListW[11];
	variable doSetInSetup;
	
	FUNCREF setInputAssignProto theSetInAssignF;  // jobListW[12];
	variable doSetInAssign;
	
	FUNCREF setResultSetupProto theSetResultSetupF; // jobListW[13];
	variable doSetOutSetup;
	
	FUNCREF setResultAssignProto theSetResultAssignF; // jobListW[14];
	variable doSetOutAssign;
	
	FUNCREF setResultCleanupProto theSetResultCleanupF; // jobListW[15];
	variable doSetOutCleanup;

	FUNCREF setPlotSetupProto theSetPlotSetupF; //  jobListW[16]
	variable doSetPlotBuild;
	
	FUNCREF setPlotAppendProto theSetPlotAppendF; 
	variable doSetPlotAppend;
endstructure

//------------------------------------------------------------------------------------
//
//

structure groupMethodsT
	string text;

	string theGroupInSetupFN
	FUNCREF GroupInputSetupProto theGroupInSetupF;  
	variable doGroupInSetup;
	string theGroupInAssignFN;
	FUNCREF GroupInputAssignProto theGroupInAssignF;  
	variable doGroupInAssign;
	
	
	string theGroupResultSetupFN
	FUNCREF groupResultSetupProto theGroupResultSetupF; ;
	variable doGroupOutSetup;
	string theGroupResultAssignFN;
	FUNCREF GroupResultAssignProto theGroupResultAssignF; 
	variable doGroupOutAssign;
	string theGroupResultCleanupFN;
	FUNCREF GroupResultCleanupProto theGroupResultCleanupF; 
	variable doGroupOutCleanup;

	string theSetPlotSetupFN
	FUNCREF setPlotSetupProto theGroupPlotSetupF; 
	variable doGroupPlotBuild;
	string theSetPlotAppendFN;
	FUNCREF GroupPlotAppendProto theGroupPlotAppendF; 
	variable doGroupPlotAppend;
endstructure

//-----------------------------------------------
//

structure SetProgDataT
	string wName;
	variable x, y;
	variable  set_start_time;
	variable  set_stop_time;
	variable  set_sims;
	variable  set_points;
	variable  set_curr_sim_in, set_curr_sim_out;
	variable  set_curr_i, set_curr_s;
	variable  set_last_update
	variable thGroupID;
	variable hosted;
	variable aborted;
endstructure;


//-----------------------------------------------
//

structure KiloProgDataT
	STRUCT SetProgDataT set;
	variable x, y;
	variable  set_sets;
	variable  set_curr_set_out;
	variable 	set_last_update;
	variable 	set_start_time
	variable  set_stop_time
	variable hosted;
endstructure;

//-----------------------------------------------
//

structure MegaProgDataT
	STRUCT KiloProgDataT kilo;
	variable x, y;
	variable  kilo_sets;
	variable  kilo_curr_set_out;
	variable 	kilo_last_update;
	variable 	kilo_start_time
	variable  kilo_stop_time
	variable hosted;
endstructure;


//*******************************************************************
//

structure SimProgDataT
	string wName;
	variable x, y;
	variable  sim_start_time;
	variable  sim_stop_time;
	variable  sim_points;
	variable  sim_curr_i, sim_curr_s;
	variable  set_last_update
	variable thGroupID;
	variable hosted;
	variable aborted;
endstructure;



//----------------------------------------------------------
//
function /S checkSimInput(SWave, CWave, ERxnsW, GRxnsW) 
	wave SWave, CWave
	wave /WAVE ERxnsW, GRxnsW

	if (!WaveExists(CWave))
		return "Components wave does not exist. Exiting..." 
	endif 

	variable cN = dimSize(CWave, 1);
	
	if (!WaveExists(SWave))
		return "Simulation wave does not exist. Exiting..." 
	endif 

	redimension /N=(-1, S_C_Offs+cN*S_C_Num ) SWave
	SWave[][2,] = NaN;

	if (!WaveExists(ERxnsW))
		// return "Rates wave does not exist. Exiting..." 
	endif 

	if (!WaveExists(GRxnsW))
		// return "Rates wave does not exist. Exiting..." 
	endif 

	return "";
end


//----------------------------------------------------------
//
threadsafe  function /S prepSimTmp(commName, cN,  simTmpData) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	
	string tempWN = commName +"_tmp" //nameofwave(CWave)
	if (waveexists($tempWN))	
		redimension /D /N=(TWaveLen, cN) $tempWN
	else 
		make /D /N=(TWaveLen, cN) $tempWN
	endif
	wave simTmpData.TWave = $tempWN


	string RK4WN = commName+"_RK4" //nameofwave(CWave)
	if (waveexists($RK4WN))	
		redimension /D /N=(4, 6, cN, 2) $RK4WN
	else 
		make /D /N=(4, 6, cN, 2) $RK4WN
	endif
	wave simTmpData.RKWave = $RK4WN

	string RK4TmpWN = "tmp_RK4"
	if (waveexists($RK4TmpWN))	
		redimension /D /N=(4, 12) $RK4TmpWN
	else 
		make /D /N=(4, 12) $RK4TmpWN
	endif
	wave simTmpData.RKTmpWave = $RK4TmpWN
	simTmpData.RKTmpWave = 0;	
			
	variable nRxns = 0;
	variable RKOrder = 4;

	string RKSolWN = commName+"_RKs" 
	if (waveexists($RKSolWN))	
		redimension /D /N=(nRxns, RKOrder) $RKSolWN
	else 
		make /D /N=(nRxns, RKOrder) $RKSolWN
	endif
	wave simTmpData.RKSolW = $RKSolWN


	string RxnsWN = commName+"_Rxn" 
	if (waveexists($RxnsWN))	
		redimension /D /N=(nRxns, cN+1, 2) $RxnsWN
	else 
		make /D /N=(nRxns, , cN+1, 2) $RxnsWN
	endif
	wave simTmpData.RKSolW = $RxnsWN


	string AliasWN = commName+"_Al" 
	if (waveexists($AliasWN))	
		redimension /D /N=(cN, 1, 2) $AliasWN
	else 
		make /D /N=(cN, 1, 2) $AliasWN
	endif
	wave simTmpData.AliasW = $AliasWN
	
	return ""
end


//----------------------------------------------------------
//
threadsafe function /S prepSimRxns(commName, cN,  simTmpData, GRxnsW, ERxnsW, CWave, PWave) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	wave /WAVE GRxnsW
	wave /WAVE  ERxnsW;
	wave CWave;
	wave PWave;
	
	variable nSolRxns = 0;
	variable RKOrder = 4;
	
	variable i, j; 
	
	if (waveexists(simTmpData.RSolW))	
		simTmpData.RSolW[][][] = 0;
		redimension /D /N=(nSolRxns, cN+1, 2) simTmpData.RSolW
	else 
		string GRxnsWN = commName+"XRxn" 
		if (waveexists($GRxnsWN))	
			redimension /D /N=(nSolRxns , cN+1, 2) $GRxnsWN
		else
			make /D /N=(nSolRxns , cN+1, 2) $GRxnsWN
		endif
		wave simTmpData.RSolW = $GRxnsWN
	endif


	string  resStr = appendRxnsTable(simTmpData.RSolW, GRxnsW, CWave, PWave[2], 0);
	if (strlen(resStr) > 0)
		return resStr;
	endif
	
	resStr = appendRxnsTable(simTmpData.RSolW, ERxnsW, CWave, PWave[2], 1);
	if (strlen(resStr) > 0)
		return resStr;
	endif
	
	
	nSolRxns = dimsize(simTmpData.RSolW, 0)
	string RKSolWN = commName+"_RKs" 
	if (waveexists($RKSolWN))	
		redimension /D /N=(nSolRxns, RKOrder) $RKSolWN 
	else 
		make /D /N=(nSolRxns, RKOrder) $RKSolWN 
	endif
	wave simTmpData.RKSolW = $RKSolWN
	
	return ""
end


//----------------------------------------------------------
//
threadsafe  function /S appendRxnsTable(RxnsTblW, RxnsListW, CWave, rateMode, KMode)
	wave RxnsTblW;
	wave /WAVE RxnsListW;
	wave CWave
	variable rateMode; 
	variable KMode; // 0 - use K from wave; 1 use E, n from CWave
	
	if (!waveexists(RxnsListW))
		return "";
	endif
	
	variable nRxns = dimsize(RxnsTblW, 0);
	variable cN = dimsize(RxnsTblW, 1) -1;
	variable i, j;
	
		wave inERxnsW =RxnsListW[0];
		for (i=1; i < dimsize (RxnsListW, 0); i+=1 )
			if ((i-1) >= dimsize (inERxnsW, 0))
				break;
			endif		
			if ((inERxnsW[i-1][0] > 0 || KMode !=0) && inERxnsW[i-1][1] > 0)
				wave theRxnW = RxnsListW[i];
				if (waveexists(theRxnW))
					variable rxnRows = dimsize (theRxnW, 0);
					redimension /D /N=(nRxns+1, -1, -1) RxnsTblW
					RxnsTblW[nRxns][][] = 0;
					for (j = 0; j< rxnRows; j+=1)
						variable cReact = theRxnW[j][0] ;// reactants
						if ( cReact >= 0 &&  cReact < cN )
							variable nOxR = theRxnW[j][1] 
							if (nOxR > 0) // participating and valid
								RxnsTblW[nRxns][cReact+1][0] += nOxR;															
							endif 
							variable nRdR = theRxnW[j][2] 
							if (nRdR > 0) // participating and valid
								RxnsTblW[nRxns][cReact+1][0] -= nRdR;															
							endif 
						endif 
						
						// products
						variable cProd = theRxnW[j][3] ;
						if ( cProd >= 0 &&  cProd < cN )
							variable nOxP = theRxnW[j][4] 
							if (nOxP > 0) // participating and valid
								RxnsTblW[nRxns][cProd+1][1] += nOxP;															
							endif 
							variable nRdP = theRxnW[j][5] 
							if (nRdP > 0) // participating and valid
								RxnsTblW[nRxns][cProd+1][1] -= nRdP;															
							endif 
						endif 
												
					endfor 

					variable isValid = 0
					variable eCh_nE = 0;
					for (j=1; j<cN+1; j+=1)
						if (RxnsTblW[nRxns][j][0] != 0 || RxnsTblW[nRxns][j][1] != 0)
							if (KMode != 0)
								if (CWave[3][j-1] >0 )
									variable nCmp_i = 0.5*(RxnsTblW[nRxns][j][0]  -  RxnsTblW[nRxns][j][1])
									eCh_nE += nCmp_i * CWave[3][j-1] * CWave[2][j-1];
									isValid = 1;
								else
									string errorStr;
									sprintf errorstr, "Component  #%d is specified in e-chem but it's n<=0.", j-1	
									return errorStr
								endif
							else
								isValid = 1;
							endif
						endif 
					endfor
					
					if (isValid)
						if (KMode != 0)
							variable F_RT = 38.94;
							variable K_eChem = exp( eCh_nE* F_RT) ;
							inERxnsW[i-1][0] = K_eChem;
						endif 
						calcCorrRates(RxnsTblW, nRxns,rateMode, inERxnsW[i-1][1], inERxnsW[i-1][0])
						nRxns += 1;	
					else
						redimension /D /N=(nRxns, -1, -1) RxnsTblW // kill last row
					endif 
				endif ; 
			endif ; 
		endfor
	return ""
end


//----------------------------------------------------------
//
threadsafe function calcCorrRates(kWave, RxnRow, rateMode, kFwd, Keq)
	wave kWave
	variable RxnRow, rateMode, kFwd, Keq
	
	if (rateMode == 0)
		kWave[RxnRow][0][0] = kFwd * sqrt(Keq);  
		kWave[RxnRow][0][1] = kFwd /  sqrt(Keq); 
	elseif (rateMode > 0)
		kWave[RxnRow][0][0] = kFwd;
		kWave[RxnRow][0][1] = kFwd / Keq; 
	else 
		kWave[RxnRow][0][0] = kFwd * Keq; 
		kWave[RxnRow][0][1] = kFwd;
	endif
end


//----------------------------------------------------------
//
// prepare alias wave from alias settings in the CWave
//
threadsafe  function /S prepSimAliases(commName, cN,  simTmpData, CWave) 
	string commName
	variable cN
	STRUCT simTmpDataT &simTmpData;
	wave CWave;
	
	string result = "";
	variable i,j,k; 
	redimension /N=( -1, cN+1, -1) simTmpData.AliasW
	simTmpData.AliasW[][1,][] = NaN
	
	// 1st pass - copy aliases as-is
	variable thisCmpRow;
	variable thisCmpState; 

	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			simTmpData.AliasW[thisCmpRow][0][thisCmpState]  = NaN; // default to no alias
			variable AliasVal = CWave[13+thisCmpState][thisCmpRow] ;
			if ((numType(AliasVal) == 0) )
				variable AliasCmp = abs(AliasVal) ; // This must be 1- based or informartion on cmp 0 is lost!
				if ( AliasCmp > cN || AliasCmp <=0 ) // this is an invalid condition!
					result += "Alias for ";
					if (thisCmpState > 0)
						result += "Rd";
					else
						result += "Ox";
					endif
					result += " C"+num2istr(thisCmpRow)+" is out of range ("+num2str( AliasVal - 1)+");"; 
				else
					simTmpData.AliasW[thisCmpRow][0][thisCmpState] =  AliasVal;
				endif
			endif
		endfor
	endfor
	
	// 2nd pass - sort aliases 
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			if (!numtype(simTmpData.AliasW[thisCmpRow][0][thisCmpState]) ) // this is an alias, reduced or oxidized
				variable thisAliasRow = abs(simTmpData.AliasW[thisCmpRow][0][thisCmpState])-1; // aliases in CWave are 1-based
				variable thisAliasState = simTmpData.AliasW[thisCmpRow][0][thisCmpState] > 0 ? 0 : 1; 
				variable toRow, toState, aliasRow, aliasState; 
				
				if (thisAliasRow <= thisCmpRow) // this is an alias to preceeeding component  - move it there
					toRow= thisAliasRow;
					toState =thisAliasState;
					aliasRow =  thisCmpRow;
					aliasState = thisCmpState;
				else
					toRow= thisCmpRow;
					toState =thisCmpState;
					aliasRow =  thisAliasRow;
					aliasState = thisAliasState;
				
				endif
				for (j=1; j<dimsize(simTmpData.AliasW, 1); j+=1)
					if (numtype ( simTmpData.AliasW[toRow][j][toState])) // this position is empty
						simTmpData.AliasW[toRow][j][toState] = (aliasRow +1)* ((aliasState > 0) ? -1 : 1) ; // positive or negative
						simTmpData.AliasW[thisCmpRow][0][thisCmpState] = NaN;
						break;
					endif
				endfor
			endif 
		endfor 	
	endfor
	
	// 3rd pass - combine aliases 
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			variable nAliases = dimsize(simTmpData.AliasW, 1);
			variable firstEmpty = 1;
			for (firstEmpty=1; firstEmpty<nAliases; firstEmpty+=1) // find first empty slot in the base compound list 
				if (numtype ( simTmpData.AliasW[thisCmpRow][firstEmpty][thisCmpState])) // this position is empty
					break;
				endif
			endfor
			// firstEmpty may be beyond dimensions of current array!
			for (j=1; j<firstEmpty; j+=1)
				// check if there are other aliases at that position and copy all over 
				variable testCmpRow = abs(simTmpData.AliasW[thisCmpRow][j][thisCmpState])-1; 
				variable testCmpState = simTmpData.AliasW[thisCmpRow][j][thisCmpState] > 0? 0 : 1;
					
				for (k=1; k<nAliases; k+=1)
					if (!numtype ( simTmpData.AliasW[testCmpRow][k][testCmpState])) // this position is not empty
						if (testCmpRow == thisCmpRow && testCmpState == thisCmpState)
						else
							// copy it to first empty and reset that position
							if (firstEmpty >=  nAliases )
								nAliases +=1;
								redimension /N=(-1,nAliases, -1) simTmpData.AliasW
								simTmpData.AliasW[][nAliases -1][] = NaN;
							endif
							simTmpData.AliasW[thisCmpRow][firstEmpty][thisCmpState] = simTmpData.AliasW[testCmpRow][k][testCmpState];
							simTmpData.AliasW[testCmpRow][k][testCmpState] = NaN;	
							firstEmpty +=1;
						endif
					endif
				endfor
			endfor
		endfor
	endfor	
	
	// 4th pass - check for merger points
	// A - create merger table 
	make /N=(cN, cN, 2) /FREE MergerW;
	
	MergerW[][][] = NaN;
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			for (i=1; i<cN; i+=1)
				if (!numtype(simTmpData.AliasW[thisCmpRow][i][thisCmpState])) // there is a reference to anther component
					testCmpRow = abs(simTmpData.AliasW[thisCmpRow][i][thisCmpState])-1; 
					testCmpState = simTmpData.AliasW[thisCmpRow][i][thisCmpState] > 0? 0 : 1;
					for (j=0; j< cN; j+=1)
						if (numtype(MergerW[testCmpRow][j][testCmpState])) // no value here 
							MergerW[testCmpRow][j][testCmpState] = (thisCmpRow+1)* (thisCmpState>0 ? -1 :1);
							break;
						endif
					endfor
				endif
			endfor
		endfor
	endfor
	
	
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
			if (numtype(MergerW[thisCmpRow][1][thisCmpState])) // there are less than two entries!
				continue;
			endif
			// merger needs to be done to that address 
			variable baseCmpRow =  abs(MergerW[thisCmpRow][0][thisCmpState])-1; 
			variable baseCmpState =  (MergerW[thisCmpRow][0][thisCmpState] < 0) ? 1 : 0;
			if (thisCmpState >0)
				string thisSign = "-";
			else
				thisSign = "+";
			endif
			
			if (baseCmpState >0)
				string baseSign = "-";
			else
				baseSign = "+";
			endif

			for (i=1; i<cN;  i+=1)
				if (numtype(MergerW[thisCmpRow][i][thisCmpState])) // no more groups to copy
					break;
				endif 
				
				variable siblingCmpRow =  abs(MergerW[thisCmpRow][i][thisCmpState])-1; 
				variable siblingCmpState =  (MergerW[thisCmpRow][i][thisCmpState] < 0) ? 1 : 0;
				
				if (siblingCmpState >0)
					string siblingSign = "-";
				else
					siblingSign = "+";
				endif
				
				// copy aliases of that compound into this base compound
				// find empty slot in the base compund list
				nAliases = dimsize(simTmpData.AliasW, 1);
				firstEmpty = 1;
				for (firstEmpty=1; firstEmpty<nAliases; firstEmpty+=1) // find first empty slot in the base compound list 
					if (numtype ( simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState])) // this position is empty
						break;
					endif
				endfor

				// firstEmpty may be beyond current array!
				// first copy the base of sibling
				if (firstEmpty >=  nAliases )
					nAliases +=1;
					redimension /N=(-1,nAliases, -1) simTmpData.AliasW
					simTmpData.AliasW[][nAliases -1][] = NaN;
				endif
				simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState] =  (siblingCmpRow+1)*(siblingCmpState > 0? -1:1);
				firstEmpty+=1;
				// then copy alias chain of sibling
				for (k=1; k<nAliases; k+=1)
					if (!numtype ( simTmpData.AliasW[siblingCmpRow][k][siblingCmpState])) // this position is not empty
						variable siblingEntryRow = abs(simTmpData.AliasW[siblingCmpRow][k][siblingCmpState]) -1
						variable siblingEntryState = simTmpData.AliasW[siblingCmpRow][k][siblingCmpState] > 0 ? 0: 1;
						if (siblingEntryState >0)
							string entrySign = "-";
						else
							entrySign = "+";
						endif

						if (siblingEntryRow == thisCmpRow && siblingEntryState == thisCmpState) 
						else
							// copy it to first empty and reset that position
							if (firstEmpty >=  nAliases )
								nAliases +=1;
								redimension /N=(-1,nAliases, -1) simTmpData.AliasW
								simTmpData.AliasW[][nAliases -1][] = NaN;
							endif
							simTmpData.AliasW[baseCmpRow][firstEmpty][baseCmpState] =  simTmpData.AliasW[siblingCmpRow][k][siblingCmpState];
							firstEmpty +=1;
						endif
					endif
				endfor
				// now erase the copied alias string
				simTmpData.AliasW[siblingCmpRow][][siblingCmpState] = NaN;
			endfor
		endfor
	endfor
	
	
	// 4th pass - write self and remove self-references
	variable longestAlias = 0;
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow <  cN; thisCmpRow += 1)
			if (!numtype ( simTmpData.AliasW[thisCmpRow][1][thisCmpState])) // this position is empty; there are no aliases
				simTmpData.AliasW[thisCmpRow][0][thisCmpState] = (thisCmpRow +1)  * (thisCmpState > 0 ? -1 : 1);
				if (1<2)
				nAliases = dimsize(simTmpData.AliasW, 1);
				for (i=0; i< nAliases; i+=1)
					if (numtype (simTmpData.AliasW[thisCmpRow][i][thisCmpState])) // this is empty
						continue;
					endif
					for (j=i+1; j<nAliases; j+=1)
						if (numtype (simTmpData.AliasW[thisCmpRow][j][thisCmpState])) // this is empty
							break;
						endif
						if (simTmpData.AliasW[thisCmpRow][i][thisCmpState] == simTmpData.AliasW[thisCmpRow][j][thisCmpState]) // this is a duplicate
							simTmpData.AliasW[thisCmpRow][j,nAliases - 2][thisCmpState] = simTmpData.AliasW[thisCmpRow][q+1][thisCmpState];
							simTmpData.AliasW[thisCmpRow][nAliases - 1][thisCmpState] = NaN;
						
						endif
					endfor
					if (i >= longestAlias)
						longestAlias = i+1;
					endif
				endfor
				endif
			endif 
		endfor
	endfor	

	// 5th pass - group aliases
	variable nAliasGroups = dimsize(simTmpData.AliasW, 0);
	variable nextAliasGroup = 0; // row to store next found group
	for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow <  nAliasGroups; thisCmpRow += 1)
			if (numtype ( simTmpData.AliasW[thisCmpRow][1][thisCmpState])) // this position is empty; there are no aliases
				simTmpData.AliasW[thisCmpRow][][thisCmpState] = NaN; // deletepoints /M=0 thisCmpRow, 1,  simTmpData.AliasW
			else
				if (thisCmpRow != nextAliasGroup || thisCmpState != 0)
					if (nextAliasGroup >=nAliasGroups )
						redimension /N=(nextAliasGroup+1, -1, -1) simTmpData.AliasW
						nAliasGroups = dimsize(simTmpData.AliasW, 0);
					endif
					simTmpData.AliasW[nextAliasGroup][][0] = simTmpData.AliasW[thisCmpRow][q][thisCmpState];
					simTmpData.AliasW[thisCmpRow][][thisCmpState] = NaN;
				endif
				nextAliasGroup +=1;
			endif 
		endfor
	endfor
	
	// 6th pass - trim alias set

	  
	// ..th pass - prep for simulation
	// trim set to just aliases
	redimension /N=(nextAliasGroup, longestAlias) simTmpData.AliasW
	
	for (	thisCmpState = 0; thisCmpState <=dimSize(simTmpData.AliasW,2); thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
		for (thisCmpRow=0; thisCmpRow<dimSize(simTmpData.AliasW,0);  thisCmpRow+=1)
			string thisCmp =  "\rAlias group#"+num2istr(thisCmpRow)+" ";
			string thisAliases = "";
			string thisRaw = " (raw "
			for (j=0; j< dimSize(simTmpData.AliasW,1); j+=1)
				if (!numtype(simTmpData.AliasW[thisCmpRow][j][thisCmpState]))
					if (strlen(thisAliases))
						thisAliases += ", ";
					endif
					if (simTmpData.AliasW[thisCmpRow][j][thisCmpState] >= 0)
						thisAliases += "+";
					else
						thisAliases += "-";
					endif
					thisAliases += num2istr(abs(simTmpData.AliasW[thisCmpRow][j][thisCmpState])-1)
				endif
				if (j >0)
					thisRaw += ",";
				endif
				thisRaw +=  num2str(simTmpData.AliasW[thisCmpRow][j][thisCmpState])
			endfor
			if (strlen(thisAliases))
				thisCmp += thisAliases;
			else
				thisCmp += " no aliases";
			endif
			thisCmp+= thisRaw+")";
			print thisCmp;
		endfor 
	endfor 	

	if (1>2) // for debugging
		Print " "
		for (	thisCmpState = 0; thisCmpState <=1; thisCmpState +=1 ) // 0 = oxidized,  1 = reduced
			Print "Merger points for state ", thisCmpState, " of ", commName
			for (thisCmpRow=0; thisCmpRow<cN; thisCmpRow+=1)
				thisCmp =  "Cmp#"+num2istr(thisCmpRow)+" ";
				thisRaw = " raw "
				for (j=0; j< cN+1; j+=1)
					if (j >0)
						thisRaw += ",";
					endif
					thisRaw +=  num2str(MergerW[thisCmpRow][j][thisCmpState])
				endfor
				thisCmp+= thisRaw+"";
				print thisCmp;
			endfor
		endfor 	
	endif
		
	return ""
end

//----------------------------------------------------------
//
threadsafe function advanceSim(curr_i, theStats, SWave, TWave)
	variable curr_i
	STRUCT RKStats &theStats;
	wave SWave
	wave TWave
	
	variable i, cN= DimSize(TWave, 1)
	
			SWave[curr_i][2] = theStats.counter; 
			SWave[curr_i][3] = theStats.rates_count_cum;
			SWave[curr_i][4] = theStats.steps_count_cum; 
			SWave[curr_i][5] = theStats.rates_count_cum / 4 / theStats.counter; // should define RKOrder;
			SWave[curr_i][6,9] = NaN;// reserved 
			theStats.counter  = 0;
			theStats.rates_count_cum = 0;
			theStats.steps_count_cum = 0;
			
			variable Q_cum_tot = 0;
			variable dC_cum_Ox_sol =0, dC_cum_Rd_sol =0, dC_cum_Ox_el =0, dC_cum_Rd_el =0
			for (i=0; i<cN ; i+=1)	// save current component parameters
				if (TWave[0][i] > 0)
					SWave[curr_i][S_C_Offs+i*S_C_Num+0] = TWave[1][i]; // Ox_sol
					SWave[curr_i][S_C_Offs+i*S_C_Num+1] = TWave[4][i] // Rd_sol 

					dC_cum_Ox_sol = TWave[11][i];
					SWave[curr_i][S_C_Offs+i*S_C_Num+4] = dC_cum_Ox_sol; 

					dC_cum_Rd_sol = TWave[14][i];
					SWave[curr_i][S_C_Offs+i*S_C_Num+5] = dC_cum_Rd_sol;
					
					Q_cum_tot += dC_cum_Ox_sol; 
					
					variable C_Ox_el = TWave[2][i]; // Ox_el
					if (C_Ox_el >= 0)
						SWave[curr_i][S_C_Offs+i*S_C_Num+2] = C_Ox_el
						dC_cum_Ox_el = TWave[12][i];
						SWave[curr_i][S_C_Offs+i*S_C_Num+6] = dC_cum_Ox_el; 
						Q_cum_tot += dC_cum_Ox_el;
					endif 
					
					variable C_Rd_el = TWave[3][i]; // Rd_el
					if (C_Rd_el >= 0)
						SWave[curr_i][S_C_Offs+i*S_C_Num+3] = C_Rd_el
						dC_cum_Rd_el = TWave[13][i];
						SWave[curr_i][S_C_Offs+i*S_C_Num+7] = dC_cum_Rd_el
					endif
					 TWave[11,14][i]=0;
				else // no compound in the system
					SWave[curr_i][(S_C_Offs+i*S_C_Num+0),(S_C_Offs+i*S_C_Num+7)]=NaN;
				endif
			endfor
			// total charge needs to be divided by the step length
			SWave[curr_i][8] = Q_cum_tot; // total charge from all sources, this should account for variation in sim step
end



//----------------------------------------------------------
// combine all concentraions in the group and set them all equal to it
//
threadsafe function InitAliasGroup(AliasW, TWave)
	wave AliasW
	wave TWave
	
	variable aGr, aEntry, entryCmp, gr_C0tot_sol //, gr_dC_sol
		
	for (aGr = 0; aGr < dimsize (AliasW, 0); aGr +=1)
		gr_C0tot_sol = 0;
		for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
			if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
				break;
			endif
			entryCmp = abs(AliasW[aGr][aEntry] )-1;
			if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
				gr_C0tot_sol += TWave[1][entryCmp]; 
			else // use reduced form of that alias
				gr_C0tot_sol += TWave[4][entryCmp]; 
			endif 
		endfor
		
		for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
			if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
				break;
			endif
			entryCmp = abs(AliasW[aGr][aEntry])-1 ;
			if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
				TWave[1][entryCmp]= gr_C0tot_sol; 
			else // use reduced form of that alias
				TWave[4][entryCmp]= gr_C0tot_sol; 
			endif 
			
		endfor		
	endfor
	
end

//----------------------------------------------------------
//
threadsafe function CombAliasGroup(AliasW, RKWave)
	wave AliasW
	wave RKWave
		
	variable aGr, aEntry, entryCmp, gr_C0tot_sol, gr_dC_sol
			
		for (aGr = 0; aGr < dimsize (AliasW, 0); aGr +=1)
			if (numtype(AliasW[aGr][0]))
				continue; // this should not be - group with no members!
			endif  
			gr_dC_sol = 0;

			// add up al the changes
			for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
				if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
					break;
				endif
				entryCmp = abs(AliasW[aGr][aEntry])-1;
				if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
					gr_dC_sol +=  RKWave[0][4][entryCmp][0];
					RKWave[0][3][entryCmp][0] = 1;
					if (entryCmp == 0)
						gr_C0tot_sol = RKWave[0][0][entryCmp][0];
					endif
				else // use reduced form of that alias
					gr_dC_sol +=  RKWave[3][4][entryCmp][0];
					RKWave[3][3][entryCmp][0] = 1;
					if (entryCmp == 0)
						gr_C0tot_sol = RKWave[3][0][entryCmp][0];
					endif
				endif 
			endfor
			// assign total changes to each member of the alias group
			variable gr_C1tot_sol = gr_C0tot_sol + gr_dC_sol;
			
			for (aEntry = 0; aEntry< dimsize (AliasW, 1); aEntry +=1 )
				if (numtype(AliasW[aGr][aEntry])) // this is a NaN, stop group integration
					break;
				endif
				entryCmp = abs(AliasW[aGr][aEntry])-1;
				if (AliasW[aGr][aEntry] >= 0) // use oxidized form of that alias
					RKWave[0][1][entryCmp][0] = gr_C1tot_sol;
					RKWave[0][4][entryCmp][0] = gr_dC_sol;
				else // use reduced form of that alias
					RKWave[3][1][entryCmp][0] = gr_C1tot_sol;
					RKWave[3][4][entryCmp][0] = gr_dC_sol;
				endif 
			endfor
		endfor

	
end


//---------------------------------------------------------------------------------------
// Debugging log
//---------------------------------------------------------------------------------------
//
//
threadsafe  function reportDbgCommon(dbg, StepsCount, curr_t, curr_i, SimStep, theStats)
	wave dbg;
	variable StepsCount, curr_t, curr_i, SimStep;
	STRUCT RKStats &theStats;
	
	dbg[StepsCount][0] = curr_t;
	dbg[StepsCount][1] =curr_i; 
	dbg[StepsCount][2] = SimStep;
	dbg[StepsCount][3] = theStats.steps_count; 
	dbg[StepsCount][4] = theStats.rates_count; 
	dbg[StepsCount][5] = theStats.lim_code_outer; 
	dbg[StepsCount][6] = theStats.lim_rel_outer;
	dbg[StepsCount][7] = theStats.lim_code_inner; 
	dbg[StepsCount][8] = theStats.lim_rel_inner;
end

//----------------------------------------------------------
//
threadsafe  function reportDbgComponent(dbg, StepsCount,TWave)
	wave dbg;
	variable StepsCount;
	wave TWave;
	variable i;
	for (i=0; i<dimsize(TWave, 1); i+=1)	
		variable dbgOffs = DbgCom+i*DbgM;
		dbg[StepsCount][dbgOffs+0, dbgOffs+2] = TWave[23 + q - (dbgOffs+0)][i]; 
		dbg[StepsCount][dbgOffs+3] = NaN
		dbg[StepsCount][dbgOffs+4, dbgOffs+7] = TWave[1 + q - (dbgOffs+4)][i]; 
		dbg[StepsCount][dbgOffs+8, dbgOffs+11] = TWave[7 + q - (dbgOffs+8)][i]; 
		dbg[StepsCount][dbgOffs+12, dbgOffs+15] = TWave[11+q - (dbgOffs+12)][i]; 
		dbg[StepsCount][dbgOffs+15, (DbgCom+(i+1)*DbgM -1)] = NaN; 
	endfor
end






//----------------------------------------------------------
//      Progress tracking
//----------------------------------------------------------
//
threadsafe function reportProgress(curr_i, curr_t, StepsCount, theStats, reset)
	variable curr_i, curr_t, StepsCount, reset
	STRUCT RKStats &theStats;

	variable /G sim_curr_i = curr_i;
	variable /G sim_curr_t = curr_t;
	variable /G sim_curr_step = StepsCount;
	variable /G sim_i_step = (reset)? 0: sim_i_step+1
	if (reset)
		sim_i_step = 0;
	else
		sim_i_step += 1;
	endif 
		sim_curr_i = curr_i;
		sim_curr_t = curr_t;
		sim_curr_step = StepsCount;

end




//-----------------------------------------------
//

function SetProgressStart(prg) // iSetSims, iPoints, iCurrI, iCurrStep, [winPropRef])
	STRUCT SetProgDataT &prg;
	
	prg.set_last_update  = -1;
	prg.set_start_time = DateTime;
	prg.set_stop_time = -1;
	if (prg.hosted) // name is set, use as sub-pane;
		return SetProgressSetup(prg);
	endif 
	
	if (strlen(prg.wName) == 0)
		prg.wName = "mySetProgress";
	endif
	prg.x = 0;
	prg.y=0;

	NewPanel/FLT /N=$prg.wName /W=(285,111,739,185) as "Simulating a set..."
	SetProgressSetup(prg);
	DoUpdate/W=mySetProgress/E=1 // /SPIN=60 // mark this as our progress window
	SetWindow mySetProgress,hook(spinner)=MySetHook
	variable /G kill_sim = -1;
End


//-----------------------------------------------
//

function SetProgressSetup(prg)
	STRUCT SetProgDataT &prg;
	
	ValDisplay inSimDisp, win=$prg.wName, title="started", pos={18+prg.x,4+prg.y},size={190,14}, limits={0,prg.set_sims,0}, barmisc={0,40}, mode=3 
	ValDisplay inSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_in

	ValDisplay outSimDisp, win=$prg.wName, title="finished", pos={210+prg.x,4+prg.y},size={190,14}, limits={0,prg.set_sims,0}, barmisc={0,40}, mode=3 
	ValDisplay outSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_out

	ValDisplay stepDisp, win=$prg.wName,  title="point", pos={25+prg.x,23+prg.y},size={377,14}, bodyWidth=350, limits={0,(prg.set_points < 0? 0 : prg.set_points),0}, barmisc={0,50}, mode=3 
	ValDisplay stepDisp, win=$prg.wName, value= _NUM:prg.set_curr_i
	
	SetVariable ETADisp win=$prg.wName, title="ETA", value=_STR:"-?-", noedit=1, pos={150+prg.x,40+prg.y},fixedSize=1,size={120,16},frame=0

	Button bStop,pos={350+prg.x,45+prg.y},size={50,20},title="Abort", proc=simStopThreadsProc
	SetActiveSubwindow _endfloat_
end 

//-----------------------------------------------
//
Function MySetHook(s)
	STRUCT WMWinHookStruct &s
	if( s.eventCode == 23 )
		variable /G set_curr_i;
		variable /G set_last_update;	
		variable /G set_points;
		if (set_points < 0)
			set_points *= -1;
			ValDisplay stepDisp limits={0,set_points,0}, win=$s.winName 
		endif 
		if (set_curr_i != set_last_update)
			variable /G set_curr_sim_in;
			variable /G set_curr_sim_out;

			variable /G set_curr_i
			variable /G set_start;
			variable now = DateTime;
		
			set_last_update = set_curr_i;

		endif	
		DoUpdate/W=$s.winName
		if( V_Flag == 2 ) // we only have one button and that means abort
			Button bStop,title="wait...", win=$(s.winName), disable=2
			NVAR kill_sim 
			kill_sim = 1;
			print "Killed #1"
			return 1
		endif
		
	endif
	return 0
end


//-----------------------------------------------
//

function doSetProgressUpdate(prg) 
	STRUCT SetProgDataT &prg;

	variable now = DateTime;
	variable elapsed_time = (now - prg.set_start_time);

	variable newTime =((prg.set_points - prg.set_curr_i) / prg.set_curr_i)*elapsed_time;
	string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
	
	ValDisplay inSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_in

	ValDisplay outSimDisp, win=$prg.wName, value= _NUM:prg.set_curr_sim_out

	ValDisplay stepDisp, win=$prg.wName, value= _NUM:prg.set_curr_i

	SetVariable ETADisp  value=_STR:ETAStr, win=$prg.wName
	NVAR kill_sim
	prg.aborted = kill_sim;
	
	if( kill_sim > 0) // we only have one button and that means abort
			Button bStop,title="wait...", win=$(prg.wName), disable=2
		endif
	DoUpdate/W=$prg.wName

	
	return (kill_sim > 0); 
end

//-----------------------------------------------
//

function doSetProgressSteps(prg) 
	STRUCT SetProgDataT &prg;

	ValDisplay stepDisp, win=$prg.wName, limits= {0,(prg.set_points < 0? 0 : prg.set_points),0}, value= _NUM:prg.set_curr_i
end



//-----------------------------------------------
//

Function SetProgressStop(prg)
	STRUCT SetProgDataT &prg;

	prg.set_stop_time = DateTime;
	
	if (prg.thGroupId < 0)
		variable 	dummy= ThreadGroupRelease(prg.thGroupId)
		prg.thGroupId = -1;
	endif

	if (!prg.hosted)
		SetProgressCleanup(prg)
	endif;

End


//-----------------------------------------------
//

Function SetProgressCleanup(prg)
	STRUCT SetProgDataT &prg;

	KillWindow $prg.wName;
	
	variable /G set_points
	variable /G set_curr_i
	variable /G set_curr_t
	variable /G set_i_step
	variable /G set_last_update
	variable /G set_start
	killvariables /Z set_points, set_curr_i, set_curr_t, set_curr_step,  set_i_step, set_last_update, set_start, kill_sim 
End

//-----------------------------------------------
//
function defaultSetPrg(thePrg, hosted, len, wName)
	STRUCT SetProgDataT &thePrg;
	variable hosted;
	variable len;
	string wName; // only if not hosted!

	thePrg.set_sims = len;
	thePrg.set_points = 0;
	thePrg.set_curr_sim_in = 0;
	thePrg.set_curr_sim_out = 0;
	thePrg.set_curr_i = 0;
	thePrg.set_curr_s = 0;
	thePrg.thGroupId = -1;
	thePrg.set_last_update = -1;
	thePrg.hosted = hosted ? 1: 0;
	thePrg.aborted = 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.wName = wName;
		else
			thePrg.wName = "mySetProgress";
		endif			
	endif
end


//========================================================================
//
threadsafe function RKPrepCmps(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, curr_E) 
	wave CWave,  TWave, PWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable curr_E;
	wave RxInWave, RxRKWave;
	variable i // index of the component

	variable k_on, k_off, E_k0, k_ET_ox, k_ET_rd
	variable cN = dimsize(CWave, 1);

	RKWave[][][][1] = 0;
	RxRKWave[][] = 0;
		
	// values in CWave must be balanced against total
	for (i=0; i<cN ; i+=1)		
		E_k0 = CWave[4][i];
		
		if (TWave[0][i]  > 0 ) 	// 1. component is present in the solution
			RKWave[0, 3; 3][0][i][0] = TWave[p+1][i]; // Ox and Rd in solution
			if (E_k0 > 0) 		// 2. rate of the electrode reaction is set 
				// check for previous Eapp and see if recaclulation is necessary							
				variable K_ET_0  = exp(TWave[21][i] * (curr_E - CWave[2][i])); // ET eq. constant  <- this can be done once per RK4 and stored in 
				k_ET_ox = E_k0 * K_ET_0; // forward
				k_ET_rd = E_k0 / K_ET_0; // reverse
				variable limRate = CWave[8][i];
				variable limMode = PWave[3];
				if ((limRate > 0) && (limMode > 0)) // there is limiting rate; no binding 
					variable k_ET_rd_lim, k_ET_ox_lim;
					k_ET_rd_lim = 1.0/((1.0/k_ET_rd) + (1.0/limRate)); 
					k_ET_ox_lim = 1.0/((1.0/k_ET_ox) + (1.0/limRate)); 
					switch (floor(limMode))
						case 1: // limit both
							TWave[24][i] = k_ET_rd_lim;
							TWave[25][i] = k_ET_ox_lim;
							break;
						case 2: // limit,correct both
							variable K_corr_sym = sqrt((k_ET_ox_lim / k_ET_rd_lim) / K_ET_0);
							TWave[24][i] = k_ET_rd_lim * K_corr_sym;
							TWave[25][i] = k_ET_ox_lim / K_corr_sym;
							break;
						case 3: // limit fast, correct slow
							variable K_corr_asm = ((k_ET_ox_lim / k_ET_rd_lim ) / K_ET_0);
							if (k_ET_ox < k_ET_rd) // limit reduction, correct oxidation
								TWave[24][i] = k_ET_rd_lim;
								TWave[25][i] = k_ET_ox_lim / K_corr_asm;
							else // limit oxidation, correct reduction
								TWave[24][i] = k_ET_rd_lim * K_corr_asm;
								TWave[25][i] = k_ET_ox_lim ;
							endif 
							break;
						case 5:
						case 4: // balanced correction
							variable K_corr_flex = ((k_ET_ox_lim / k_ET_rd_lim ) / K_ET_0);
							variable currK = k_ET_ox_lim/ k_ET_rd_lim;
							variable corrPower = currK / (1+currK)
							TWave[24][i] = k_ET_rd_lim *  (K_corr_flex ^ corrPower) ;
							TWave[25][i] = k_ET_ox_lim / (K_corr_flex ^ (1-corrPower));
							break;
						default:
					endswitch 
					TWave[23][i] = K_ET_0;
					RKWave[1,2][0][i][0] = -1;
				else // no limiting rate, maybe binding?
					k_on = TWave[28][i];
					k_off = TWave[29][i];
					if (k_on > 0 && k_off > 0) // 3. binding does occur
						TWave[23][i] = K_ET_0;
						TWave[24][i] =  k_ET_rd;
						TWave[25][i] =  k_ET_ox;
						RKWave[1,2][0][i][0] = TWave[p+1][i]; // Ox and Rd on the electrode
					else // no limit and no binding 
						TWave[23][i] = NaN;
						TWave[24, 25][i] = 0;
						RKWave[1,2][0][i][0] = -1;
					endif 
					TWave[23][i] =  K_ET_0;

				endif
			else // no echem, no binding to consider; but solution txn may still go on
				TWave[23][i] = NaN;
				TWave[24, 25][i] = NaN;
				RKWave[0, 3; 3][0][i][0] = TWave[p+1][i]; // Ox sol 
			endif
		else // there is no component in the system
			TWave[23][i] = NaN;
			RKWave[][0][i][0] = -1; // to avoid division by zero error
		endif 
	endfor

end

//========================================================================
//
// placefolder function for checking and adjusting RK parameters, if necessary

threadsafe function RKPostCmps(RK_Order, CWave, TWave, RKWave) 
	variable RK_Order
	wave CWave, TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	
	return 0;
end




//========================================================================
//
// obtain rates based on specified concentrations. 
//

function RKCmpRatesMT(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep, threadGroupID) // returns sim step, all rates are in TWave
	wave  PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable RKStep;
	variable threadGroupID
	wave RxInWave // reaction rates annd stoichiometry
	wave RxRKWave // wave to store solution RK values

	variable i, j;
	variable cN = dimsize(CWave, 1);	
	variable sol_height = PWave[10]; 

	// calculate current vectors for each solution rxn
	 RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 
	 
	Variable dummy

	// now generate total vectors for each component
	for (i=0; i<cN ; i+=1)	
		if (TWave[0][i]  <= 0) // component is present in the system
			continue;
		endif
		Variable threadIndex = ThreadGroupWait(threadGroupID,-2) - 1		
		if (threadIndex < 0)
			dummy = ThreadGroupWait(threadGroupID, 10)// Let threads run a while
			i -= 1 // Try again for the same column
			continue // No free threads yet
		endif
		ThreadStart threadGroupID, threadIndex,  getCmpVector(i, RKStep, sol_height, PWave, CWave, RxInWave, RxRKWave, TWave, RKWave)		
	endfor
	do
		Variable threadGroupStatus = ThreadGroupWait(threadGroupID,0)
		if (threadGroupStatus == 0)
			threadGroupStatus = ThreadGroupWait(threadGroupID,10)
		endif
	while(threadGroupStatus != 0)
end


//========================================================================
//
threadsafe  function RKCmpRatesST(PWave, CWave, RxInWave, RxRKWave, TWave, RKWave, RKStep) // returns sim step, all rates are in TWave
	wave  PWave, CWave,  TWave;
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	variable RKStep;
	wave RxInWave, RxRKWave
	
	
	variable i, j;
	variable cN = dimsize(CWave, 1);	
	variable sol_height = PWave[10]; 

	// calculate current vectors for each solution pair
	 RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 

	// now generate total vectors for each component
	for (i=0; i<cN ; i+=1)	
		if (TWave[0][i]  <= 0) // component is present in the system
			continue;
		endif
		getCmpVector(i, RKStep, sol_height, PWave, CWave, RxInWave, RxRKWave, TWave, RKWave);
	endfor
end


//========================================================================
//
threadsafe function RKRxnRates(RKWave, TWave, RxInWave, RxRKWave, cN, RKStep) 
	wave  RKWave; // rows - species, cols - RK4 order, layers - components, chunks - C or R
	wave TWave
	wave RxInWave // reaction rates annd stoichiometry
	wave RxRKWave // wave to store solution RK values
	variable cN ; 
	variable RKStep;

	variable rxn, cmp;

	// calculate current vectors for each solution pair
	variable nRxns = dimsize(RxRKWave, 0);
	RxRKWave[][RKStep] = 0;
	for (rxn=0; rxn< nRxns; rxn+= 1)
		variable fwdRxnRate = RxInWave[rxn][0][0] ;
		variable fwdRxnMode = -1;
		variable revRxnRate = RxInWave[rxn][0][1] ;
		variable revRxnMode = -1;
		
		for (cmp=0; cmp< cN; cmp+=1)
			if (TWave[0][cmp] > 0) // componet is present in the solution 
				if (fwdRxnMode != 0)
					variable nReact = RxInWave[rxn][cmp+1][0];
					variable cReact = 0;
					if (nReact > 0) // oxidized form
						cReact =  RKWave[0][RKStep][cmp][0] 
					elseif (nReact < 0) // reduced form
						nReact = -nReact;
						cReact =  RKWave[3][RKStep][cmp][0]
					// else // not participating - skip
					endif 
					if (nReact > 0) // must be involved
						if (cReact > 0)
							fwdRxnRate *= cReact ^ nReact;	
							fwdRxnMode = 1;
						elseif (cReact == 0) // reverse rate is zero, not need to continue calcs
							fwdRxnMode = 0;
						endif 
					// else  no n, not participating 
					endif
				elseif (revRxnMode == 0)
					break; // both rates are zero, regardless of other components; break the loop
				endif 	
				
				if (revRxnMode != 0)
					variable nProd = RxInWave[rxn][cmp+1][1];
					variable cProd = 0;
					if (nProd > 0) // oxidized form
 						cProd =  RKWave[0][RKStep][cmp][0];
					elseif (nProd < 0) // reduced form
						nProd = -nProd;
						cProd =  RKWave[3][RKStep][cmp][0];
					endif 

					if (nProd > 0) // must be involved
						if (cProd > 0)
							revRxnRate *= cProd ^ nProd;	
							revRxnMode = 1;
						elseif (cProd == 0) // reverse rate is zero, not need to continue calcs
							revRxnMode = 0;
						endif 
					// else  no n, not participating 
					endif
				endif // revRxnMode != 0
			endif
		endfor
		
		variable totRxnRate = 0;
		if (revRxnMode > 0 )
			totRxnRate += revRxnRate;
		endif
		if (fwdRxnMode > 0 )
			totRxnRate -= fwdRxnRate;
		endif
		
		RxRKWave[rxn][RKStep] =totRxnRate;
	endfor 
end 

//========================================================================
//

threadsafe  function getCmpVector(i,  RKStep, sol_height, PWave, CWave,  RxInWave, RxRKWave, TWave, RKWave) 
		variable i, RKStep, sol_height; //r1Nx, 
		wave PWave, CWave,  TWave, RKWave;
		wave RxInWave, RxRKWave

		variable j
		
		// get all solution echem rates for this component
		// for pure echem reduction and oxidation rates are the same, but for rxns with isomerization it may not be!
		variable C_soln_Rd_rate = 0; 
		variable C_soln_Ox_rate = 0; 
		for (j=0; j< dimsize(RxRKWave, 0); j+=1)
			variable nReact = RxInWave[j][i+1][0]
			variable nProd = RxInWave[j][i+1][1]

			variable netRate = -RxRKWave[j][RKStep] // fwdRate - revRate;
				
				if (nReact>0) // gain of oxidized 
					C_soln_Ox_rate -=nReact  * netRate
				elseif (nReact<0) // gain of reduced
					C_soln_Rd_rate += nReact  * netRate
				endif;

				if (nProd>0) // gain of oxidized 
					C_soln_Ox_rate +=nProd  * netRate
				elseif (nProd<0) // gain of reduced
					C_soln_Rd_rate -=nProd  * netRate
				endif;			
		endfor  

		// now the electrode					
		variable limRate = CWave[8][i];
		variable limMode = PWave[3];

		variable ET_rate = 0; // effective ET rate, limited or not
		if (limRate > 0 && limMode > 0) // there is limiting rate and no binding
			variable k_ET_rd_lim = TWave[24][i];
			variable k_ET_ox_lim  = TWave[25][i];
			variable C_ox_tot = RKWave[0][RKStep][i][0];// , TWave[1][i];
			variable C_rd_tot = RKWave[3][RKStep][i][0];// TWave[4][i];
			if (k_ET_rd_lim > 0 && k_ET_ox_lim > 0) // there is ET
				ET_rate = (C_ox_tot * k_ET_rd_lim -  C_rd_tot * k_ET_ox_lim);
			endif 
			RKWave[0][RKStep][i][1] = +C_soln_Ox_rate - ET_rate;  // Ox sol
			RKWave[3][RKStep][i][1] = +C_soln_Rd_rate + ET_rate; // Rd sol
		else  // no limiting rate; does binding occur?
			variable k_on = TWave[28][i];
			variable k_off = TWave[29][i];
			if (k_on > 0 && k_off > 0 ) // binding does occur
				variable C_ox_sol = RKWave[0][RKStep][i][0];// , TWave[1][i];
				variable C_rd_sol = RKWave[3][RKStep][i][0];// TWave[4][i];
				variable C_ox_el = RKWave[1][RKStep][i][0];// TWave[2][i];
				variable C_rd_el = RKWave[2][RKStep][i][0];// TWave[3][i];
					
				// calculate redox rates for oxidized / reduced species
				variable k_ET_rd = TWave[24][i];
				variable k_ET_ox  = TWave[25][i];
				if (k_ET_rd > 0 && k_ET_ox > 0) // there is ET
					ET_rate = (C_ox_el * k_ET_rd -  C_rd_el * k_ET_ox);
				endif 
					
				variable Bind_Ox_rate = C_ox_sol * k_on -  C_ox_el * k_off / sol_height; // net binding rate of the oxidized component
				variable Bind_Rd_rate = C_rd_sol * k_on -  C_rd_el * k_off / sol_height; // net binding rate of the reduced component
					
				RKWave[0][RKStep][i][1] = +C_soln_Ox_rate - Bind_Ox_rate;  // Ox sol
				RKWave[1][RKStep][i][1] = -ET_rate + Bind_Ox_rate;  // Ox el
				RKWave[2][RKStep][i][1] = +ET_rate + Bind_Rd_rate; // Rd el 
				RKWave[3][RKStep][i][1] = +C_soln_Rd_rate - Bind_Rd_rate; // Rd sol
			else // no binding, no echem
				RKWave[0][RKStep][i][1] = +C_soln_Ox_rate;  // Ox sol
				RKWave[3][RKStep][i][1] = +C_soln_Rd_rate ; // Rd sol
			endif			
		endif

end

//========================================================================
//
// optional debugging log - enable in code as needed

function dbg_up(RK4TmpW, RKWave) 
	wave RK4TmpW, RKWave;
	variable RKStep
	
	RK4TmpW[][0,4] = RKWave[p][q][0][0]; // conc
	RK4TmpW[][5] = NaN;
	RK4TmpW[][6,9] = RKWave[p][q-6][0][1]; // rates
	RK4TmpW[][10] = RKWave[p][4][0][0]; // dC RK7
	RK4TmpW[][11] = RKWave[p][4][0][1]; // dC Euler
	if (DoDbgUpdate)
		DoUpdate ////W=$"tmp_RK4Wnd";
	endif
end


//========================================================================
//
//
//
threadsafe function stepRK(RK_Order, RKStep, RKWave, PWave, TWave, simStep, theStats) 
	variable RK_Order, RKStep;
	
	wave RKWave
	wave PWave, TWave
	variable &simStep
	STRUCT RKStats &theStats;

	
	variable Cref = 0;
	
		
		variable i, j, cN=dimsize(RKWave, 2);
		variable cF= dimsize(RKWave, 0);
		variable RKi_drop_max_Sol=PWave[5];	
		variable RKi_rise_max_Sol=PWave[6];	
		variable RKi_drop_max_El=PWave[11];	
		variable RKi_rise_max_El=PWave[12];	
		
		variable RK_drop_time_overshot=PWave[16];	
		variable RK_drop_lim_time_X = PWave[17];	
		variable RK_rise_lim_time_X = PWave[18];	

		string RK4TmpWN = "tmp_RK4"
		wave RK4TmpW = $RK4TmpWN;

		variable RK_steps_count;
		
		do 
			variable reset  =  0;
			variable rise_rel_max = 0;
			variable drop_rel_max = 0;
			variable max_rise_code = -1;
			variable max_drop_code = -1;
			variable TStep;
			RK_steps_count += 1;
			switch (RKStep)
				case 0:
				case 1: 	
					TStep = 0.5 * simStep;
					break
				case 2: 
					TStep = simStep;
					break
				case 3: 
			endswitch

			for (i=0; i<cN && reset == 0 ; i+=1)		
				if (TWave[0][i]  <=  0) // component is NOT present in the solution
					continue; 
				endif
				for (j=0; j < cF; j+=1)
					variable theC_i = RKWave[j][Cref][i][0] 
					if (theC_i < 0) // negative initial concentration means there is no need to consider it.
						continue
					endif 
					
					variable theR_i = RKWave[j][RKStep][i][1];
					if (theR_i !=0 ) // concentration is changing
						if (theC_i>0 )  // compund is present, may estimate realtive change
							variable thedC_rel_i = abs(theR_i * TStep / theC_i);
							 if (theR_i > 0 ) // rise 
							 	if (j == 0 || j == 3) // solution 
									if (thedC_rel_i > RKi_rise_max_Sol)
										rise_rel_max = thedC_rel_i;
										max_rise_code = i*10+j;
										reset = 1;
										break; 
									endif
							 	else // electrode 
									if (thedC_rel_i > RKi_rise_max_El)
										rise_rel_max = thedC_rel_i;
										max_rise_code = i*10+j;
										reset = 1;
										break; 
									endif
							 	endif 
							elseif (theR_i < 0 ) // fall 
							 	if (j == 0 || j == 3) // solution 
									if (thedC_rel_i > RKi_drop_max_Sol)
										drop_rel_max =thedC_rel_i;
										max_drop_code = i*10+j;
										reset = 1;
										break; 
									endif
							 	else // electrode 
									if (thedC_rel_i > RKi_drop_max_El)
										drop_rel_max =thedC_rel_i;
										max_drop_code = i*10+j;
										reset = 1;
										break; 
									endif
							 	endif 
							endif
						endif
						RKWave[j][RKStep+1][i][0] = RKWave[j][RKStep][i][0] + theR_i * TStep;
					else
						RKWave[j][RKStep+1][i][0] = RKWave[j][RKStep][i][0]; // no rate, conditions remain
					endif 
				endfor
			endfor 
			
			if (max_drop_code >= 0)
				if (RKStep == 0 )
					SimStep  /= drop_rel_max / (RKi_drop_max_El  * RK_drop_time_overshot); 
				else
					SimStep  *= RK_drop_lim_time_X; 
				endif
			elseif (max_rise_code >= 0)
				if (RKStep == 0)		
					SimStep /= rise_rel_max / RKi_rise_max_El ;
				else 
					SimStep  *= RK_rise_lim_time_X; 
				endif
			endif

			if (max_rise_code >=0 || max_drop_code >=0)
				RKWave[][1,][][] = 0; // reset all previous values except C0 and Euler rates
//				dbg_up(RK4TmpW, RKWave) ;
				RKStep = 0; // values of C0_i do not change with iteration! simply restart with smaller step

				theStats.lim_code_inner  = (rise_rel_max > drop_rel_max) ? max_rise_code :  -max_drop_code;
				theStats.lim_rel_inner =  (rise_rel_max > drop_rel_max) ? rise_rel_max :  -drop_rel_max;				
			else
				return RK_steps_count;
			endif 
		while (1) 
end


//========================================================================
//
threadsafe function finishRK(RK_Order, RKWave, PWave, TWave, simStep, theStats) 
	variable RK_Order
	wave RKWave
	wave PWave, TWave
	variable &simStep
	STRUCT RKStats &theStats;

	

		string RK4TmpWN = "tmp_RK4"
		wave RK4TmpW = $RK4TmpWN;
	
		variable RKFull_drop_max_Sol =PWave[7];	
		variable RKFull_rise_max_Sol=PWave[8];	
		
		variable RKFull_drop_max_El=PWave[13];	
		variable RKFull_rise_max_El=PWave[14];	
		
		variable RK_drop_lim_time_X = PWave[17];	
		variable RK_rise_lim_time_X = PWave[18];	
	
		variable max_drop_code, max_rise_code, rise_rel_max, 	drop_rel_max ;	
		variable cN= dimsize(RKWave, 2); // # of components
		variable cF= dimsize(RKWave, 0); // # of forms for this componnt

		variable i, j

	
		// calculate weighted rate per RK4 model
		switch (RK_order)
			case 4:
				RKWave[][RK_order-1][][1] =  (RKWave[p][0][r][1] + 2*RKWave[p][1][r][1] + 2*RKWave[p][2][r][1] + 2*RKWave[p][3][r][1]) / 6;
				break;
			case 1:
				// no need to do anything, RKWave[][0][][1] already contains intial rates
				break;
			default:
				// this is a problem, must abort
		endswitch
				
		// calculate RK4 change in concentrations at full step after adjustments
		RKWave[][RK_order+0][][0] = SimStep * RKWave[p][RK_order-1][r][1];
				
		// final rates are in, check if they comply with the limits
		rise_rel_max = 0;
		drop_rel_max = 0;
		max_rise_code = -1;
		max_drop_code = -1;
				
		for (i=0; i<cN; i+=1)		
			if (TWave[0][i]  > 0) // component is present in the solution
				for (j=0; j < cF; j+=1)
					variable theC_i = RKWave[j][0][i][0] //RKWave[j][Cref][i][0] 
					if (theC_i>0)
						variable thedC_i = RKWave[j][RK_order][i][0] // RKWave[j][1][i][0];
						variable thedC_rel_i = abs(thedC_i / theC_i);
						 if (thedC_i > 0 ) // rise 
						 	if (j == 0 || j == 3) // solution 
								if (thedC_rel_i > RKFull_rise_max_Sol)
									rise_rel_max = thedC_rel_i;
									max_rise_code = i*10+j;
								endif
						 	else // electrode 
								if (thedC_rel_i > RKFull_rise_max_El)
									rise_rel_max = thedC_rel_i;
									max_rise_code = i*10+j;
								endif
						 	endif 
						elseif (thedC_i < 0 ) // fall 
						 	if (j == 0 || j == 3) // solution 
								if (thedC_rel_i > RKFull_drop_max_Sol)
									drop_rel_max = thedC_rel_i;
									max_drop_code = i*10+j;
								endif
						 	else // electrode 
								if (thedC_rel_i > RKFull_drop_max_El)
									drop_rel_max = thedC_rel_i;
									max_drop_code = i*10+j;
								endif
						 	endif 
						endif
					endif 
				endfor
			endif
		endfor // components, RK order 0

		if (max_drop_code >= 0 )
			SimStep *= RK_drop_lim_time_X;
		elseif (max_rise_code >= 0)
			SimStep *= RK_rise_lim_time_X;				
		endif

		if (max_rise_code >=0 || max_drop_code >=0 )
			RKWave[][1,][][] = 0; // reset all previous values except C0 and Euler rates
//			dbg_up(RK4TmpW, RKWave) ;
			theStats.lim_code_outer = (rise_rel_max > drop_rel_max) ? max_rise_code :  -max_drop_code;
			theStats.lim_rel_outer = (rise_rel_max > drop_rel_max) ? rise_rel_max :  -drop_rel_max;
			return 0;
		else // all good - carry on
			return 1; 
		endif 
end


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



//----------------------------------------------------------------------------------------------
//
// prototype function for mechanism-specific rates calculations
//
function SimRatesProto(PWave, CWave, RWave, TWave, curr_E)
	wave PWave, CWave, RWave, TWave
	variable curr_E
	
end

//----------------------------------------------------------------------------------------------
//
// prototype function for mechanism-specific prep calculations
//
threadsafe function SimSetupProto(SWave, CWave, ERxnsW, GRxnsW,PWave,  simTmpData) 
	wave SWave, CWave, PWave
	wave /WAVE ERxnsW, GRxnsW
	STRUCT simTmpDataT &simTmpData;
	
end

//-----------------------------------------------
//
threadsafe  function simWSetupProto(setData, simData) 
	STRUCT simSetDataT &setData;
	STRUCT simDataT &simData;
	
end

//----------------------------------------------------------
//
threadsafe  function /WAVE simWProcessProto(ResultWNSuffix, simData) //SWave, PWave, CWave, RWave, NPVWave, JParWave, iteration)
	string ResultWNSuffix
	STRUCT simDataT &simData;
	
end

//----------------------------------------------------------------------------------------------
//
//			 prototype function for creating a single sim plot in a series
//	
//-----------------------------------------------
//
// this function does not return a value 

 function simPlotBuildProto(plotNameS, theSim, theSet) 
	string plotNameS // name of the plot/window
	STRUCT simSetDataT &theSet;
	STRUCT simDataT &theSim;
	
	print "Prototype Plot Build functions called. "
end



//----------------------------------------------------------------------------------------------
//
// 		prototype function for set input variable value setup & calculation
//
//-----------------------------------------------
//
// this function returns status string

threadsafe function /S setInputSetupProto(setData, setEntries) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;

	variable Set_From =  setData.JParWave[2];
	variable Set_To =  setData.JParWave[3];
	variable Set_Steps =  setData.JParWave[4];
	setData.setValueClb = Set_From + p * (Set_To - Set_From) / (Set_Steps-1);
	
	return "This is a set setup template function. It should not be called directly. "
end

//-----------------------------------------------
//
// this function returns status string
threadsafe function /S groupInputSetupProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	variable Set_From =  setData.JParWave[2];
	variable Set_To =  setData.JParWave[3];
	variable Set_Steps =  setData.JParWave[4];
	setData.setValueClb = Set_From + p * (Set_To - Set_From) / (Set_Steps-1);
	
	return "This is a set setup template function. It should not be called directly. "
end


//-----------------------------------------------
//
// this function does not return a value

threadsafe function setInputAssignProto(setData, setEntries) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;

	// create copies of parametric waves that contain variable parameter; 
	// RWave must be duplicated for threaded cacluclation regardless of whether values are changed by the assignement 
	
	// most applicaitons will modify only one of these waves and only such wave need to be copied
	variable i;
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		duplicate /O setData.PWave $(tgtSimPath+"P")
		WAVE setEntries.sims[i].PWave = $(tgtSimPath+"P")
		duplicate /O setData.MWave $(tgtSimPath+"M")
		WAVE setEntries.sims[i].MWave = $(tgtSimPath+"M")
	endfor
end


//-----------------------------------------------
//
// this function does not return a value

threadsafe function groupInputAssignProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	// create copies of parametric waves that contain variable parameter; 
	// RWave must be duplicated for threaded cacluclation regardless of whether values are changed by the assignement 
	
	// most applicaitons will modify only one of these waves and only such wave need to be copied
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+groupEntries.sets[i].name
		duplicate /O setData.PWave $(tgtSimPath+"P")
		WAVE groupEntries.sets[i].PWave = $(tgtSimPath+"P")
		duplicate /O setData.CWave $(tgtSimPath+"C")
		WAVE groupEntries.sets[i].CWave = $(tgtSimPath+"C")
		duplicate /O setData.ERxnsW $(tgtSimPath+"ER")
		WAVE /WAVE groupEntries.sets[i].ERxnsW = $(tgtSimPath+"ER")
		duplicate /O setData.GRxnsW $(tgtSimPath+"GR")
		WAVE /WAVE groupEntries.sets[i].GRxnsW = $(tgtSimPath+"GR")
		duplicate /O setData.MWave $(tgtSimPath+"M")
		WAVE groupEntries.sets[i].MWave = $(tgtSimPath+"M")
	endfor
end

//----------------------------------------------------------------------------------------------
//
//			 prototype function for set input variable value assignment
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 

threadsafe function /S simInputAssignProto(setData, simData) 
	STRUCT simSetDataT &setData;
	STRUCT simDataT &simData;
	
	return "Prototype set input assign function called. "
end


//----------------------------------------------------------------------------------------------
//
// 		prototype function for set result wave setup 
//
//-----------------------------------------------
//
// this function does not return a value

function setResultSetupProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &groupEntries;

	Print "This is a set setup template function. It should not be called directly. "
end

//-----------------------------------------------
//

function groupResultSetupProto(setData, groupEntries) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;

	Print "This is a set setup template function. It should not be called directly. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for set result wave assignment
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 
threadsafe function setResultAssignProto(setData,simData) 
	STRUCT simSetDataT &setData;
	STRUCT simDataT &simData;

	print "Prototype set result assign functions called. "
end


//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 
threadsafe function groupResultAssignProto(groupData,setData) 
	STRUCT simSetDataT &groupData;
	STRUCT setDataT &setData;

	print "Prototype set result assign functions called. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for set result final steps
//	
//-----------------------------------------------
//
// this function returns information string that is printed in the history with other information 

function setResultCleanupProto(setData, setEntries, setResultWN) 
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	string setResultWN; // common name for the set....

	// only temp waves that were created in setInputSetupProto need to be deleted here
	variable i;
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		killwaves /Z $(tgtSimPath+"P"),  $(tgtSimPath+"C"),  $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M"), $(tgtSimPath+"RK4") //,  $(tgtSimPath+"M")
	endfor

	print "Prototype result cleanup functions called. "
end

//-----------------------------------------------
//

function groupResultCleanupProto(setData, groupEntries, setResultWN) 
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &groupEntries;
	string setResultWN; // common name for the set....

	// only temp waves that were created in setInputSetupProto need to be deleted here
	variable i;
	for (i=0; i< groupEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+groupEntries.sets[i].name
		killwaves /Z $(tgtSimPath+"P"),  $(tgtSimPath+"C"),  $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M")
	endfor

	print "Prototype result cleanup functions called. "
end


//----------------------------------------------------------------------------------------------
//
//			 prototype function for preparing data to plot in a set 
//	
//-----------------------------------------------
//
// this does not return a value 

function setPlotSetupProto(setData, plotNameS) 
	STRUCT simSetDataT &setData;
	string plotNameS // name of the plot/window

	// prepare a plot (or plots)  here to append results later
	print "Prototype Plot Setup functions called. "
end



//----------------------------------------------------------------------------------------------
//
//			 prototype function for appending data to plot in a set 
//	
//-----------------------------------------------
//
// this does not return a value 

function setPlotAppendProto(setData, setEntries, plotNameS, iteration)
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &setEntries;
	string plotNameS // name of the plot/window
	variable iteration // call # in this superset

	print "Prototype Plot Append functions called. "
end

//-----------------------------------------------
//
function groupPlotAppendProto(setData, setEntries, plotNameS, iteration)
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &setEntries;
	string plotNameS // name of the plot/window
	variable iteration // call # in this superset

	print "Prototype Plot Append functions called. "
end



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
//								  																					 //
//									Sets of simulations section												 //
//																													 //
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//



//-----------------------------------------------
// default prep of the simSet, called once; specific handing can be done after by template function
//
function simSetPrepData(jobListW, setData, entries, prefix, [justOne]) 
	wave /T jobListW;
	STRUCT simSetDataT &setData;
	STRUCT simSetDataArrT &entries;
	string prefix;
	variable justOne; 
	
	if (paramIsDefault(justOne))
		justOne = 0
	endif
	
	setData.commName =prefix+jobListW[0]; 	
	setData.text = ""; // initialize to avoid errors
	
	wave setData.JParWave = $jobListW[1];
	if (!waveexists(setData.JParWave))
		setData.text = "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 

	wave setData.MWave = $jobListW[2];
	if (!waveexists(setData.MWave))
		setData.text = "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 

	wave setData.PWave = $jobListW[3];
	if (!waveexists(setData.PWave))
		setData.text = "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 

	wave setData.CWave = $ jobListW[4];
	if (!waveexists(setData.CWave))
		setData.text = "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 

	wave /WAVE setData.ERxnsW = $ jobListW[5];
	wave /WAVE setData.GRxnsW = $ jobListW[6];

	setData.rootFldr = GetDataFolder(1);
	setData.dataFldr = setData.rootFldr +"SimData:"; 
	
	variable setLen;
	if (justOne) 
		setLen = 1; 
	else
		setLen =  setData.JParWave[4];
		if (setLen <= 1)
			setLen = 1;
			setData.JParWave[4] = 1;
		endif
	endif

	setData.BiDir = setData.PWave[1] ;
	if (setData.BiDir != 0 )
		setData.BiDir = 1;
		setData.PWave[1] = 1;
	endif 
	
	string setValueClbN = setData.rootFldr+setData.commName + "_SetClb";	
	make /N=(setLen) /O $setValueClbN
	wave setData.setValueClb = $setValueClbN
	

	NewDataFolder /O SimData 
	SetDataFolder $(setData.dataFldr) 
	
	variable i, s;
	for (i=0, s=0; i<setLen; s+=1, i +=  setData.BiDir ? 0.5 : 1)
		variable theDir = setData.BiDir *  (floor(i)==i ? 1 : -1); // 0 or integer 
		string fmtStr
		string thisSimName
		if (justOne)
			if (theDir > 0)
				thisSimName = setData.commName+"f"
			elseif (theDir < 0) 
				thisSimName = setData.commName+"r"
			else
				thisSimName = setData.commName
			endif
		else
			if (theDir > 0)
				fmtStr = "%s%02df"
			elseif (theDir < 0) 
				fmtStr = "%s%02dr"
			else
				fmtStr = "%s%02d"
			endif
			
			sprintf thisSimName fmtStr  setData.commName, i
		endif
		
		entries.sims[s].name=thisSimName;
		
		// default param waves; specific setup function can override these references
		wave entries.sims[s].PWave = setData.PWave;
		wave entries.sims[s].CWave = setData.CWave;
		wave entries.sims[s].ERxnsW = setData.ERxnsW;
		wave entries.sims[s].GRxnsW = setData.GRxnsW;
		wave entries.sims[s].MWave = setData.MWave;
		
		// is simW already prepared? Save it here...
		entries.sims[s].direction = theDir;
		entries.sims[s].index = s;
		entries.sims[s].group = floor(i);

		entries.sims[s].text = "";
		entries.sims[s].result = NaN;
	endfor
	
	entries.count = s;
	
	// zerp out the rest...
	for (i=s; i<maxSims; i+=1)
		entries.sims[i].name ="";
		entries.sims[i].text = "";
		entries.sims[i].result = NaN;
		entries.sims[i].index = i;
		entries.sims[i].group = -1;
	endfor
	
	setData.error = -1;
end


//-----------------------------------------------
//

function simSet_PrepMethods(setData, jobListW, simM, setM, simMode, offset, prefix, [justOne])
	STRUCT simSetDataT &setData;
	wave /T jobListW;
	STRUCT simMethodsT &simM;
	STRUCT setMethodsT &setM;
	variable simMode;
	string offset, prefix;
	variable justOne

	variable sysNThreads = ThreadProcessorCount
	
	if (paramIsDefault(justOne))
		justOne = 0;
	endif

	// single sim methods
	//
	variable tgtThreads = setData.PWave[0];
	if (numType(tgtThreads)!=0)
		tgtThreads = 1;
	endif	
	switch (tgtThreads)
		case 0: // no threads
		case 1:
			simM.simNThreads = 1;
			break;
		case -1: // max up to nComp
			simM.simNThreads = min (dimsize(setData.CWave, 1), sysNThreads);
			break;			
		default: // up to physical threads
			simM.simNThreads = min (tgtThreads, sysNThreads);
	endswitch 

	FUNCREF SimSetupProto simM.prepSimSpecificF = SimRateSetup; 
	FUNCREF SimRatesProto simM.theSimRatesF = SimRateVectors;
	
	FUNCREF simWSetupProto simM.theSimWSetupF = $(jobListW[7]); 
	if ( strlen(jobListW[7]))
		if (NumberByKey("ISPROTO", FuncRefInfo (simM.theSimWSetupF)))
			setM.text = "== Reference to function \""+(jobListW[7])+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimWSetup = 1;
	endif

	FUNCREF simWProcessProto simM.theSimWProcessF = $(jobListW[8]); 
	if ( strlen(jobListW[8]))
		if (NumberByKey("ISPROTO", FuncRefInfo (simM.theSimWProcessF)))
			setM.text = "== Reference to function \""+(jobListW[8])+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimWProcess = 1;
	endif

	FUNCREF simPlotBuildProto simM.theSimPlotBuildF = $(jobListW[9]); 
	if ( strlen(jobListW[9]))
		if (NumberByKey("ISPROTO", FuncRefInfo (simM.theSimPlotBuildF)))
			setM.text = "== Reference to function \""+(jobListW[9])+"\" has not been resolved! ==\r"
			return 1; 
		endif
		simM.doSimPlotBuild = 1;
	endif

	string simStr = "";
	if (simM.doSimWSetup || simM.doSimWProcess || simM.doSimPlotBuild)
		simStr += "\r"+offset+"Method";
		if (simM.doSimWSetup)
			simStr += " setup:"+jobListW[7]+",";
		endif
		if (simM.doSimWProcess)
			simStr += " process:"+jobListW[8]+",";
		endif
		if (simM.doSimPlotBuild)
			simStr += " plot:"+jobListW[9]+",";
		endif
	endif 


	// set of sims methods....
	setM.text = "";
	setM.offset = offset;
	
	tgtThreads = setData.JParWave[1];
	
	if (numType(tgtThreads)!=0 || simM.simNThreads > 1)
		tgtThreads = 1;
	endif	

	switch (tgtThreads)
		case 0: // no threads
		case 1:
			setM.setNThreads = 0;
			break;
		case -1: // max number up to nSims		
			setM.setNThreads = setData.JParWave[4]; // set steps
			break;
		default: // use one thread per cmp
			setM.setNThreads = tgtThreads;
	endswitch 
	setM.setNThreads = min (setM.setNThreads, sysNThreads);
	

	if (!justOne)
		FUNCREF setInputSetupProto setM.theSetInSetupF = $(jobListW[11]);  
		if ( strlen(jobListW[11]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetInSetupF)))
				setM.text = "== Reference to function \""+(jobListW[11])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetInSetup = 1;
		endif
	
		FUNCREF setInputAssignProto setM.theSetInAssignF = $(jobListW[12]);  
		if ( strlen(jobListW[12]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetInAssignF)))
				setM.text = "== Reference to function \""+(jobListW[12])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetInAssign = 1;
		endif

		FUNCREF setResultSetupProto setM.theSetResultSetupF = $(jobListW[13]); 
		if ( strlen(jobListW[13]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultSetupF)))
				setM.text = "== Reference to function \""+(jobListW[13])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutSetup = 1;
		endif

		FUNCREF setResultAssignProto setM.theSetResultAssignF = $(jobListW[14]); 
		if ( strlen(jobListW[14]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultAssignF)))
				setM.text = "== Reference to function \""+(jobListW[14])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutAssign = 1;
		endif

		FUNCREF setResultCleanupProto setM.theSetResultCleanupF = $(jobListW[15]); 
		if ( strlen(jobListW[15]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetResultCleanupF)))
				setM.text = "== Reference to function \""+(jobListW[15])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetOutCleanup = 1;
		endif

		FUNCREF setPlotSetupProto setM.theSetPlotSetupF = $(jobListW[16]); 
		if ( strlen(jobListW[16]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetPlotSetupF)))
				setM.text = "== Reference to function \""+(jobListW[16])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetPlotBuild = 1;
		endif

		FUNCREF setPlotAppendProto setM.theSetPlotAppendF = $(jobListW[17]);
		if ( strlen(jobListW[17]))
			if (NumberByKey("ISPROTO", FuncRefInfo (setM.theSetPlotAppendF)))
				setM.text = "== Reference to function \""+(jobListW[17])+"\" has not been resolved! ==\r"
				return 1; 
			endif
			setM.doSetPlotAppend = 1;
		endif

		switch (simMode)
			case 0:
				if (!simM.doSimWSetup)
					setM.text = "Function that should prepare sumulation wave is not specified. Cannot continue... :-("	
					setData.error=0;
					return -1
				endif
				sprintf  setM.text "\r%s~~~~~~~~~~~~~~~~~~ Kin-E-Set %s %s ~~~~~~~~~~~~~~~~~~\r", offset, cKESVer, prefix
				setM.modeName = "simulations";
				break;
			case 1:
				sprintf setM.text "%sProcessing a set from previous simulations ", offset
				setM.modeName = "processings"
				setM.doSetInSetup = 0;
				setM.doSetInAssign = 0;
				break;
			case 2:
				sprintf setM.text "%sAssmbly of a set from previous simulations ", offset;
				setM.doSetInSetup = 0;
				setM.doSetInAssign = 0;
				setM.doSetOutSetup = 0;
				setM.doSetOutAssign = 0;
				setM.doSetOutCleanup = 0;			
				break;
			case 3: // no re-processing
				return 0;
				break;
			default:
				sprintf setM.text"%sUknown flag %g! cannot continue", offset, simMode;
				return -1;
		endswitch
		string setStr = "";
		if (setM.doSetInSetup || setM.doSetInAssign)
			setStr += "\r"+offset+"Input";
			if (setM.doSetInSetup)
				setStr += " setup:"+jobListW[11]+",";
			endif
			if (setM.doSetInAssign)
				setStr += " assign:"+jobListW[12]+",";
			endif
		endif 
	
		if (setM.doSetOutSetup || setM.doSetOutAssign || setM.doSetOutCleanup)
			setStr += "\r"+offset+"Result: ";
			if (setM.doSetOutSetup)
				setStr += "setup:"+jobListW[13]+"; "
			endif 
			if (setM.doSetOutAssign)
				setStr +=  "assign:"+jobListW[14]+"; "
			endif
			if (setM.doSetOutCleanup)
				setStr +=  "cleanup:"+jobListW[15]+"; "
			endif
		endif
	
		if (setM.doSetPlotBuild || setM.doSetPlotAppend )
			setStr += "\r"+offset+"Plot: ";
			if (setM.doSetPlotBuild)
				setStr += "setup:"+jobListW[16]+"; "
			endif 
			if (setM.doSetPlotAppend)
				setStr +=  "append:"+jobListW[17]+"; "
			endif
		endif
		if (strlen(setStr) > 0) // there is a report
			setData.text = offset + setStr;	
		endif
		
	else // justOne
			switch (simMode)
			case 0:
				if (!simM.doSimWSetup)
					setM.text = "Function that should prepare sumulation wave is not specified. Cannot continue... :-("	
					setData.error=0;
					return -1
				endif
				sprintf  setM.text "\r%s~~~~~~~~~~~~~~~~~~ Kin-E-Sim %s %s ~~~~~~~~~~~~~~~~~~\r", offset, cKESVer, prefix
				setM.modeName = "simulations";
				break;
			case 1:
				sprintf setM.text "%sProcessing data from previous simulations ", offset
				setM.modeName = "processings"
				break;
			case 2:
				sprintf setM.text "%sAssmbly of data from previous simulations ", offset;
				break;
			case 3: // no re-processing
				return 0;
				break;
			default:
				sprintf setM.text"%sUknown flag %g! cannot continue", offset, simMode;
				return -1;
		endswitch
		setM.doSetInSetup = 0;
		setM.doSetInAssign = 0;
		setM.doSetOutSetup = 0;
		setM.doSetOutAssign = 0;
		setM.doSetOutCleanup = 0;
		setM.doSetPlotBuild = 0;
		setM.doSetPlotAppend = 0;
	endif 
	setData.text  += "\r"+offset+"Output folder: "+setData.rootFldr;
end


//---------------------------------------------------------------------------------
//  The follwing two functions are an example of implementing kinetic model;
//	 Another model may provide different versions

//---------------------------------------------- 
//  proto: SimSetupProto
//
threadsafe  function SimRateSetup(SWave, CWave, ERxnsW, GRxnsW, PWave,  simTmpData) 
	wave SWave, CWave, PWave
	wave /WAVE ERxnsW, GRxnsW
	STRUCT simTmpDataT &simTmpData;

	wave TWave = simTmpData.TWave 
	
	variable curr_E;
	variable mN = dimsize(CWave, 1);
	
	variable i, j;	
	variable F_RT = 38.94;
	
	for (i=0; i<mN ; i+=1)		
		variable total_C_i = CWave[0][i] + CWave[1][i];
		if (total_C_i <= 0)
			TWave[1,4][i]  = NaN; 
			TWave[11, 14][i]  = NaN; 
			TWave[26, 30][i] = NaN; 
			continue;
		endif 
		TWave[0][i] = total_C_i; 
		TWave[1][i]  = CWave[0][i]; 
		TWave[2,3][i] = 0; // surface concentration of oxidized component
		TWave[4][i]  = total_C_i - TWave[1][i]; 
		TWave[11, 14][i]  = 0; 
		
		variable do_surface; 
		if (CWave[4][i] > 0 && CWave[3][i] > 0) // there is electrchemistry
			TWave[21][i] = CWave[5][i] * CWave[3][i] * F_RT * 2; 
			if (CWave[8][i] > 0 && PWave[3] > 0) // there is a limit; any binding is ignored
				do_surface = 0;
			else // no rate limit, maybe binding
				if ((CWave[10][i] > 0) && (CWave[11][i] > 0)) // there is binding
					variable k_on = CWave[11][i]
					variable k_off = CWave[11][i] / CWave[10];
					TWave[28][i] = k_on;
					TWave[29][i] =k_off;
					TWave[27][i] =CWave[10] * PWave[10]; 
					do_surface = 1;
				else // no binding, no echem
					do_surface = 0;
				endif
				TWave[24,25][i] = 0 // no lmiting rates
			endif
		else // no echem!
			do_surface = 0;
			TWave[23, 29][i] = 0; 
		endif
		
		
		variable C_tot_adj 
		if (do_surface)
			C_tot_adj = (TWave[1][i] +TWave[2][i]+ TWave[3][i] + TWave[4][i]) / TWave[0][i];
			TWave[1,4][i] /=C_tot_adj
		else
			C_tot_adj = (TWave[1][i]+ TWave[4][i]) / TWave[0][i];
			TWave[1,4; 3][i] /=C_tot_adj
			TWave[2,3][i] = -1; // no bound fraction
			TWave[26, 30][i] = NaN; 
		endif
		
	endfor; 
end

//----------------------------------------------
//
function SimRateVectors(PWave, CWave, RWave, TWave, curr_E)
	wave PWave, CWave,  RWave, TWave
	variable curr_E;
	variable mN = dimsize(CWave, 1);
	variable i, j, k;	

	variable r0N = dimsize(RWave, 0);	// row
	variable r1N = dimsize(RWave, 1);	// col

	// normallize all populations to the total initial amount
	// this needs to be done before relative rates are calculated
	for (i=0; i<mN ; i+=1)		
		if (TWave[0][i] > 0)
			variable currCSol = TWave[1][i]+ TWave[4][i];
			variable currCEl  = TWave[2][i] + TWave[3][i];
			variable currCTot =  currCSol + currCEl;
			TWave[1,6][i] /= currCTot / TWave[0][i]; // solution fraction
		endif
	endfor
	
	// bimolecular rates
	for (i=0; i<r0N ; i+=1)		
		for (j=i+1; j<r1N ; j+=1)	// rates of reactions - this is reaction-specific!
			if (TWave[0][i]  > 0 && TWave[0][j]  > 0)
				RWave[i][j][3] = ((TWave[1][j]^CWave[3][i]) * (TWave[4][i]^CWave[3][j])*RWave[i][j][2]  -  (TWave[4][j]^CWave[3][i])  * (TWave[1][i]^CWave[3][j]) * RWave[i][j][1] ); 
				variable thisRate = RWave[i][j][3];
			else // [Analyte] or [this M] is zero, no reacion
				RWave[i][j][3] = 0;  
			endif
		endfor
	endfor

	// echem rates
	// Using RK method
			
	for (i=0; i<mN ; i+=1)		
		if (TWave[0][i]  > 0) // component is present in the solution
			// get latest  concentration of all forms of this component
			
			// get electrode rate
				variable M_E_dCdt = 0;

				variable k_on = TWave[28][i];
				variable k_off = TWave[29][i];
				variable C_ox_sol = TWave[1][i];
				variable C_rd_sol = TWave[4][i];
				variable C_ox_el = TWave[2][i];
				variable C_rd_el = TWave[3][i];
				variable K_ET_0; // + for reduced C, - for oxidized C
				
				if (k_on > 0 && k_off > 0) // binding does occur
					variable E_k0 = CWave[4][i];
					variable ET_rate = 0; // pure ET rate
					if (E_k0 > 0) // rate of the electrode reaction is set
						K_ET_0  = exp(TWave[21][i] * (curr_E - CWave[2][i])); // ET eq. constant
						TWave[23][i] = K_ET_0;
						variable k_ET_ox = E_k0 * K_ET_0; // forward
						variable k_ET_rd = E_k0 / K_ET_0; // reverse
						if (CWave[8][i] > 0 && PWave[3] > 0) // is rate limit set?
							// use  PWave[3]  to change how the lim is calculated
							variable rateLimInv = 1/CWave[8][i] ;
							k_ET_ox = 1/( rateLimInv + 1/k_ET_ox );
							k_ET_rd = 1/( rateLimInv + 1/k_ET_rd );
						endif 
						ET_rate = (TWave[2][i] * k_ET_rd -  TWave[3][i] * k_ET_ox);
					else
						TWave[23][i] = -1;
						K_ET_0 = 0;
					endif 

					// calculate binding rates for oxidized and reduced species
					variable sol_height = PWave[10]; 
					variable Bind_Ox_rate = C_ox_sol * k_on -  C_ox_el * k_off / sol_height; // net binding rate of the oxidized component
					variable Bind_Rd_rate = C_rd_sol * k_on -  C_rd_el * k_off / sol_height; // net binding rate of the reduced component
				else // k_on is zero or negative - no binding and no echem
					TWave[23][i] = -1;
					K_ET_0 = 0;
				endif

			// get all solution rates for this component
				variable C_soln_rate = 0; 
				for (j=0; j<i; j+=1)
					C_soln_rate += (CWave[3][j] / CWave[3][i]) * RWave[j][i][3];
				endfor
				for (j=i+1; j<r1N; j+=1)
					C_soln_rate -= (CWave[3][i] / CWave[3][j]) * RWave[i][j][3]; 
				endfor

			// total change in concentration of this component
			TWave[38][i] = C_soln_rate; 
			TWave[39][i] = Bind_Ox_rate; 
			TWave[40][i] = Bind_Rd_rate; 
			TWave[41][i] = ET_rate; 
			
			TWave[7][i]  = -C_soln_rate - Bind_Ox_rate; 
			TWave[8][i]  = -ET_rate + Bind_Ox_rate; 
			TWave[9][i]  = +C_soln_rate - Bind_Rd_rate; 
			TWave[10][i]  = +ET_rate + Bind_Rd_rate; 
			
			variable Kb_th = TWave[27][i];
			variable Ctot_sys =  C_ox_sol + C_rd_sol + C_ox_el + C_rd_el;
			variable C_Rd_sol_eq, C_Rd_el_eq,  C_Ox_el_eq, C_Ox_sol_eq

			
			if (Kb_th > 0 && K_ET_0 > 0 &&  Ctot_sys > 0)
				C_Rd_sol_eq = Ctot_sys/(1 + Kb_th + K_ET_0 + Kb_th*K_ET_0);
				C_Rd_el_eq = C_Rd_sol_eq * Kb_th;
				C_Ox_el_eq = C_Rd_el_eq * K_ET_0;
				C_Ox_sol_eq  = C_Ox_el_eq / Kb_th;  
			else
				C_Rd_sol_eq  = Inf;
				C_Rd_el_eq = Inf;
				C_Ox_el_eq = Inf;
				C_Ox_sol_eq = Inf;
			endif
							
			TWave[34][i]  = C_Ox_sol_eq
			TWave[35][i] = C_Ox_el_eq
			TWave[36][i] = C_Rd_el_eq
			TWave[37][i]  = C_Rd_sol_eq
			
		else 
			TWave[34,37][i] = inf; 
			TWave[38,41][i] = 0; 
			TWave[7,10][i] = 0;
		endif
	endfor	
end
//------------------------- end of kinetic model implementaion -------------------------



//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// this function illustrates calculation of a set simulation varying potential of the mediator
// Simulations are saved in individual files with incrementing suffix
// All simulations use same parameters wave, which should exist - use single manual execution to prepare and verify it;
// All simulations are integrated into individual summary waves per settings in the parameters wave
// Integrated profiles of  oxidized analyte are saved to JobWave, where each column corresponds to different potential  		
// 	 Set_From initial set param value
// 	 Set_To final set param value; ingnored if number of steps is less than 2
// 	 Set_Steps number of values to vary parameter over

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function Set_MedEChem(jobListW, [prefix, offset, hostPrg, doSingle] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT SetProgDataT &hostPrg;
	variable doSingle;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif

	if (paramIsDefault(hostPrg))
		variable noPrg = 1
	endif

	if (paramIsDefault(doSingle))
		doSingle = 0;
	endif
	
	
	STRUCT simSetDataT setData;

	// prepare data structures
	STRUCT simSetDataArrT setEntries;
	simSetPrepData(jobListW, setData, setEntries, prefix, justOne = doSingle); 

	// prepare method strcutures
	STRUCT simMethodsT simM;
	STRUCT setMethodsT setM;
	if (simSet_PrepMethods(setData, jobListW, simM, setM, setData.JParWave[0], offset, prefix,  justOne = doSingle) < 0)
		return -1; // there was a problem
	endif
	
	variable i, j  
	for (i=0 ; i<setEntries.count; i+=1)
		setEntries.sims[i].text = prefix;
	endfor 

	if (setM.doSetInSetup && !doSingle)
		string outStr = setM.theSetInSetupF(setData, setEntries) 
		if (strlen(outStr) >0)
			setData.text += "\r"+offset+outStr;
		endif;
	endif;
	
	// duplicate CWave and RWaves
	for (i=0; i< setEntries.count; i+=1)
		string tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		duplicate /O setData.CWave $(tgtSimPath+"C")
		WAVE setEntries.sims[i].CWave = $(tgtSimPath+"C")
	endfor


	if (setM.doSetInAssign && !doSingle)
		setM.theSetInAssignF(setData, setEntries) 
	endif;
	
	if (setM.doSetOutSetup && !doSingle)
		setM.theSetResultSetupF(setData, setEntries) 
	endif;
	
	Variable setSimStartTime = DateTime
	
	string thisSimName; 
	
	if (setM.setNThreads > 1) // parallel MT sims 
		if (noPrg)
			simSet_FullSimPrl(setData, setEntries, simM, setM)
		else
			simSet_FullSimPrl(setData, setEntries, simM, setM, hostPrg=hostPrg)
		endif
	else // sequential sims 
		if (noPrg)
			simSet_FullSimSeq(setData, setEntries, simM, setM)
		else
			simSet_FullSimSeq(setData, setEntries, simM, setM, hostPrg=hostPrg)
		endif 
	endif 

	// Simulation is done, clean up and process results
	for (i=setEntries.count; i<99; i+=1) // clean up unused waves //Set_Steps
		sprintf thisSimName "%s%02d" setData.commName, i
		string killListS = wavelist(thisSimName+"_*", ";","") 
		string killNameS;
		j = 0
		do
			killNameS= StringFromList(j,killListS)
			if( strlen(killNameS) == 0 )
				break
			endif
			killwaves /Z 	$killNameS;
			j += 1
		while (1)	// exit is via break statement
		// killwaves /Z 	$(thisSimName), $(thisSimName+"_i"), $(thisSimName+"f"), $(thisSimName+"f_i"),$(thisSimName+"r"), $(thisSimName+"r_i")			
	endfor
		
	SetDataFolder $setData.rootFldr

	variable setSimEndTime = DateTime;
		
	// print output
	if (noPrg)
		print offset, setM.text
	endif 
	print setData.text;
	for (i=0; i < setEntries.count; i+=1)
		print offset, setEntries.sims[i].text;
	endfor

	string BiDirS = "";
	if (setData.BiDir)
		BiDirS = "x2 ";
	endif;
	
	Printf "%sTotal time: %0.2fs for %s%d %s", offset , (setSimEndTime - setSimStartTime), BiDirS, setEntries.count, setM.modeName;
	
	// Plot the results after simulation is complete
	// this is non-thread safe operation
	
	if (simM.doSimPlotBuild) // individual plots for each sim
		for (i=0; i < setEntries.count; i+=1)
			simM.theSimPlotBuildF(setData.commName, setEntries.sims[i], setData) 
		endfor
	endif

	string gizmoN = prefix+setData.commName+"Set";
	if (setM.doSetPlotBuild && !doSingle)
		setM.theSetPlotSetupF(setData, gizmoN); //, MWave,  JParWave, setValueClb);
	endif

	if (setM.doSetPlotAppend  && !doSingle)
		for (i=0; i < setEntries.count; i+=1)
			setM.theSetPlotAppendF(setData, setEntries, gizmoN, i); 
		endfor
	endif 

	
	
	// cleanup C and R waves!
	for (i=0; i< setEntries.count; i+=1)
		tgtSimPath = setData.dataFldr+setEntries.sims[i].name
		killwaves /Z $(tgtSimPath+"P"),   $(tgtSimPath+"ER"), $(tgtSimPath+"GR"), $(tgtSimPath+"M"), $(tgtSimPath+"RK4")
	endfor

	if (setM.doSetOutCleanup && !doSingle)
		setM.theSetResultCleanupF(setData, setEntries,  setData.rootFldr+setData.commName)
	endif

	variable setProcessEndTime = DateTime
	
	printf "\r%sProcessing time: %.2f sec", offset, (setProcessEndTime - setSimEndTime);
	printf "\r%s#\r",offset 
end


//-----------------------------------------------
//

function /S childWCopy(theWName, oldSetName, newSetName, tgtPath, thisSetW, index)
			string theWName
			string oldSetName;
			string newSetName;
			
			string tgtPath;
			wave /T thisSetW;
			variable index;

			string thisRWN =newSetName+ReplaceString(oldSetName, theWName, "");
			string thisRWP=tgtPath+thisRWN
			duplicate /O  $theWName $thisRWP
			if (index >=0)
				thisSetW[index] = thisRWN;
			endif;
			return thisRWP
		end






//-----------------------------------------------
// not being used

function SetProgressUpdate_DELME(OWave)
	wave OWave;
	
	STRUCT WMWinHookStruct s;
	
	s.eventCode = 23;
	s.winname="mySetProgress"
	MySetHook(s);

end



//-----------------------------------------------
//
// not currently being used
//
Function AbortTheSimProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			NVAR kill_sim 
			kill_sim = 1;
			print "Killed #2"
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
















//-----------------------------------------------
//

function simGroupPrepData(jobListW, setData, entries, prefix, sizeField, waveSuffix, FolderFmtStr) 
	wave /T jobListW;
	STRUCT simSetDataT &setData;
	STRUCT setSetDataArrT &entries;
	string prefix;
	variable sizeField  // in JParWave 
	string waveSuffix
	string FolderFmtStr
	
	
	setData.commName = jobListW[0];
	wave setData.JParWave = $jobListW[1];
	if (!waveexists(setData.JParWave))
		setData.text = "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 

	wave setData.MWave = $jobListW[2];
	if (!waveexists(setData.MWave))
		setData.text = "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 

	wave setData.PWave = $jobListW[3];
	if (!waveexists(setData.PWave))
		setData.text = "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 

	wave setData.CWave = $ jobListW[4];
	if (!waveexists(setData.CWave))
		setData.text = "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 

	wave /WAVE setData.ERxnsW = $ jobListW[5];
	wave /WAVE setData.GRxnsW = $ jobListW[6];
	
	variable setLen;
	if (dimsize(setData.JParWave, 0) < (sizeField+1)) 
		setLen = 1;
	elseif (setData.JParWave[sizeField] <=0)
		setData.JParWave[sizeField] = 1;
		setLen = 1
	else 
		setLen = setData.JParWave[sizeField];
	endif 
	
	setData.rootFldr = GetDataFolder(1);
	setData.dataFldr = ""; 

	string setValueClbN = setData.rootFldr+prefix+setData.commName + "_"+waveSuffix+"Clb";	
	make /N=(setLen) /O $setValueClbN
	wave setData.setValueClb = $setValueClbN
	
	variable s;
	for (s=0; s < setLen; s+=1)
		string thisFldrName
		sprintf thisFldrName FolderFmtStr,  s
		entries.sets[s].name=thisFldrName; 
		string thisPrefix = prefix + thisFldrName;
		
		NewDataFolder /O $thisFldrName
		string tgtPath = setData.rootFldr + thisFldrName+":";
		entries.sets[s].folder= tgtPath;

		wave /T setJobListW = $(childWCopy(nameofwave(jobListW), prefix, thisPrefix, tgtPath, $"", -1)); 
		wave /T entries.sets[s].JListWave = setJobListW

		// default param waves; specific setup function can override these references
		wave entries.sets[s].JParWave = $(childWCopy(nameofwave(setData.JParWave), prefix, thisPrefix, tgtPath, setJobListW, 1));
		wave entries.sets[s].MWave = $(childWCopy(nameofwave(setData.MWave), prefix, thisPrefix, tgtPath, setJobListW, 2));
		wave entries.sets[s].PWave = $(childWCopy(nameofwave(setData.PWave), prefix, thisPrefix, tgtPath, setJobListW, 3)); 
		wave entries.sets[s].CWave = $(childWCopy(nameofwave(setData.CWave), prefix, thisPrefix, tgtPath, setJobListW, 4)); 
		wave entries.sets[s].ERxnsW = $(childWCopy(nameofwave(setData.ERxnsW),prefix, thisPrefix, tgtPath, setJobListW, 5)); 
		wave entries.sets[s].GRxnsW = $(childWCopy(nameofwave(setData.GRxnsW),prefix, thisPrefix, tgtPath, setJobListW, 6)); 
		
		entries.sets[s].index = s;
		entries.sets[s].text = "";
		entries.sets[s].result = NaN;
	endfor
	
	entries.count = s;
	
	// zero out the rest...
	for (s=setLen; s<maxSims; s+=1)
		entries.sets[s].name ="";
		entries.sets[s].folder ="";
		entries.sets[s].text = "";
		entries.sets[s].result = NaN;
		entries.sets[s].index = NaN;
	endfor
	
	setData.error = -1;
	return 0
end





//------------------------------------------------------------------------------------
//
//

function prepGroupMethods(grMethods, jobListW, paramOffset)
	STRUCT groupMethodsT &grMethods;
	wave /T jobListW;
	variable paramOffset;
	
	grMethods.theGroupInSetupFN = jobListW[paramOffset+0];
	FUNCREF groupInputSetupProto grMethods.theGroupInSetupF = $(grMethods.theGroupInSetupFN);
	if ( strlen(grMethods.theGroupInSetupFN))
		if (NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupInSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupInSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupInSetup = 1;
	endif
	
	grMethods.theGroupInAssignFN = jobListW[paramOffset+1];
	FUNCREF groupInputAssignProto grMethods.theGroupInAssignF = $(grMethods.theGroupInAssignFN);
	if ( strlen(grMethods.theGroupInAssignFN) )
		if (NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupInAssignF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupInAssignFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupInAssign = 1;
	endif

	
	grMethods.theGroupResultSetupFN = jobListW[paramOffset+2];
	FUNCREF groupResultSetupProto grMethods.theGroupResultSetupF = $grMethods.theGroupResultSetupFN;
	if ( strlen(grMethods.theGroupResultSetupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutSetup = 1;
	endif


	grMethods.theGroupResultAssignFN = jobListW[paramOffset+3];
	FUNCREF groupResultAssignProto grMethods.theGroupResultAssignF = $grMethods.theGroupResultAssignFN;
	if ( strlen(grMethods.theGroupResultAssignFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultAssignF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultAssignFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutAssign = 1;
	endif


	grMethods.theGroupResultCleanupFN = jobListW[paramOffset+4];
	FUNCREF groupResultCleanupProto grMethods.theGroupResultCleanupF = $grMethods.theGroupResultCleanupFN;
	if ( strlen(grMethods.theGroupResultCleanupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupResultCleanupF)))
			grMethods.text += "== Reference to function \""+grMethods.theGroupResultCleanupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupOutCleanup = 1;
	endif


	grMethods.theSetPlotSetupFN  = jobListW[paramOffset+5];
	FUNCREF setPlotSetupProto grMethods.theGroupPlotSetupF = $grMethods.theSetPlotSetupFN;
	if ( strlen(grMethods.theSetPlotSetupFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupPlotSetupF)))
			grMethods.text += "== Reference to function \""+grMethods.theSetPlotSetupFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupPlotBuild = 1;
	endif

	grMethods.theSetPlotAppendFN = jobListW[paramOffset+6];
	FUNCREF groupPlotAppendProto grMethods.theGroupPlotAppendF = $grMethods.theSetPlotAppendFN;
	if ( strlen(grMethods.theSetPlotAppendFN)  )
		if ( NumberByKey("ISPROTO", FuncRefInfo (grMethods.theGroupPlotAppendF)))
			grMethods.text += "== Reference to function \""+grMethods.theSetPlotAppendFN+"\" has not been resolved! ==\r"
			return 1; 
		endif
		grMethods.doGroupPlotAppend = 1;
	endif
end


//------------------------------------------------------------------------------------
//
//
function reportGroupMethods(grMethods, setData,  grName, offset, prefix )
	STRUCT groupMethodsT &grMethods;
	STRUCT simSetDataT &setData;
	string grName, offset, prefix;

	grMethods.text = "";
	switch (setData.JParWave[0]) // mode of sim
		case 0:
		case 1: 				
			grMethods.text += offset+ "~~~~~~~~~~~~~~~~~~~~~~ "+grName+"Set "+prefix+" full model ~~~~~~~~~~~~~~~~~~~~~~"
			if (grMethods.doGroupInSetup || grMethods.doGroupInAssign)
				grMethods.text +=  "\r"+offset+"Input "
				if (grMethods.doGroupInSetup)
					grMethods.text +=  "setup:"+ grMethods.theGroupInSetupFN+";";
				endif
				if (grMethods.doGroupInAssign)
					grMethods.text +=  " assign "+ grMethods.theGroupInAssignFN+";"
				endif
			endif
			
			break;
		case 2: 				
			string tmpStr;
			sprintf tmpStr, "Set patial model, mode %d", (setData.JParWave[0])
			grMethods.text +=  offset+grName+tmpStr
			break;
		case 3: 				
			grMethods.text +=  offset+grName+"Set re-plotting"
			break;
		default:
	endswitch		


	if (grMethods.doGroupOutSetup || grMethods.doGroupOutAssign || grMethods.doGroupOutCleanup)
		grMethods.text +=  "\r"+offset+"Result ";
		if (grMethods.doGroupOutSetup)
			grMethods.text +=  "setup: "+ grMethods.theGroupResultSetupFN+";";
		endif 
		if (grMethods.doGroupOutAssign)
			grMethods.text +=  "assign: "+ grMethods.theGroupResultAssignFN+";";
		endif
		if (grMethods.doGroupOutCleanup)
			grMethods.text +=  "cleanup: "+ grMethods.theGroupResultCleanupFN+";";
		endif
	endif
	
	if (grMethods.doGroupPlotBuild || grMethods.doGroupPlotAppend)
		grMethods.text +=   "\r"+offset+"Plot "
		if (grMethods.doGroupPlotBuild)
			grMethods.text +=  " setup:"+ grMethods.theSetPlotSetupFN+";";
		endif 
		if (grMethods.doGroupPlotAppend)
			grMethods.text +=  " append:"+ grMethods.theSetPlotAppendFN+";";
		endif
	endif

end 


//------------------------------------------------------------------------------------
//
//
function Kilo_MedEChem05(jobListW, [prefix, offset, hostPrg] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KiloProgDataT &hostPrg;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif
	
	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT KiloProgDataT locPrg;
		defaultKiloPrg(locPrg, 0, 0, "")
		return Kilo_MedEChem05Prg(jobListW, prefix, offset,   locPrg);
	else // progress dialog is hosted
		defaultKiloPrg(hostPrg, 1, 0, "")
		return Kilo_MedEChem05Prg(jobListW, prefix, offset,  hostPrg);
	endif
end

//-----------------------------------------------
//

function Kilo_MedEChem05Prg(jobListW, prefix, offset,  hostPrg)
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT KiloProgDataT &hostPrg;

	if (!waveexists(jobListW))
		printf "%sJob wave (%s) was not found...\r", offset, nameofwave(jobListW);
		return 1;
	endif

	// this struct must be initialized!
	STRUCT simSetDataT setData;
	STRUCT setSetDataArrT setEntries;
	if (simGroupPrepData(jobListW, setData, setEntries, prefix, 12, "Kilo", "K%02d"))
		print offset+setData.text+"\r"
		return 1;
	endif; 
	
	STRUCT groupMethodsT grMethods;
	if (prepGroupMethods(grMethods, jobListW, 20)) 
		print offset + grMethods.text+"\r";
		return 1;
	endif

	reportGroupMethods(grMethods, setData,  "Kilo", offset, prefix );

	if (grMethods.doGroupInSetup)
		grMethods.text += "\r"+offset+ grMethods.theGroupInSetupF(setData, setEntries);
	endif
	if (grMethods.doGroupInAssign)
		grMethods.theGroupInAssignF(setData, setEntries);
	endif
	
	if (grMethods.doGroupOutSetup)
		grMethods.theGroupResultSetupF(setData, setEntries)
	endif 
	
	string plotName = prefix+setData.commName+"Kilo"+"Set";
	if (grMethods.doGroupPlotBuild)
		grMethods.theGroupPlotSetupF(setData, plotName) 
	endif 

	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r"
	printf grMethods.text+"\r";

	hostPrg.set_sets = setEntries.count;
	hostPrg.set_curr_set_out = 0;
	KiloProgressStart(hostPrg); 
	
	variable i;
	for (i=0; i < setEntries.count; i+=1)
		SetDataFolder  $(setEntries.sets[i].folder);

		switch (setEntries.sets[i].JParWave[0]) // mode of sim
			case 0:
			case 1: 				
				printf "%s~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r", offset
				printf "%sSet:%s\r",  offset, setEntries.sets[i].name
				printf "%s%s\r",  offset, setEntries.sets[i].text
				break;
			default:
		endswitch		
		Set_MedEChem(setEntries.sets[i].JListWave, prefix=setEntries.sets[i].name, offset=offset+"\t", hostPrg = hostPrg);

		if (grMethods.doGroupOutAssign)
			grMethods.theGroupResultAssignF(setData, setEntries.sets[i]) 
		endif
		if (grMethods.doGroupPlotAppend)
			grMethods.theGroupPlotAppendF(setData, setEntries, plotName,  i);
		endif
		// restore folder
		SetDataFolder $setData.rootFldr
		hostPrg.set_curr_set_out  = i+1;
		doKiloProgressUpdate(hostPrg)
	endfor
	KiloProgressStop(hostPrg);	

	if (grMethods.doGroupOutCleanup)
		grMethods.theGroupResultCleanupF(setData, setEntries, setData.rootFldr+setData.commName);
	endif
end


//------------------------------------------------------------------------------------
//
//
function Mega_MedEChem05(jobListW, [prefix, offset, hostPrg] )
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT MegaProgDataT &hostPrg;
	
	if (paramIsDefault(prefix))
		prefix = "";
	endif
	if (paramIsDefault(offset))
		offset = "";
	endif
	
	if (paramIsDefault(hostPrg)) // no host is supplied
		STRUCT MegaProgDataT locPrg;
		defaultMegaPrg(locPrg, 0, 0, "")
		return Mega_MedEChem05Prg(jobListW, prefix, offset,   locPrg);
	else // progress dialog is hosted
		defaultMegaPrg(hostPrg, 1, 0, "")
		return Mega_MedEChem05Prg(jobListW, prefix, offset,  hostPrg);
	endif
end

//-----------------------------------------------
//

function Mega_MedEChem05Prg(jobListW, prefix, offset,  hostPrg)
	wave /T jobListW;
	string prefix;
	string offset; 
	STRUCT MegaProgDataT &hostPrg;
	
	if (!waveexists(jobListW))
		printf "%sJob wave (%s) was not found...\r", offset, nameofwave(jobListW);
		return 1;
	endif

	// this struct must be initialized!
	STRUCT simSetDataT setData;
	STRUCT setSetDataArrT setEntries;
	if (simGroupPrepData(jobListW, setData, setEntries, prefix, 21, "Mega", "M%02d"))
		print offset+setData.text+"\r"
		return 1;
	endif; 
	
	STRUCT groupMethodsT grMethods;
	if (prepGroupMethods(grMethods, jobListW, 29)) 
		// report error
		print offset + grMethods.text+"\r";
		return 1;
	endif

	reportGroupMethods(grMethods, setData,  "Mega", offset, prefix );

	
	if (grMethods.doGroupInSetup)
		print "\r"+offset+ grMethods.theGroupInSetupF(setData, setEntries)
	endif
	if (grMethods.doGroupInAssign)
		grMethods.theGroupInAssignF(setData, setEntries);
	endif
	
	if (grMethods.doGroupOutSetup)
		grMethods.theGroupResultSetupF(setData, setEntries)
	endif 
	
	string plotName = prefix+setData.commName+"Mega"+"Set";
	if (grMethods.doGroupPlotBuild)
		grMethods.theGroupPlotSetupF(setData, plotName) 
	endif 

	
	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	print "\r"+offset+"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
	printf grMethods.text+"\r";

	hostPrg.kilo_sets = setEntries.count;
	hostPrg.kilo_curr_set_out = 0;
	MegaProgressStart(hostPrg); 

	String currFldr= GetDataFolder(1)
	variable i;
	for (i=0; i<setEntries.count; i+=1)
		SetDataFolder  $(setEntries.sets[i].folder);
	
		switch (setEntries.sets[i].JParWave[0]) // mode of sim
			case 0:
			case 1: 				
				printf "%s~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r",offset
				printf "%sSet:%s \r",   offset, setEntries.sets[i].name
				printf "%s%s\r",  offset, setEntries.sets[i].text
				break;
			default:
		endswitch			
		
		Kilo_MedEChem05(setEntries.sets[i].JListWave, prefix = setEntries.sets[i].name, offset = offset+"\t", hostPrg = hostPrg);
		
		if (grMethods.doGroupOutAssign)
			grMethods.theGroupResultAssignF(setData, setEntries.sets[i]) 
		endif
		if (grMethods.doGroupPlotAppend)
			grMethods.theGroupPlotAppendF(setData, setEntries, PlotName,  i);
		endif

		// restore folder
		SetDataFolder $currFldr
		hostPrg.kilo_curr_set_out  = i+1;
		doMegaProgressUpdate(hostPrg)
	endfor
	MegaProgressStop(hostPrg);	

	if (grMethods.doGroupOutCleanup)
		grMethods.theGroupResultCleanupF(setData, setEntries, currFldr+setData.commName);
	endif

end





//-----------------------------------------------
//
function defaultKiloPrg(thePrg, hosted, len, wName)
	STRUCT KiloProgDataT &thePrg;
	variable hosted;
	variable len;
	string wName; // only if not hosted!

	thePrg.set_sets = len;
	thePrg.set_curr_set_out = 0;
	thePrg.set_last_update = -1;
	thePrg.hosted = hosted ? 1: 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.set.wName = wName;
		else
			thePrg.set.wName = "myKiloProgress";
		endif			
	endif
end

//-----------------------------------------------
//
function defaultMegaPrg(thePrg, hosted, len, wName)
	STRUCT MegaProgDataT &thePrg;
	variable hosted;
	variable len;
	string wName; // only if not hosted!

	thePrg.kilo_sets = len;
	thePrg.kilo_curr_set_out = 0;
	thePrg.kilo_last_update = -1;
	thePrg.hosted = hosted ? 1: 0;
	if (!thePrg.hosted)
		if (strlen(wName)>0)
			thePrg.kilo.set.wName = wName;
		else
			thePrg.kilo.set.wName = "myKiloProgress";
		endif			
	endif
end


//------------------------------------------------------------------------------------
//
//
function KiloProgressSetup(prg)
	STRUCT KiloProgDataT &prg;

	ValDisplay kiloSetDone, win=$prg.set.wName, pos={20+prg.x,5+prg.y}, size={200,14},title="   kilo set", limits={0,prg.set_sets,0},barmisc={0,40},mode= 3
	ValDisplay kiloSetDone, win=$prg.set.wName,  value= _NUM:prg.set_curr_set_out;
	
	SetVariable kiloETA, win=$prg.set.wName,  value= _STR:"-pending 1st set-",noedit= 1, pos={230+prg.x, 4+prg.y},size={175,16},title="ETA",frame=0
	
	prg.set.x = prg.x+0;
	prg.set.y = prg.y+18;
	
end 


//-----------------------------------------------
//

function KiloProgressStart(prg) 
	STRUCT KiloProgDataT &prg;
	
	prg.set_last_update  = -1;
	prg.set_start_time = DateTime;
	prg.set_stop_time = -1;

	if (prg.hosted) // name is set, use as sub-pane;
		return KiloProgressSetup(prg);
	endif 		
	if (strlen(prg.set.wName) == 0)
		prg.set.wName = "myKiloProgress";
	endif
	prg.x = 0;
	prg.y=0;
	NewPanel/FLT /N=$prg.set.wName /W=(285,111,739,200) as "Simulating a Kilo..."
	KiloProgressSetup(prg);
	DoUpdate/W=$prg.set.wName/E=1 // mark this as our progress window
	SetWindow $prg.set.wName, hook(spinner)=MySetHook
End

//-----------------------------------------------
//

function doKiloProgressUpdate(prg) 
	STRUCT KiloProgDataT &prg;

	if (prg.set_curr_set_out > 0 )
		variable now = DateTime;
		variable elapsed_time = (now - prg.set_start_time);

		variable newTime =((prg.set_sets - prg.set_curr_set_out) / prg.set_curr_set_out)*elapsed_time;
		string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
		SetVariable kiloETA  value=_STR:ETAStr, win=$prg.set.wName
	else
		// not known...
	endif;
	
	ValDisplay kiloSetDone, win=$prg.set.wName, value= _NUM:prg.set_curr_set_out

	return doSetProgressUpdate(prg.set) 
end



//-----------------------------------------------
//

Function KiloProgressStop(prg)
	STRUCT KiloProgDataT &prg;
	
	prg.set_stop_time = DateTime;
	SetProgressStop(prg.set);
	if (!prg.hosted)
		KiloProgressCleanup(prg);
	endif;	
End

//-----------------------------------------------
//

Function KiloProgressCleanup(prg)
	STRUCT KiloProgDataT &prg;

	SetProgressCleanup(prg.set);
End



//------------------------------------------------------------------------------------
//

function MegaProgressSetup(prg)
	STRUCT MegaProgDataT &prg;
	
	ValDisplay megaSetDone, win=$prg.kilo.set.wName, pos={20,5},size={200,14},title="mega set", limits={0,prg.kilo_sets,0},barmisc={0,40},mode= 3
	ValDisplay megaSetDone, win=$prg.kilo.set.wName,  value= _NUM:0
	SetVariable megaETA, win=$prg.kilo.set.wName, pos={230,4},size={175,16},title="ETA",frame=0, value= _STR:"-pending 1st kilo-",noedit= 1

	prg.kilo.x = prg.x+0;
	prg.kilo.y = prg.y+18;
end 

//-----------------------------------------------
//
function MegaProgressStart(prg) 
	STRUCT MegaProgDataT &prg;

	prg.kilo_last_update  = -1;
	prg.kilo_start_time = DateTime;
	prg.kilo_stop_time = -1;

	if (prg.hosted) // name is set, use as sub-pane;
		return MegaProgressSetup(prg);
	endif
	if (strlen(prg.kilo.set.wName) == 0)
		prg.kilo.set.wName = "myMegaProgress";
	endif
	prg.x = 0;
	prg.y=0;
	NewPanel/FLT /N=$prg.kilo.set.wName /W=(285,111,739,220) as "Simulating a Mega..."
	MegaProgressSetup(prg);
	DoUpdate/W=$prg.kilo.set.wName/E=1 // mark this as our progress window
	SetWindow $prg.kilo.set.wName, hook(spinner)=MySetHook
End


//-----------------------------------------------
//

function doMegaProgressUpdate(prg) 
	STRUCT MegaProgDataT &prg;

	if (prg.kilo_curr_set_out > 0 )
		variable now = DateTime;
		variable elapsed_time = (now - prg.kilo_start_time);

		variable newTime =((prg.kilo_sets - prg.kilo_curr_set_out) / prg.kilo_curr_set_out)*elapsed_time;
		string ETAStr = Secs2Time(newTime,5)+" ("+Secs2Time(now+newTime, 0)+")";
		SetVariable megaETA  value=_STR:ETAStr, win=$prg.kilo.set.wName
	else
		// not known...
	endif;
	
	ValDisplay megaSetDone, win=$prg.kilo.set.wName, value= _NUM:prg.kilo_curr_set_out

	return doKiloProgressUpdate(prg.kilo) 
end

//-----------------------------------------------
//

Function MegaProgressStop(prg)
	STRUCT MegaProgDataT &prg;
	
	prg.kilo_stop_time = DateTime;
	KiloProgressStop(prg.kilo);
	if (!prg.hosted)
		MegaProgressCleanup(prg);
	endif;	
End

//-----------------------------------------------
//
//
Function MegaProgressCleanup(prg)
	STRUCT MegaProgDataT &prg;
	KiloProgressCleanup(prg.kilo);
End




Menu "Analysis"
	Submenu "Kin-E-Sim"
		"Control Panel", /Q, KinESimCtrl ()
		"Copy set", /Q, simCopyMenu();
		"Stop all threads", /Q, simStopThreads();
		"Unload", /Q, UnloadKES()
	end
end

Function UnloadKES()
	if (WinType("KinESimCtrl") == 7)
		DoWindow/K KinESimCtrl
	endif
	Execute/P "COMPILEPROCEDURES "
end


Window KinESimCtrl() : Panel
	if (WinType("KinESimCtrl") == 7)
		DoWindow/F KinESimCtrl
		return
	endif
	
	variable v;
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(0,0,1188,510) as "Kin-E-Sim control panel"
	ModifyPanel fixedSize=1
	ShowTools/A
	Button InfoButton,pos={4,6},size={20,20},proc=KESInfoProc,title="\\K(0,12800,52224)\\f03\\F'Times'i"
	Button InfoButton,help={"About current version of analysis."},fSize=20
	Button InfoButton,fColor=(65535,65535,65535)
	Button simReload,pos={25,6},size={20,20},proc=simReloadProc,title="\\F'Wingdings 3'P"
	Button simReload,help={"Read and re-interpret content of the job wave. This overries all other settigns. Same as selecting the same wave job again."}
	Button makeCtrlTbl,pos={5,31},size={64,19},proc=makeCtrlTableProc,title="ctrl. table"

	PopupMenu jobListWSelect,pos={50,5},size={167,21},bodyWidth=150,proc=jobListWProc,title="job"
	PopupMenu jobListWSelect,help={"This is the main job wave, which contains the list of options. This wave is updated when options on this dialog are changed. Manual changes to this wave outside of this panel are not reflected automatically."}
	PopupMenu jobListWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:1\")"

	PopupMenu jobParamWSelect,pos={231,5},size={187,21},bodyWidth=150,proc=jobParamWProc,title="sets =>"
	PopupMenu jobParamWSelect,help={"Numeric parameters of the job, including individual, kilo- and mega- sets."}
	PopupMenu jobParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"

	SetVariable jobFlagsEdit,pos={135,33},size={71,16},bodyWidth=45,proc=setJobFlagsEditProc,title="flags"
	SetVariable jobFlagsEdit,help={"Miscellenious flags that appy to entire simulaiton."}
	SetVariable jobFlagsEdit,limits={-inf,inf,0},value= _STR:"-"
	
	PopupMenu esimParamWSelect,pos={229,31},size={189,21},bodyWidth=150,proc=esimParamWProc,title="esim =>"
	PopupMenu esimParamWSelect,help={"Electrochemical parameters of the simulaiton. These values are found under \"simulation\" section."}
	PopupMenu esimParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"
	
	NewPanel/W=(425,0,975,90)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=0
	SetDrawLayer UserBack
	TitleBox simTitle,pos={0,0},size={96,14},title="simulation"
	TitleBox simTitle,help={"Electrochemical parameters of the sumulation."},frame=0
	TitleBox simTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC

	v=16;
	PopupMenu simWPrepFSelect,pos={40,v   },size={174,21},bodyWidth=150,proc=simWPrepFProc,title="prep"
	PopupMenu simWPrepFSelect,help={"Method that defines the waveform for electrochemical process; called before the sim to set up sim wave; required. This method should use parameters in \"Method settings\" section."}
	PopupMenu simWPrepFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simWSetupProto\" )"
	PopupMenu simWProcFSelect,pos={24,v+24},size={190,21},bodyWidth=150,proc=simWProcFProc,title="process"
	PopupMenu simWProcFSelect,help={"Method that processes results of individual sim after it is finsihed."}
	PopupMenu simWProcFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simWProcessProto\" )"
	PopupMenu simPlotBuildFSelect,pos={44,v+48},size={170,21},bodyWidth=150,proc=simPlotBuildFProc,title="plot"
	PopupMenu simPlotBuildFSelect,help={"Method that builds a plot to display desults of individual sim. Beware of large number fo plots that can be build in kilo- and mega-sets."}
	PopupMenu simPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"simPlotBuildProto\" )"
	

	SetVariable simCommName,pos={234,v},size={116,16},bodyWidth=60,proc=simBaseNameEditProc,title="base name"
	SetVariable simCommName,help={"Base name of the simulation wave. Names of all output waves will start with this name. "}
	SetVariable simCommName,limits={1,inf,1},value= _STR:""
	SetVariable simNThrds,pos={236,v+24},size={109,16},bodyWidth=45,proc=simNThreadsEditProc,title="CPU threads"
	SetVariable simNThrds,help={"Number of threads to use in single sim. Any value other than 1 causes simulation set to be run sequentially in favor of sim multithreading."}
	SetVariable simNThrds,limits={1,inf,1},value= _STR:"-"
	Button simDoIt,pos={235,v+48},size={110,20},proc=simDoIt,title="do this sim"
	Button simDoIt,help={"Start individual simulation, either undi- or bi-direftional as selected. "}
	Button simDoIt,fStyle=1

	SetVariable simLayerThick,pos={364,v},size={88,16},bodyWidth=45,proc=simLayerThicknessEditProc,title="rel. layer"
	SetVariable simLayerThick,help={"Relative thickness of the solution per unit of volume. A 1L volume is 100x100x100 mm and a x0.01 layer is 1mm thick."}
	SetVariable simLayerThick,limits={0,inf,0},value= _STR:"-"
	PopupMenu simIsBiDir,pos={461,v},size={47,21},proc=simIsBiDirEditProc,title="Bi-dir"
	PopupMenu simIsBiDir,help={"Generate two simulations - in forward and reverse directions. Each particular prep function may interpret this flag differently.This option may override initial concentrations of components when set to Pool."}
	PopupMenu simIsBiDir,mode=2147483647,popvalue="",value= #"\"No;Yes;Pool\""
	PopupMenu simETRateMode,pos={369,v+24},size={165,21},bodyWidth=100,proc=simETRateModePopupProc,title="ET rate vs. E"
	PopupMenu simETRateMode,help={"Method for calculating effective rates of ET at imposed potential by either holding forward or reverse rate constant ot changing both rates equally."}
	PopupMenu simETRateMode,mode=2147483647,popvalue="",value= #"\"fix oxidation;symmetrical;fix reduction\""
	PopupMenu simLimRateMode,pos={373,v+48},size={161,21},bodyWidth=120,proc=simLimRateModePiopupProc,title="rate limit"
	PopupMenu simLimRateMode,help={"Mode of limiting the rate of electrochemical reaction. Any option other than none causes the sim to ignore lectrode binding.  "}
	PopupMenu simLimRateMode,mode=2147483647,popvalue="",value= #"\"no limit (full);limit both;lim, correct both;lim. fast, corr. slow; balanced corr.\""
	RenameWindow #,Sim
	SetActiveSubwindow ##
	
	
	NewPanel/W=(0,60,420,175)/FG=(FL,,,)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrTitle,pos={1,1},size={96,14},title=" integrator "
	TitleBox intgrTitle,help={"Integrator panel specifies the integration method for the system of differential equations that describe the reaction."}
	TitleBox intgrTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC

	NewPanel/W=(7,15,125,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrSolTitle,pos={1,1},size={116,14},title="RK limits in solution"
	TitleBox intgrSolTitle,help={"Limiting conditions for solution equilibria."},frame=0
	TitleBox intgrSolTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKiDrop,pos={19,16},size={87,16},bodyWidth=45,proc=simRKiDropMaxSol,title="i-th drop"
	SetVariable RKiDrop,help={"Maximal relative drop of population over any RK order."}
	SetVariable RKiDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKiRise,pos={24,35},size={82,16},bodyWidth=45,proc=simRKiRiseMaxSol,title="i-th rise"
	SetVariable RKiRise,help={"Maximal relative rise of population over any RK order."}
	SetVariable RKiRise,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullDrop,pos={13,54},size={93,16},bodyWidth=45,proc=simRKFullDropMaxSol,title="step drop"
	SetVariable RKFullDrop,help={"Maximal relative drop of population over the entire sim step."}
	SetVariable RKFullDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullRise,pos={18,73},size={88,16},bodyWidth=45,proc=simRKFullRiseMaxSol,title="step rise"
	SetVariable RKFullRise,help={"Maximal relative rise of population over the entire sim step."}
	SetVariable RKFullRise,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKSol
	SetActiveSubwindow ##
	NewPanel/W=(125,15,245,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrElclTitle,pos={1,1},size={118,14},title="RK limits on electr."
	TitleBox intgrElclTitle,help={"Limiting conditions for electrode equilibria."},frame=0
	TitleBox intgrElclTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKiDrop,pos={19,16},size={87,16},bodyWidth=45,proc=simRKiDropMaxElec,title="i-th drop"
	SetVariable RKiDrop,help={"Maximal relative drop of population over any RK order."}
	SetVariable RKiDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKiRise,pos={24,35},size={82,16},bodyWidth=45,proc=simRKiRiseMaxElec,title="i-th rise"
	SetVariable RKiRise,help={"Maximal relative rise of population over any RK order."}
	SetVariable RKiRise,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullDrop,pos={13,54},size={93,16},bodyWidth=45,proc=simRKFullDropMaxElec,title="step drop"
	SetVariable RKFullDrop,help={"Maximal relative drop of population over the entire sim step."}
	SetVariable RKFullDrop,limits={0,inf,0},value= _STR:"-"
	SetVariable RKFullRise,pos={18,73},size={88,16},bodyWidth=45,proc=simRKFullRiseMaxElec,title="step rise"
	SetVariable RKFullRise,help={"Maximal relative rise of population over the entire sim step."}
	SetVariable RKFullRise,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKElec
	SetActiveSubwindow ##
	NewPanel/W=(245,15,415,110)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox intgrTimeTitle,pos={1,1},size={168,14},title="RK timing changes"
	TitleBox intgrTimeTitle,help={"Handling of simulation timing on limiting conditions and step advance."}
	TitleBox intgrTimeTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(32768,32768,32768), fColor=(65535,65535,65535), anchor=MC
	SetVariable RKTimeDropX,pos={22,16},size={137,16},bodyWidth=45,proc=simRKTimeDropX,title="mult. on drop limit"
	SetVariable RKTimeDropX,help={"Reduciton of the simulation step on the population drop limit."}
	SetVariable RKTimeDropX,limits={0,inf,0},value= _STR:"-"
	SetVariable RKTimeDropOver,pos={12,35},size={147,16},bodyWidth=45,proc=simRKTimeDropOver,title="rollback on drop"
	SetVariable RKTimeDropOver,help={"Additional rollback of simulation step on limiting conditions."}
	SetVariable RKTimeDropOver,limits={0,inf,0},value= _STR:"-"
	SetVariable RKTimeRiseX,pos={27,54},size={132,16},bodyWidth=45,proc=simRKTimeRiseX,title="mult. on rise limit"
	SetVariable RKTimeRiseX,help={"Reduciton of the simulation step on the population rise limit."}
	SetVariable RKTimeRiseX,limits={0,inf,0},value= _STR:"-"
	SetVariable RKTimeNextX,pos={35,73},size={124,16},bodyWidth=45,proc=simRKTimeNextX,title="mult. next step"
	SetVariable RKTimeNextX,help={"Initial change in the duration of the subsequent step."}
	SetVariable RKTimeNextX,limits={0,inf,0},value= _STR:"-"
	RenameWindow #,RKComm
	SetActiveSubwindow ##
	RenameWindow #,Integr
	SetActiveSubwindow ##
	
	NewPanel/W=(425,92,975,185)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox compTitle,pos={1,1},size={128,14},title=" Components "
	TitleBox compTitle,help={"Properies of chemical components for the simulation."}
	TitleBox compTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	PopupMenu compParamWSelect,pos={10,v},size={165,21},bodyWidth=150,proc=compParamWProc,title="=>"
	PopupMenu compParamWSelect,help={"Selection of wave describing components and their properties."}
	PopupMenu compParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:2,TEXT:0,WAVE:0\")"
	Button addCmpBtn,pos={178,v+2},size={36,17},proc=addCmpProc,title="+ C#"
	Button addCmpBtn,help={"Add a component."}
	Button delCmpBtn,pos={214,v+2},size={36,17},proc=delCmpProc,title="- C#"
	Button delCmpBtn,help={"Delete current component."}
	
	PopupMenu cmpSelect,pos={12,v+25},size={52,21},proc=cmpSelectProc,title="C #"
	PopupMenu cmpSelect,help={"Currently selected component, whose properties are displayed."}
	PopupMenu cmpSelect,mode=1,popvalue="-",value= #"\"-\""
	SetVariable cmpName,pos={65,v+23},size={95,20},bodyWidth=95,proc=cmpNameEditProc
	SetVariable cmpName,help={"Literal name of this component."},fSize=14,fStyle=1
	SetVariable cmpName,limits={1,inf,1},value= _STR:"-"
	SetVariable cmpFlags,pos={165,v+25},size={56,16},bodyWidth=30,proc=compFlagsEditProc,title="flags"
	SetVariable cmpFlags,help={"Simulation-depended flags for his component, such as whether it should be analyzed further. "}
	SetVariable cmpFlags,limits={0,inf,0},value= _STR:"-"
	
	PopupMenu cmpAliasThisState,pos={10,v+48},size={93,21},bodyWidth=50,proc=cmpAliasThisStateProc,title="alias this"
	PopupMenu cmpAliasThisState,help={"Enable aliasing for one of the redox states of current component."}
	PopupMenu cmpAliasThisState,mode=1,popvalue="none",value= #"cmpAliasThisState()"
	PopupMenu cmpAliasThatCmp,pos={115,v+48},size={124,21},bodyWidth=95,disable=0,proc=cmpAliasThatSelectProc,title="to C#"
	PopupMenu cmpAliasThatCmp,help={"Identify another comonent which is an alias to currently selected component."}
	PopupMenu cmpAliasThatCmp,mode=1,value= #"\"\""
	PopupMenu cmpAliasThatState,pos={242,v+48},size={45,21},bodyWidth=45,disable=0,proc=cmpAliasThatStateProc
	PopupMenu cmpAliasThatState,help={"The redox state of the alias component."}
	PopupMenu cmpAliasThatState,mode=1,popvalue="ox.",value= #"cmpAliasThatState()"

	
	SetVariable intOx,pos={261,v},size={79,16},bodyWidth=55,proc=compInitOxEditProc,title="[ox.]"
	SetVariable intOx,help={"Initial concentration of the oxidzed form of this component."}
	SetVariable intOx,limits={0,inf,0},value= _STR:"-"
	SetVariable intRd,pos={263,v+24},size={77,16},bodyWidth=55,proc=compInitRdEditProc,title="[rd.]"
	SetVariable intRd,help={"Initial concentration of the reduced form of this component."}
	SetVariable intRd,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpE,pos={354,v},size={62,16},bodyWidth=45,proc=compE0EditProc,title="E0"
	SetVariable cmpE,help={"Standard reduction potential of this component."}
	SetVariable cmpE,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpN,pos={428,v},size={40,16},bodyWidth=30,proc=compNEditProc,title="n"
	SetVariable cmpN,help={"The number of electrons required for reduction/oxidation of this component. No electrochemistry (solution or electrode) is considered if it is zero."}
	SetVariable cmpN,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpA,pos={480,v},size={60,16},bodyWidth=30,proc=compAlphaEditProc,title="alpha"
	SetVariable cmpA,help={"Charge transfer coefficient for this component; No electrode chemistry is considered if it is zero."}
	SetVariable cmpA,limits={0,inf,0},value= _STR:"-"
	SetVariable cmp_k0,pos={348,v+24},size={84,16},bodyWidth=45,proc=compET_kEditProc,title="ET rate"
	SetVariable cmp_k0,help={"The rate of reduction/oxidation on the electrode at standard potential. Must be >0 for electrode chemistry to be considered."}
	SetVariable cmp_k0,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpLim_k,pos={335,v+48},size={85,16},bodyWidth=45,proc=compLimRateEditProc,title="lim. rate"
	SetVariable cmpLim_k,help={"The limiting rate of the electrode reaction.  Must be >0 and rate limit mode msut be set to use fast simulation. Overrides electrode binding."}
	SetVariable cmpLim_k,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpBindK,pos={447,v+24},size={93,16},bodyWidth=45,proc=compBindKEditProc,title="binding K"
	SetVariable cmpBindK,help={"Equilibrium constant for component binding to the electrode. Must be >0  to consider electrode chemistry."}
	SetVariable cmpBindK,limits={0,inf,0},value= _STR:"-"
	SetVariable cmpOnRate,pos={436,v+48},size={104,16},bodyWidth=45,proc=compBindRateEditProc,title="binding rate"
	SetVariable cmpOnRate,help={"The rate of binding of component to the electrode. Must be >0  to consider electrode chemistry."}
	SetVariable cmpOnRate,limits={0,inf,0},value= _STR:"-"

	
	RenameWindow #,Comp
	SetActiveSubwindow ##
	NewPanel/W=(0,187,485,317)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox rxnsTitle,pos={1,1},size={128,14},title="General reactions"
	TitleBox rxnsTitle,help={"Description of general chemical equilibria in the solution. These reactions are defined by equilibrium constants. "}
	TitleBox rxnsTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	Button InfoButton,pos={3,v},size={18,18},proc=makeGRxnWaveProc,title="\\W560"
	Button InfoButton,help={"Create a new reactions set, which includes two shared waves (summary and thermodynamics wave) and a single empty stiochiometry wave. "}
	Button InfoButton,fSize=10,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu gRxnsParamWSelect,pos={24,v},size={165,21},bodyWidth=150,proc=gRxnsParamWProc,title="=>"
	PopupMenu gRxnsParamWSelect,help={"Selection of wave describing general reactions. This is a wave of wave references; first entry is the wave with a list of rates & Ks, other - wave with reaciton stoichiometires."}
	PopupMenu gRxnsParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,WAVE:1\")"
	
	TitleBox tableInfo,pos={190,v+2},size={11,13},title=" i "
	TitleBox tableInfo,help={"Stoichiometry table: identify reactant (left) and product (right) components and number of equivalents of their reduced and oxidized forms involved in the reaction. Any section with amounts of Ox and Rd set at 0 is ignored."}
	TitleBox tableInfo,labelBack=(0,0,0),frame=0,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu rxnSelect,pos={5,v+24},size={55,21},proc=gRxnSelectProc,title="Rx#"
	PopupMenu rxnSelect,help={"Currently selected reaction, whose properties are displayed."}
	PopupMenu rxnSelect, mode=1,popvalue="-",value= #"\"-\""

	SetVariable rxnName,pos={70,v+22},size={90,16},bodyWidth=90,proc=rxnNameEditProc
	SetVariable rxnName,help={"Literal name of this reaction."}
	SetVariable rxnName,limits={1,inf,1},value= _STR:"-"

	SetVariable rxnWaveName,pos={55,v+44},size={105,21},bodyWidth=90,disable=2,title="w:"
	SetVariable rxnWaveName,help={"Name of wave for selected reaction."},fSize=12
	SetVariable rxnWaveName,limits={1,inf,1},value= _STR:"-"

	SetVariable tdWaveName,pos={75,v+66},size={120,16},bodyWidth=90,disable=2,title="thermo w"
	SetVariable tdWaveName,help={"Name of wave for thermodynamic parameters for all reactions."}
	SetVariable tdWaveName,fSize=12,limits={1,inf,1},value= _STR:"-",noedit= 1

	SetVariable rxn_K_eq,pos={54,v+88},size={63,16},bodyWidth=40,proc=gRxnKeqEditProc,title="Keq"
	SetVariable rxn_K_eq,help={"Equilibrium constant for this reaction."}
	SetVariable rxn_K_eq,limits={0,inf,0},value= _STR:"-"
	SetVariable rxn_k_fwd,pos={125,v+88},size={73,16},bodyWidth=40,proc=gRxnkfwdEditProc,title="k(fwd)"
	SetVariable rxn_k_fwd,help={"Forward rate for this reaction. Rate order is determined by the reaction stoichiometry. "}
	SetVariable rxn_k_fwd,limits={0,inf,0},value= _STR:"-"
	
	Button addRxnRowBtn,pos={164,v+22},size={36,18},proc=addRxnRowProc,title="+row"
	Button addRxnRowBtn,help={"Add row to this reaction."}
	Button delRxnRowBtn,pos={164,v+44},size={36,18},proc=delRxnRowProc,title="-row"
	Button delRxnRowBtn,help={"Delete current row in this reaction."}

	Button addRxnBtn,pos={5,v+48},size={35,20},proc=addGRxnProc,title="+ Rx"
	Button addRxnBtn,help={"Add a reaction."}
	Button delRxnBtn,pos={5,v+70},size={35,20},proc=delGRxnProc,title="- Rx"
	Button delRxnBtn,help={"Delet this reaction."}


	Edit/W=(200,5,475,120)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xED
	ModifyTable statsArea=34
	ModifyTable horizontalIndex=2
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,GRxns
	
	SetActiveSubwindow ##
	NewPanel/W=(490,187,975,317)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox eRxnsTitle,pos={1,1},size={128,14},title="E-chem reactions"
	TitleBox eRxnsTitle,help={"Description of electrochemical equilibria in the solution. These reactions are defined by E0 and n of components. "}
	TitleBox eRxnsTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	Button InfoButton,pos={3,v},size={18,18},proc=makeERxnWaveProc,title="\\W560"
	Button InfoButton,help={"Create a new reactions set, which includes two shared waves (summary and thermodynamics wave) and a single empty stiochiometry wave. "}
	Button InfoButton,fSize=10,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu eRxnsParamWSelect,pos={24,v},size={165,21},bodyWidth=150,proc=eRxnsParamWProc,title="=>"
	PopupMenu eRxnsParamWSelect,help={"Selection of wave describing echeml reactions. This is a wave of wave references; first entry is the wave with a list of rates, other - wave with reaciton stoichiometires."}
	PopupMenu eRxnsParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,WAVE:1\")"
	
	TitleBox tableInfo,pos={190,v+2},size={11,13},title=" i "
	TitleBox tableInfo,help={"Stoichiometry table: identify reactant (left) and product (right) components and number of equivalents of their reduced and oxidized forms involved in the reaction. Any section with amounts of Ox and Rd set at 0 is ignored."}
	TitleBox tableInfo,labelBack=(0,0,0),frame=0,fStyle=1,fColor=(65535,65535,65535)

	PopupMenu rxnSelect,pos={5,v+24},size={55,21},proc=eRxnSelectProc,title="Rx#"
	PopupMenu rxnSelect,help={"Currently selected reaction, whose properties are displayed."}
	PopupMenu rxnSelect,mode=1,popvalue="-",value= #"\"-\""

	SetVariable rxnName,pos={70,v+22},size={90,21},bodyWidth=90,proc=eRxnNameEditProc
	SetVariable rxnName,help={"Literal name of this reaction."}
	SetVariable rxnName,limits={1,inf,1},value= _STR:"-"

	SetVariable rxnWaveName,pos={55,v+44},size={105,16},bodyWidth=90,disable=2,title="w:"
	SetVariable rxnWaveName,help={"Name of wave for selected reaction."},fSize=12
	SetVariable rxnWaveName,limits={1,inf,1},value= _STR:"-",noedit= 1

	SetVariable tdWaveName,pos={75,v+66},size={120,16},bodyWidth=90,disable=2,title="thermo w"
	SetVariable tdWaveName,help={"Name of wave for thermodynamic parameters for all reactions."}
	SetVariable tdWaveName,fSize=12,limits={1,inf,1},value= _STR:"-",noedit= 1


	SetVariable rxn_K_eq,pos={54,v+88},size={63,16},bodyWidth=40,disable=2,title="Keq"
	SetVariable rxn_K_eq,help={"Equilibrium constant for this reaction. This a read-only value for electrochemical reactions, which is calculated and updated during sim from E0 and n of components."}
	SetVariable rxn_K_eq,limits={0,inf,0},value= _STR:"-"
	SetVariable rxn_k_fwd,pos={125,v+88},size={73,16},bodyWidth=40,proc=eRxnkfwdEditProc,title="k(fwd)"
	SetVariable rxn_k_fwd,help={"Forward rate for this reaction. Rate order is determined by the reaction stoichiometry."}
	SetVariable rxn_k_fwd,limits={0,inf,0},value= _STR:"-"

	Button addRxnRowBtn,pos={164,v+22},size={36,18},proc=addRxnRowProc,title="+row"
	Button addRxnRowBtn,help={"Add row to this reaction."}
	Button delRxnRowBtn,pos={164,v+44},size={36,18},proc=delRxnRowProc,title="-row"
	Button delRxnRowBtn,help={"Delete current row in this reaction."}
	Button addRxnBtn,pos={5,v+48},size={35,20},proc=addERxnProc,title="+ Rx"
	Button addRxnBtn,help={"Add a reaction."}
	Button delRxnBtn,pos={5,v+70},size={35,20},proc=delERxnProc,title="- Rx"
	Button delRxnBtn,help={"Delet this reaction."}

	Edit/W=(200,5,475,120)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xED
	ModifyTable statsArea=34
	ModifyTable horizontalIndex=2
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,ERxns
	SetActiveSubwindow ##
	
	
	NewPanel/W=(975,0,1185,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox methodTitle,pos={1,1},size={120,14},title="Method settings"
	TitleBox methodTitle,help={"Section describing parameters of a particular method. "}
	TitleBox methodTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu methodParamWSelect,pos={28,16},size={165,21},bodyWidth=150,proc=methodParamWProc,title="=>"
	PopupMenu methodParamWSelect,help={"Numerical wave describing inividual method parameters. Use row dimension labels to idenitify the meaning of parameters. Any user function have access to them, but the number and meaning of parameters is not managed."}
	PopupMenu methodParamWSelect,mode=1,popvalue="-",value= #"\"-;\"+wavelist(\"*\", \";\",\"DIMS:1,TEXT:0,WAVE:0\")"
	Edit/W=(5,39,205,503)/HOST=# 
	ModifyTable format=1,width=20
	ModifyTable showParts=0xE9
	ModifyTable statsArea=85
	RenameWindow #,Tbl
	SetActiveSubwindow ##
	RenameWindow #,Method
	SetActiveSubwindow ##
	
	
	NewPanel/W=(0,320,325,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox setTitle,pos={1,1},size={64,14},title=" sim. set "
	TitleBox setTitle,help={"Parameters of a 1D set of simulaitons."},frame=0
	TitleBox setTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	v=16
	PopupMenu setInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=setInSetupFProc,title="in setup"
	PopupMenu setInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu setInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setInputSetupProto\" )"
	PopupMenu setInAssignFSelect,pos={17,v+24},size={194,21},bodyWidth=150,proc=setInAssignFProc,title="in assign"
	PopupMenu setInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu setInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setInputAssignProto\" )"
	PopupMenu setOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=setOutSetupFProc,title="out setup"
	PopupMenu setOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu setOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu setOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=setOutAssignFProc,title="out assign"
	PopupMenu setOutAssignFSelect,help={"Method that processes and saves results of individual simulations in this set."}
	PopupMenu setOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultAssignProto\" )"
	PopupMenu setOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=setOutCleanupFProc,title="cleanup"
	PopupMenu setOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu setOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultCleanupProto\" )"
	PopupMenu setPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=setPlotSetupFProc,title="plot setup"
	PopupMenu setPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu setPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu setPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=setPlotAppendFProc,title="append"
	PopupMenu setPlotAppendFSelect,help={"Method that appends results of an individual simulation to this set's plot."}
	PopupMenu setPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotAppendProto\" )"
	SetVariable setFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=setFromEditProc,title="from"
	SetVariable setFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable setFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable setToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=setToEditProc,title="to"
	SetVariable setToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable setToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable setStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=setStepsEditProc,title="steps"
	SetVariable setStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable setStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable setVarCmpNo,pos={228,v+61},size={86,16},bodyWidth=45,proc=setVarCmpNoEditProc,title="vary C#"
	SetVariable setVarCmpNo,help={"Optional set parameter #1."},value= _STR:"-"
	SetVariable setPlotCmpNo,pos={231,v+81},size={83,16},bodyWidth=45,proc=setPlotCmpNoEditProc,title="plot C#"
	SetVariable setPlotCmpNo,help={"Optional set parameter #2."},value= _STR:"-"
	SetVariable setNThrds,pos={225,v+122},size={89,16},bodyWidth=45,proc=setNThreadsEditProc,title="CPU thr."
	SetVariable setNThrds,help={"Number of threads to use for this set. This value is effective only if individual simulations are performed in a single-threaded mode."}
	SetVariable setNThrds,limits={1,inf,1},value= _STR:"-"
	Button setDoIt,pos={220,v+142},size={90,22},proc=setDoIt,title="do single set"
	Button setDoIt,help={"Start a set of individual simulations. "},fStyle=1
	RenameWindow #,Set
	SetActiveSubwindow ##
	NewPanel/W=(325,320,650,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox kiloTitle,pos={1,1},size={64,13},title=" kilo set "
	TitleBox kiloTitle,help={"Parameters of a 2D kilo-set of simulaitons."},frame=0
	TitleBox kiloTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu kiloInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=kiloInSetupFProc,title="in setup"
	PopupMenu kiloInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu kiloInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputSetupProto\" )"
	PopupMenu kiloInAssignFSelect,pos={16,v+24},size={194,21},bodyWidth=150,proc=kiloInAssignFProc,title="in assign"
	PopupMenu kiloInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu kiloInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputAssignProto\" )"
	PopupMenu kiloOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=kiloOutSetupFProc,title="out setup"
	PopupMenu kiloOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu kiloOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu kiloOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=kiloOutAssignFProc,title="out assign"
	PopupMenu kiloOutAssignFSelect,help={"Method that processes and saves results of individual sets in this kilo-set."}
	PopupMenu kiloOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultAssignProto\" )"
	PopupMenu kiloOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=kiloOutCleanupFProc,title="cleanup"
	PopupMenu kiloOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu kiloOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultCleanupProto\" )"
	PopupMenu kiloPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=kiloPlotSetupFProc,title="plot setup"
	PopupMenu kiloPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu kiloPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu kiloPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=kiloPlotAppendFProc,title="append"
	PopupMenu kiloPlotAppendFSelect,help={"Method that appends results of an individual set to this kilo-set's plot"}
	PopupMenu kiloPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupPlotAppendProto\" )"
	SetVariable kiloFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=kiloFromEditProc,title="from"
	SetVariable kiloFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable kiloFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=kiloToEditProc,title="to"
	SetVariable kiloToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable kiloToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=kiloStepsEditProc,title="steps"
	SetVariable kiloStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable kiloStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable kiloParam1Edit,pos={226,v+61},size={87,16},bodyWidth=45,proc=kiloParam1EditProc,title="param 1"
	SetVariable kiloParam1Edit,help={"Optional set parameter #1."}
	SetVariable kiloParam1Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloParam2Edit,pos={226,v+81},size={87,16},bodyWidth=45,proc=kiloParam2EditProc,title="param 2"
	SetVariable kiloParam2Edit,help={"Optional set parameter #2."}
	SetVariable kiloParam2Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable kiloFlagsEdit,pos={242,v+101},size={71,16},bodyWidth=45,proc=kiloFlagsEditProc,title="flags"
	SetVariable kiloFlagsEdit,help={"Simulation-depended flags for his set. The meaning of this flag varies between slelected setup and processing functions."}
	SetVariable kiloFlagsEdit,limits={1,inf,1},value= _STR:"-"
	Button kiloDoIt,pos={220,v+142},size={90,22},proc=kiloDoIt,title="do kilo set"
	Button kiloDoIt,help={"Start a kilo-set of simulation sets. "},fStyle=1
	RenameWindow #,Kilo
	SetActiveSubwindow ##
	NewPanel/W=(650,320,975,510)/HOST=# 
	ModifyPanel frameStyle=1, frameInset=1
	TitleBox megaTitle,pos={0,0},size={64,13},title=" mega set "
	TitleBox megaTitle,help={"Parameters of a 3D mega-set of simulaitons."},frame=0
	TitleBox megaTitle,frame=0,fstyle=1,fixedSize=1,labelBack=(24576,24576,24576), fColor=(65535,65535,65535), anchor=MC
	PopupMenu megaInSetupFSelect,pos={20,v},size={190,21},bodyWidth=150,proc=megaInSetupFProc,title="in setup"
	PopupMenu megaInSetupFSelect,help={"Method that defines the dependent variable  in this set and creates set calibration."}
	PopupMenu megaInSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputSetupProto\" )"
	PopupMenu megaInAssignFSelect,pos={16,v+24},size={194,21},bodyWidth=150,proc=megaInAssignFProc,title="in assign"
	PopupMenu megaInAssignFSelect,help={"Method that assigned dependent variable in this set. Any assignement must be done on a copy of common wave, as per examples."}
	PopupMenu megaInAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupInputAssignProto\" )"
	PopupMenu megaOutSetupFSelect,pos={14,v+48},size={197,21},bodyWidth=150,proc=megaOutSetupFProc,title="out setup"
	PopupMenu megaOutSetupFSelect,help={"Method that prepares output data for  this set."}
	PopupMenu megaOutSetupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setResultSetupProto\" )"
	PopupMenu megaOutAssignFSelect,pos={10,v+72},size={201,21},bodyWidth=150,proc=megaOutAssignFProc,title="out assign"
	PopupMenu megaOutAssignFSelect,help={"Method that processes and saves results of individual kilo-sets in this mega-set."}
	PopupMenu megaOutAssignFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultAssignProto\" )"
	PopupMenu megaOutCleanupFSelect,pos={20,v+96},size={191,21},bodyWidth=150,proc=megaOutCleanupFProc,title="cleanup"
	PopupMenu megaOutCleanupFSelect,help={"Method that perforns final processing and cleanup for this set."}
	PopupMenu megaOutCleanupFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupResultCleanupProto\" )"
	PopupMenu megaPlotBuildFSelect,pos={12,v+120},size={199,21},bodyWidth=150,proc=megaPlotSetupFProc,title="plot setup"
	PopupMenu megaPlotBuildFSelect,help={"Method that prepares a plot to display individual or summary results for this set."}
	PopupMenu megaPlotBuildFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"setPlotSetupProto\" )"
	PopupMenu megaPlotAppendFSelect,pos={22,v+144},size={189,21},bodyWidth=150,proc=megaPlotAppendFProc,title="append"
	PopupMenu megaPlotAppendFSelect,help={"Method that appends results of an individual kilo-set to this mega-set's plot"}
	PopupMenu megaPlotAppendFSelect,mode=1,popvalue="-none-",value= #"funcSelByProto(\"groupPlotAppendProto\" )"
	SetVariable megaFromEdit,pos={245,v-10},size={69,16},bodyWidth=45,proc=megaFromEditProc,title="from"
	SetVariable megaFromEdit,help={"The low limit of independent variable value for this set."}
	SetVariable megaFromEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaToEdit,pos={256,v+10},size={58,16},bodyWidth=45,proc=megaToEditProc,title="to"
	SetVariable megaToEdit,help={"The high limit of independent variable value for this set."}
	SetVariable megaToEdit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaStepsEdit,pos={240,v+30},size={74,16},bodyWidth=45,proc=megaStepsEditProc,title="steps"
	SetVariable megaStepsEdit,help={"The the number of descrete steps in the independent variable value for this set, including both low and high values."}
	SetVariable megaStepsEdit,limits={1,inf,1},value= _STR:"-"
	SetVariable megaParam1Edit,pos={227,v+61},size={87,16},bodyWidth=45,proc=megaParam1EditProc,title="param 1"
	SetVariable megaParam1Edit,help={"Optional set parameter #1."}
	SetVariable megaParam1Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaParam2Edit,pos={227,v+81},size={87,16},bodyWidth=45,proc=megaParam2EditProc,title="param 2"
	SetVariable megaParam2Edit,help={"Optional set parameter #2."}
	SetVariable megaParam2Edit,limits={-inf,inf,0},value= _STR:"-"
	SetVariable megaFlagsEdit,pos={243,v+101},size={71,16},bodyWidth=45,proc=megaFlagsEditProc,title="flags"
	SetVariable megaFlagsEdit,help={"Simulation-depended flags for his set. The meaning of this flag varies between slelected setup and processing functions."}
	SetVariable megaFlagsEdit,limits={1,inf,1},value= _STR:"-"
	Button megaDoIt,pos={220,v+142},size={90,22},proc=megaDoIt,title="do mega set"
	Button megaDoIt,help={"Start a mega-set of simulation kilo-sets. "},fStyle=1
	RenameWindow #,Mega
	SetActiveSubwindow ##
EndMacro



//--------------------------------------------------------------------
//
function /S funcSelByProto(protoName)
	string protoName
	string fName; 
	string validFNameStr = "-none-;"
	variable i, j;
	
	string protoInfo = FunctionInfo(protoName);
	string isTS = StringByKey("THREADSAFE", protoInfo)
	variable returnType = NumberByKey("RETURNTYPE", protoInfo);
	variable nPar =  NumberByKey("N_PARAMS", protoInfo);
	variable nOptPar =  NumberByKey("N_OPT_PARAMS", protoInfo);

	string searchStr;
	sprintf searchStr, "KIND:2,NPARAMS:%u,VALTYPE:%u", nPar, (returnType == 4) ? 1 : ((returnType == 5) ? 2 : ((returnType == 16384) ? 8 : 4))
	string allFnameStr = FunctionList("*",";",searchStr)
	for (i = 0; 1; i+=1)
		fname = stringfromlist(i,allFNameStr);
		if (strlen(fName) == 0)
			return validFNameStr;
		endif
		if (cmpstr(fName, protoName) == 0)
			continue;
		endif 
		// ends withProto?
		if (stringmatch(fName, "*proto"))
			continue
		endif
		string funcInfo = FunctionInfo(fName);
		if (cmpstr( isTS, StringByKey("THREADSAFE", protoInfo)))
			continue;
		endif
		if (returnType != NumberByKey("RETURNTYPE", funcInfo))
			continue;
		endif
		if (nPar != NumberByKey("N_PARAMS", funcInfo))
			continue;
		endif
		if (nOptPar != NumberByKey("N_OPT_PARAMS", funcInfo))
			continue;
		endif
		string parKey;
		variable parsMatch = 1;
		for (j=0; j< nPar; j+=1)
			sprintf parKey "PARAM_%u_TYPE", j
			if (NumberByKey(parKey, protoInfo) != NumberByKey(parKey, funcInfo))
				parsMatch = 0;
				break;
			endif
		endfor
		if (parsMatch)
			validFNameStr += fName+";";
		endif
	endfor;
end


//--------------------------------------------------------------------
//
Function PopFuncSelect(pa, ctrlName , jobField) : PopupMenuControl
	STRUCT WMPopupAction &pa
	string ctrlName;
	variable jobField;
	
	switch( pa.eventCode )
		case 2: // mouse up
//			Variable popNum = pa.popNum
//			String popStr = pa.popStr
			setJobField(pa.win, ctrlName , jobField, pa.popStr);
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------------------------------------------
//
function setJobField(win, ctrlName , jobField, valStr)
	string win;
	string ctrlName;
	variable jobField;
	string valStr; 

			ControlInfo /W=$(StringFromList(0,win,"#")) $ctrlName
			wave /T jobListW = $S_Value;
			if (waveexists(jobListW)) 
				if (cmpstr(valStr, "-none-") == 0)
					jobListW[jobField] = "";
				else
					jobListW[jobField] = valStr;
				endif 
				//ControlUpdate?
			else
				DoAlert /T="Beware..." 0, "You selected element of the job but the job wave does not exist. You will need to repeat this selction before the job can be executed"
			endif 

end

//--------------------------------------------------------------------
//
Function simWPrepFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "esimParamWSelect", 1);  
//	return PopFuncSelect(pa, "jobListWSelect", 7);  esimParamWSelect
end 

//--------------------------------------------------------------------
//
Function simWProcFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 8);  
end 

//--------------------------------------------------------------------
//
Function simPlotBuildFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 9);  
end 

//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Set
//--------------------------------------------------------------------
//
Function setInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 11);  
end 

//--------------------------------------------------------------------
//
Function setInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 12);  
end 

//--------------------------------------------------------------------
//
Function setOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 13);  
end 

//--------------------------------------------------------------------
//
Function setOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 14);  
end 

//--------------------------------------------------------------------
//
Function setOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 15);  
end 

//--------------------------------------------------------------------
//
Function setPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 16);  
end 

//--------------------------------------------------------------------
//
Function setPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 17);  
end 

//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Kilo
//--------------------------------------------------------------------
//
Function kiloInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 20);  
end 

//--------------------------------------------------------------------
//
Function kiloInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 21);  
end 

//--------------------------------------------------------------------
//
Function kiloOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 22);  
end 

//--------------------------------------------------------------------
//
Function kiloOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 23);  
end 

//--------------------------------------------------------------------
//
Function kiloOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 24);  
end 

//--------------------------------------------------------------------
//
Function kiloPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 25);  
end 

//--------------------------------------------------------------------
//
Function kiloPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 26);  
end 


//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	Mega
//--------------------------------------------------------------------
//
Function megaInSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 29);  
end 

//--------------------------------------------------------------------
//
Function megaInAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 30);  
end 

//--------------------------------------------------------------------
//
Function megaOutSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 31);  
end 

//--------------------------------------------------------------------
//
Function megaOutAssignFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 32);  
end 

//--------------------------------------------------------------------
//
Function megaOutCleanupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 33);  
end 

//--------------------------------------------------------------------
//
Function megaPlotSetupFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 34);  
end 

//--------------------------------------------------------------------
//
Function megaPlotAppendFProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return PopFuncSelect(pa, "jobListWSelect", 35);  
end 







//----------------------------------------------------------------------------------------------------------------------------------------
//
//----------------------------------------------------------------------------------------------------------------------------------------
//	dialog service
//--------------------------------------------------------------------
//

Function ctrlSetVar2WaveByValue(sva, ctrlName , theRow) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo /W=$(StringFromList(0,sva.win,"#")) $ctrlName
			if (strlen(S_value)) 
				wave jobParamW = $S_Value;
				jobParamW[theRow] = dval
			endif 
			if (numtype(dval)==2) 
				SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
			endif
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
Function ctrlSetVar2Wave2DByValue(sva, ctrlName , theRow, theCol) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow, theCol;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = sva.dval
			String sval = sva.sval
			ControlInfo /W=$(sva.win) $ctrlName
			if (strlen(S_value)) 
				wave jobParamW = $S_Value;
				jobParamW[theRow][theCol] = dval
			endif 
			if (numtype(dval)==2) 
				SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
			endif
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End



//--------------------------------------------------------------------
//
Function ctrlSetVar2WaveByStr(sva, ctrlName , theRow) 
	STRUCT WMSetVariableAction &sva

	string ctrlName;
	variable theRow;
	
	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			ControlInfo /W=$(StringFromList(0,sva.win,"#")) $ctrlName
			if (strlen(S_value)) 
				wave /T jobParamW = $S_Value;
				jobParamW[theRow] =  sva.sval
			endif 
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
Function ctrlSetList2WaveByValue(pa, ctrlName , theRow, offset) 
	STRUCT WMPopupAction &pa
	string ctrlName;
	variable theRow;
	variable offset; // correction from popup index to wave value
	
	switch( pa.eventCode )
		case 1: // mouse up
		case 2: // Enter key
			Variable dval = pa.popNum +offset;
			String sval = pa.popStr
			ControlInfo /W=$(StringFromList(0,pa.win,"#")) $ctrlName
			wave jobParamW = $S_Value;
			if (waveexists(jobParamW)) 
				if (numtype(dval)==0)
					jobParamW[theRow] = dval
				else
					PopupMenu $pa.ctrlName,mode = jobParamW[theRow], win=$(pa.win)
				endif
			else
				PopupMenu $pa.ctrlName,mode = inf, win=$(pa.win)
			endif 
			break
		case 3: // Live update
			break;
		case -1: // control being killed
			break
	endswitch
	return 0
end



//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
function wave2CtrlSetVarBylValue(winNStr, paramWave, theRow, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow;
	wave paramWave

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]
		if (numtype(theValue)==2) 
			SetVariable  $ctrlNStr, value= _STR:"", win=$(winNStr) 
		else	
			SetVariable $ctrlNStr, value= _NUM:theValue, win=$(winNStr) 
		endif
	else
			SetVariable  $ctrlNStr, value= _STR:"-", win=$(winNStr) 
	endif
	
end

//--------------------------------------------------------------------
//
function wave2D2CtrlSetVarBylValue(winNStr, paramWave, theRow, theCol, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow, theCol;
	wave paramWave

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow][theCol]
		if (numtype(theValue)==2) 
			SetVariable  $ctrlNStr, value= _STR:"", win=$(winNStr) 
		else	
			SetVariable $ctrlNStr, value= _NUM:theValue, win=$(winNStr) 
		endif
	else
			SetVariable  $ctrlNStr, value= _STR:"-", win=$(winNStr) 
	endif
	
end

//--------------------------------------------------------------------
//
function wave2CtrlSetVarByStr(winNStr, paramWave, theRow, ctrlNStr)
	string winNStr, ctrlNStr;
	variable theRow;
	wave /T paramWave

	string theValue = "";
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]
	endif
	SetVariable  $ctrlNStr, value= _STR:theValue, win=$(winNStr) 
end

//--------------------------------------------------------------------
//
function wave2CtrlPopupByValue(winNStr, paramWave, theRow, ctrlNStr, offset)
	string winNStr, ctrlNStr;
	variable theRow;
	wave paramWave
	variable offset; // correction between popup index and wave value

	variable theValue = NaN;
	if (waveexists(paramWave))  
		theValue =  paramWave[theRow]-offset
		if (numtype(theValue)==2) 
			PopupMenu $ctrlNStr,mode = inf, win=$(winNStr)
		else	
			PopupMenu $ctrlNStr, mode = (theValue), win=$(winNStr)
		endif
	else
//			PopupMenu $ctrlNStr, popvalue="-?-", win=$(winNStr)
			PopupMenu $ctrlNStr, mode = inf, win=$(winNStr)
	endif
	
end

//----------------------------------------------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------------------------------------------
//
// job set service
//
//--------------------------------------------------------------------
//

Function setJobFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 0)
End

//--------------------------------------------------------------------
//
Function setFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 2)
End

//--------------------------------------------------------------------
//
Function setToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 3)
End

//--------------------------------------------------------------------
//
Function setStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 4)
End
//--------------------------------------------------------------------
//
Function setVarCmpNoEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 6)
End

//--------------------------------------------------------------------
//
Function setIsBiDirEditProc_old(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 1)
End

//--------------------------------------------------------------------
//
Function simIsBiDirEditProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 1, -1)
End


//--------------------------------------------------------------------
//
Function setPlotCmpNoEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 8)
End

//--------------------------------------------------------------------
//
Function setNThreadsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 1)
End

//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function kiloFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 10)
End

//--------------------------------------------------------------------
//
Function kiloToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 11)
End

//--------------------------------------------------------------------
//
Function kiloStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 12)
End

//--------------------------------------------------------------------
//
Function kiloParam1EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 14)
End

//--------------------------------------------------------------------
//
Function kiloParam2EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 15)
End

//--------------------------------------------------------------------
//
Function kiloFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 16)
End

//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function megaFromEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 19)
End

//--------------------------------------------------------------------
//
Function megaToEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 20)
End

//--------------------------------------------------------------------
//
Function megaStepsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 21)
End
//--------------------------------------------------------------------
//
Function megaParam1EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 23)
End

//--------------------------------------------------------------------
//
Function megaParam2EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 24)
End

//--------------------------------------------------------------------
//
Function megaFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "jobParamWSelect" , 25)
End


//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//

Function simReloadProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			simReloadPanelJob(ba.win, "jobListWSelect")			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End


//--------------------------------------------------------------------
//
function simReloadPanelJob(wName, jListWCtrl)
	string wName, jListWCtrl
	ControlInfo /W=$(StringFromList(0,wName,"#")) $jListWCtrl
	if (strlen(S_value)) 
		 wave /T jListW= $S_Value;
		 simReloadJob(wName, jListW)
	else
		 simReloadJob(wName, $(""))
	endif
	
end
//--------------------------------------------------------------------
//

function wave2PopMenuStr(winN, ctrlName, paramW, paramField)
	string winN, ctrlName
	wave /T paramW
	variable paramField

	if (waveexists(paramW))
		PopupMenu  $ctrlName, popmatch =  paramW[paramField], win=$(winN)
	else
		PopupMenu  $ctrlName, popmatch =  "-none-", win=$(winN)
	endif
end

//--------------------------------------------------------------------
//

function wave2PopMenuWave(winN, ctrlName, paramW, paramField)
	string winN, ctrlName
	wave /T paramW
	variable paramField

	if (waveexists(paramW))
		string tgtWN = paramW[paramField];
		if (waveexists($tgtWN))
			PopupMenu  $ctrlName, popmatch =  tgtWN, win=$(winN)
		else
			PopupMenu  $ctrlName, popmatch = "-", win=$(winN)
		endif
	else
		PopupMenu  $ctrlName, popmatch =  "-", win=$(winN)
	endif
end



//--------------------------------------------------------------------
//

function simReloadJob(wName, jobListW)
	string wName
	 wave /T jobListW

		wave2CtrlSetVarByStr(wName+"#Sim", jobListW, 0, "simCommName")

		wave2PopMenuStr(wName+"#Sim", "simWPrepFSelect", jobListW, 7); 
		wave2PopMenuStr(wName+"#Sim", "simWProcFSelect", jobListW, 8); 
		wave2PopMenuStr(wName+"#Sim", "simPlotBuildFSelect", jobListW, 9); 
		
		wave2PopMenuStr(wName+"#Set", "setInSetupFSelect", jobListW, 11); 
		wave2PopMenuStr(wName+"#Set", "setInAssignFSelect", jobListW, 12); 
		wave2PopMenuStr(wName+"#Set", "setOutSetupFSelect", jobListW, 13); 
		wave2PopMenuStr(wName+"#Set", "setOutAssignFSelect", jobListW, 14); 
		wave2PopMenuStr(wName+"#Set", "setOutCleanupFSelect", jobListW, 15); 
		wave2PopMenuStr(wName+"#Set", "setPlotBuildFSelect", jobListW, 16); 
		wave2PopMenuStr(wName+"#Set", "setPlotAppendFSelect", jobListW, 17); 
	
		wave2PopMenuStr(wName+"#Kilo", "kiloInSetupFSelect", jobListW, 20); 
		wave2PopMenuStr(wName+"#Kilo", "kiloInAssignFSelect", jobListW, 21); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutSetupFSelect", jobListW, 22); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutAssignFSelect", jobListW, 23); 
		wave2PopMenuStr(wName+"#Kilo", "kiloOutCleanupFSelect", jobListW, 24); 
		wave2PopMenuStr(wName+"#Kilo", "kiloPlotBuildFSelect", jobListW, 25); 
		wave2PopMenuStr(wName+"#Kilo", "kiloPlotAppendFSelect", jobListW, 26); 

		wave2PopMenuStr(wName+"#Mega", "megaInSetupFSelect", jobListW, 29); 
		wave2PopMenuStr(wName+"#Mega", "megaInAssignFSelect", jobListW, 30); 
		wave2PopMenuStr(wName+"#Mega", "megaOutSetupFSelect", jobListW, 31); 
		wave2PopMenuStr(wName+"#Mega", "megaOutAssignFSelect", jobListW, 32); 
		wave2PopMenuStr(wName+"#Mega", "megaOutCleanupFSelect", jobListW, 33); 
		wave2PopMenuStr(wName+"#Mega", "megaPlotBuildFSelect", jobListW, 34); 
		wave2PopMenuStr(wName+"#Mega", "megaPlotAppendFSelect", jobListW, 35); 


		// reload params wave
		wave2PopMenuWave(wName, "jobParamWSelect", jobListW, 1);
		wave2PopMenuWave(wName+"#Method", "methodParamWSelect", jobListW, 2);
		wave2PopMenuWave(wName, "esimParamWSelect", jobListW, 3);
		wave2PopMenuWave(wName+"#Comp", "compParamWSelect", jobListW, 4);
		wave2PopMenuWave(wName+"#ERxns", "eRxnsParamWSelect", jobListW, 5);
		wave2PopMenuWave(wName+"#GRxns", "gRxnsParamWSelect", jobListW, 6);
	
	if (waveexists(jobListW))
		// reload functions
		simReloadJParamPanel(wName, $(jobListW[1]));
		simReloadMethodParamPanel(wName+"#Method", $(jobListW[2]))
		simReloadESimParamPanel(wName, $(jobListW[3]));
		simReloadCompParamPanel(wName+"#Comp", $(jobListW[4]))
		simReloadRxnsParamPanel(wName+"#ERxns", $(jobListW[5]))
		simReloadRxnsParamPanel(wName+"#GRxns", $(jobListW[6]))		
	else
		simReloadJParamPanel(wName, $(""));
		simReloadMethodParamPanel(wName+"#Method", $(""))
		simReloadESimParamPanel(wName, $(""));
		simReloadCompParamPanel(wName+"#Comp", $(""))
		simReloadRxnsParamPanel(wName+"#ERxns", $(""))
		simReloadRxnsParamPanel(wName+"#GRxns", $(""))		

	endif

end

//--------------------------------------------------------------------
//
function simReloadJParamPanel(wName, jParamW)
	string wName
	wave jParamW
	
	wave2CtrlSetVarBylValue(wName+"", jParamW, 0, "jobFlagsEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 1, "setNThrds")

	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 2, "setFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 3, "setToEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 4, "setStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 6, "setVarCmpNo")
	wave2CtrlSetVarBylValue(wName+"#Set", jParamW, 8, "setPlotCmpNo")

	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 10, "kiloFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 11, "kiloToEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 12, "kiloStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 14, "kiloParam1Edit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 15, "kiloParam2Edit")
	wave2CtrlSetVarBylValue(wName+"#Kilo", jParamW, 16, "kiloFlagsEdit")

	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 19, "megaFromEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 20, "megaToEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 21, "megaStepsEdit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 23, "megaParam1Edit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 24, "megaParam2Edit")
	wave2CtrlSetVarBylValue(wName+"#Mega", jParamW, 25, "megaFlagsEdit")
	
end

//--------------------------------------------------------------------
//
function simReloadESimParamPanel(wName, eSimParamW)
	string wName
	wave eSimParamW
	
	wave2CtrlSetVarBylValue(wName+"#Sim", eSimParamW, 0, "simNThrds")
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 1, "simIsBiDir", -1);
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 2, "simETRateMode", -2)
	wave2CtrlPopupByValue(wName+"#Sim", eSimParamW, 3, "simLimRateMode", -1)
	wave2CtrlSetVarBylValue(wName+"#Sim", eSimParamW, 10, "simLayerThick")

	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 5, "RKiDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 6, "RKiRise")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 7, "RKFullDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKSol", eSimParamW, 8, "RKFullRise")

	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 11, "RKiDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 12, "RKiRise")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 13, "RKFullDrop")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKElec", eSimParamW, 14, "RKFullRise")


	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 17, "RKTimeDropX")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 16, "RKTimeDropOver")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 18, "RKTimeRiseX")
	wave2CtrlSetVarBylValue(wName+"#Integr#RKComm", eSimParamW, 20, "RKTimeNextX")
end



//--------------------------------------------------------------------
//
function simReloadMethodParamPanel(wName, methodParamW)
	string wName
	wave methodParamW
	string tblName = wName+"#Tbl"
	variable i;
	for (i=0; 1; i+=1)	
		wave theWave = WaveRefIndexed(tblName, i, 3)
		if (waveexists(theWave))
			RemoveFromTable /W=$tblName theWave.ld
		else
			break;
		endif  
	endfor
	if (waveexists(methodParamW))
		AppendToTable /W=$tblName methodParamW.ld
		ModifyTable /W=$tblName width(methodParamW.l)=64,width(methodParamW.d)=40
	endif
end 


//----------------------------------------------------------------------------------------------------------------------------------------
//
//-------------------------------------------------------------------
//


Function simNThreadsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 0)
End


//--------------------------------------------------------------------
//
Function simLayerThicknessEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 10)
End

//--------------------------------------------------------------------
//
Function simRKiDropMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 5)
End

//--------------------------------------------------------------------
//
Function simRKiRiseMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 6)
End

//--------------------------------------------------------------------
//
Function simRKFullDropMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 7)
End

//--------------------------------------------------------------------
//
Function simRKFullRiseMaxSol(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 8)
End



//--------------------------------------------------------------------
//
Function simRKiDropMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 11)
End

//--------------------------------------------------------------------
//
Function simRKiRiseMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 12)
End

//--------------------------------------------------------------------
//
Function simRKFullDropMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 13)
End

//--------------------------------------------------------------------
//
Function simRKFullRiseMaxElec(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 14)
End

//--------------------------------------------------------------------
//
Function simRKTimeDropX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 17)
End

//--------------------------------------------------------------------
//
Function simRKTimeRiseX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 18)
End

//--------------------------------------------------------------------
//
Function simRKTimeNextX(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 20)
End

//--------------------------------------------------------------------
//
Function simRKTimeDropOver(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByValue(sva, "esimParamWSelect" , 16)
End

//--------------------------------------------------------------------
//


//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function simDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		ControlInfo /W=$(StringFromList(0,ba.win,"#")) jobListWSelect
		wave jobW = $(S_value);
		if (waveexists(jobW))
			Set_MedEChem(jobW, doSingle = 1)
		elseif (cmpstr(S_value, "-")!=0)
			DoAlert /T="Oops!", 0, "The wave ["+S_value+"] is not found. Please check the location and try again."
		endif
	endif
	return 0

	if (ba.eventCode == 2)
	DoAlert /T="Oops!" 0, "This feature is not yet available..." 
	endif
	return 0
End
//--------------------------------------------------------------------
//
Function setDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		ControlInfo /W=$(StringFromList(0,ba.win,"#")) jobListWSelect
		wave jobW = $(S_value);
		if (waveexists(jobW))
			Set_MedEChem(jobW)
		elseif (cmpstr(S_value, "-")!=0)
			DoAlert /T="Oops!", 0, "The wave ["+S_value+"] is not found. Please check the location and try again."
		endif
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function kiloDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		ControlInfo /W=$(StringFromList(0,ba.win,"#")) jobListWSelect
		wave jobW = $(S_value);
		if (waveexists(jobW))
			Kilo_MedEChem05(jobW)
		elseif (cmpstr(S_value, "-")!=0)
			DoAlert /T="Oops!", 0, "The wave ["+S_value+"] is not found. Please check the location and try again."
		endif
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function megaDoIt(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2)
		ControlInfo /W=$(StringFromList(0,ba.win,"#")) jobListWSelect
		wave jobW = $(S_value);
		if (waveexists(jobW))
			Mega_MedEChem05(jobW)
		elseif (cmpstr(S_value, "-")!=0)
			DoAlert /T="Oops!", 0, "The wave ["+S_value+"] is not found. Please check the location and try again."
		endif
	endif
	return 0
End

//----------------------------------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------
//
Function jobListWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if ( pa.eventCode == 2)  // mouse up
		wave /T jListW = $pa.popStr;
		simReloadJob(pa.win, jListW)
	endif 
	return 0
End

//--------------------------------------------------------------------
//

Function simBaseNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2WaveByStr(sva, "jobListWSelect" , 0)
End


//--------------------------------------------------------------------
//
function simReloadCompParamPanel(wName, compParamW, [setCmpNo])
	string wName
	wave compParamW
	variable setCmpNo
	
	if (paramisdefault(setCmpNo))
		setCmpNo = 0;
	endif

	if (waveexists(compParamW))
		variable nCmp = dimsize(compParamW,1);
		string cmpList = "\"";
		variable i;
		for (i=0; i<nCmp; i+=1)
			cmpList += num2str(i)+";";		
		endfor
		cmpList+="\"";
		PopupMenu $"cmpSelect", value=#cmpList, mode = (setCmpNo+1), win=$(wName)
		setCmpVals(wName, setCmpNo);
		
	else
		PopupMenu $"cmpSelect", value="-", mode = (1), win=$(wName)
		setCmpVals(wName, 0);
	endif	
	
end 


//--------------------------------------------------------------------
//
function setCmpVals(wName,  cmpNo)
	string wName;
	variable cmpNo;

	ControlInfo /W=$(wName) $"compParamWSelect"
	wave cmpParamW =$(S_value)
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 0,cmpNo, "intOx")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 1,cmpNo, "intRd")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 2,cmpNo, "cmpE")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 3,cmpNo, "cmpN")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 5,cmpNo, "cmpA")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 4,cmpNo, "cmp_k0")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 6,cmpNo, "cmpFlags")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 8,cmpNo, "cmpLim_k")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 10,cmpNo, "cmpBindK")
	wave2D2CtrlSetVarBylValue(wName, cmpParamW, 11,cmpNo, "cmpOnRate")

	if (waveexists(cmpParamW))
		string thisLabel = GetDimLabel(cmpParamW, 1,cmpNo)
		SetVariable  $"cmpName", value= _STR:thisLabel, win=$(wName) 
	else
		SetVariable  $"cmpName", value= _STR:"-", win=$(wName) 
	endif

	setCmpAlias(cmpParamW, cmpNo, wName)
end

//--------------------------------------------------------------------
//

Function simCopyMenu() 
	simCopySet("KinESimCtrl");
end


//--------------------------------------------------------------------
//

Function simCopySet(win) 
	string win;
			ControlInfo /W=$win $"jobListWSelect"
			wave /T jobListW= $S_Value;
			if (!waveexists(jobListW))
				DoAlert /T="Oops!" 0, "The job wave that you want to copy is not found."
				return 0;
			endif 

			String cdfBefore = GetDataFolder(1)		
			string BrowserCmd = " CreateBrowser prompt=\"Select new folder to copy set to\", showWaves=1, showVars=0, showStrs=0 ";

			Execute BrowserCmd;
			String cdfAfter = GetDataFolder(1)	// Save current data folder after.
			SetDataFolder cdfBefore			// Restore current data folder.
			SVAR S_BrowserList=S_BrowserList
			NVAR dlg_Flag=V_Flag
			if(V_Flag==0)
				return 0;
			endif

			// check if folder is the same
			if (cmpstr(cdfBefore, cdfAfter) == 0)
				DoAlert /T="Oops!" 0, "Please select target folder other than the source folder."
				return 0;
			endif 
			string jListWName = nameofwave(jobListW);
			string newName = cdfAfter+jListWName
			duplicate /O $jListWName $(cdfAfter+jListWName);

			string jParamWName = jobListW[1];
			if (waveexists($jParamWName))
				duplicate /O $jParamWName $(cdfAfter+jParamWName);
			endif 
	
			 string methodWName = jobListW[2];
			if (waveexists($methodWName))
				duplicate /O $methodWName $(cdfAfter+methodWName);
			endif 
		
			 string esimWName = jobListW[3];
			if (waveexists($esimWName))
				duplicate /O $esimWName $(cdfAfter+esimWName);
			endif 

			 string compWName = jobListW[4];
			if (waveexists($compWName))
				duplicate /O $compWName $(cdfAfter+compWName);
			endif 
			
			copyRxnsSet( jobListW[5], cdfAfter)
			copyRxnsSet( jobListW[6], cdfAfter)
end


//--------------------------------------------------------------------
//
function copyRxnsSet(eRxnsWName, cdfAfter)
	string eRxnsWName, cdfAfter

			variable i;

			if (waveexists($eRxnsWName))
				duplicate /O $eRxnsWName $(cdfAfter+eRxnsWName);
				wave /WAVE eRxnsW = $eRxnsWName;
				wave eRxnsRDW =  eRxnsW[0]
				if (waveexists(eRxnsRDW))
					duplicate /O eRxnsRDW $(cdfAfter+nameofwave(eRxnsRDW));
				endif
				for (i=1; i<dimsize(eRxnsW, 0); i+=1)
					wave theRxnW =  eRxnsW[i]
					if (waveexists(theRxnW))
						duplicate /O theRxnW $(cdfAfter+nameofwave(theRxnW));
					endif 
				endfor
			endif 
			
end

//--------------------------------------------------------------------
//
Function simStopThreadsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

//--------------------------------------------------------------------
//
Function simStopThreads()
	variable i, dummy, lastThread;
	lastThread = ThreadGroupCreate(1);
	for (i=0; i<99 || i< lastThread; i+=1)
		dummy = ThreadGroupRelease(i);
	endfor
end


//--------------------------------------------------------------------
//
Function simETRateModePopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 2, -2)
End

//--------------------------------------------------------------------
//
Function simLimRateModePiopupProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa
	return ctrlSetList2WaveByValue(pa, "esimParamWSelect" , 3, -1)
End

//--------------------------------------------------------------------
//
Function rxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
function simReloadRxnsParamPanel(wName, rxnsParamW, [currRxn])
	string wName
	wave /WAVE rxnsParamW
	variable currRxn;
	
	if (paramisdefault(currRxn)) 	
		currRxn = 0; 
	endif

	setRxn(wName, rxnsParamW, currRxn)
end

//--------------------------------------------------------------------
//
function setRxn(wName, rxnsParamW, currRxn)
	string wName
	wave /WAVE rxnsParamW
	variable currRxn;
	
	variable nRx = 0;
	variable i;
	if (waveexists(rxnsParamW))
		wave ratesW = rxnsParamW[0]
		if (waveexists(ratesW))
			nRx = dimsize(ratesW, 0);
			for (i=0; i < nRx; i += 1 )
				wave theRxW = rxnsParamW[i+1];
				if (!waveexists(theRxW))
					nRx = i;
					break;
				endif 
			endfor
		endif
	endif	
	
	if (nRx>0)
		if (currRxn >= nRx)
			currRxn = 0;
		endif
		string rxnList = "\"";
		for (i=0; i<nRx; i+=1)
			rxnList += num2str(i)+";";		
		endfor
		rxnList+="\"";
		PopupMenu $"rxnSelect", value=#rxnList, mode = (currRxn+1), win=$(wName)
		SetVariable $"rxn_K_Eq", value =_NUM: ratesW[currRxn][0], win=$(wName)
		SetVariable $"rxn_k_fwd", value =_NUM: ratesW[currRxn][1], win=$(wName)
		loadRxnTbl(wName, rxnsParamW[currRxn+1] )
		
		string thisLabel = GetDimLabel(ratesW, 0,currRxn)
		SetVariable  $"rxnName", value= _STR:thisLabel, win=$(wName) 
		SetVariable  $"rxnWaveName", value= _STR:nameofwave(rxnsParamW[currRxn+1]), win=$(wName) 
		SetVariable  $"tdWaveName", value= _STR:nameofwave(ratesW), win=$(wName) 
		
	else
		PopupMenu $"rxnSelect", value="-", mode = 1, win=$(wName)
		SetVariable $"rxn_K_Eq", value =_STR:"-", win=$(wName)
		SetVariable $"rxn_k_fwd", value =_STR:"-", win=$(wName)
		loadRxnTbl(wName, $"")
		SetVariable  $"rxnName", value= _STR:"-", win=$(wName) 
		SetVariable  $"rxnWaveName", value= _STR:"-", win=$(wName) 
		SetVariable  $"tdWaveName", value= _STR:"-", win=$(wName) 
	endif
	

end 


//--------------------------------------------------------------------
//
// after simReloadRatesParamPanel
function loadRxnTbl(wName, rxnW )
	wave rxnW
	string wName

	string tblName = wName+"#Tbl"
	variable i;
	string WatcherNameS
	for (i=0; 1; i+=1)	
		wave theWave = WaveRefIndexed(tblName, i, 3)
		if (!waveexists(theWave))
			break;
		endif  
		RemoveFromTable /W=$tblName theWave.ld
		// delete dependence
		WatcherNameS = nameofwave( theWave)+"Dep";
		SetFormula $WatcherNameS, ""
		killvariables  /Z $WatcherNameS
	endfor
	if (waveexists(rxnW))
		SetDimLabel 1,0, $"-›¦#..", rxnW
		SetDimLabel 1,1, $"-›¦Ox..", rxnW
		SetDimLabel 1,2, $"-›¦Rd..", rxnW
		SetDimLabel 1,3, $"..#¦-›", rxnW
		SetDimLabel 1,4, $"..Ox¦-›", rxnW
		SetDimLabel 1,5, $"..Rd¦-›", rxnW
		
		AppendToTable /W=$tblName rxnW //.ld
		ModifyTable /W=$tblName horizontalIndex=2, format(Point)=1,width(Point)=20,sigDigits(rxnW)=1,width(rxnW)=38 
		ModifyTable /W=$tblName font[1] ="Arial Black", font[4] ="Arial Black"
		ModifyTable /W=$tblName style[1] =0, style[4] =0
		ModifyTable /W=$tblName format[1] =1, format[4] =1
		ModifyTable /W=$tblName rgb[1] =(0,0,65535), rgb[4] =(0,0,65535)
		ModifyTable /W=$tblName alignment[1,3] =0, alignment[4,6]=2
		// add dependence
		WatcherNameS = nameofwave(rxnW)+"Dep";
		Variable/G $WatcherNameS
		SetFormula $WatcherNameS, "EUpdateHook(\""+wName+"\", "+nameofwave(rxnW)+")"
	endif	
	
end

//--------------------------------------------------------------------
//
function EUpdateHook(WinNameStr, theWave)
	string WinNameStr
	wave theWave
	// print "Value updated for window ", WinNameStr, " and reactions wave ", nameofwave(theWave) ;
	// use this hook to update effective K for the reaction
end


//--------------------------------------------------------------------
//
// after simIsBiDirEditProc
Function rxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//
// after compE0EditProc
Function rxnKeqEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtOffset = 0;
	variable refOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refOffset, tgtOffset,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 
	
//--------------------------------------------------------------------
//
Function ctrlSelectorPos(wName, selectorWCtrlN)
	string wName
	string selectorWCtrlN

	ControlInfo /W=$wName $selectorWCtrlN
	if (cmpstr(S_value,"-") == 0 ||  strlen(S_value) == 0)
		return -1;
	endif 
	return  V_Value -1;
end
	
//--------------------------------------------------------------------
//
	
Function ctrlSetVar2WaveRef2DByValue(sva, refWCtrl, refOffset, tgtCol, tgtRow)
	STRUCT WMSetVariableAction &sva
//	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 2, ctrlSliderPos(sva.win, "cmpSlider"))
	variable refOffset; 
	variable tgtCol ;
	string refWCtrl 
	variable tgtRow; 

	if (sva.eventCode != 1 &&  sva.eventCode != 2)
		return 0;
	endif

	ControlInfo /W=$(sva.win) $refWCtrl
	
	wave /WAVE rxnsParamW = $S_Value;
	if (!waveexists(rxnsParamW))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 
	
	wave ratesW = rxnsParamW[0]
	if (!waveexists(ratesW))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 

	if (tgtRow > dimSize(ratesW, 0))
		SetVariable  $(sva.ctrlName), value= _STR:"", win=$(sva.win) 
		return 0;
	endif 
	ratesW[tgtRow][tgtCol] = sva.dval;
	return 0;
End

//--------------------------------------------------------------------
//
Function rxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//

Function cmpSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable curval = pa.popnum - 1
	setCmpVals(pa.win, curval);
End

//--------------------------------------------------------------------
//
Function compInitRdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 1, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compInitOxEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 0, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compE0EditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 2,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compNEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 3,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compAlphaEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 5,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compET_kEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 4,  ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compLimRateEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 8, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compBindKEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 10, ctrlSelectorPos(sva.win, "cmpSelect"))
End

//--------------------------------------------------------------------
//
Function compBindRateEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 11,  ctrlSelectorPos(sva.win, "cmpSelect"))
End



//--------------------------------------------------------------------
//
Function addRxnRowProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string tblName = ba.win+"#Tbl"
	GetSelection table, $tblName, 1
	variable theRow = V_startRow;
	
	wave theWave = WaveRefIndexed(tblName, 0, 3)
	if (waveexists(theWave))
		insertpoints /M=0 theRow, 1, theWave
	endif  
	
	return 0
End

//--------------------------------------------------------------------
//
Function delRxnRowProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string tblName = ba.win+"#Tbl"
	GetSelection table, $tblName, 1
	variable theRow = V_startRow;
	
	wave theWave = WaveRefIndexed(tblName, 0, 3)
	if (waveexists(theWave))
		deletepoints /M=0 theRow, 1, theWave
	endif  

	return 0
End

//--------------------------------------------------------------------
//

Function rxnNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(sva.win, "rxnSelect")
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			string thisName = sva.sVal				
			SetDimLabel 0,currRxn, $sva.sVal, rxParamsW
		endif 
	endif 	
End

//--------------------------------------------------------------------
//
Function addCmpProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(ba.win, "cmpSelect")
		insertpoints /M=1 currCmp+1, 1, cmpParamW
		simReloadCompParamPanel(ba.win, cmpParamW, setCmpNo =currCmp+1 )
	endif  
	
	return 0
End

//--------------------------------------------------------------------
//
Function delCmpProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 

	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(ba.win, "cmpSelect")
		deletepoints /M=1 currCmp, 1, cmpParamW
		if (currCmp >= dimsize(cmpParamW, 1))
			currCmp =  dimsize(cmpParamW, 1) -1;
		endif 
		simReloadCompParamPanel(ba.win, cmpParamW, setCmpNo =currCmp )
	endif  

	return 0
End

//--------------------------------------------------------------------
//
Function cmpNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "compParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave cmpParamW = $S_Value;

	if (waveexists(cmpParamW))
		variable currCmp =  ctrlSelectorPos(sva.win, "cmpSelect")
		string thisName = sva.sVal				
		SetDimLabel 1,currCmp, $sva.sVal, cmpParamW
	endif 	
End


//--------------------------------------------------------------------
//

Function compFlagsEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	return ctrlSetVar2Wave2DByValue(sva, "compParamWSelect" , 6, ctrlSelectorPos(sva.win, "cmpSelect"))
End


//--------------------------------------------------------------------
//

Function gRxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//

Function addGRxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	addRxnProc(ba.win, "gRxnsParamWSelect", "GRxn")
	return 0
End

//--------------------------------------------------------------------
//
function addRxnProc(win, ctrlName, prefix)
	string win, ctrlName, prefix
	
	ControlInfo /W=$(win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;
	
	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(win, "rxnSelect")
		variable newRxIndex = currRxn+2;
		
		InsertPoints /M=0 newRxIndex, 1, rxnsParamW;
		variable i
		for (i=0; i<99; i+=1)
			string rxWName
			sprintf  rxWName "%s%02d", prefix, i
			if (!waveexists($rxWName))
				make /N=(1, 6) $rxWName
				rxnsParamW[newRxIndex] = $rxWName
				break;
			endif 
		endfor
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			InsertPoints /M=0 currRxn+1, 1, rxParamsW;
			rxParamsW[currRxn+1][] = 0;
		endif 
		 simReloadRxnsParamPanel(win, rxnsParamW, currRxn = currRxn+1)		
	endif 

end

//--------------------------------------------------------------------
//
Function delGRxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string ctrlName = "gRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		
		DeletePoints /M=0 currRxn+1, 1, rxnsParamW;
		
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			DeletePoints /M=0 currRxn, 1, rxParamsW;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn)		
	endif 	

	return 0
End

//--------------------------------------------------------------------
//
Function gRxnKeqEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtOffset = 0;
	variable refOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refOffset, tgtOffset,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function gRxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="gRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "gRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function eRxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 5) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function eRxnSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif
	
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(pa.win) $ctrlName
	
	wave rxnsParamW = $S_Value;
	
	setRxn(pa.win, rxnsParamW, pa.popNum-1)
	
End

//--------------------------------------------------------------------
//
Function eRxnNameEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(sva.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(sva.win, "rxnSelect")
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			string thisName = sva.sVal				
			SetDimLabel 0,currRxn, $sva.sVal, rxParamsW
		endif 
	endif 	
End

//--------------------------------------------------------------------
//
Function addERxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	addRxnProc(ba.win, "eRxnsParamWSelect", "ERxn")
	return 0
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;
	
	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		variable newRxIndex = currRxn+2;
		
		InsertPoints /M=0 newRxIndex, 1, rxnsParamW;
		variable i
		for (i=0; i<99; i+=1)
			string rxWName
			sprintf  rxWName "Rxn%02d", i
			if (!waveexists($rxWName))
				make /N=(1, 6) $rxWName
				rxnsParamW[newRxIndex] = $rxWName
				break;
			endif 
		endfor
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			InsertPoints /M=0 currRxn+1, 1, rxParamsW;
			rxParamsW[currRxn+1][] = 0;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn+1)		
	endif 
	
	return 0
End

//--------------------------------------------------------------------
//
Function delERxnProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	if (ba.eventCode != 2)
		return 0
	endif 
	
	string ctrlName = "eRxnsParamWSelect"
	ControlInfo /W=$(ba.win) $ctrlName
	wave /WAVE rxnsParamW = $S_Value;

	if (waveexists(rxnsParamW))
		variable currRxn =  ctrlSelectorPos(ba.win, "rxnSelect")
		
		DeletePoints /M=0 currRxn+1, 1, rxnsParamW;
		
		wave rxParamsW = rxnsParamW[0]
		if (waveexists(rxParamsW))
			DeletePoints /M=0 currRxn, 1, rxParamsW;
		endif 
		 simReloadRxnsParamPanel(ba.win, rxnsParamW, currRxn = currRxn)		
	endif 	

	return 0
End

//--------------------------------------------------------------------
//
Function eRxnkfwdEditProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	variable tgtCol = 1;
	variable refWOffset = 0;
	string refWCtrl ="eRxnsParamWSelect"
	string selectorWCtrl = "rxnSelect"
	
	return ctrlSetVar2WaveRef2DByValue(sva, "eRxnsParamWSelect", refWOffset, tgtCol,  ctrlSelectorPos(sva.win, selectorWCtrl))
end 

//--------------------------------------------------------------------
//
Function gRxnsParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 6) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadRxnsParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function jobParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 1) ;

	if ( pa.eventCode == 2)  // mouse up
		simReloadJParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function esimParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 3) ;

	if ( pa.eventCode == 2)  // mouse up
		 simReloadESimParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function compParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 4) ;
	if ( pa.eventCode == 2)  // mouse up
		 simReloadCompParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function methodParamWProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	PopFuncSelect(pa,  "jobListWSelect" , 2) ;
	if ( pa.eventCode == 2)  // mouse up
		simReloadMethodParamPanel(pa.win, $(pa.popStr))
	endif
	return 0
End

//--------------------------------------------------------------------
//
Function KESInfoProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
			NewPanel /W=(250,200,615,294)  /N=KESAbout as "About KES"
			SetDrawEnv fsize= 14
			DrawText 22,33,"Kin-E-Sim kinetic simulator."
			SetDrawEnv fsize= 14
			DrawText 138,60,"version "+cKESVer
			Button CloseButton,pos={141,67},size={50,20},proc=KESAboutCloseProc,title="Close"
			// click code here
			PauseForUser KESAbout
	endif 
	return 0
End

//--------------------------------------------------------------------
//

Function KESAboutCloseProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode ==  2) // mouse up
			DoWindow /K KESAbout
	endif 
	return 0
End


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeCtrlTableProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
			ControlInfo /W=$(StringFromList(0,ba.win,"#")) $"jobListWSelect"
			wave /T jobListW = $S_Value;
		
		SimCtrlTable(jobListW)
	endif 
	return 0
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

function SimCtrlTable(jobListW)
	wave /T jobListW;
	
	string jobName = nameofwave(jobListW);
	
	string jobFldr = GetWavesDataFolder(jobListW, 1);
	
	if (!waveexists($jobListW[1]))
		print  "Job params wave "+jobListW[1]+" is not found\r";
		return 1;
	endif 
	wave JobParams = $jobListW[1];

	if (!waveexists($jobListW[2]))
		print "Method params wave "+jobListW[2]+" is not found\r";
		return 1;
	endif 
	wave MethodParams = $jobListW[2];

	if (!waveexists($jobListW[3]))
		print "Sim params wave "+jobListW[3]+" is not found\r";
		return 1;
	endif 
	wave ESimParams = $jobListW[3];

	if (!waveexists($jobListW[4]))
		print "Components wave "+jobListW[4]+" is not found\r";
		return 1;
	endif 
	wave  ESimComp = $jobListW[4];

	if (!waveexists($jobListW[5]))
		print "rates wave "+jobListW[5]+" is not found\r";
		return 1;
	endif 
	wave Rates = $jobListW[5];

	string title = jobName+" control table";
	
	Edit /W=(5.25,43.25,1277.25,716) jobListW.ld, JobParams.ld,MethodParams.ld,ESimParams.ld, ESimComp.ld,Rates.ld as title
	
	ModifyTable format(Point)=1,width(Point)=23,style( jobListW.l)=1,width( jobListW.l)=95
	ModifyTable width( jobListW.d)=129,style(JobParams.l)=1,width(JobParams.d)=50,style(MethodParams.l)=1
	ModifyTable width(MethodParams.d)=45,style(ESimParams.l)=1,width(ESimParams.l)=122
	ModifyTable width(ESimParams.d)=41,style(ESimComp.l)=1,width(ESimComp.d)=45,style(Rates.l)=1
	ModifyTable width(Rates.l)=53,width(Rates.d)=27

end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeGRxnWaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
		makeRxnWave(ba.win, "GRxn", "gRxnsParamWSelect", "jobListWSelect", 6)
	endif 
	return 0
End

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

function makeRxnWave(win, prefix, popupName, jobListCtrlName, jobIndex)
	string win, prefix, popupName, jobListCtrlName
	variable jobIndex;

		variable i
		for (i=0; i<99; i+=1)
			string rxListWName
			sprintf  rxListWName "%ss%02d", prefix, i
			string rxTDWaveName = rxListWName+"_TD";
			if (!waveexists($rxListWName) && !waveexists($rxTDWaveName))
				make /WAVE  /N=(2) $rxListWName
				make  /N=(1,2) $rxTDWaveName
				wave /WAVE rxnsParamW = $rxListWName;
				rxnsParamW[0] = $rxTDWaveName
				// now make 1st reaction
				for (i=0; i<99; i+=1)
					string rxWName
					sprintf  rxWName "%s%02d", prefix, i
					if (!waveexists($rxWName))
						make /N=(1, 6) $rxWName
						rxnsParamW[1] = $rxWName
						break;
					endif 
				endfor
				
				break;
			endif 
		endfor
		 setJobField(win, jobListCtrlName , jobIndex , rxListWName)			
		PopupMenu $popupName, win=$win, popmatch=rxListWName
		setRxn(win, rxnsParamW, 0)
end


//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//

Function makeERxnWaveProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode == 2) // mouse up
		makeRxnWave(ba.win, "ERxn", "eRxnsParamWSelect", "jobListWSelect", 5)
	endif 
	return 0
End





//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function setCmpAlias(cmpParamW, cmpNo, win)
	wave cmpParamW
	variable cmpNo
	string win
	// display alias

	string thatList = "";
	variable i;
	for ( i=0; i< dimsize(cmpParamW, 1); i+= 1)
		if (i== cmpNo)
			continue;
		endif 
		if (strlen(thatList) >0 )
			thatList += ";";
		endif 
		string thatLabel = GetDimLabel(cmpParamW, 1,i)
		if (strlen(thatLabel) <= 0)
			sprintf thatLabel, "cmp #%d", i; 
		endif
		thatList += thatLabel;
			
	endfor; 
	 thatList  = "\""+thatList+"\""
	PopupMenu 	$"cmpAliasThatCmp", value=#thatList, win=$(win)

	
	if (waveexists(cmpParamW))
		variable anAliasCmp = cmpParamW[13][cmpNo];
		variable thisState = 1;
		if (anAliasCmp == 0)
			anAliasCmp = cmpParamW[14];
			thisState = 2;
		endif 

		variable thatState = anAliasCmp > 0 ? 1 : 2;
		variable thatCmp = abs(anAliasCmp);
		if (thatCmp == cmpNo) // self-reference!
			anAliasCmp = 0;
		endif 
	else
		anAliasCmp = 0;
	endif
	
	if (anAliasCmp == 0) // no alias or no data
		PopupMenu 	$"cmpAliasThatState" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThatCmp" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThisState" mode=1, win=$(win)
		return 0; 		
	endif
	
	//alias exists
	PopupMenu 	$"cmpAliasThatState" disable=0, win=$(win)
	PopupMenu 	$"cmpAliasThisState", mode=(1+thisState), win=$(win)

	variable aliasIndex = thatCmp;
	if (thatCmp > (cmpNo+1)) // reduce the index 
		aliasIndex =  thatCmp -1;
	endif  

	PopupMenu 	$"cmpAliasThatCmp", disable=0,  mode=(aliasIndex), win=$(win)
	PopupMenu 	$"cmpAliasThatState", disable=0, mode=(thatState), win=$(win)
end


//--------------------------------------------------------------------
//
function /S cmpAliasThisState()
	string validFNameStr = "none;ox.;red."
	return validFNameStr;
end

//--------------------------------------------------------------------
//
Function cmpAliasThisStateProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable currState = pa.popnum-1;
	variable aliasState =  ctrlSelectorPos(pa.win, "cmpAliasThatState")
	variable aliasCmp =  ctrlSelectorPos(pa.win, "cmpAliasThatCmp")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)
	
End



//--------------------------------------------------------------------
//
function /S cmpAliasThatState()
	string validFNameStr = "ox.;red."
	return validFNameStr;
end


//--------------------------------------------------------------------
//
Function cmpAliasThatStateProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable aliasState = pa.popnum-1 
	variable currState =  ctrlSelectorPos(pa.win, "cmpAliasThisState")
	variable aliasCmp =  ctrlSelectorPos(pa.win, "cmpAliasThatCmp")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)
End


//--------------------------------------------------------------------
//
function /S cmpAliasThatSel()
	string validFNameStr = "-none-;"
	variable i, j;
	

end



//--------------------------------------------------------------------
//
Function cmpAliasThatSelectProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	if (pa.eventCode != 1 &&  pa.eventCode != 2)
		return 0;
	endif

	Variable aliasCmp = pa.popnum-1
	variable currState =  ctrlSelectorPos(pa.win, "cmpAliasThisState")
	variable aliasState =  ctrlSelectorPos(pa.win, "cmpAliasThatState")
	
	assignAllias(currState, aliasState, aliasCmp, pa.win)

End


//--------------------------------------------------------------------
//

function assignAllias(currState, aliasState, aliasCmp, win)
	variable currState,  aliasState, aliasCmp;
	string win;
	
	// name of components wave
	ControlInfo /W=$(win) $"compParamWSelect"
	wave cmpParamW =$(S_value)

	variable currCmp =  ctrlSelectorPos(win, "cmpSelect")

	
	if (currState == 0) // slected "none"
		PopupMenu 	$"cmpAliasThatState" disable=1, win=$(win)
		PopupMenu 	$"cmpAliasThatCmp" disable=1, win=$(win)
		cmpParamW[13,14][currCmp] = 0;
		return 0;
	endif

	if (aliasCmp >= currCmp)
		aliasCmp +=1;
	endif
	aliasCmp +=1;

	PopupMenu 	$"cmpAliasThatState" disable=0, win=$(win)
	PopupMenu 	$"cmpAliasThatCmp" disable=0, win=$(win)

	if (currState == 1) // set oxidized 
		cmpParamW[13][currCmp] = aliasCmp * ((aliasState == 0)? 1: -1);
		cmpParamW[14][currCmp] = 0;
	else // set reduced 
		cmpParamW[13][currCmp] = 0;
		cmpParamW[14][currCmp] = aliasCmp * ((aliasState == 0)? 1: -1);
	endif 

end





