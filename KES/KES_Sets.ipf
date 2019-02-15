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

