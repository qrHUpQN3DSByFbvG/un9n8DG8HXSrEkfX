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
