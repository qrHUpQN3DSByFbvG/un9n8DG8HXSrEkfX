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

#pragma version = 20190123


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
