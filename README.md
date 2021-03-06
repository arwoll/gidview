"Gidview" is a matlab-based GUI for viewing and simple analysis of Grazing-Indcidence Diffraction data obtained at CHESS

Gidview depends on Matlab_Xray_Utils
Both packages are located at https://github.com/arwoll


Many of the scripts here relate to data obtained using proprietary software, SPEC (Certified Scientific Software, www.certif.com), and make use of the Openspec/openspec.m in this distribution.

To obtain Gidview : git clone https://github.com/arwoll/Gidview.git
To obtain Matlab_Xray_Utils : git clone https://github.com/arwoll/Matlab_Xray_Utils.git


******************************************************************
************* Setup Suggestion **********************************
******************************************************************

The file "sample_startup.m" in Setup/ defines a base path for various packages in this and related repositories. Suggested use is to put this file into the users default Matlab path (e.g. Documents/MATLAB/) and rename it to "startup.m", then use that file to call other setup scripts -- e.g. gid_setup.m (which uses the Gidview package and assumes it is in the same location as Matlab_Xray_Utils

****************************************************************** 
******************************************************************
******************************************************************

%%%%%%%%%%%%%%%%%%%%%%% COPYRIGHT %%%%%%%%%%%%%%%%%%%%%%%

Copyright (c) 2014, Arthur R. Woll
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted
	provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and
	the following disclaimer.

Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 	and the following disclaimer in the documentation and/or other materials provided with the
 	distribution.
 
Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to
  	endorse or promote products derived from this software without specific prior written
  	permission.
 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
