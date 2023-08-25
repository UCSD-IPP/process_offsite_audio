# This program calls a set of Praat scripts to generate features for a specific .wav file
# 
#
#  Input:
#       inputWavFileName
#       acousticFeatureFileName
#       Gender ('Male' or 'Female')
#       Subject
#       Session
#    
#  Steps: 1. Make sure .wav file has been finished (copied using ffmpeg)
#  2. Example invocation string:
#  python /Users/Heisig/West/LEAP/AcousticFeatureGen/praatFeatureGen.py '/Users/Heisig/Library/CloudStorage/Box-Box/Q-Lab-MS/mayberg/QRID000812/QRID000812_07202022_13_48_46/iMotions/Q-Lab_Circuit_Cue_Cards/RCS812_7_20_22/Webcam/RespCam_RCS812_7_20_22_Rainbow_Passage_Reading_(0_MALE_1000).wav' /Users/Heisig/West/LEAP/AcousticFeatureGen/results/acousticFeatures.csv 'Male' '123' 'sessionx'
#
#  Prereqs: parselmouth v0.3.3
#
#  N.B.- The Praat scripts you run should be in the same directory as this python code.
#        You can point to any directory but if a script calls another script it will look in the directory
#        as where Praat is running.  
#
# Author: Stephen Heisig
# Initial Release: 7/3/19 - The dawn of time.
#

#        Imports
import os
import sys, traceback
import pandas as pd
import parselmouth
from io import StringIO
import numpy as np

import generateFormantStats

#        Settings
pd.set_option('display.max_columns', None)



print("praatFeatureGen V1.0")

inputWavFileName = sys.argv[1]
print('inputWavFileName: ',inputWavFileName)
acousticFeatureFileName = sys.argv[2]
print('acousticFeatureFileName: ',acousticFeatureFileName)

Gender = sys.argv[3]
print('Gender: ',Gender)

Subject = sys.argv[4]
print('Subject: ',Subject)

Session = sys.argv[5]
print('Session: ',Session)

path_file = os.path.split(acousticFeatureFileName) 
#Note this doesn't include the last /
pathName = path_file[0]+'/'
pauseDistFileName = pathName+'results/pauses.csv'
formantFileName = pathName+'results/formants.csv'

print("parselmouth.VERSION: ",parselmouth.VERSION)

#Vowel Space Constants
F1males = np.array([342, 768, 378, 427, 476, 580, 588, 652, 497, 469, 623, 474])
F1females = np.array([437, 936, 459, 483, 536, 731, 669, 781, 555, 519, 753, 523])
F2males = np.array([2322, 1333, 997, 2034, 2089, 1799, 1952, 997, 910, 1122, 1200, 1379])
F2females = np.array([2761, 1551, 1105, 2365, 2530, 2058, 2349, 1136, 1035, 1225, 1426, 1588])

#Reference Vowel Space Centroids
centroids_males = np.array([F1males, F2males]).T
centroids_females = np.array([F1females, F2females]).T

#This function takes the result from a Praat script and turns it into a dataframe
def processPraatScriptResults(resulting_objects):
    praatReturnStr = ''.join(map(str, resulting_objects[1]))
    printableChars = min(len(praatReturnStr),200)
    print('praatReturnStr: ',praatReturnStr[0:printableChars])
    readableStr = StringIO(praatReturnStr)
    featureDF = pd.read_csv(readableStr, sep=",")
    rows,cols = featureDF.shape
    printableRows = min(rows,5)
    print('printableRows: ',printableRows)
    print(featureDF.iloc[0:printableRows,:])
    return(featureDF)
    

#This function puts Subject,Session,filename in the first 3 columns of a DataFrame 
def addColumns(featureDF,Subject,Session,inputWavFileName):
    featureDF['filename'] = inputWavFileName
    tempCol = featureDF.pop('filename')
    featureDF.insert(0, 'filename', tempCol)
    
    featureDF['Session'] = Session
    tempCol = featureDF.pop('Session')
    featureDF.insert(0, 'Session', tempCol)   
     
    featureDF['Subject'] = Subject   
    tempCol = featureDF.pop('Subject')
    featureDF.insert(0, 'Subject', tempCol)    
    return(featureDF)    

#Parse out Subject and Session
print('inputWavFileName: ',inputWavFileName)
split1 = inputWavFileName.split('/')
wavFileName = split1[len(split1)-1]
print('wavFileName: ',wavFileName)

SubjectSession = Subject+'_'+Session
print('Subject: ',Subject)
print('Session: ',Session) 
print('SubjectSession: ',SubjectSession)  


totalDF = pd.DataFrame()

try:    
   
    # Before calling any scripts setup up the parameters first...
    if  Gender == 'Male': #subject is male
        init_centroids1 = centroids_males
        max_freq = 5000
        min_pitch = 75
        max_pitch = 300
    else:
        init_centroids1 = centroids_females
        max_freq = 5500
        min_pitch = 100
        max_pitch = 500
   

    #       Run the SyllableNuclei.praat script to generate the Syllable Nuclei features
    #       Want to run this against the entire file, not just speaking
    scriptToRun = 'SyllableNuclei.praat' #Needs to be in the same directory as this python code
    print('Running: ',scriptToRun) 
    resulting_objects = parselmouth.praat.run_file(scriptToRun, -25, 2, 0.3, False, inputWavFileName, capture_output=True)
    print('Back from: ',scriptToRun) 
    #Convert string version of variables to a dataframe
    snDF = processPraatScriptResults(resulting_objects)
    totalDF = pd.concat([totalDF, snDF], axis=1)
    
    
    #       Run the AVQR  script to generate voice quality metrics
    #       This will save a high passed speech only .wav file
    scriptToRun = 'AcousticVoiceQualityReport.praat' #Needs to be in the same directory as this python code
    channelToExtract = 1
    print('Running: ',scriptToRun) 
    resulting_objects = parselmouth.praat.run_file(scriptToRun, inputWavFileName, channelToExtract, 60, 600, capture_output=True)
    print('Back from: ',scriptToRun) 
    #Convert string version of variables to a dataframe
    avqrDF = processPraatScriptResults(resulting_objects)
    
            
    #       Run the Extract_Formants.praat script to generate first 4 formants for each frame
    scriptToRun = 'extractFormants.praat' #Needs to be in the same directory as this python code
    print('Running: ',scriptToRun) 
    resulting_objects = parselmouth.praat.run_file(scriptToRun, inputWavFileName, channelToExtract, max_freq, capture_output=True)
    print('Back from: ',scriptToRun) 
    #Convert string version of variables to a dataframe
    formantDF = processPraatScriptResults(resulting_objects)
    
    #Do a little column fixup  
    formantDF = addColumns(formantDF,Subject,Session,inputWavFileName) 
     
    #Write out raw formant data results   
    formantDF.to_csv(formantFileName,sep=',', index=False)
    
    #Calculate Formant Stats
    print('Off to generateFormantStats')
    formantStatDF = generateFormantStats.mainPath(formantDF)
    print('Back from generateFormantStats')
    
    #Mash the SyllableNuclei and AcousticVoiceQualityReport and Formant features together
    print('totalDF: \n',totalDF)
    print('avqrDF: \n',avqrDF)
    print('formantStatDF: \n',formantStatDF)
    totalDF = pd.concat([totalDF, avqrDF, formantStatDF], axis=1)
    print('totalDF.columns: ', totalDF.columns)
    
    #Do a little fixup here on the combined DataFrame
    totalDF.drop(['soundname'], axis=1, inplace=True)
    totalDF.drop(['fileName'], axis=1, inplace=True)
    
    totalDF = addColumns(totalDF,Subject,Session,inputWavFileName) 
    
    #   Save the Syllable Nuclei, AVQR, and Formant features to a file
    totalDF.to_csv(acousticFeatureFileName, index=False)
    
    
    #       Run the Pause_distribution.praat script to generate the silent sounding interval file
    scriptToRun = 'pauseDistribution.praat' #Needs to be in the same directory as this python code
    print('Running: ',scriptToRun) 
    #To TextGrid (silences)... 75 0 -25 0.1 0.1 silent sounding
    min_pitch = 75
    time_step = 0
    silence_threshold = -25
    min_silent_interval = 0.1
    min_sounding_interval = 0.1
    resulting_objects = parselmouth.praat.run_file(scriptToRun, min_pitch, time_step, silence_threshold,  min_silent_interval, min_sounding_interval, inputWavFileName, capture_output=True)
    print('Back from: ',scriptToRun) 
    #Convert string version of variables to a dataframe
    pauseDF = processPraatScriptResults(resulting_objects)
    
    #Do a little column fixup     
    pauseDF = addColumns(pauseDF,Subject,Session,inputWavFileName) 
    
    #Write out results
    pauseDF.to_csv(pauseDistFileName, index=False)
    

except:
    exceptionType, exceptionValue, exceptionTraceback = sys.exc_info()
    print("print_exception:")
    traceback.print_stack()
    traceback.print_exception(exceptionType, exceptionValue, exceptionTraceback, file=sys.stdout)
