% Copyright (c) <2016-2018> <Amit Lal, Peng Xi>
% 
% Permission is hereby granted, free of charge, to any person obtaining a 
% copy of this software and associated documentation files (the "Software"), 
% to deal in the Software without restriction, including without limitation 
% the rights to use, copy, modify, merge, publish, distribute, sublicense, 
% and/or sell copies of the Software, and to permit persons to whom the 
% Software is furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included 
% in all copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
% DEALINGS IN THE SOFTWARE.

clear all
close all
clc

%% Loading system OTF file
OTFo = double(imread('OTF.tif'));
OTFo = OTFpost(OTFo); 

%% Read Expt. Raw SIM Images
aa1 = imread('sim01z4.tif');
aa = aa1(:,:,2);
bb = uint16(zeros(512,512,9));
for ii=1:3
     for jj=1:3
        bb(1:512,1:512,(ii-1)*3+jj)=aa((ii-1)*512+1:ii*512,(jj-1)*512+1:jj*512,1);
     end
end

% separating the raw SIM images
S1aTnoisy = double( bb(:,:,1) ); 
S2aTnoisy = double( bb(:,:,2) ); 
S3aTnoisy = double( bb(:,:,3) ); 
S1bTnoisy = double( bb(:,:,4) ); 
S2bTnoisy = double( bb(:,:,5) );
S3bTnoisy = double( bb(:,:,6) );
S1cTnoisy = double( bb(:,:,7) );
S2cTnoisy = double( bb(:,:,8) );
S3cTnoisy = double( bb(:,:,9) );
clear aa aa1 bb

%% Intensity Normalization
[S1aTnoisy, S2aTnoisy, S3aTnoisy, ...
 S1bTnoisy, S2bTnoisy, S3bTnoisy, ...
 S1cTnoisy, S2cTnoisy, S3cTnoisy] = BgNormalization0(...
    S1aTnoisy, S2aTnoisy, S3aTnoisy, ...
    S1bTnoisy, S2bTnoisy, S3bTnoisy, ...
    S1cTnoisy, S2cTnoisy, S3cTnoisy);

%% Background subtraction
SE = strel('disk',20);
S1aTnoisy = S1aTnoisy - imopen(S1aTnoisy,SE);
S2aTnoisy = S2aTnoisy - imopen(S2aTnoisy,SE);
S3aTnoisy = S3aTnoisy - imopen(S3aTnoisy,SE);
S1bTnoisy = S1bTnoisy - imopen(S1bTnoisy,SE);
S2bTnoisy = S2bTnoisy - imopen(S2bTnoisy,SE);
S3bTnoisy = S3bTnoisy - imopen(S3bTnoisy,SE);
S1cTnoisy = S1cTnoisy - imopen(S1cTnoisy,SE);
S2cTnoisy = S2cTnoisy - imopen(S2cTnoisy,SE);
S3cTnoisy = S3cTnoisy - imopen(S3cTnoisy,SE);

% tentative values to define search region for illumination frequency
% determination
k2o = 125; % tentative illumination frequency 
thetaA = 20*pi/180; % orientations of structured illumination
thetaB = 140*pi/180;
thetaC = 260*pi/180;

%% obtaining the noisy estimates of three frequency components
[fAo,fAp,fAm]...
    = PCMseparateF(S1aTnoisy,S2aTnoisy,S3aTnoisy,OTFo);
kA = IlluminationFreqTIRF(fAo,fAp,OTFo,k2o,thetaA);
[fBo,fBp,fBm]...
    = PCMseparateF(S1bTnoisy,S2bTnoisy,S3bTnoisy,OTFo);
kB = IlluminationFreqTIRF(fBo,fBp,OTFo,k2o,thetaB);
[fCo,fCp,fCm]...
    = PCMseparateF(S1cTnoisy,S2cTnoisy,S3cTnoisy,OTFo);
kC = IlluminationFreqTIRF(fCo,fCp,OTFo,k2o,thetaC);

% averaging the central frequency components
fCent = (fAo + fBo + fCo)/3;

% Object power parameters determination
OBJparaA = OBJpowerPara(fCent,OTFo);

%% Wiener Filtering the noisy frequency components
[fAof,fApf,fAmf,Nao,Nap,Nam,Ma,DoubleMatSize]...
    = PCMfilteringF(fAo,fAp,fAm,OTFo,OBJparaA,kA);
[fBof,fBpf,fBmf,Nbo,Nbp,Nbm,Mb,~]...
    = PCMfilteringF(fAo,fBp,fBm,OTFo,OBJparaA,kB);
[fCof,fCpf,fCmf,Nco,Ncp,Ncm,Mc,~]...
    = PCMfilteringF(fAo,fCp,fCm,OTFo,OBJparaA,kC);

%% doubling Fourier domain size if necessary
OTFo = OTFdoubling(OTFo,DoubleMatSize);

%% merging all 9 frequency components using generalized Wiener Filter
[Fsum,Fperi,Fcent] = MergingHeptaletsF(fAof,fApf,fAmf,...
    fBof,fBpf,fBmf,fCof,fCpf,fCmf,...
    Ma,Mb,Mc,Nao,Nap,Nam,Nbo,Nbp,Nbm,...
    Nco,Ncp,Ncm,kA,kB,kC,OBJparaA,OTFo);

% Plotting SIM results
SIMplot(Fsum,Fperi,Fcent,OTFo,kA,kB,kC,S1aTnoisy);

