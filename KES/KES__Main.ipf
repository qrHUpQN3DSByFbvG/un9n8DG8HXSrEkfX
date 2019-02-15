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
#pragma IgorVersion=8.0

strconstant cKESVer = "1.6.7a"

#include  ":KES_Sim_Parallel", version>= 20190123
#include  ":KES_Sim_Sequential", version>= 20190123
#include  ":KES_Common", version>= 20190123
#include  ":KES_Data", version>= 20190123
#include  ":KES_RKInt", version>= 20170309
#include  ":KES_Sets", version>= 20190123
#include  ":KES_Templates", version>= 20170309
#include  ":KES_Panel", version>= 20170607

