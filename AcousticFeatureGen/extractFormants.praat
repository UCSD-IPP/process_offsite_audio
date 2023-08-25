form Variables
    sentence inputWavFileName
    integer channelToProces
    integer maxfreq
endform

#                   Read input .wav file
Read from file: inputWavFileName$
Extract one channel... channelToProces
Rename... rawInputSound

#                   High pass the sound
stop_Floor = 0
stop_Ceiling = 34
smoothing_Width = 0.1

Filter (stop Hann band)... stop_Floor stop_Ceiling smoothing_Width
Rename... highPassedInputSound

#         Separate Vowels and Calculate Voice Report Stats
select Sound highPassedInputSound
include extractVowels.praat
Rename... highPassedInputSound

select Sound highPassedInputSound
To Formant (burg): 0, 5, maxfreq, 0.040, 50

sep$ = ","
output$ = "time(s)"+sep$+"nformants"+sep$+"F1(Hz)"+sep$+"B1(Hz)"+sep$+"F2(Hz)"+sep$+"B2(Hz)"+sep$+"F3(Hz)"+sep$+"B3(Hz)"+sep$+"F4(Hz)"+sep$+"B4(Hz)"+sep$+"F5(Hz)"+sep$+"B5(Hz)"+newline$

#nformants	F1(Hz)	B1(Hz)	F2(Hz)	B2(Hz)	F3(Hz)
#	B3(Hz)	F4(Hz)	B4(Hz)	F5(Hz)	B5(Hz)

frames = Get number of frames

for f from 1 to frames
	time = Get time from frame: f
	time$ = fixed$(time, 6)

	nformants$ = Get number of formants: f

	f1 = Get value at time: 1, time, "Hertz", "Linear"
	f1$ = fixed$(f1, 3)
	b1 = Get bandwidth at time: 1, time, "Hertz", "Linear"
	b1$ = fixed$(b1, 3)

	f2 = Get value at time: 2, time, "Hertz", "Linear"
	f2$ = fixed$(f2, 3)
	b2 = Get bandwidth at time: 2, time, "Hertz", "Linear"
	b2$ = fixed$(b2, 3)

	f3 = Get value at time: 3, time, "Hertz", "Linear"
	f3$ = fixed$(f3, 3)
	b3 = Get bandwidth at time: 3, time, "Hertz", "Linear"
	b3$ = fixed$(b3, 3)

	f4 = Get value at time: 4, time, "Hertz", "Linear"
	f4$ = fixed$(f4, 3)
	b4 = Get bandwidth at time: 4, time, "Hertz", "Linear"
	b4$ = fixed$(b4, 3)

	f5 = Get value at time: 5, time, "Hertz", "Linear"
	f5$ = fixed$(f5, 3)
	b5 = Get bandwidth at time: 5, time, "Hertz", "Linear"
	b5$ = fixed$(b5, 3)

	output$ = output$+time$+sep$+nformants$+sep$+f1$+sep$+b1$+sep$+f2$+sep$+b2$+sep$+f3$+sep$+b3$+sep$+f4$+sep$+b4$+sep$+f5$+sep$+b5$+newline$

endfor


printline 'output$'
