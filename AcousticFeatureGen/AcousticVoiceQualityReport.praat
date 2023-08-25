#
#          ACOUSTIC VOICE FEATURE REPORT
#
#   This Praat script generates some interesting features from a wav file. It can be run directly in Praat
# or in batch mode from python. It returns the features as a row of column names and row of values. 
#
#  Author: Stephen Heisig
#  4/21/19: Dawn of Time
#

#                 Input variables
#  1. wav file to process
#  2. Channel number in the .wav file to process
form Variables
    sentence inputWavFileName
    positive channelToProcess
    real pitch_Floor 60
    real pitch_Ceiling 600
endform

#                    Parameters
#For non-pathological voices these frequency ranges are good (Vogel et. al.):
#100-300 Hz and 100-250 Hz for females, and 70 to 250 Hz


#                   Read input .wav file
Read from file: inputWavFileName$
Extract one channel... channelToProcess
Rename... rawInputSound


#                   High pass the sound
stop_Floor = 0
stop_Ceiling = 34
smoothing_Width = 0.1

Filter (stop Hann band)... stop_Floor stop_Ceiling smoothing_Width
Rename... highPassedInputSound


select Sound highPassedInputSound

#Get the sampling rate of the band passed sound 
samplingRate = Get sampling frequency
intermediateSamples = Get sampling period

#Create stub sound to add bits onto later
Create Sound... onlyVoice 0 0.001 'samplingRate' 0 

#                  Seperate Speech and Silence Intervals
select Sound highPassedInputSound
silence_Pitch_Floor = 50
silence_Time_Step = 0.003
silence_ThresholdDb = -30
silence_Minimum_Interval_Duration = 0.1
silence_Minimum_Sounding_Interval_Duration = 0.1
To TextGrid (silences)... silence_Pitch_Floor silence_Time_Step silence_ThresholdDb silence_Minimum_Interval_Duration silence_Minimum_Sounding_Interval_Duration silence sounding

select Sound highPassedInputSound
plus TextGrid highPassedInputSound
Extract intervals where... 1 no "does not contain" silence
Concatenate
select Sound chain
Copy... onlyLoud
globalPower = Get power in air
select TextGrid highPassedInputSound


select Sound onlyLoud
signalEnd = Get end time
windowBorderLeft = Get start time
windowWidth = 0.03
windowBorderRight = windowBorderLeft + windowWidth
globalPower = Get power in air
voicelessThreshold = globalPower*(30/100)

select Sound onlyLoud
# Want to save this for other analysis later
#Save as WAV file: "/Users/Mjnxnl/West/WestAtHomeSamples/results/P801_20200423/DeNovoFeatures/onlyLoud.wav"

extremeRight = signalEnd - windowWidth
while windowBorderRight < extremeRight
	Extract part... 'windowBorderLeft' 'windowBorderRight' Rectangular 1.0 no
	select Sound onlyLoud_part
	partialPower = Get power in air
	#writeInfoLine: "partialPower in air: ",partialPower," ",voicelessThreshold
	if partialPower > voicelessThreshold
		call checkZeros 0
		if (zeroCrossingRate <> undefined) and (zeroCrossingRate < 3000)
			select Sound onlyVoice
			plus Sound onlyLoud_part
			Concatenate
			Rename... onlyVoiceNew
			select Sound onlyVoice
			Remove
			select Sound onlyVoiceNew
			Rename... onlyVoice
		endif
	endif
	select Sound onlyLoud_part
	Remove
	windowBorderLeft = windowBorderLeft + 0.03
	windowBorderRight = windowBorderLeft + 0.03
	select Sound onlyLoud
endwhile
select Sound onlyVoice

procedure checkZeros zeroCrossingRate
    #writeInfoLine: "check Zeros"
	start = 0.0025
	startZero = Get nearest zero crossing... 1 start
	findStart = startZero
	findStartZeroPlusOne = startZero + intermediateSamples
	startZeroPlusOne = Get nearest zero crossing... 1 findStartZeroPlusOne
	zeroCrossings = 0
	strips = 0

	while (findStart < 0.0275) and (findStart <> undefined)
		while startZeroPlusOne = findStart
			findStartZeroPlusOne = findStartZeroPlusOne + intermediateSamples
			startZeroPlusOne = Get nearest zero crossing... 1 findStartZeroPlusOne
		endwhile
		afstand = startZeroPlusOne - startZero
		strips = strips +1
		zeroCrossings = zeroCrossings +1
		findStart = startZeroPlusOne
	endwhile
	zeroCrossingRate = zeroCrossings/afstand
endproc



#     --- Calculate Voice Report Stats on the whole original signal ---
#select Sound highPassedInputSound

#                       ----- OR -----

#         Separate Vowels and Calculate Voice Report Stats
select Sound highPassedInputSound
include extractVowels.praat
Rename... highPassedInputSound

#time_Step = 100 default
time_Step = 0.010
max_Candidates = 15
very_Accurate$ = "yes" 
silence_Threshold = 0.03
voicing_Threshold = 0.45
octave_Cost = 0.01
octave_JumpCost = 0.35
voiced_UnvoicedCost = 0.14

To Pitch (cc)... time_Step pitch_Floor max_Candidates very_Accurate$ silence_Threshold voicing_Threshold octave_Cost octave_JumpCost voiced_UnvoicedCost pitch_Ceiling
select Sound highPassedInputSound
plus Pitch highPassedInputSound
To PointProcess (cc)
Rename... highPassedInputSound2
select Sound highPassedInputSound
plus Pitch highPassedInputSound
plus PointProcess highPassedInputSound2
voiceReport$ = Voice report... 0 0 pitch_Floor pitch_Ceiling 1.3 1.6 0.03 0.45


#           Parse whole original Voice report

pitch_Mean_all = extractNumber(voiceReport$, "Mean pitch: ")
pitch_Median_all = extractNumber(voiceReport$, "Median pitch: ")
pitch_Min_all = extractNumber(voiceReport$, "Minimum pitch: ")
pitch_Max_all = extractNumber(voiceReport$, "Maximum pitch: ")
pitch_Std_all = extractNumber(voiceReport$, "Standard deviation: ")

pulse_Count_all = extractNumber(voiceReport$, "Number of pulses: ")
period_Mean_all = extractNumber(voiceReport$, "Mean period: ")
period_Std_all = extractNumber(voiceReport$, "Standard deviation of period: ")


select Sound onlyVoice
# Power-cepstrogram, Cepstral peak prominence and Smoothed cepstral peak prominence
select Sound onlyVoice
To PowerCepstrogram... 60 0.002 5000 50
cpps = Get CPPS... no 0.01 0.001 60 330 0.05 Parabolic 0.001 0 Straight Robust


# Slope of the long-term average spectrum
select Sound onlyVoice
To Ltas... 1
slope = Get slope... 0 1000 1000 10000 energy


# Tilt of trendline through the long-term average spectrum
select Ltas onlyVoice
Compute trend line... 1 10000
tilt = Get slope... 0 1000 1000 10000 energy


# Amplitude perturbation measures
select Sound onlyVoice
To PointProcess (periodic, cc)... 50 400
Rename... onlyVoice1
select Sound onlyVoice
plus PointProcess onlyVoice1
percentShimmer = Get shimmer (local)... 0 0 0.0001 0.02 1.3 1.6
shim = percentShimmer*100
shdb = Get shimmer (local_dB)... 0 0 0.0001 0.02 1.3 1.6


select Sound onlyVoice

#time_Step = 100 default
time_Step = 0.010
max_Candidates = 15
very_Accurate$ = "yes" 
silence_Threshold = 0.03
voicing_Threshold = 0.45
octave_Cost = 0.01
octave_JumpCost = 0.35
voiced_UnvoicedCost = 0.14

To Pitch (cc)... time_Step pitch_Floor max_Candidates very_Accurate$ silence_Threshold voicing_Threshold octave_Cost octave_JumpCost voiced_UnvoicedCost pitch_Ceiling
select Sound onlyVoice
plus Pitch onlyVoice
To PointProcess (cc)
Rename... onlyVoice2
select Sound onlyVoice
plus Pitch onlyVoice
plus PointProcess onlyVoice2

#           Run the Voice report on onlyVoice
voiceReport$ = Voice report... 0 0 pitch_Floor pitch_Ceiling 1.3 1.6 0.03 0.45

#Compute the Glottal to Noise Excitation Ratio
select Sound onlyVoice
signalStart = Get start time
signalEnd = Get end time
Extract part... signalStart signalEnd rectangular 1.0 false
To Harmonicity (gne)... 500 4500 1000 80
gne = Get maximum


#           Parse Voice report

pitch_Mean = extractNumber(voiceReport$, "Mean pitch: ")
pitch_Median = extractNumber(voiceReport$, "Median pitch: ")
pitch_Min = extractNumber(voiceReport$, "Minimum pitch: ")
pitch_Max = extractNumber(voiceReport$, "Maximum pitch: ")
pitch_Std = extractNumber(voiceReport$, "Standard deviation: ")

pulse_Count = extractNumber(voiceReport$, "Number of pulses: ")
period_Mean = extractNumber(voiceReport$, "Mean period: ")
period_Std = extractNumber(voiceReport$, "Standard deviation of period: ")

unvoiced_Frames = extractNumber(voiceReport$, "Fraction of locally unvoiced frames: ")
voiceBreaks_Count = extractNumber(voiceReport$, "Number of voice breaks: ")
voiceBreaks_Degree = extractNumber(voiceReport$, "Degree of voice breaks: ")

#You typically perform jitter measurements only on long sustained vowels.
#This is the average absolute difference between consecutive periods, divided by the average period. 
#Multidimensional voice program analysis (MDVP) calls this parameter Jitt, and gives 1.040% as a threshold for pathology. As this number was based on jitter measurements influenced by noise, the correct threshold is probably lower.
jitter_Local = extractNumber(voiceReport$, "Jitter (local): ")
jitter_Local_Absolute = extractNumber(voiceReport$, "Jitter (local, absolute): ")*100
jitter_Rap = extractNumber(voiceReport$, "Jitter (rap): ")
jitter_Ppq5 = extractNumber(voiceReport$, "Jitter (ppq5): ")
jitter_Ddp = extractNumber(voiceReport$, "Jitter (ddp): ")

shimmer_Local = extractNumber(voiceReport$, "Shimmer (local): ")
shimmer_Local_Db = extractNumber(voiceReport$, "Shimmer (local, dB): ")
shimmer_Apq3 = extractNumber(voiceReport$, "Shimmer (apq3): ")
shimmer_Apq5 = extractNumber(voiceReport$, "Shimmer (apq5): ")
shimmer_Apq11 = extractNumber(voiceReport$, "Shimmer (apq11): ")
shimmer_Dda = extractNumber(voiceReport$, "Shimmer (dda): ")

hnr = extractNumber (voiceReport$, "Mean harmonics-to-noise ratio: ")
nhr = extractNumber(voiceReport$, "Mean noise-to-harmonics ratio: ")
mac = extractNumber(voiceReport$, "Mean autocorrelation: ")

#             Transform Numbers to Strings
power_In_Air$ = fixed$(globalPower, 5)

pitch_Mean_all$ = fixed$(pitch_Mean_all, 5)
pitch_Median_all$ = fixed$(pitch_Median_all, 5)
pitch_Min_all$ = fixed$(pitch_Min_all, 5)
pitch_Max_all$ = fixed$(pitch_Max_all, 5)
pitch_Std_all$ = fixed$(pitch_Std_all, 5)

pulse_Count_all$ = fixed$(pulse_Count_all, 5)
period_Mean_all$ = fixed$(period_Mean_all, 5)
period_Std_all$ = fixed$(period_Std_all, 5)

pitch_Mean$ = fixed$(pitch_Mean, 5)
pitch_Median$ = fixed$(pitch_Median, 5)
pitch_Min$ = fixed$(pitch_Min, 5)
pitch_Max$ = fixed$(pitch_Max, 5)
pitch_Std$ = fixed$(pitch_Std, 5)

pulse_Count$ = fixed$(pulse_Count, 5)
period_Mean$ = fixed$(period_Mean, 5)
period_Std$ = fixed$(period_Std, 5)

unvoiced_Frames$ = fixed$(unvoiced_Frames, 5)
voiceBreaks_Count$ = fixed$(voiceBreaks_Count, 5)
voiceBreaks_Degree$ = fixed$(voiceBreaks_Degree, 5)

jitter_Local$ = fixed$(jitter_Local, 5)
jitter_Local_Absolute$ = fixed$(jitter_Local_Absolute, 5)
jitter_Rap$ = fixed$(jitter_Rap, 5)
jitter_Ppq5$ = fixed$(jitter_Ppq5, 5)
jitter_Ddp$ = fixed$(jitter_Ddp, 5)

shimmer_Local$ = fixed$(shimmer_Local, 5)
shimmer_Local_Db$ = fixed$(shimmer_Local_Db, 5)
shimmer_Apq3$ = fixed$(shimmer_Apq3, 5)
shimmer_Apq5$ = fixed$(shimmer_Apq5, 5)
shimmer_Apq11$ = fixed$(shimmer_Apq11, 5)
shimmer_Dda$ = fixed$(shimmer_Dda, 5)

shim$ = fixed$(shim, 5)
shdb$ = fixed$(shdb, 5)
slope$ = fixed$(slope, 5)
tilt$ = fixed$(tilt, 5)

cpps$ = fixed$(cpps, 5)
hnr$ = fixed$(hnr, 5)
nhr$ = fixed$(nhr, 5)
mac$ = fixed$(mac, 5)
gne$ = fixed$(gne, 5)

time_Step$ = fixed$(time_Step, 5)
pitch_Floor$ = fixed$(pitch_Floor, 5)
pitch_Ceiling$ = fixed$(pitch_Ceiling, 5)
max_Candidates$ = fixed$(max_Candidates, 5)
silence_Threshold$ = fixed$(silence_Threshold, 5)
voicing_Threshold$ = fixed$(voicing_Threshold, 5)
octave_Cost$ = fixed$(octave_Cost, 5)
octave_JumpCost$ = fixed$(octave_JumpCost, 5) 
voiced_UnvoicedCost$ = fixed$(voiced_UnvoicedCost, 5)

sep$ = ","

#                             Column Names
output$ = "fileName"+sep$+
...       "time_Step"+sep$+
...       "very_Accurate"+sep$+
...       "pitch_Floor"+sep$+
...       "pitch_Ceiling"+sep$+  
...       "max_Candidates"+sep$+
...       "silence_Threshold"+sep$+
...       "voicing_Threshold"+sep$+
...       "octave_Cost"+sep$+
...       "octave_JumpCost"+sep$+
...       "voiced_UnvoicedCost"+sep$+ 
...       "power_In_Air"+sep$+
...       "pitch_Mean_all"+sep$+
...       "pitch_Median_all"+sep$+
...       "pitch_Min_all"+sep$+
...       "pitch_Max_all_all"+sep$+
...       "pitch_Std_all"+sep$+
...       "pulse_Count_all"+sep$+
...       "period_Mean_all"+sep$+
...       "period_Std_all"+sep$+
...       "pitch_Mean"+sep$+
...       "pitch_Median"+sep$+
...       "pitch_Min"+sep$+
...       "pitch_Max"+sep$+
...       "pitch_Std"+sep$+
...       "pulse_Count"+sep$+
...       "period_Mean"+sep$+
...       "period_Std"+sep$+
...       "unvoiced_Frames"+sep$+
...       "voiceBreaks_Count"+sep$+
...       "voiceBreaks_Degree"+sep$+
...       "jitter_Local"+sep$+
...       "jitter_Local_Absolute"+sep$+
...       "jitter_Rap"+sep$+
...       "jitter_Ppq5"+sep$+
...       "jitter_Ddp"+sep$+
...       "shimmer_Local"+sep$+
...       "shimmer_Local_Db"+sep$+
...       "shimmer_Apq3"+sep$+
...       "shimmer_Apq5"+sep$+
...       "shimmer_Apq11"+sep$+
...       "shimmer_Dda"+sep$+
...       "shim"+sep$+
...       "shdb"+sep$+
...       "slope"+sep$+
...       "tilt"+sep$+
...       "cpps"+sep$+
...       "hnr"+sep$+
...       "nrh"+sep$+
...       "gne"+sep$+
...       "mac"+newline$

#                             Values
output$ = output$+
...       inputWavFileName$+sep$+
...       time_Step$+sep$+
...       very_Accurate$+sep$+
...       pitch_Floor$+sep$+
...       pitch_Ceiling$+sep$+
...       max_Candidates$+sep$+
...       silence_Threshold$+sep$+
...       voicing_Threshold$+sep$+
...       octave_Cost$+sep$+
...       octave_JumpCost$+sep$+
...       voiced_UnvoicedCost$+sep$+
...       power_In_Air$+sep$+
...       pitch_Mean_all$+sep$+
...       pitch_Median_all$+sep$+
...       pitch_Min_all$+sep$+
...       pitch_Max_all$+sep$+
...       pitch_Std_all$+sep$+
...       pulse_Count_all$+sep$+
...       period_Mean_all$+sep$+
...       period_Std_all$+sep$+
...       pitch_Mean$+sep$+
...       pitch_Median$+sep$+
...       pitch_Min$+sep$+
...       pitch_Max$+sep$+
...       pitch_Std$+sep$+
...       pulse_Count$+sep$+
...       period_Mean$+sep$+
...       period_Std$+sep$+
...       unvoiced_Frames$+sep$+
...       voiceBreaks_Count$+sep$+
...       voiceBreaks_Degree$+sep$+
...       jitter_Local$+sep$+
...       jitter_Local_Absolute$+sep$+
...       jitter_Rap$+sep$+
...       jitter_Ppq5$+sep$+
...       jitter_Ddp$+sep$+
...       shimmer_Local$+sep$+
...       shimmer_Local_Db$+sep$+
...       shimmer_Apq3$+sep$+
...       shimmer_Apq5$+sep$+
...       shimmer_Apq11$+sep$+
...       shimmer_Dda$+sep$+
...       shim$+sep$+
...       shdb$+sep$+
...       slope$+sep$+
...       tilt$+sep$+
...       cpps$+sep$+
...       hnr$+sep$+
...       nhr$+sep$+
...       gne$+sep$+
...       mac$+newline$

#                            Return data  
#Steve parselmouth style return data
writeInfoLine: output$

#Carla praatloader style return data
#appendFile: txtfile$, output$


