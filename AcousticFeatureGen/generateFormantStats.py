#This code will generate a set of stats based on the raw Formant DataFrame....
#Works for standard formant data
#
#Input variables:
#formantDF  standard formant data from Praat
#
#Output
#formantStatsDF a one row DF of stats
#
# Author: Stephen Heisig
# Initial Release: 7/3/19 - The dawn of time.
#
#   Imports
from __future__ import division
#from sqlalchemy import *
import os
import sys
import traceback
import pandas as pd
import numpy as np
import datetime
import scipy as sp
import matplotlib as mp
import matplotlib.pyplot as plt
import math
import time, datetime
import seaborn as sns
import sklearn.cluster as cluster
#import cv2
import numpy as np
import scipy.signal
import scipy.io.wavfile
from scipy import stats


#  Settings
pd.set_option('display.max_columns', 500)
pd.set_option('display.max_rows', 5000)
pd.set_option('display.width', 1000)

sns.set() # seaborn default style
mp.rcParams['agg.path.chunksize'] = 10000
plt.rcParams["axes.grid"] = False
#Convert warnings to errors
import warnings
warnings.simplefilter('error', RuntimeWarning)

def computeBasicFeatures(successful_metrics,metric_name):
    featureSuffixes = ['_Mean','_Var','_Kur','_Skew','_Median','_qtl05', '_IQR','_qtl95' ]
    featureNames = [metric_name+s for s in featureSuffixes]
    mean = np.mean(successful_metrics)
    var = np.var(successful_metrics)
    median = np.median(successful_metrics)
    kur = sp.stats.kurtosis(successful_metrics)
    skew = sp.stats.skew(successful_metrics)
    iqr = stats.iqr(successful_metrics)
    qtl05 = np.quantile(successful_metrics, .05)
    qtl95 = np.quantile(successful_metrics, .95)      
    features = [ mean, var, kur, skew, median, qtl05, iqr, qtl95 ]
    print('basicFeatureNames: \n',featureNames)
    print('basicFeatures: \n',features)
    return [features,featureNames]  
   
    
#             Main Path Starts Here
def mainPath(formantDF):
    print('generateFormantStats V0.19')

    featureSet = []
    featureNameSet = []
    formantCols = ['F1(Hz)','B1(Hz)','F2(Hz)','B2(Hz)','F3(Hz)','B3(Hz)','F4(Hz)','B4(Hz)','F5(Hz)','B5(Hz)']
    for metric_name in formantCols:
        #Change --undefined-- character values to NaNs
        metrics = formantDF[metric_name]
        metrics.replace('--undefined--', np.NaN, inplace=True)
        metrics.dropna(inplace=True) 
        print('type(metrics): ',type(metrics))
        #print('metrics: ',metrics) 
        metrics=  metrics.astype(float) 
        #print('metrics: ',metrics)
        basicFeatures, basicFeatureNames = computeBasicFeatures(metrics,metric_name)
        featureSet.extend(basicFeatures)
        featureNameSet.extend(basicFeatureNames)
        print('len(featureSet): \n',len(featureSet))
        print('len(featureNameSet): \n',len(featureNameSet))
        print('featureSet: \n',featureSet)
        print('featureNameSet: \n',featureNameSet)
        formantStatDF = pd.DataFrame(columns=featureNameSet)
        formantStatDF.loc[0] = featureSet
    return formantStatDF     


