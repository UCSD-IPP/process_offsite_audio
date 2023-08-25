#SJH parselmouth version

form Variables
   real min_pitch
   real time_step
   real silence_threshold
   real min_silent_interval
   real min_sounding_interval
   sentence filename
endform

Read from file... 'filename$'

#To TextGrid (silences)... min_pitch time_step silence_threshold min_silent_interval min_sounding_interval silent sounding
To TextGrid (silences)... 75 0 -25 0.1 0.1 silent sounding

#Save the TextGrid for debugging
#Save as text file: txtfile$+".txt"

Down to Table: "no", 6, "yes", "no"
rows = Get number of rows

comma$ = ","
output$ = "tmin"+comma$+"tmax"+comma$+"tier"+comma$+"text"+newline$

for r from 1 to rows
	tmin = Get value: r, "tmin"
    tmin$ = fixed$(tmin, 6)
	tmax = Get value: r, "tmax"
	tmax$ = fixed$(tmax, 6)
	tier$ = Get value: r, "tier"
	text$ = Get value: r, "text"
	output$ = output$+tmin$+comma$+tmax$+comma$+tier$+comma$+text$+newline$
endfor

printline 'output$'


