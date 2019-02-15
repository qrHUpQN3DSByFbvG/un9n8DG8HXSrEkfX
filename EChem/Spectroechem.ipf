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

#pragma rtGlobals=1		// Use modern global access method.

strconstant cSEChemHome =  "root:Packages:SpectroEChem"

//~~~~~~~~~~~~~~~~~
Menu "Analysis"
	Submenu "Spectro E-Chem"
		"Show panel", /Q, SEChemMenu ()
		"Unload", /Q, UnloadSEChem()
	end
end

//~~~~~~~~~~~~~~~~~
function SEChemMenu()
	InitSEChemParams() // set parameters from local directory
	
	if (wintype("SEChemPanel") == 0)
		CreateSEChemPanel()
	else
		DoWindow/F SEChemPanel
	endif
end

//~~~~~~~~~~~~~~~~~
Function UnloadSEChem()
	if (WinType("SEChemPanel") == 7)
		DoWindow/K SEChemPanel
	endif
	if (DatafolderExists(cSEChemHome))
		KillDatafolder $cSEChemHome
	endif
	Execute/P "DELETEINCLUDE  <spectroechem>"
	Execute/P "COMPILEPROCEDURES "
end

//~~~~~~~~~~~~~~~~~
// Initialization 
function InitSEChemParams()
	variable /G seesawBlanks, seesawTrailers, seesawFinalRepeat
	variable /G seesawEFrom, seesawETo, seesawEStep

	string /G DataWaveN, EClbWaveN, EChemWaveSuffix, BkgWaveSuffix, SeesawClbWaveSuffix, E_WaveSuffix
	if (!strlen(SeesawClbWaveSuffix))
		SeesawClbWaveSuffix = "_EEx"
	endif

	if (!strlen(EChemWaveSuffix))
		EChemWaveSuffix = "_Rsp"
	endif
	if (!strlen(BkgWaveSuffix))
		BkgWaveSuffix = "_Bkg"
	endif
	if (!strlen(E_WaveSuffix))
		E_WaveSuffix = "_ERd"
	endif

end


//---------------------------------------------------------------------
//
Function CleanupSEChemParams_DELME()
	DoAlert 1, "You are about to delete variables and waves used in S-EChem corrections and reduction. Do you want to continue?"
	if (V_Flag ==2)
		return 0
	endif
	
	KillVariables /Z seesawBlanks, seesawFinalRepeat, seesawTrailers
	KillVariables /Z seesawEFrom, seesawETo, seesawEStep
	KillStrings /Z DataWaveN, EClbWaveN, EChemWaveSuffix, BkgWaveSuffix, SeesawClbWaveSuffix, E_WaveSuffix

	if (V_Flag == 2)
//		KillWaves /Z AdditionsList, AdditivesList, ReductionList, ExtraParamsList
	endif
End

//---------------------------------------------------------------------
//
Function/S SEChemSourceContents()
	String theContents=""
	theContents = "_none_;"+WaveList("*", ";", "DIMS:2")
	return theContents
end

//---------------------------------------------------------------------
//
Function/S SEChemClbContents_DELME()
	String theContents=""
	theContents = WaveList("*", ";", "DIMS:1")
	return theContents
end

//---------------------------------------------------------------------
//
Function SEChemSourceProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	SVAR DWaveS = $"root:DataWaveN"
	
	if (!cmpstr(popStr, "_none_") || !strlen(popStr))
		DWaveS = "";
		// disable Do button
		return 0;
	endif	

	// store full name in MWave
	String CDF=GetDataFolder(1)
	DWaveS = CDF + popStr
End

//---------------------------------------------------------------------
//
Function CreateSeeSawClbProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode !=2)
		return 0
	endif
	return DoEClb("SeeSaw");
end

//---------------------------------------------------------------------
//
Function CreateReducedClbProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode !=2)
		return 0
	endif
	return DoEClb("RedClb");
end

//---------------------------------------------------------------------
//
Function SplitComponentsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	if (ba.eventCode !=2)
		return 0
	endif
	return DoEClb("Components");
end

//---------------------------------------------------------------------
//
Function DoEClb(Mode)
	string Mode 
	// 0 = Seesaw calibratiuon
	// 1 = E calibration
	// 2 = echem & bkg components
	// 
	
	// check is main dataset was selected
	SVAR DataWN = $"root:DataWaveN"
	if (exists(DataWN)!=1)
		DoAlert 0,"Please select dataset first...";
		return 0
	endif
	variable NSpectra = dimsize($DataWN,1)

	NVAR nBlanks = $"root:seesawBlanks"
	NVAR nTrailers = $"root:seesawTrailers"
	NVAR EFrom = $"root:seesawEFrom"
	NVAR ETo = $"root:seesawETo"
	NVAR EStep = $"root:seesawEStep"
	NVAR fRepeat = $"root:seesawFinalRepeat" // applies to bi-directional only, n scans at final E before reverse scan begins

	// verify that a correct method is selected
	ControlInfo /W=SEChemPanel SEChemMethodPopup
	string method = S_Value
	variable NSteps;
	
	
	ControlInfo  DataFirstIsRefCheck
	variable addRef = V_Value

	strswitch (method) 
		case "seesaw":
		case "pulse":
			variable biDirect;
			ControlInfo  seesawReverseCheck
			biDirect = V_Value

			if (EStep == 0) 
				DoAlert 0,"Seesaw step cannot be zero.";
				return 0
			endif 

			NSteps = round((ETo - EFrom) / EStep)
			if (NSteps <= 0) 
				DoAlert 0,"Incorrect step parameters, please revise.";
				return 0
			endif 

			break;
		case "repeat":
			biDirect = 0;
			NSteps = 0.5 *(NSpectra - nBlanks - nTrailers);
			ControlInfo  DataAverageCheck
			if (V_Value)
				method +="_ave";
			else
				NSteps = round(NSteps);		
			endif;
			break;
		default:
			DoAlert 0,"Please select a valid method...";
			return 0
	endswitch
		
	variable NPoints = NSteps * (1 + biDirect);
	strswitch (Mode)
		case "SeeSaw":
			if (nBlanks > 0)
				NPoints +=nBlanks;
			endif
			if (biDirect && fRepeat > 0)
				NPoints += fRepeat // for edge values
			endif
	  
			if (nTrailers > 0)
				NPoints +=nTrailers;
			endif
			break;
		case "RedClb":
		case "Components":
			if (nBlanks > 0)
				NPoints +=1;
			endif
	
			if (biDirect && fRepeat > 0)
				NPoints += 1;
			endif
	  
			if (nTrailers > 0)
				NPoints +=1;
			endif
			break;
	endswitch 
	  

	strswitch (mode)
		case "SeeSaw":
			SVAR SeesawClbWaveSuffix
			if (strlen(SeesawClbWaveSuffix)==0)
				SeesawClbWaveSuffix = "_EEx"
			endif
			 DoOriginalClb(method, EFrom, EStep, nSteps, dimsize($DataWN,1), nBlanks,  biDirect, fRepeat, DataWN + SeesawClbWaveSuffix)
			break;	
		case "RedClb":
			SVAR E_WaveSuffix
			if (strlen(E_WaveSuffix)==0)
				E_WaveSuffix = "_ERd"
			endif
			if (biDirect)
				DoMakeClb(method, EFrom+EStep, EStep, nSteps,  addref, EFrom, DataWN + E_WaveSuffix+"F")
				DoMakeClb(method, ETo, -EStep, nSteps, addref, ETo,  DataWN + E_WaveSuffix+"R")
			else
				DoMakeClb(method, EFrom+EStep, EStep, nSteps+1, addref, EFrom,  DataWN + E_WaveSuffix)
			endif

			break;
		case "Components": // data
			SVAR EChemWaveSuffix
			if (strlen(EChemWaveSuffix)==0)
				EChemWaveSuffix = "_Rsp"
			endif

			SVAR BkgWaveSuffix
			if (strlen(BkgWaveSuffix)==0)
				BkgWaveSuffix = "_Bkg"
			endif
			
			if (biDirect)
				if (addRef)
					DoSplitComponents(method, $DataWN, NSteps, DataWN + EChemWaveSuffix+"F",DataWN + BkgWaveSuffix+"F", 0, 0, nBlanks+addRef, fRepeat)
					DoSplitComponents(method, $DataWN, NSteps, DataWN + EChemWaveSuffix+"R",DataWN + BkgWaveSuffix+"R", NSteps, nBlanks, fRepeat+addRef, nTrailers)
				else
					DoSplitComponents(method, $DataWN, NSteps, DataWN + EChemWaveSuffix+"F",DataWN + BkgWaveSuffix+"F", 0, nBlanks, 0, fRepeat)
					DoSplitComponents(method, $DataWN, NSteps, DataWN + EChemWaveSuffix+"R",DataWN + BkgWaveSuffix+"R", NSteps, nBlanks+ fRepeat+1,0, nTrailers)
				endif
			else
				print  "DoSplitComponents(", method,", ave(",DataWN,"), ",NSteps,", ", (DataWN + EChemWaveSuffix),", ",(DataWN + BkgWaveSuffix),", ", 0,", ", 0,", ", num2str(nBlanks+addRef),", ",  nTrailers,")"
				DoSplitComponents(method, $DataWN, NSteps, DataWN + EChemWaveSuffix,DataWN + BkgWaveSuffix, 0, 0, nBlanks+addRef,  nTrailers)
			endif
			break;
	endswitch
	
End

//---------------------------------------------------------------------
//

function DoOriginalClb(method, E0, EStep, NSteps, NSpectra, nBlanks,  biDirect, fRepeat, ClbWN)
	string method
	variable E0, EStep, NSteps, NSpectra, nBlanks, biDirect, fRepeat
	string ClbWN
	

	variable s
	variable cPnt = 0;
	variable E = E0;
	
	
	make /O/D/N=(NSpectra) $ClbWN
	wave ClbW = $ClbWN

	// blanks
	if (nBlanks > 0 )
		ClbW[cPnt, cPnt+nBlanks] = E;
		cPnt +=nBlanks; 
	endif;

	strswitch (method)
		case "seesaw":
			for (s=0; ((s<NSteps) && (cPnt < NSpectra)); s+=1)
				ClbW[cPnt] = E
				ClbW[cPnt+1]= E + EStep;
				ClbW[cPnt+2]= E;
				E+=EStep;
				cPnt +=3
			endfor
			break;
		case "pulse":
			for (s=0; ((s<NSteps) && (cPnt < NSpectra)); s+=1)
				E+=EStep;
				ClbW[cPnt] = E0
				ClbW[cPnt+1]= E;
				cPnt +=2
			endfor
			// one more is needed to complete the cycle
			ClbW[cPnt] = E0
			ClbW[cPnt+1]= E;
			cPnt +=2
			break;
	endswitch 

	if (biDirect)
		for (s=0; ((s<fRepeat) && (cPnt < NSpectra)); s+=1, cPnt+=1)
			ClbW[cPnt] = E
		endfor 
		strswitch (method)
			case "seesaw":
				for (s=0; ((s<NSteps) && (cPnt < NSpectra)); s+=1)
					ClbW[cPnt] = E
					ClbW[cPnt+1]= E - EStep;
					ClbW[cPnt+2]= E;
					cPnt+=3
					E-=EStep
				endfor 
				break;
			case "pulse":
				// first step is needed to get reference point 
				ClbW[cPnt] = E0
				ClbW[cPnt+1]= E;
				cPnt +=2
				for (s=0; ((s<NSteps) && (cPnt < NSpectra)); s+=1)
					E-=EStep
					ClbW[cPnt] = E0
					ClbW[cPnt+1]= E;
					cPnt+=2
				endfor
				break;
		endswitch
	endif
	ClbW[cPnt, ]= E;
end

//---------------------------------------------------------------------
//

function 	DoMakeClb(method, E0, EStep,  NCycles, nref, eRef, EClbWN)
			string method
			variable E0, EStep
			variable NCycles, nRef, eRef
			string EClbWN

			variable nSpectra = NCycles;
			if (nRef)
				nSpectra += 1 
			endif
			make /O/D/N=(nSpectra) $EClbWN
			wave ClbW = $EClbWN

			variable cPnt = 0
			variable i, s, E = E0;

			if (nRef)
				ClbW[cPnt] = ERef; // initial 
				cPnt +=1; 
			endif

			for (s=0; s<NCycles; s+=1)
				ClbW[cPnt] = E
				E+=EStep;
				cPnt +=1
			endfor 
			

end

//---------------------------------------------------------------------
//

function DoSplitComponents(method, DataW, NCycles, EChWN, BkgWN, skipSteps, nBlanks, nRefs, nTrailers)
			string method
			wave DataW
			variable NCycles, nBlanks, nRefs, nTrailers, skipSteps
			string EChWN, BkgWN 
			print "DoSplitComponents(",method,",",nameofwave(DataW),",",num2str(NCycles),",",EChWN,",", BkgWN,",", num2str(skipSteps),",", num2str(nBlanks),",", num2str(nRefs),",", num2str(nTrailers),")"
		
			variable nSpectra = NCycles;
			strswitch (method)
				case "seesaw":
				case "pulse":
				case "repeat":
					nSpectra = NCycles;
					break;
				case "repeat_ave":
					nSpectra = 1;
					break;
				default :
				return -1;
			endswitch 
			
			string DataWN = nameofwave(DataW)
			variable nDim0 = dimsize($DataWN, 0)
			if (nRefs>0) 
				nSpectra += 1;
			endif

			if (nSpectra > 1)
				make /O/D/N=(nDim0, nSpectra) $EChWN
				make /O/D/N=(nDim0, nSpectra) $BkgWN
			else
				make /O/D/N=(nDim0) $EChWN
				make /O/D/N=(nDim0) $BkgWN
			endif
			wave EChW = $EChWN
			wave BkgW = $BkgWN

			variable cPnt = 0 // component (result) pointer
			variable dPnt; // data pointer
			
			// move data pointer to skip blanks and cycles as requested
			dPnt = nBlanks;
			strswitch (method)
				case "seesaw":
					dPnt += skipSteps*3;
					break;
				case "pulse":
				case "repeat":
				case "repeat_ave":
					dPnt += skipSteps*2;
					if (skipsteps > 0)
						dPnt+=1; // in pulse mode the first 
					endif
					break;
					
				default :
				return -1;
			endswitch 


			// average reference spectra
			variable i, s;
			if (nRefs > 0 )
				EChW[][cPnt] = 0; 
				for (i=0; i< nRefs; i+=1)
					EChW[][cPnt]  += DataW[p][dPnt+i]
				endfor
				EChW[][cPnt] /= nRefs;
				if (skipSteps>0) // this is reverse leg
					strswitch (method)
						case "seesaw":
						case "repeat":
						case "repeat_ave":
							// check what should go on here
							break;
						case "pulse":
							dPnt+=1; 
							break;
						default :
						return -1;
					endswitch 
				endif
				dPnt+=nRefs-1;
				cPnt +=1;  // output[0] now contains averaged reference
			endif

			// perform splitting
			variable verbose = 0;
			strswitch (method)
				case "seesaw":
					for (s=0; ((s<NCycles) && (cPnt < nSpectra)); s+=1)
						EChW[][cPnt]= EChW[p][cPnt-1]+ 0.25 * (- DataW[p][dPnt] + 3 * DataW[p][dPnt+1] - 3 * DataW[p][dPnt+2]+  DataW[p][dPnt+3]) 
						BkgW[][cPnt] = BkgW[p][cPnt-1]+0.25 * (- DataW[p][dPnt] - DataW[p][dPnt+1] + DataW[p][dPnt+2] + DataW[p][dPnt+3])
						dPnt +=3
						cPnt +=1
					endfor 
					break;
				case "pulse":
				case "repeat": // this does not allow for half-cycle
					for (s=0; ((s<NCycles) && (cPnt < nSpectra - 1)); s+=1)
						EChW[][cPnt]= 0.5 * (- DataW[p][dPnt] + 2 * DataW[p][dPnt+1] -  DataW[p][dPnt+2]) 
						BkgW[][cPnt] = 0.5 * (- DataW[p][dPnt] + DataW[p][dPnt+2])
						dPnt +=2
						cPnt +=1
					EChW[][cPnt]= - DataW[p][dPnt] +  DataW[p][dPnt+1] - BkgW[p][cPnt-1]
					BkgW[][cPnt] = 0

					endfor 
					break;
				case "repeat_ave":
					variable n_high = floor(NCycles);
					variable n_low = ceil(NCycles); // this may be same as n_high or larger if the number of measurements is odd
					variable factor = 1 / n_high;
					EChW[][cPnt]  = 0;
					if (verbose) 
						print "cycles: ", nCycles, " high:",n_high, " low:", n_low 
						print "add:"
					endif;
					
					for (s=0; s < n_high; s+=1)
						EChW[][cPnt] += factor* DataW[p][dPnt + 1 + s*2]  
						if (verbose) 
							print dPnt + 1 + s*2 
						endif;
					endfor 
					factor = 1 / n_low;
					if (verbose) 
						print "subtract:" 
					endif 
					for (s=0; s < n_low; s+=1)
						EChW[][cPnt] -= factor* DataW[p][dPnt + s*2]  
						if (verbose) 
							print dPnt + s*2 
						endif
					endfor 
					BkgW[][cPnt] = (DataW[p][dPnt + n_low *2 -1]   - DataW[p][dPnt] ) / NCycles
					if (! mod(NCycles, 2)) // even, complete cycle
						BkgW[][cPnt] -=  EChW[p][cPnt]   / NCycles;
						EChW[][cPnt] -= 0.5 * BkgW[p][cPnt] ;  //why?!! Check math
						if (verbose) 
							print "even number of cylces,", num2str(NCycles), ", subtract ", num2str(cPnt) 
						endif
					else
						if (verbose) 
							print "odd number of cylces,", num2str(NCycles) 
						endif
					endif
					break;
				default :
					return -1;
			endswitch 

			if (nRefs > 0) // only in this case first trace is a reference
				ControlInfo   /W=SEChemPanel DataSubtrFirstCheck
				if (V_Value) // subtract the first from the rest....
					EChW[][1,] = EChW[p][q] - EChW[p][0]
					BkgW[][1,] = BkgW[p][q] - BkgW[p][0]
					EChW[][0] = 0
					BkgW[][0] = 0
				endif 
			endif
end

//---------------------------------------------------------------------
//
Function ClbSourceProc_DELME(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr

	SVAR DWaveS = $"EClbWaveN"
	
	if (!cmpstr(popStr, "_none_") || !strlen(popStr))
		DWaveS = "";
		// disable Do button
		return 0;
	endif	

	// store full name in MWave
	String CDF=GetDataFolder(1)
	DWaveS = CDF + popStr

End
//---------------------------------------------------------------------
//
Function RedDataDifferenceCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	if ( cba.eventCode !=2)
		return 0
	endif
	if (cba.checked)
		modifycontrol DataSubtrFirstCheck disable = 0
	else
		modifycontrol DataSubtrFirstCheck disable = 2
	endif
End

//---------------------------------------------------------------------
//
Function BiDirectCheckProc(cba) : CheckBoxControl
	STRUCT WMCheckboxAction &cba

	if ( cba.eventCode !=2)
		return 0
	endif
	if (cba.checked)
		modifycontrol seesawFinalRepeatEdit disable = 0
	else
		modifycontrol seesawFinalRepeatEdit disable = 1
	endif
End

//******************************************************************************************************************************

function CreateSEChemPanel()
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(108,99,475,500) /N=SEChemPanel as "E-Chem seesaw processing"
	ModifyPanel fixedSize=1
	GroupBox DataGroup,pos={5,4},size={350,55},title="Spectral Data",fSize=14
	GroupBox DataGroup,fStyle=1
	PopupMenu DataWavePopup,pos={16,26},size={294,23},bodyWidth=225,proc=SEChemSourceProc,title="matrix wave"
	PopupMenu DataWavePopup,mode=13,popvalue=">> select spectral data <<",value= #"SEChemSourceContents()"
	GroupBox PotentialGroup,pos={5,65},size={350,55},title="Potential",fSize=14
	GroupBox PotentialGroup,fStyle=1
	SetVariable seesawInitEEdit,pos={24,92},size={83,18},bodyWidth=50,title="initial"
	SetVariable seesawInitEEdit,limits={-inf,inf,0.02},value= seesawEFrom
	SetVariable seesawFinalEEdit,pos={140,92},size={77,18},bodyWidth=50,title="final"
	SetVariable seesawFinalEEdit,limits={-inf,inf,0.02},value= seesawETo
	SetVariable seesawStepEEdit,pos={241,92},size={81,18},bodyWidth=50,title="step"
	SetVariable seesawStepEEdit,limits={-inf,inf,0.02},value= seesawEStep
	GroupBox OptionsGroup,pos={5,127},size={350,105},title="Data Options",fSize=14
	GroupBox OptionsGroup,fStyle=1
	SetVariable blanksEdit,pos={19,150},size={128,18},bodyWidth=50,title="blank spectra"
	SetVariable blanksEdit,limits={0,inf,1},value= seesawBlanks
	SetVariable trailersEdit,pos={187,150},size={135,18},bodyWidth=50,title="trailing spectra"
	SetVariable trailersEdit,limits={0,inf,1},value= seesawTrailers
	SetVariable seesawFinalRepeatEdit,pos={177,172},size={145,18},bodyWidth=50,title="spectra at final E"
	SetVariable seesawFinalRepeatEdit,limits={0,inf,1},value= seesawFinalRepeat
	CheckBox seesawReverseCheck,pos={19,174},size={89,15},proc=BiDirectCheckProc,title="bi-directional"
	CheckBox seesawReverseCheck,value= 1
	CheckBox DataFirstIsRefCheck,pos={20,210},size={136,15},proc=RedDataDifferenceCheckProc,title="1st spectrum is blank"
	CheckBox DataFirstIsRefCheck,value= 0
	CheckBox DataAverageCheck,pos={176,192},size={150,15},disable=2,title="average data"
	CheckBox DataAverageCheck,value= 1
	CheckBox DataSubtrFirstCheck,pos={176,210},size={150,15},disable=2,title="subtract blank spectrum"
	CheckBox DataSubtrFirstCheck,value= 1
	SetVariable EchemWaveSuffixEdit,pos={35,336},size={127,18},bodyWidth=50,title="EChem suffix"
	SetVariable EchemWaveSuffixEdit,value= EChemWaveSuffix
	SetVariable EClbWaveSuffixEdit,pos={6,306},size={156,18},bodyWidth=50,title="Processed E suffix"
	SetVariable EClbWaveSuffixEdit,value= E_WaveSuffix
	SetVariable ExptEWaveSuffixEdit,pos={23,281},size={139,18},bodyWidth=50,title="Original E suffix"
	SetVariable ExptEWaveSuffixEdit,value= SeesawClbWaveSuffix
	SetVariable BkgWaveSuffixEdit,pos={12,360},size={151,18},bodyWidth=50,title="Background suffix"
	SetVariable BkgWaveSuffixEdit,value= BkgWaveSuffix
	PopupMenu SEChemMethodPopup,pos={37,243},size={272,23},bodyWidth=225,title="method"
	PopupMenu SEChemMethodPopup,mode=2,proc=SEChemMethodPopProc,popvalue=">> Select method <<",value= #"\"Seesaw;Pulse;Repeat\""
	Button seesawECreateButton,pos={169,279},size={175,22},proc=CreateSeeSawClbProc,title="Create Original E Clb"
	Button EClbCreateButton,pos={168,305},size={175,22},proc=CreateReducedClbProc,title="Create Processed E Clb"
	Button SplitComponentsButton,pos={168,334},size={175,45},proc=SplitComponentsProc,title="Split components"
	
 end

//******************************************************************************************************************************
//******************************************************************************************************************************
//******************************************************************************************************************************



Function SEChemMethodPopProc(pa) : PopupMenuControl
	STRUCT WMPopupAction &pa

	switch( pa.eventCode )
		case 2: // mouse up
			Variable popNum = pa.popNum
			String popStr = pa.popStr
			strswitch (popStr)
				case "Pulse":
				case "SeeSaw":
					// enable input fields
					modifycontrol seesawReverseCheck disable = 0
					modifycontrol seesawInitEEdit disable = 0
					modifycontrol seesawFinalEEdit disable = 0
					modifycontrol seesawStepEEdit disable = 0
					modifycontrol seesawECreateButton disable = 0
					modifycontrol EClbCreateButton disable = 0
					modifycontrol ExptEWaveSuffixEdit disable = 0
					modifycontrol EClbWaveSuffixEdit disable = 0
					modifycontrol DataAverageCheck disable = 1
					break;
				case "Repeat":
					// disable input fields
					modifycontrol seesawReverseCheck disable = 1
					modifycontrol seesawInitEEdit disable = 1
					modifycontrol seesawFinalEEdit disable = 1
					modifycontrol seesawStepEEdit disable = 1
					modifycontrol seesawECreateButton disable = 1
					modifycontrol EClbCreateButton disable = 1
					modifycontrol ExptEWaveSuffixEdit disable = 1
					modifycontrol EClbWaveSuffixEdit disable = 1
					modifycontrol DataAverageCheck disable = 0
					break;
			endswitch
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
