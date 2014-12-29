package require Tk 
###############################################################
#TODO:
#Work out total income, total going to build ships/bases/research, and total ships/bases per player
	#Variables: tinco, tshbl, tbsbl, trese, tship, tbase 
		#DONE
	
#num commands available to each player=((int($bases($home($p),1)))>100 ? 100:(int($bases($home($p),1)))), store as numcmd($p), update every endtrn
		#DONE

#Procs incscmd, decscmd (incr/decr scmd & call proc updatescmd (wrap around, min 1, max $numcmd($p)))
	#call proc updatescmd every end trn
	#proc updatescmd: update all sc- vars
		#DONE

#Minimap clear rectangle showing area I can see
		#DONE

#tech research done on planets (select research to work on) 
	#resch($s,1) 0=ecnmc, 1=weapn, 2=armor, 3=engin
	#all research variables now per star, not per player
	#if player doesn't own planet, iRESEARCH($p,$s)=0 and iresch($p,$s)=0
	#selecting planet updates sRESEARCH($p) variables with iRESEARCH($p,$s)
	#similar formula for research costs as for base building (do 0.1 of a research at a time)
		#DONE
	
#ships carry tech info with them as they move (MOVE cmd), and their tech updates destination tech when they arrive if (TECH is better AND dest belongs to you) OR (conquered from enemy)
		#DONE
	
#Speed up section of endtrn done for every star
		#ONGOING PROCESS

#Rebellions
		#DONE
		
#Delay for info coming from MOVE cmd
	#save turn MOVE starts (or should). After delay set cmd info to move cmd. Before delay, cmdtype=MOV?, with all other visible numbers staying the same.
	#After delay, update it to how it should be.
	#delay=[dist home cloca]/10
		#newvariables: chturn, chctype, chship, checnmc, chweapn, charmor, chengin, chdist
			#when MOVE arrives at destination, update all ch- vars (NOT c- vars)
			#these variables used to keep track of MOVE cmd, after delay update all c- vars with ch- vars
		#DONE

#On AItesting.tcl, make each R- cmd seperate (at least to get it working as fast as possible), and test
		#DONE

#Make mutation proc, input a piece of AIcode, output slightly changed piece of code
	#If new AI comes from rebellion, make it's code a mutated version of previous owners code
		#IN PROGRESS
proc F {x a b c} {
	if {$x<$c} {return [expr {($x-$a)**2 / (($b-$a)*($b-$c))}]
	} else {return [expr {1-($b-$x)**2 / (($b-$a)*($b-$c))}]}
}
proc f {U a b c} {
	if {$U<[F $c $a $b $c]} {return [expr {$a + ($U*($b-$a)*($c-$a)) **0.5}]
	} else {return [expr {$b - ((1-$U)*($b-$a)*($b-$c)) **0.5}]}
}
proc random_triangular {min max mode} {return [f [expr {rand()}] $min $max $mode]}
##############################################################################################################################
#VARIABLES
##############################################################################################################################
#NOTE: 10 coords=1LY
set speed 20	;#1 speed=1 year/turn
set ux 700
set uy 500
set cx 700
set cy 500
set maxhist 20	;#time to trace stars history for sight (must be >=1, if ==1 then there is no delay for sight)
set histacc [expr {int(hypot($ux,$uy)/10/$maxhist)+1}]	;#num turns until history is set back 1 step, so hist is traced back maxhist*histacc turns
set turn 0
set tstar 31	;#total num stars (form of 2^n-1)
set nplay 16	;#num players
set scry 0		;#current screen pos
set scrx 0
set mmsize 10000
set watchp 1	;#changing this allows me to watch from a different players view (on canvas only)
#AI
	set stacksize 63;#0 to stacksize (form of 2^n-1)
	set numAIvar 15;#0 to numAIvar (form of 2^n-1)
	set codelength 511;# (form of 2^n-1)
	set AIrepspertrn 25
#PLAYER COLOURS
	set col(0) #888888
	set col(1) #ff0000
	set col(2) #00ff00
	set col(3) #0000ff
	set col(4) #00ffff
	set col(5) #ff00ff
	set col(6) #ffff00
	set col(7) #ff8888
	set col(8) #88ff88
	set col(9) #8888ff
	set col(10) #ff8800
	set col(11) #ff0088
	set col(12) #8800ff
	set col(13) #88ff00
	set col(14) #00ff88
	set col(15) #0088ff
	set col(16) #ffffff
#SELECTED CMD (only for P1)
	set scmd 1
	set sctype 0
	set scloca 0
	set sctime 0
	set scship 0
	set scdest 0
	set scdist 0
	set scecnmc 0
	set scweapn 0
	set scarmor 0
	set scengin 0
#PER STAR
#========
for {set s 0} {$s<=$tstar} {incr s} {
	#CURRENT STAR STATISTICS
	set coord($s) 0
	set owned($s,1) 0
	set bases($s,1) 0
	set incom($s,1) 0
	set ships($s,1) 0
	set nohab($s) [expr {int([random_triangular 0 15 4])}]
	set inhab($s) [expr {int([random_triangular 0 2 0.0001])}]
	set metal($s) [expr {int([random_triangular 0 50 10])}]
	set trnpc($s,1) 33
	set bldpc($s,1) 33
	set ecnmc($s,1) 1
	set weapn($s,1) 1
	set armor($s,1) 1
	set engin($s,1) 1
	set resch($s,1) [expr {int(rand()*4)}]
	#STAR'S HISTORY
	for {set n 2} {$n<=$maxhist} {incr n} {
		set owned($s,$n) $owned($s,1)
		set bases($s,$n) $bases($s,1)
		set incom($s,$n) $incom($s,1)
		set ships($s,$n) $ships($s,1)
		set trnpc($s,$n) $trnpc($s,1)
		set bldpc($s,$n) $bldpc($s,1)
		set ecnmc($s,$n) $ecnmc($s,1)
		set weapn($s,$n) $weapn($s,1)
		set armor($s,$n) $armor($s,1)
		set engin($s,$n) $engin($s,1)
		set resch($s,$n) $resch($s,1)
	}
}
#PER PLAYER
#==========
for {set p 0} {$p<=$nplay} {incr p} {
	#AI
	#old seed: "#1 33 Wstrnpc 33 Wsbldpc 3 Wsresch Rhome Ribases MPL 50 LES MPL 4 JMP #2 Pchngpcnt 25 Wpcnflt 1 Rvar Wsstar 90 Wstrnpc 10 Wsbldpc Pchngpcnt Pbuild Rhome Wsstar Pbuild 1 Rvar Pmove 1 Rvar MPL 1 ADD MPL 1 Wvar Rtstar MPL 1 Rvar GRE MPL 3 JMP 1 MPL 1 JMP #3 1 MPL 1 Wvar 1 MPL 1 JMP #4 50 Wstrnpc 0 Wsbldpc Rhome Riengin MPL 200 LES MPL 5 JMP 1 MPL 2 JMP #5 0 Wsresch 1 MPL 2 JMP"
		set AIcode($p) "Rhome Wsstar 33 Wstrnpc 33 Wsbldpc 3 Wsresch Pchngpcnt 1 Rvar Pmove 1 Rvar MPL 1 ADD MPL 1 Wvar"
		while {[llength $AIcode($p)]<$codelength} {lappend AIcode($p) 0}
		set pos($p) 0
		set ptr($p) 0
		for {set s 0} {$s<=$numAIvar} {incr s} {set AIvar($p,$s) 0}
		for {set n 0;set stack($p) 0} {$n<$stacksize} {incr n} {lappend stack($p) 0}	;#stack: list of length $stacksize
		for {set n 0;set stack($p) 0} {$n<$stacksize} {incr n} {lappend stack($p) 0}	;#stack: list of length $stacksize
	#homeworld, if this is lost new one is selected randomly from owned planets with most bases (when home=-1, out of game, when =-2, newhome cmd on way
	set home($p) [expr {1+int(rand()*($tstar-1))}]
		while {$owned($home($p),1)!=$p && $owned($home($p),1)>0} {
			set home($p) [expr {1+int(rand()*($tstar-1))}]
		}
		set inhab($home($p)) 1
		set owned($home($p),1) $p
		set bases($home($p),1) 10
		set ships($home($p),1) 1000
	set sstar($p)  $home($p);#selected star
	set tinco($p) 0
	set tshbl($p) 0
	set tbsbl($p) 0
	set trese($p) 0
	set tship($p) 0
	set tbase($p) 0
	set credit($p) 0
	set pcnflt($p) 5		;#percent ships to use in command
	set numcmd($p) 1
	#COMMANDS
	#--------
	for {set c 1} {$c<=100} {incr c} {
		set ctype($p,$c) 0
		set cloca($p,$c) 0	;#co-ords of star
		set ctime($p,$c) 0
		set cship($p,$c) 0
		set cdest($p,$c) 0	;#co-ords of star
		set cdist($p,$c) 0
		set cecnmc($p,$c) 0
		set cweapn($p,$c) 0
		set carmor($p,$c) 0
		set cengin($p,$c) 0
		
		set chturn($p,$c) 0
		set chdlay($p,$c) 0
		set chtype($p,$c) 0
		set chship($p,$c) 0
		set chdist($p,$c) 0
		set checnmc($p,$c) 0
		set chweapn($p,$c) 0
		set charmor($p,$c) 0
		set chengin($p,$c) 0
	}
	#PER STAR
	#--------
	for {set s 0} {$s<=$tstar} {incr s} {
		#INFO AVIAILABLE TO PLAYER ABOUT STAR
		set iowned($p,$s) 0
		set ibases($p,$s) 0
		set iincom($p,$s) 0
		set iships($p,$s) 0
		set itrnpc($p,$s) 0
		set ibldpc($p,$s) 0
		set iecnmc($p,$s) 1
		set iweapn($p,$s) 1
		set iarmor($p,$s) 1
		set iengin($p,$s) 1
		set iresch($p,$s) 0
	}
	#SELECTED STAR
	#-------------
	set scoord($p) 0	;#ALWAYS AVAILABLE
	set sowned($p) 0	;#DELAY
	set sbases($p) 0	;#DELAY
	set sincom($p) 0	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iincom($p,$s)=0}
	set sships($p) 0	;#DELAY
	set snohab($p) 0	;#ALWAYS AVAILABLE
	set sinhab($p) 0	;#ALWAYS AVAILABLE
	set smetal($p) 0	;#ALWAYS AVAILABLE
	set strnpc($p) 0	;#DELAY, IF {iowned($p,$s)!=$p} THEN {itrnpc($p,$s)=0}
	set sbldpc($p) 0	;#DELAY, IF {iowned($p,$s)!=$p} THEN {ibldpc($p,$s)=0}
	set secnmc($p,$s) 1	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iecnmc($p,$s)=1}
	set sweapn($p,$s) 1	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iweapn($p,$s)=1}
	set sarmor($p,$s) 1	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iarmor($p,$s)=1}
	set sengin($p,$s) 1	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iengin($p,$s)=1}
	set sresch($p) 0	;#DELAY, IF {iowned($p,$s)!=$p} THEN {iresch($p,$s)=0}
}
set AIcode(0) "Rhome Rcecnmc Ribldpc 40 63 2 Wpcnflt 68 21 Pchngpcnt Rstarx Rplay Rinhab MOD Rtshbl Rnumcmd 14 Rtbase Riarmor Rhome Wsstar Rcship Riincom 48 Rsbldpc Rnumcmd Rplay Rcdist Rstrnpc Rtshbl 54 1 Rvar Pmove Pscrap 87 Rstarx MUL ADD 1 Rvar MPL Ribldpc ADD MPL LOR Wvar 45 Wstrnpc LOR Rctime Rtrese 93 20 60 Rcloca 94 35 Rsstar Rtshbl Rcdist SUB Rcloca EQU Rsstar 13 Riresch Riresch Riowned 46 Rhome 83 35 MOD Wsbldpc Wsresch Rctype Riowned MPR Riecnmc Riecnmc Riships 1 Pchngpcnt Rinhab Rcarmor Rinhab Pchngpcnt Rtshbl END Rnohab 87 Pdist Rcdist LOR Rstary 70 22 Wvar 73 Rvar 34 Pdist Rcarmor Ribases Riowned 55 Pnewhome Rtrese Riincom Rcdist 66 Pnewhome Rmetal LND Wvar EQU 74 Wsresch JMP 57 Rnohab LOR Pnewhome 44 Rmetal Rtinco Pbuild Rvar 74 JMP Rcengin Ritrnpc MPR Pchngpcnt Rsstar END Pdist Pchngpcnt LES Riarmor 60 Rsstar Wsbldpc 30 66 MPR 80 Rnumcmd 75 Rmetal 55 77 24 Wstrnpc Wpcnflt 27 Rsstar Wstrnpc 0 Ribases 5 DIV SUB Rcarmor Rmetal 58 Rstrnpc MOD Wsbldpc Rcarmor Rstarx Pnewhome Riincom MPL Rstarx Rsstar 27 Rnohab Rcweapn Rtinco Riowned 27 Rnumcmd JMP Rcengin Wstrnpc Riengin 71 JMP MPR Riincom DIV Rstrnpc 80 57 40 Rtbsbl Rnohab 57 65 Rmetal DIV Rplay 73 Rsresch MPL Rcengin Rsstar Rtstar Riships Rnumcmd Rvar Rcweapn 62 4 Pmove Wstrnpc 22 Rhome LND Rinhab 62 20 Pchngpcnt 40 18 Riowned Rcengin Pdist Rcloca 72 28 20 MUL LND 53 Rctime Rstrnpc Pscrap MPR 41 Wsresch 82 Rtbsbl 16 67 73 66 81 Rplay Riengin Ritrnpc Riowned 80 5 GRE Rstarx Rnohab Wsstar 68 Rcengin Riships 11 #47 Rnumcmd Riresch 23 Rtship Rcecnmc 56 EQU SUB Rcship JMP 80 Riweapn Pchngpcnt 81 80 Rcarmor Ritrnpc 85 55 MUL 82 Riengin Rstrnpc 60 SUB GRE 62 Rcdist Rcdest Rstarx Riecnmc Ribases MPL 81 Rctime Rpcnflt Rcweapn LOR Wstrnpc Rpcnflt 14 64 Pbuild Wsstar 36 END 41 49 Rnumcmd Rcengin Rcdest Wvar LOR Rstary Rcship 64 Wsresch 98 Riincom Rvar #53 Rstrnpc Wsbldpc END Rcloca 81 Rplay 3 Ribases 10 Rtbase Rtbsbl Riecnmc Rstary EQU 33 73 Rsstar 56 Ritrnpc 75 Pbuild Rcecnmc 69 72 Pchngpcnt 25 Wpcnflt Pscrap Riecnmc Wsstar Pdist 90 Rcarmor Rvar Riarmor Rtstar Ribases Rpcnflt Wpcnflt Pchngpcnt Riecnmc Rcarmor Rcecnmc GRE Rsresch 19 Ritrnpc GRE Pscrap 38 MPL Riowned Wstrnpc Riresch 91 Pscrap 82 Riarmor ADD 51 41 61 END Riships #23 Riresch Rcloca Riarmor MUL Rstarx MPL Rinhab Wstrnpc Ribases Rstarx MPR Rcloca 18 Rstrnpc Pdist 63 Rplay Wvar 57 48 4 3 Wsbldpc Wpcnflt Rnohab 76 Riarmor END Ribases 79 Wsstar Wsstar Rctime Riowned Pmove MUL Rstarx Rcweapn Pchngpcnt 91 Rnumcmd Rplay 15 Pdist 62 97 Riships 67 Wsstar 21 Rcecnmc SUB 19 96 Rinhab 31 88 Rtbase DIV 11 Rcloca Pchngpcnt Wpcnflt Rctype 43 59 Ritrnpc Pdist Rplay Riresch LND Rmetal 0 Rcship 0 0 Pmove 0 0 0 Rinhab MPL Pscrap 0 Wvar 0 Rsstar 0 0 0 LND Riarmor 0 0 0 89 0 0 0 0 LES 18 0 2 Rctype 95 0 Pnewhome Ribases 0 Rcdist 14 59 0 0 0 0 0 0 0"

##############################################################################################################################
#PRODCEDURES
##############################################################################################################################

###############################################################
#SENDING COMMANDS
proc build {p} {
	global home
	if {$home($p)>=0} {
		global sstar
		global coord
		global numcmd
		set s $sstar($p)
		#FIND EMPTY COMMAND SLOT
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar ctype($p,$c) ctype
			if {$ctype==0} {break}
			if {$c>=$numcmd($p)} {set c 0;break}
		}
		if {$c>=1} {
			#SEND BLD COMMAND TO SELCTED STAR
			upvar cloca($p,$c) cloca
			upvar ctime($p,$c) ctime
			upvar cship($p,$c) cship
			upvar cdest($p,$c) cdest
			upvar cdist($p,$c) cdist
			global pcnflt
			set ctype "CBLD"
			set cloca $s
			set ctime [expr {[dist $home($p) $s]/10}]
			if {$pcnflt($p)>100} {set pcnflt($p) 100} elseif {$pcnflt($p)<0} {set pcnflt($p) 0}
			set cship $pcnflt($p);#cship carries percent of fleet to convert to bases
			updatescmd
		}
	}
}
proc scrap {p} {
	global home
	if {$home($p)>=0} {
		global sstar
		global coord
		global numcmd
		set s $sstar($p)
		#FIND EMPTY COMMAND SLOT
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar ctype($p,$c) ctype
			if {$ctype==0} {break}
			if {$c>=$numcmd($p)} {set c 0;break}
		}
		if {$c>=1} {
			#SEND SCR COMMAND TO SELCTED STAR
			upvar cloca($p,$c) cloca
			upvar ctime($p,$c) ctime
			upvar cship($p,$c) cship
			upvar cdest($p,$c) cdest
			upvar cdist($p,$c) cdist
			upvar cecnmc($p,$c) cecnmc
			upvar cweapn($p,$c) cweapn
			upvar carmor($p,$c) carmor
			upvar cengin($p,$c) cengin
			global pcnflt
			global sresch
			set ctype "CSCR"
			set cloca $s
			set ctime [expr {[dist $home($p) $s]/10}]
			if {$pcnflt($p)>100} {set pcnflt($p) 100} elseif {$pcnflt($p)<0} {set pcnflt($p) 0}
			set cship $pcnflt($p);#cship carries percent of tech to be scrapped
			set cecnmc [expr {$sresch($p)==0 ? 1:0}]
			set cweapn [expr {$sresch($p)==1 ? 1:0}]
			set carmor [expr {$sresch($p)==2 ? 1:0}]
			set cengin [expr {$sresch($p)==3 ? 1:0}]
			updatescmd
		}
	}
}
proc move {p s} {
	global home
	if {$home($p)>=0} {
		global sstar
		global coord
		global numcmd
		set o $sstar($p)
		#FIND EMPTY COMMAND SLOT
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar ctype($p,$c) ctype
			if {$ctype==0} {break}
			if {$c>=$numcmd($p)} {set c 0;break}
		}
		if {$c>=1} {
			#SEND MVE COMMAND TO SELCTED STAR
			upvar cloca($p,$c) cloca
			upvar ctime($p,$c) ctime
			upvar cship($p,$c) cship
			upvar cdest($p,$c) cdest
			upvar cdist($p,$c) cdist
			global pcnflt
			set ctype "CMVE"
			set cloca $o
			set ctime [expr {[dist $home($p) $o]/10}]
			if {$pcnflt($p)>100} {set pcnflt($p) 100} elseif {$pcnflt($p)<0} {set pcnflt($p) 0}
			set cship $pcnflt($p);#cship carries percent of fleet to attack with
			set cdest $s
			set cdist [dist $o $s]
			updatescmd
		}
	}
}
proc chngpcnt {p} {
	global home
	if {$home($p)>=0} {
		global sstar
		global strnpc
		global sbldpc
		global numcmd
		set s $sstar($p)
		#FIND EMPTY COMMAND SLOT
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar ctype($p,$c) ctype
			if {$ctype==0} {break}
			if {$c>=$numcmd($p)} {set c 0;break}
		}
		if {$c>=1} {
			#SEND PCN COMMAND TO SELCTED STAR
			upvar cloca($p,$c) cloca
			upvar ctime($p,$c) ctime
			upvar cship($p,$c) cship
			upvar cdest($p,$c) cdest
			upvar cdist($p,$c) cdist
			upvar cecnmc($p,$c) cecnmc
			upvar cweapn($p,$c) cweapn
			upvar carmor($p,$c) carmor
			upvar cengin($p,$c) cengin
			global sresch
			set ctype "CPCN"
			set cloca $s
			set ctime [expr {[dist $home($p) $s]/10}]
			set cship $strnpc($p)
			set cdest $sbldpc($p)
			set cecnmc [expr {$sresch($p)==0 ? 1:0}]
			set cweapn [expr {$sresch($p)==1 ? 1:0}]
			set carmor [expr {$sresch($p)==2 ? 1:0}]
			set cengin [expr {$sresch($p)==3 ? 1:0}]
			updatescmd
		}
	}
}
proc newhome {p} {
	upvar #0 home($p) home
	if {$home>=0} {
		global tstar
		set homerand 0
		global sstar
		global numcmd
		set s $sstar($p)
		#FIND EMPTY COMMAND SLOT
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar #0 ctype($p,$c) ctype
			if {$ctype==0} {break}
			if {$c>=$numcmd($p)} {set c 0;break}
		}
		if {$c>=1} {
			#SEND HOME COMMAND TO SELCTED STAR
			upvar #0 cloca($p,$c) cloca
			upvar #0 ctime($p,$c) ctime
			upvar #0 cship($p,$c) cship
			upvar #0 cdest($p,$c) cdest
			upvar #0 cdist($p,$c) cdist
			upvar #0 cecnmc($p,$c) cecnmc
			upvar #0 cweapn($p,$c) cweapn
			upvar #0 carmor($p,$c) carmor
			upvar #0 cengin($p,$c) cengin
			set ctype "HOME"
			set cloca $home
			set cdest $s
			set cdist [dist $home $s]
			global ecnmc;global weapn;global armor;global engin
			global owned
			set cecnmc [expr {$ecnmc($home,1)}]
			set cweapn [expr {$weapn($home,1)}]
			set carmor [expr {$armor($home,1)}]
			set cengin [expr {$engin($home,1)}]
			set home -2
		}
		updatescmd
	}
}
###############################################################
#MOUSE CLICKS
proc selstar {x y} {
	set item [.map find overlapping $x $y $x $y]
	set coords [.map coords $item]
	set x1 [lindex $coords 0]
	set x2 [lindex $coords 2]
	set y1 [lindex $coords 1]
	set y2 [lindex $coords 3]
	set targx1 0
	set targy1 0
	global tstar
	if {$x1>0 && $y1>0} {
		for {set s 0} {$s<=$tstar && ($targx1!=$x1 || $targy1!=$y1)} {incr s} {
			set targx1 [lindex [.map coords star($s)] 0]
			set targy1 [lindex [.map coords star($s)] 1]
		}
	}
	if {$targx1!=$x1 && $targy1!=$y1} {set s 0}
	incr s -1
	return $s
}
proc lclick {x y p} {
	global mmx;global mmy;global cx;global cy
	if {$x<($cx-$mmx) || $y<($cy-$mmy)} {
		set s [selstar $x $y]
		if {$s>=0} {
						upvar watchp watchp
						upvar owned($s,1) owned
						setwatchp $owned
			upvar sstar sstar
			upvar snohab($p) snohab;upvar sinhab($p) sinhab;upvar smetal($p) smetal
			upvar scoord($p) scoord;upvar sowned($p) sowned;upvar sbases($p) sbases
			upvar sincom($p) sincom;upvar sships($p) sships;upvar strnpc($p) strnpc
			uplevel 1 slct $p $s
		}
	} else {
	#Click minimap
		global ux;global uy
		global starx;global stary;global tstar
		upvar scrx scrx;upvar scry scry
		set mmox [expr {$mmx+$x-$cx}];set mmoy [expr {$mmy+$y-$cy}]
		set ox [expr {$mmox/$mmx*$ux}];set oy [expr {$mmoy/$mmy*$uy}]
		set scrx [expr {$ox-$cx/2.}];set scry [expr {$oy-$cy/2.}]
			#REDRAW STARS
				for {set s 0} {$s<=$tstar} {incr s} {
						.map coords star($s)	[expr {$starx($s)-15-$scrx}] [expr {$stary($s)-10-$scry}] \
												[expr {$starx($s)+15-$scrx}] [expr {$stary($s)+10-$scry}]
						.map coords scrbase($s) [expr {$starx($s)-$scrx}] [expr {$stary($s)-$scry}]
						.map coords scrship($s) [expr {$starx($s)-$scrx}] [expr {$stary($s)-14-$scry}]
						.map coords scrinco($s) [expr {$starx($s)-$scrx}] [expr {$stary($s)+14-$scry}]
				}
			#COMMAND LINES (ONLY FOR P1)
				uplevel #0 {
					for {set c 1} {$c<=$numcmd($watchp)} {incr c} {
						drawcmdline $c
					}
				}
			#SIGHT-BOX
				global smmx;global smmy
				.map coords sghtbox [expr {($scrx)/"$ux."*$mmx+$cx-$mmx}]     [expr {($scry)/"$uy."*$mmy+$cy-$mmy}] \
									[expr {($scrx+$cx)/"$ux."*$mmx+$cx-$mmx}] [expr {($scry+$cy)/"$uy."*$mmy+$cy-$mmy}]
				#convert ox to mmox
				#ox=scrx(+$cx)
				#mmox=ox/ux*mmx+cx-mmx
		}
}
proc rclick {x y p} {
	set s [selstar $x $y]
	if {$s!=0} {uplevel 1 move $p $s}
}
proc cpcndrg {x y p} {
	upvar strnpc($p) strnpc
	upvar sbldpc($p) sbldpc
	if {($x-10)<=$strnpc} {
		if {$x>80} {set x 80}
		if {$x<10} {set x 10}
		if {($strnpc+$sbldpc)>90} {set sbldpc [expr {90-$strnpc}]}
		.cpcn coords cpcntrn 0 0 $x 25
		.cpcn coords cpcnbld 0 0 [expr {$strnpc+$sbldpc}] 25
		set strnpc $x
	} else {
		if {$x>90} {set x 90}
		if {($strnpc+$x)<10} {set x [expr {$strnpc+10}]}
		.cpcn coords cpcnbld 0 0 $x 25
		set sbldpc [expr {$x-$strnpc}]
	}
}
###############################################################
#SELECT STAR
proc slct {p s} {
	upvar sstar($p) sstar
	upvar scoord($p) scoord;upvar sowned($p) sowned;upvar sbases($p) sbases
	upvar sincom($p) sincom;upvar sships($p) sships;upvar sinhab($p) sinhab
	upvar snohab($p) snohab;upvar smetal($p) smetal;upvar strnpc($p) strnpc
	upvar sbldpc($p) sbldpc;upvar secnmc($p) secnmc;upvar sweapn($p) sweapn
	upvar sarmor($p) sarmor;upvar sengin($p) sengin;upvar sresch($p) sresch
	global coord ;global iowned;global ibases
	global iincom;global iships;global nohab
	global inhab ;global metal ;global itrnpc
	global ibldpc;global iecnmc;global iweapn
	global iarmor;global iengin;global iresch
		if {$p==1&& $sstar!=$s} {
		#REDRAW PERCENTAGES SLIDER
			set strnpc $itrnpc($p,$s)
			set sbldpc $ibldpc($p,$s)
			set sresch $iresch($p,$s)
			.cpcn coords cpcntrn 0 0 $strnpc					25
			.cpcn coords cpcnbld 0 0 [expr {$strnpc+$sbldpc}]	25
		}
		set sstar $s
		
		set scoord $coord($s)
		set sowned $iowned($p,$s)
		set sbases $ibases($p,$s)
		set sincom $iincom($p,$s)
		set sships $iships($p,$s)
		set snohab $nohab($s)
		set sinhab $inhab($s)
		set smetal $metal($s)
		set secnmc $iecnmc($p,$s)
		set sweapn $iweapn($p,$s)
		set sarmor $iarmor($p,$s)
		set sengin $iengin($p,$s)
		
}
###############################################################
#SELECTED COMMAND
proc incscmd {} {
	global numcmd
	upvar scmd scmd
	incr scmd
	if {$scmd>$numcmd(1)} {set scmd 1}
	updatescmd
}
proc decscmd {} {
	global numcmd
	upvar scmd scmd
	incr scmd -1
	if {$scmd<1} {set scmd $numcmd(1)}
	updatescmd
}
proc updatescmd {} {
	uplevel #0 {
		set sctype  $ctype(1,$scmd)
		set scloca  $cloca(1,$scmd)
		set sctime  $ctime(1,$scmd)
		set scship  $cship(1,$scmd)
		set scdest  $cdest(1,$scmd)
		set scdist  $cdist(1,$scmd)
		set scecnmc $cecnmc(1,$scmd)
		set scweapn $cweapn(1,$scmd)
		set scarmor $carmor(1,$scmd)
		set scengin $cengin(1,$scmd)
	}
}
###############################################################
#OTHER
proc battle {s1 at1 dt1 s2 at2 dt2} {
	set ls1 1;set ls2 1
	while {$s1>0 && $s2>0 && ($ls1>0.001 || $ls2>0.001)} {
		set r1 [expr {($at2==0 ? 1:$at2)/($dt1==0 ? 1.:"$dt1.")}]
		set r2 [expr {($at1==0 ? 1:$at1)/($dt2==0 ? 1.:"$dt2.")}]
		set ls1 [expr {(($r1<=1)*(0.5*$r1)+($r1>1)*(1-0.5/$r1))*$s2}]
		set ls2 [expr {(($r2<=1)*(0.5*$r2)+($r2>1)*(1-0.5/$r2))*$s1}]
		set s1 [expr {$s1-$ls1}]
		set s2 [expr {$s2-$ls2}]
	}
	if {$s1>0 && $s2>0} {set s1 0;set s2 0}
	if {$s1<0} {set s1 0}
	if {$s2<0} {set s2 0}
	set s1 [expr {int($s1)}]
	set s2 [expr {int($s2)}]
	set output "$s1 $s2"
	return $output
}
proc income {s} {
	global nohab
	global inhab
	global metal
	global bases
	global owned
	global ecnmc
	set income [expr {(2*$nohab($s)+10*$inhab($s))*$metal($s)**0.1*$bases($s,1)**0.5*(2-0.99**$ecnmc($s,1))**2+$bases($s,1)**0.5}]
	return $income
}
proc dist {a b} {
	global starx;global stary
	global tstar
	set a [expr {$a&$tstar}];set b [expr {$b&$tstar}]
	set dx [expr {$starx($a)-$starx($b)}]
	set dy [expr {$stary($a)-$stary($b)}]
	set dist [expr {int(hypot($dx,$dy))}]
	return $dist
}
##############################################################################################################################
#GUI
##############################################################################################################################
frame .left
grid .left -in . -row 1 -column 1

frame .cntr
grid .cntr -in . -row 1 -column 2

frame .rght
grid .rght -in . -row 1 -column 3
###############################################################
#LEFT
###############################################################
#Change left display to (tick boxes decide which tech to research):
	#####################
	#Total income		#
	#Total ship-build	#
	#Total base-build	#
	#Total research		#
	#Total ships		#
	#Total bases		#
	#% Fleet action		#
	#####################
	#Coords		x,y		#
	#Owner		x		#
	#Bases		x		#
	#Ships		x		#
	#Uninhab	x		#
	#Inhab		x		#
	#Metal		x	 	#
	#Income		x	 _	#
	#Ecnmc		x	|_| #
	#Weapn		x	|_| #
	#Armor		x	|_| #
	#Engin _____x__ |_| #
	#|_R__|___B____|_G_|#
	#SET|SHIPS TO| NEW	#
	#   |  BASE  | HOME	#
	#####################
###############################################################
#LEFT-1st
frame .left1
grid .left1 -in .left -row 1 -column 1

label .ltinco -text "Total income:"		;label .vtinco -textvariable tinco(1) -width 7
label .ltshbl -text "Total ship-build:"	;label .vtshbl -textvariable tshbl(1) -width 7
label .ltbsbl -text "Total base-build:"	;label .vtbsbl -textvariable tbsbl(1) -width 7
label .ltrese -text "Total research:"	;label .vtrese -textvariable trese(1) -width 7
label .ltship -text "Total ships:"		;label .vtship -textvariable tship(1) -width 7
label .ltbase -text "Total bases:"		;label .vtbase -textvariable tbase(1) -width 7
scale .spatk -label "% action" -variable pcnflt(1) -orient horizontal   -width 5 -length 75 -sliderlength 10 -from 0 -to 100

grid .ltinco -in .left1 -row 1  -column 1 -sticky w;grid .vtinco -in .left1 -row 1  -column 2 -sticky w
grid .ltshbl -in .left1 -row 2  -column 1 -sticky w;grid .vtshbl -in .left1 -row 2  -column 2 -sticky w
grid .ltbsbl -in .left1 -row 3  -column 1 -sticky w;grid .vtbsbl -in .left1 -row 3  -column 2 -sticky w
grid .ltrese -in .left1 -row 4  -column 1 -sticky w;grid .vtrese -in .left1 -row 4  -column 2 -sticky w
grid .ltship -in .left1 -row 5  -column 1 -sticky w;grid .vtship -in .left1 -row 5  -column 2 -sticky w
grid .ltbase -in .left1 -row 6  -column 1 -sticky w;grid .vtbase -in .left1 -row 6  -column 2 -sticky w
grid .spatk  -in .left1 -row 7  -column 1 -sticky w
###############################################################
#LEFT-2nd
frame .left2
grid .left2 -in .left -row 2 -column 1

label .lcoord -text "Co-ords:"		;label .vcoord -textvariable scoord(1) -width 7
label .lowned -text "Owner:"		;label .vowned -textvariable sowned(1) -width 7
label .lbases -text "Bases:"		;label .vbases -textvariable sbases(1) -width 7
label .lships -text "Ships:"		;label .vships -textvariable sships(1) -width 7
label .lnohab -text "Uninhabitable:";label .vnohab -textvariable snohab(1) -width 7
label .linhab -text "Inhabitable:"	;label .vinhab -textvariable sinhab(1) -width 7
label .lmetal -text "Metal:"		;label .vmetal -textvariable smetal(1) -width 7
label .lincom -text "Income:"		;label .vincom -textvariable sincom(1) -width 7

label .lecnmc -text "Economic:"		;label .vecnmc -textvariable secnmc(1) -width 7;radiobutton .recnmc -value "0" -variable sresch(1)
label .lweapn -text "Weaponry:"		;label .vweapn -textvariable sweapn(1) -width 7;radiobutton .rweapn -value "1" -variable sresch(1)
label .larmor -text "Armour:"		;label .varmor -textvariable sarmor(1) -width 7;radiobutton .rarmor -value "2" -variable sresch(1)
label .lengin -text "Engines:"		;label .vengin -textvariable sengin(1) -width 7;radiobutton .rengin -value "3" -variable sresch(1)

canvas .cpcn  -width 100 -height 20 -bg green
	.cpcn create rectangle 	0 0 66 25 -fill blue -tag cpcnbld
	.cpcn create rectangle 	0 0 33 25 -fill red  -tag cpcntrn


grid .lcoord -in .left2 -row 1  -column 1 -sticky w;grid .vcoord -in .left2 -row 1  -column 2 -sticky w
grid .lowned -in .left2 -row 2  -column 1 -sticky w;grid .vowned -in .left2 -row 2  -column 2 -sticky w
grid .lbases -in .left2 -row 3  -column 1 -sticky w;grid .vbases -in .left2 -row 3  -column 2 -sticky w
grid .lships -in .left2 -row 4  -column 1 -sticky w;grid .vships -in .left2 -row 4  -column 2 -sticky w
grid .lnohab -in .left2 -row 5  -column 1 -sticky w;grid .vnohab -in .left2 -row 5  -column 2 -sticky w
grid .linhab -in .left2 -row 6  -column 1 -sticky w;grid .vinhab -in .left2 -row 6  -column 2 -sticky w
grid .lmetal -in .left2 -row 7  -column 1 -sticky w;grid .vmetal -in .left2 -row 7  -column 2 -sticky w
grid .lincom -in .left2 -row 8  -column 1 -sticky w;grid .vincom -in .left2 -row 8  -column 2 -sticky w
grid .lecnmc -in .left2 -row 9  -column 1 -sticky w;grid .vecnmc -in .left2 -row 9  -column 2 -sticky w;grid .recnmc -in .left2 -row 9  -column 3 -sticky w
grid .lweapn -in .left2 -row 10 -column 1 -sticky w;grid .vweapn -in .left2 -row 10 -column 2 -sticky w;grid .rweapn -in .left2 -row 10 -column 3 -sticky w
grid .larmor -in .left2 -row 11 -column 1 -sticky w;grid .varmor -in .left2 -row 11 -column 2 -sticky w;grid .rarmor -in .left2 -row 11 -column 3 -sticky w
grid .lengin -in .left2 -row 12 -column 1 -sticky w;grid .vengin -in .left2 -row 12 -column 2 -sticky w;grid .rengin -in .left2 -row 12 -column 3 -sticky w
grid .cpcn   -in .left2 -row 13 -column 1 -sticky w
###############################################################
#LEFT-3rd
frame .left3
grid .left3 -in .left -row 3 -column 1

button .bpcn  -text "SET" -command "chngpcnt 1";button .bbld  -text "SHIPS TO\nBASE" -command "build 1";button .bnhome -text "NEW\nHOME" -command "newhome 1"
button .bscr  -text "SCRAP" -command "scrap 1" ;button .brun  -text "RUN" -command "run"			   ;button .bstp  -text "STOP"           -command "stoprun"

grid .bpcn -in .left3 -row 1 -column 1;grid .bbld -in .left3 -row 1 -column 2;grid .bnhome -in .left3 -row 1 -column 3
grid .bscr -in .left3 -row 2 -column 1;grid .brun -in .left3 -row 2 -column 2;grid .bstp   -in .left3 -row 2 -column 3

###############################################################
#CENTRE
###############################################################
canvas .map -width $cx -height $cy -bg black
grid .map -in .cntr -row 1   -column 1
for {set c 1} {$c<=100} {incr c} {
	#CMD LINES
	.map create line 0 0 0 0 -tag cmdlne($c,1)
	.map create line 0 0 0 0 -tag cmdlne($c,2)
}
for {set c 1} {$c<=100} {incr c} {
	#FLEET MARKERS
	.map create oval 0 0 0 0 -tag cmdmrk($c) -fill white
}
proc shuffle {} {
	global tstar
	global ux;global uy
	global col
	upvar coord coord
	for {set s 0} {$s<=$tstar} {incr s} {
		#CREATING STARS
		set starx($s) [expr {int(rand()*($ux-26)+13)}]
		set stary($s) [expr {int(rand()*($uy-36)+18)}]
		#ensure star is not on-top/directly in line/too close to another star, check every other star
		for {set s2 0} {$s2<$s} {incr s2} {
			while {[dist $s $s2]<50} {
				set starx($s) [expr {int(rand()*($ux-26)+13)}]
				set stary($s) [expr {int(rand()*($uy-36)+18)}]
				puts 1
			}
			while {$starx($s)==$starx($s2)} {
				set starx($s) [expr {int(rand()*($ux-26)+13)}]
			}
			while {$stary($s)==$stary($s2)} {
				set stary($s) [expr {int(rand()*($uy-36)+18)}]
			}
		}
		.map create oval 	[expr {$starx($s)-15}] [expr {$stary($s)-10}] \
							[expr {$starx($s)+15}] [expr {$stary($s)+10}] -tag star($s) -fill $col(0) -outline black
		.map create text $starx($s) $stary($s) -tag scrbase($s) -text "0" -fill black
		.map create text $starx($s) [expr {$stary($s)-14}] -tag scrship($s) -text "0" -fill red
		.map create text $starx($s) [expr {$stary($s)+14}] -tag scrinco($s) -text "0" -fill cyan
		puts $s
		set coord($s) "$starx($s) $stary($s)"
	}
}
for {set s 0} {$s<=$tstar} {incr s} {
	#CREATING STARS
	set starx($s) [expr {int(rand()*($ux-26)+13)}]
	set stary($s) [expr {int(rand()*($uy-36)+18)}]
	#ensure star is not on-top/directly in line/too close to another star, check every other star
	for {set s2 0} {$s2<$s} {incr s2} {
		while {[dist $s $s2]<50} {
			set starx($s) [expr {int(rand()*($ux-26)+13)}]
			set stary($s) [expr {int(rand()*($uy-36)+18)}]
		}
		while {$starx($s)==$starx($s2)} {
			set starx($s) [expr {int(rand()*($ux-26)+13)}]
		}
		while {$stary($s)==$stary($s2)} {
			set stary($s) [expr {int(rand()*($uy-36)+18)}]
		}
	}
	.map create oval 	[expr {$starx($s)-15}] [expr {$stary($s)-10}] \
						[expr {$starx($s)+15}] [expr {$stary($s)+10}] -tag star($s) -fill $col(0) -outline black
	.map create text $starx($s) $stary($s) -tag scrbase($s) -text "0" -fill black
	.map create text $starx($s) [expr {$stary($s)-14}] -tag scrship($s) -text "0" -fill red
	.map create text $starx($s) [expr {$stary($s)+14}] -tag scrinco($s) -text "0" -fill cyan

	set coord($s) "$starx($s) $stary($s)"
}
#Mini-map
	set mmx [expr {sqrt($ux/"$uy."*$mmsize)}]
	set mmy [expr {sqrt($uy/"$ux."*$mmsize)}]
	.map create rectangle [expr {$cx-$mmx}] [expr {$cy-$mmy}] $cx $cy -fill black -outline white
	#Mini-map sight-box
		set smmx [expr {$cx/"$ux."*$mmx}]
		set smmy [expr {$cy/"$uy."*$mmy}]
		.map create rectangle [expr {$cx-$mmx}] [expr {$cy-$mmy}] [expr {$cx-$mmx+$smmx}] [expr {$cy-$mmy+$smmy}] -tag sghtbox -outline white
	for {set s 0} {$s<=$tstar} {incr s} {
		.map create oval 	[expr {$starx($s)/"$ux."*$mmx+$cx-$mmx+1.5}] [expr {$stary($s)/"$uy."*$mmy+$cy-$mmy+1.5}] \
							[expr {$starx($s)/"$ux."*$mmx+$cx-$mmx-1.5}] [expr {$stary($s)/"$uy."*$mmy+$cy-$mmy-1.5}] -tag mmstar($s) -fill $col(0)
	}
###############################################################
#RIGHT
###############################################################
#Change right display to (arrows change CMD NUM, looping round total cmds available):
	#new variables: sctype for all cmds, new procs: incscmd, decscmd
	###################
	#	CMD NUM		  #
	#	ctype		  #
	#	cloca		  #
	#	ctime		  #
	#	cship		  #
	#	cdest		  #
	#	cdist		  #
	#	cecnmc		  #
	#	cweapn		  #
	#	carmor		  #
	#	cengin		  #
	#	 _ 		 _	  #
	#	|<|		|>|   #
	###################
	# END 	|	X10   #
	# TURN 	|	  	  #
	###################
###############################################################
#RIGHT-1st
frame .rght1
grid .rght1 -in .rght -row 1 -column 1

label .lcmdno  -text "Cmd num:"			;label .vcmdno  -textvariable scmd   -width 9
label .lctype  -text "Cmd type:"		;label .vctype  -textvariable sctype -width 9
label .lcloca  -text "Location:"		;label .vcloca  -textvariable scloca -width 9
label .lctime  -text "Time to action:"	;label .vctime  -textvariable sctime -width 9
label .lcship  -text "Num ships:"		;label .vcship  -textvariable scship -width 9
label .lcdest  -text "Destination:"		;label .vcdest  -textvariable scdest -width 9
label .lcdist  -text "Dist to dest:"	;label .vcdist  -textvariable scdist -width 9
label .lcecnmc -text "Econ tech:"		;label .vcecnmc -textvariable scecnmc -width 9
label .lcweapn -text "Weapon tech:"		;label .vcweapn -textvariable scweapn -width 9
label .lcarmor -text "Armour tech:"		;label .vcarmor -textvariable scarmor -width 9
label .lcengin -text "Engine tech:"		;label .vcengin -textvariable scengin -width 9

button .bcmds -text "<" -command decscmd;button .bcmdp -text ">" -command incscmd

grid .lcmdno  -in .rght1 -row 1  -column 1 -sticky w;grid .vcmdno  -in .rght1 -row 1  -column 2 -sticky w
grid .lctype  -in .rght1 -row 2  -column 1 -sticky w;grid .vctype  -in .rght1 -row 2  -column 2 -sticky w
grid .lcloca  -in .rght1 -row 3  -column 1 -sticky w;grid .vcloca  -in .rght1 -row 3  -column 2 -sticky w
grid .lctime  -in .rght1 -row 4  -column 1 -sticky w;grid .vctime  -in .rght1 -row 4  -column 2 -sticky w
grid .lcship  -in .rght1 -row 5  -column 1 -sticky w;grid .vcship  -in .rght1 -row 5  -column 2 -sticky w
grid .lcdest  -in .rght1 -row 6  -column 1 -sticky w;grid .vcdest  -in .rght1 -row 6  -column 2 -sticky w
grid .lcdist  -in .rght1 -row 7  -column 1 -sticky w;grid .vcdist  -in .rght1 -row 7  -column 2 -sticky w
grid .lcecnmc -in .rght1 -row 8  -column 1 -sticky w;grid .vcecnmc -in .rght1 -row 8  -column 2 -sticky w
grid .lcweapn -in .rght1 -row 9  -column 1 -sticky w;grid .vcweapn -in .rght1 -row 9  -column 2 -sticky w
grid .lcarmor -in .rght1 -row 10 -column 1 -sticky w;grid .vcarmor -in .rght1 -row 10 -column 2 -sticky w
grid .lcengin -in .rght1 -row 11 -column 1 -sticky w;grid .vcengin -in .rght1 -row 11 -column 2 -sticky w
grid .bcmds   -in .rght1 -row 12 -column 1 -sticky w;grid .bcmdp   -in .rght1 -row 12 -column 2 -sticky w
###############################################################
#RIGHT-2nd
frame .rght2
grid .rght2 -in .rght -row 2 -column 1

button .bndtrn -text "END\nTURN" -command "endtrn";button .bndtrn10 -text "X10" -command "end10trn"
scale .sspeed -label "Speed" -variable speed -orient vertical   -width 5 -length 75 -sliderlength 10 -from 0 -to 50

grid   .bndtrn -in .rght2 -row 1 -column 1;grid   .bndtrn10 -in .rght2 -row 1 -column 2
grid   .sspeed -in .rght2 -row 2 -column 1

###############################################################
#MOUSECLICK
###############################################################
bind .map <ButtonPress-1> "lclick %x %y 1"
bind .map <B1-Motion> "lclick %x %y 1"
bind .map <ButtonPress-3> "rclick %x %y 1"

bind .cpcn <B1-Motion> "cpcndrg %x %y 1"

##############################################################################################################################
##############################################################################################################################
#END TURN
##############################################################################################################################
##############################################################################################################################
proc endtrn {} {
	uplevel #0 {
		for {set p 1} {$p<=$nplay} {incr p} {
#AI ACTIONS
			AI
#GAME EVENTS
			for {set c 1} {$c<=$numcmd($p)} {incr c} {
				command
			}
		} 
		#proc reb {ships bases dhome const} {
		#	set rships [expr {$ships<($bases*1000) ? $ships:($bases*1000)}]
		#	set shipposval [expr {($rships/($rships+1.))**0.01}]
		#	set rships [expr {$ships>($bases*1000) ? ($ships/($bases>0 ? $bases:1)-1000):1}]
		#	set shipnegval [expr {1/$rships**0.01}]
		#	set homeval [expr {1/($dhome+1)**0.1}]
		#	puts "1 - ( $shipposval * $shipnegval * $homeval ) ** $const"
		#	set ret [expr {1 - ( $shipposval * $shipnegval * $homeval ) ** $const}]
		#	puts [expr {1/$ret}]
		#	return $ret
		#}
		for {set s 0} {$s<=$tstar} {incr s} {
			#REBELLION
			#rand() < (1 / (ship-positive-effect * ship-negative-effect * dist-from-home-effect * constant)
				#ship-positive-effect=(ships+1)^0.05
					#ships=(ships<(bases*1000) ? ships:(bases*1000))
				#ship-negative-effect=1/(ships^0.01)
					#ships=(ships>(bases*1000) ? (ships/(bases+1)-1000):1)
				#dist-from-home-effect=1/(([dist from home]+1)^0.1)
				#constant=0.001
			#if neutral star, treat it like a homeworld
				set rships [expr {$ships($s,1)<($bases($s,1)*1000+10) ? $ships($s,1):($bases($s,1)*1000+10)}]
				set shipposval [expr {($rships/($rships+sqrt($rships)+1))**0.1}]
				set rships [expr {$ships($s,1)>(($bases($s,1)+10)*1000) ? ($ships($s,1)/($bases($s,1)+10.)-1000):1}]
				set shipnegval [expr {1/$rships**0.0001}]
				set homeval [expr {1/($owned($s,1)==0 ? 1:([dist $home($owned($s,1)) $s]+1))**0.0001}]
			if {$ships($s,1)>((rand()*1e8+1e7)**0.5) && rand()<($speed*(1-($shipposval * $shipnegval * $homeval) ** 1))} {rebellion $s};#;puts "REB $s\nSP $shipposval\nSN $shipnegval\nHV $homeval"
			#ADD STARS INCOME
			starincome $s
		}
#VARIABLE UPDATES/DRAWING TO MAP
		for {set p 1} {$p<=$nplay} {incr p} {
			for {set s 0} {$s<=$tstar} {incr s} {
				if {$home($p)>=0} {updateinfo $p $s}
			}
			#UPDATE TOTALS/INFO
			set tinco($p) 0;set tshbl($p) 0;set tbsbl($p) 0
			set trese($p) 0;set tship($p) 0;set tbase($p) 0
			addtotals $p
			#UPDATE SELECTED STAR, NUMCMD
			slct $p $sstar($p)
			if {$home($p)>=0} {set numcmd($p) [expr {$bases($home($p),1)>=1000 ? 100:(1+$bases($home($p),1)/10)}]}
		}
		#UPDATE SELECTED CMD
		updatescmd
		for {set s 0} {$s<=$tstar} {incr s} {
			#MOVE ALL STARS HISTORY BACK
			if {$turn%$histacc==0} {movehistback $s}
			#DRAW STARS
			drawstarperfect $s
		}
		#DRAW CMDLINES
		for {set c 1} {$c<=$numcmd($watchp)} {incr c} {drawcmdline $c}
		incr turn $speed
		#after 100 {set sleep {}}
		#tkwait variable sleep
		#if {$turn%50==0} {puts $turn}
	}
}
###############################################################
proc end10trn {} {for {set n 1} {$n<=10} {incr n} {endtrn;after 1 {set sleep {}};tkwait variable sleep}}
###############################################################
proc run {} {uplevel #0 {set run 1;while {$run} {endtrn;after 1 {set sleep {}};tkwait variable sleep}}}
proc stoprun {} {uplevel #0 {set run 0}}
###############################################################
#END TURN SUBROUTINES
###############################################################
proc losthome {p} {
	global tstar;global owned;upvar #0 home($p) home
	global numcmd;global watchp;upvar #0 sstar($p) sstar
	global incom
	if {$p==$watchp} {for {set c 1} {$c<=$numcmd($p)} {incr c} {
		.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
		.map coords cmdmrk($c) 0 0 0 0}}
	#newhome=system with most income
	global ux;global uy
	set mindist [expr {hypot($ux,$uy)}]
	for {set s 0} {$s<=$tstar} {incr s} {
		if {$owned($s,1)==$p && [dist $home $s]<$mindist} {
			set sstar $s
			set mindist [dist $home $s]
		}
	}
	if {$mindist>=hypot($ux,$uy)} {
		set home -1
		#reset all cmds
		for {set c 1} {$c<=$numcmd($p)} {incr c} {
			upvar #0 ctype($p,$c) ctype  ;upvar #0 cloca($p,$c) cloca  ;upvar #0 ctime($p,$c) ctime
			upvar #0 cship($p,$c) cship  ;upvar #0 cdest($p,$c) cdest  ;upvar #0 cdist($p,$c) cdist
			upvar #0 cecnmc($p,$c) cecnmc;upvar #0 cweapn($p,$c) cweapn;upvar #0 carmor($p,$c) carmor
			upvar #0 cengin($p,$c) cengin
			set ctype 0 ;set cloca 0 ;set ctime 0
			set cship 0 ;set cdest 0 ;set cdist 0
			set cecnmc 0;set cweapn 0;set carmor 0
			set cengin 0
		}
	} else {
		#send newhome command
		upvar #0 ctype($p,1) ctype;set ctype 0
		newhome $p
		#clear all cmds above new max
		global bases
		set newnumcmd [expr {$bases($sstar,1)>=1000 ? 100:(1+$bases($sstar,1)/10)}]
		for {set c $newnumcmd;incr c} {$c<=$numcmd($p)} {incr c} {
			upvar #0 ctype($p,$c) ctype  ;upvar #0 cloca($p,$c) cloca  ;upvar #0 ctime($p,$c) ctime
			upvar #0 cship($p,$c) cship  ;upvar #0 cdest($p,$c) cdest  ;upvar #0 cdist($p,$c) cdist
			upvar #0 cecnmc($p,$c) cecnmc;upvar #0 cweapn($p,$c) cweapn;upvar #0 carmor($p,$c) carmor
			upvar #0 cengin($p,$c) cengin
			set ctype 0 ;set cloca 0 ;set ctime 0
			set cship 0 ;set cdest 0 ;set cdist 0
			set cecnmc 0;set cweapn 0;set carmor 0
			set cengin 0
			.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
			.map coords cmdmrk($c) 0 0 0 0
		}
	}
		#upvar #0 ctype($p,1) ctype 
		#puts "$p HOME:$home, SSTAR:$sstar ($ctype)"
}
proc hometestinfo {} {global nplay;global numcmd;global ctype;global home;for {set p 1} {$p<=$nplay} {incr p} {
		if {$home($p)==-2} {
			set ok 0
			for {set c 1} {$c<=$numcmd($p)} {incr c} {
				if {$ctype($p,$c)=="HOME"} {puts "$p HOME";set ok 1;break}
			}
			if {$ok==0} {puts "$p NOHOME"}
		}
	}
}
proc homes {} {global home;global owned;global nplay;for {set p 1} {$p<=$nplay} {incr p} {if {$home($p)>=0} {puts "$p $home($p) $owned($home($p),1)"} else {puts "$p $home($p)"}}}
proc pinfo {p} {global home;global ecnmc;global weapn;global armor;global engin;global resch;global tinco;global tship;global tbase;global tbsbl;global tshbl;global trese;global turn;global pcnflt
puts "TURN $turn | PLAYER $p"
puts "ECNMC $ecnmc($home($p),1) | WEAPN $weapn($home($p),1) | ARMOR $armor($home($p),1) | ENGIN $engin($home($p),1) | RESCH $resch($home($p),1) | PCNFLT $pcnflt($p)"
puts "TINCO $tinco($p) | TSHIP $tship($p) | TBASE $tbase($p)\nTSHBL $tshbl($p) | TBSBL $tbsbl($p) | TRESE $trese($p)\n################################"}
proc bestshipinfo {} {global tship;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$tship($p)>$max} {set bestp $p;set max $tship($p)}
	}
	pinfo $bestp
}
proc bestbaseinfo {} {global tbase;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$tbase($p)>$max} {set bestp $p;set max $tbase($p)}
	}
	pinfo $bestp
}
proc bestincoinfo {} {global tinco;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$tinco($p)>$max} {set bestp $p;set max $tinco($p)}
	}
	pinfo $bestp
}
proc besttechinfo {} {global ecnmc;global weapn;global armor;global engin;global home;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$home($p)>=0} {set ttech [expr {$ecnmc($home($p),1)+$weapn($home($p),1)+$armor($home($p),1)+$engin($home($p),1)}]} else {set ttech 0}
		if {$ttech>$max} {set bestp $p;set max $ttech}
	}
	pinfo $bestp
}
proc bestinfo {} {global tship;global tinco;global ecnmc;global weapn;global armor;global engin;global home;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$home($p)>=0} {set ttech [expr {$ecnmc($home($p),1)+$weapn($home($p),1)+$armor($home($p),1)+$engin($home($p),1)}]} else {set ttech 0}
		set rating [expr {$tship($p)*10+$tinco($p)**2+$ttech**3}]
		if {$rating>$max} {set bestp $p;set max $rating}
	}
	pinfo $bestp
}
proc pscores {} {global tship;global tinco;global ecnmc;global weapn;global armor;global engin;global home;set max 0;global nplay
	for {set p 1} {$p<=$nplay} {incr p} {
		if {$home($p)>=0} {set ttech [expr {$ecnmc($home($p),1)+$weapn($home($p),1)+$armor($home($p),1)+$engin($home($p),1)}]} else {set ttech 0}
		set rating($p) [expr {$tship($p)*10+$tinco($p)**2+$ttech**3}]
	}
	for {set p 1} {$p<=$nplay} {incr p} {
		set max 0
		for {set p2 1} {$p2<=$nplay} {incr p2} {
			if {$rating($p2)>$max} {set maxp $p2;set max $rating($p2)}
		}
		puts "P$maxp: $rating($maxp)"
		set rating($maxp) 0
	}
}
##############################################################################################################################
proc AI {} {
	uplevel #0 {
		if {$home($p)>=0} {
			#AI to loop between all stars, sending attacks from homeworld whenever possible
				##1
				#sstar=home
				#var(1)=atkstar
				#move $var(1)
				#incr var(1)
				#var(1)>tstar jmp #2
				#jmp #1
				##2
				#var(1)=1
				#set AIcode($p) "#1 50 Wpcnflt Rhome Wsstar 1 RVAR Pmove 1 RVAR MPL 1 ADD MPR 1 MPL WVAR Rtstar MPL 1 RVAR GRE MPL 2 JMP 1 MPL 1 JMP #2 1 MPL 1 WVAR 1 MPL 1 JMP"
			#COMMANDS LIST
				#CMD	RESULT (x=p, y=p+1)
				#n		x=n
				##n		none
				#JMP	pos=#x if y!=0
				#MPR	ptr++
				#MPL	ptr--
				#ADD	x=x+y
				#SUB	x=x-y
				#MUL	x=x*y
				#DIV	x=x/y
				#MOD	x=x%y
				#LND	x=x&&y
				#LOR	x=x||y
				#EQU	x=x==y
				#LES	x=x<y
				#GRE	x=x>y
				#RvarP	x=varP(p)
					#Rtinco , Rtshbl , Rtbsbl , Rtrese, Rtship, Rtbase, Rpcnflt
					#Rstrnpc, Rsbldpc, Rsresch, Rsstar, Rnumcmd, Rhome, Rtstar
					#Rplay
				#RvarPX	x=varPX(p,x)
					#Rctype , Rcloca , Rctime , Rcship , Rcdest , Rcdist
					#Rcecnmc, Rcweapn, Rcarmor, Rcengin
					#Riowned, Ribases, Riincom, Riships, Ritrnpc, Ribldpc
					#Riecnmc, Riweapn, Riarmor, Riengin, Riresch
				#RvarX	x=varX(x)
					#Rstarx , Rstary , Rinhab , Rnohab , Rmetal
				#Rvar	x=var(p,x)
				#WvarP	varP(p)=x
					#Wsstar, Wpcnflt, Wstrnpc, Wsbldpc, Wsresch
				#Wvar	var(p,x)=y
				#PrcP	proc p
					#Pbuild, Pnewhome, Pchngpcnt, Pscrap
				#PrcPX	proc p x
					#Pmove, Pdist
				#END	ptr=0, break
			set reps [expr {$speed*$AIrepspertrn}]
			for {set n 1} {$n<$reps} {incr n} {
				set cmd [lindex $AIcode($p) $pos($p)]
				set x [lindex $stack($p) $ptr($p)]							;if {$x>1000000} {set x 1000000} elseif {$x<-1000000} {set x -1000000}
				set y [lindex $stack($p) [expr {($ptr($p)+1)&$stacksize}]]	;if {$y>1000000} {set y 1000000} elseif {$y<-1000000} {set y -1000000}
				if {[string is integer $cmd]==1 && $cmd!=""} {
					lset stack($p) $ptr($p) $cmd
				} elseif {$cmd=="JMP"} {
					if {$y!=0} {if {[lsearch $AIcode($p) "#$x"]!=-1} {set pos($p) [lsearch $AIcode($p) "#$x"]}}
				} elseif {$cmd=="MPR"} {
					set ptr($p) [expr {($ptr($p)+1)&$stacksize}]
				} elseif {$cmd=="MPL"} {
					set ptr($p) [expr {($ptr($p)-1)&$stacksize}]
				} elseif {$cmd=="ADD"} {if {($x+$y)>1000} {lset stack($p) $ptr($p) -1000} elseif {($x+$y)<-1000} {lset stack($p) $ptr($p) 1000} else {
					lset stack($p) $ptr($p) [expr {$x+ $y}]}
				} elseif {$cmd=="SUB"} {if {($x+$y)>1000} {lset stack($p) $ptr($p) -1000} elseif {($x+$y)<-1000} {lset stack($p) $ptr($p) 1000} else {
					lset stack($p) $ptr($p) [expr {$x- $y}]}
				} elseif {$cmd=="MUL"} {if {($x+$y)>1000} {lset stack($p) $ptr($p) -1000} elseif {($x+$y)<-1000} {lset stack($p) $ptr($p) 1000} else {
					lset stack($p) $ptr($p) [expr {$x* $y}]}
				} elseif {$cmd=="DIV"} {if {$y==0} {set y 1};if {($x+$y)>1000} {lset stack($p) $ptr($p) -1000} elseif {($x+$y)<-1000} {lset stack($p) $ptr($p) 1000} else {
					lset stack($p) $ptr($p) [expr {$x/ $y}]}
				} elseif {$cmd=="MOD"} {set y [expr {int($y)}];set x [expr {int($x)}];if {$y==0} {set y 1};if {($x+$y)>1000} {lset stack($p) $ptr($p) -1000} elseif {($x+$y)<-1000} {lset stack($p) $ptr($p) 1000} else {
					lset stack($p) $ptr($p) [expr {$x% $y}]}
				} elseif {$cmd=="LND"} {
					lset stack($p) $ptr($p) [expr {$x&&$y}]
				} elseif {$cmd=="LOR"} {
					lset stack($p) $ptr($p) [expr {$x||$y}]
				} elseif {$cmd=="EQU"} {
					lset stack($p) $ptr($p) [expr {$x==$y}]
				} elseif {$cmd=="LES"} {
					lset stack($p) $ptr($p) [expr {$x< $y}]
				} elseif {$cmd=="GRE"} {
					lset stack($p) $ptr($p) [expr {$x> $y}]
					
					
				} elseif {$cmd=="Rtinco"} {lset stack($p) $ptr($p) $tinco($p)
				} elseif {$cmd=="Rtshbl"} {lset stack($p) $ptr($p) $tshbl($p)
				} elseif {$cmd=="Rtbsbl"} {lset stack($p) $ptr($p) $tbsbl($p)
				} elseif {$cmd=="Rtrese"} {lset stack($p) $ptr($p) $trese($p)
				} elseif {$cmd=="Rtship"} {lset stack($p) $ptr($p) $tship($p)
				} elseif {$cmd=="Rtbase"} {lset stack($p) $ptr($p) $tbase($p)
				} elseif {$cmd=="Rpcnflt"} {lset stack($p) $ptr($p) $pcnflt($p)
				} elseif {$cmd=="Rstrnpc"} {lset stack($p) $ptr($p) $strnpc($p)
				} elseif {$cmd=="Rsbldpc"} {lset stack($p) $ptr($p) $sbldpc($p)
				} elseif {$cmd=="Rsresch"} {lset stack($p) $ptr($p) $sresch($p)
				} elseif {$cmd=="Rsstar"} {lset stack($p) $ptr($p) $sstar($p)
				} elseif {$cmd=="Rnumcmd"} {lset stack($p) $ptr($p) $numcmd($p)
				} elseif {$cmd=="Rhome"} {lset stack($p) $ptr($p) $home($p)
				} elseif {$cmd=="Rtstar"} {lset stack($p) $ptr($p) $tstar
				} elseif {$cmd=="Rplay"} {lset stack($p) $ptr($p) $p
				
				
				} elseif {$cmd=="Rctype"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};
					if {$ctype($p,$x)=="HOME"} {set c 1} elseif {$ctype($p,$x)=="CBLD"} {set c 2} elseif {$ctype($p,$x)=="CPCN"} {set c 3} elseif {$ctype($p,$x)=="CMOV"} {set c 4
					} elseif {$ctype($p,$x)=="MOVE"} {set c 5} elseif {$ctype($p,$x)=="MOV?"} {set c 6} else {set c 0}
					lset stack($p) $ptr($p) $c
				} elseif {$cmd=="Rcloca"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cloca($p,$x)
				} elseif {$cmd=="Rcship"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cship($p,$x)
				} elseif {$cmd=="Rcdest"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cdest($p,$x)
				} elseif {$cmd=="Rcdist"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cdist($p,$x)
				} elseif {$cmd=="Rcecnmc"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cecnmc($p,$x)
				} elseif {$cmd=="Rcweapn"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cweapn($p,$x)
				} elseif {$cmd=="Rcarmor"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $carmor($p,$x)
				} elseif {$cmd=="Rcengin"} {set x [expr {int($x)}];if {$x>100} {set x 100} elseif {$x<1} {set x 1};lset stack($p) $ptr($p) $cengin($p,$x)
				} elseif {$cmd=="Riowned"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iowned($p,$x)
				} elseif {$cmd=="Ribases"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $ibases($p,$x)
				} elseif {$cmd=="Riincom"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iincom($p,$x)
				} elseif {$cmd=="Riships"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iships($p,$x)
				} elseif {$cmd=="Ritrnpc"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $itrnpc($p,$x)
				} elseif {$cmd=="Ribldpc"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $ibldpc($p,$x)
				} elseif {$cmd=="Riecnmc"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iecnmc($p,$x)
				} elseif {$cmd=="Riweapn"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iweapn($p,$x)
				} elseif {$cmd=="Riarmor"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iarmor($p,$x)
				} elseif {$cmd=="Riengin"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iengin($p,$x)
				} elseif {$cmd=="Riresch"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $iresch($p,$x)
				
				
				} elseif {$cmd=="Rstarx"} {set x [expr {int($x)}];set x [expr {$x&$tstar}]
					lset stack($p) $ptr($p) [expr {$starx($x)-($home($p)>=0 ? $starx($home($p)):0)}]
				} elseif {$cmd=="Rstary"} {set x [expr {int($x)}];set x [expr {$x&$tstar}]
					lset stack($p) $ptr($p) [expr {$stary($x)-($home($p)>=0 ? $stary($home($p)):0)}]
				} elseif {$cmd=="Rinhab"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $inhab($x)
				} elseif {$cmd=="Rnohab"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $nohab($x)
				} elseif {$cmd=="Rmetal"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];lset stack($p) $ptr($p) $metal($x)
				
				
				} elseif {$cmd=="Rvar"} {set x [expr {int($x)}];lset stack($p) $ptr($p) $AIvar($p,[expr {$x&$numAIvar}])
					
					
				} elseif {$cmd=="Wsstar"} {set x [expr {int($x)}];set x [expr {$x&$tstar}];set sstar($p) $x
				} elseif {$cmd=="Wpcnflt"} {if {$x>100} {set x 100} elseif {$x<0} {set x 0};set pcnflt($p) $x
				} elseif {$cmd=="Wstrnpc"} {set strnpc($p) $x
				} elseif {$cmd=="Wsbldpc"} {set sbldpc($p) $x
				} elseif {$cmd=="Wsresch"} {set x [expr {int($x)&3}];set sresch($p) $x
				
				
				} elseif {$cmd=="Wvar"} {set x [expr {int($x)}];set AIvar($p,[expr {$x&$numAIvar}]) $y
					
				} elseif {$cmd=="Pbuild" || $cmd=="Pnewhome" || $cmd=="Pchngpcnt" || $cmd=="Pscrap"} {
					set PROC [string trimleft $cmd P]
					$PROC $p
					
				} elseif {$cmd=="Pmove"} {set x [expr {int($x)}];set x [expr {$x&$tstar}]
					set PROC [string trimleft $cmd P]
					$PROC $p $x
					
				} elseif {$cmd=="Pdist"} {set x [expr {int($x)}];set x [expr {$x&$tstar}]
					set PROC [string trimleft $cmd P]
					lset stack($p) $ptr($p) [$PROC $sstar($p) $x]
					
				} elseif {$cmd=="END"} {
					set pos($p) 0
					set ptr($p) 0
					break
				}
				set pos($p) [expr {($pos($p)+1)&$codelength}]
			}
		}
	}
}
##############################################################################################################################
proc command {} {
	uplevel #0 {
		#Move cmds forward
		if {$ctime($p,$c)>0} {set ctime($p,$c) [expr {$ctime($p,$c)-1*$speed}]}
		
		#info arrives from outgoing move cmd
		if {$ctype($p,$c)=="MOV?"} {
			if {$chdlay($p,$c)<=($turn-$chturn($p,$c))} {mov?cmd} else {;#mov? cmd info arrives
				if {$chdist($p,$c)>0} {set chdist($p,$c) [expr {int(($chdist($p,$c)-(10.001-0.999**$chengin($p,$c)*10)*$speed)*100)/100.}]} else {
					if {$chtype($p,$c)=="MOVE"} {move?cmd}
				};#mov? fleet arrives at dest
			}
		}
		#if command at destination
		if {$ctime($p,$c)<=0 && $ctype($p,$c)!=0} {
			#Move fleets forward
			if {$cdist($p,$c)>0} {set cdist($p,$c) [expr {int(($cdist($p,$c)-(10.001-0.999**$cengin($p,$c)*10)*$speed)*100)/100.}]}
			#Enact commands
			if {$ctype($p,$c)=="HOME"} {homecmd}
			if {$ctype($p,$c)=="CBLD"} {cbldcmd}
			if {$ctype($p,$c)=="CSCR"} {cscrcmd}
			if {$ctype($p,$c)=="CPCN"} {cpcncmd}
			if {$ctype($p,$c)=="CMVE"} {cmvecmd}
			#Move requires extra check with cdist
			if {$ctype($p,$c)=="MOVE" && $cdist($p,$c)<=0} {movecmd}
		}
	}
}
###############################################################
	proc mov?cmd {} {
		uplevel #0 {
			if {$chtype($p,$c)=="MOVE"} {
				set ctype($p,$c) "MOVE"
				set cdist($p,$c) $chdist($p,$c)
				set cship($p,$c) $chship($p,$c)
				set cecnmc($p,$c) $checnmc($p,$c)
				set cweapn($p,$c) $chweapn($p,$c)
				set carmor($p,$c) $charmor($p,$c)
				set cengin($p,$c) $chengin($p,$c)
			} else {
				set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
				set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
				set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
				set cengin($p,$c) 0
			}
		}
	}
	proc move?cmd {} {
		uplevel #0 {
			#IF WE OWN DESTINATION
			if {$owned($cdest($p,$c),1)==$p} {
				set ships($cdest($p,$c),1) [expr {$ships($cdest($p,$c),1)+$chship($p,$c)}]
				set owned($cdest($p,$c),1) $p
				set ecnmc($cdest($p,$c),1) [expr {$checnmc($p,$c)>$ecnmc($cdest($p,$c),1) ? $checnmc($p,$c):$ecnmc($cdest($p,$c),1)}]
				set weapn($cdest($p,$c),1) [expr {$chweapn($p,$c)>$weapn($cdest($p,$c),1) ? $chweapn($p,$c):$weapn($cdest($p,$c),1)}]
				set armor($cdest($p,$c),1) [expr {$charmor($p,$c)>$armor($cdest($p,$c),1) ? $charmor($p,$c):$armor($cdest($p,$c),1)}]
				set engin($cdest($p,$c),1) [expr {$chengin($p,$c)>$engin($cdest($p,$c),1) ? $chengin($p,$c):$engin($cdest($p,$c),1)}]
			} else {
				#ENEMY DESTINATION
				#BATTLES
					#WORK OUT BATTLE RESULTS FOR FLEETS AT DESTINATION, DESTROY BASES AND CHANGE SYSTEM OWNER IF NECESSARY
					set result [battle $chship($p,$c) $chweapn($p,$c) $charmor($p,$c) $ships($cdest($p,$c),1) $weapn($cdest($p,$c),1) $armor($cdest($p,$c),1)]
					set chship($p,$c) [lindex $result 0]
					set ships($cdest($p,$c),1) [lindex $result 1]
					#IF ENEMY HAS NO SHIPS ON BASE...
					if {$ships($cdest($p,$c),1)==0} {
						#DEFAULT TO NO OWNER
						set owned($cdest($p,$c),1) 0
						#CHECK IF IT IS A HOME OF ANYONE & IF SO FIND THEM NEW HOME IF POSSIBLE
						for {set p2 1} {$p2<=$nplay} {incr p2} {
							if {$home($p2)==$cdest($p,$c)} {
								losthome $p2
								break
							}
						}
						if {$chship($p,$c)>0} {
							#WE HAVE SOME SHIPS; IT'S OURS
							set bases($cdest($p,$c),1) 1
							set owned($cdest($p,$c),1) $p
							set ships($cdest($p,$c),1) $chship($p,$c)
							set ecnmc($cdest($p,$c),1) $checnmc($p,$c)
							set weapn($cdest($p,$c),1) $chweapn($p,$c)
							set armor($cdest($p,$c),1) $charmor($p,$c)
							set engin($cdest($p,$c),1) $chengin($p,$c)
							set resch($cdest($p,$c),1) [expr {int(rand()*4)}]
							set bldpc($cdest($p,$c),1) 33
							set trnpc($cdest($p,$c),1) 33
						}
					}
			}
			set chtype($p,$c) 0
		}
	}
###############################################################
	proc homecmd {} {
		uplevel #0 {
			if {$owned($cdest($p,$c),1)==$p && $cdist($p,$c)<=0} {
				set home($p) $cdest($p,$c)
				
				set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
				set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
				set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
				set cengin($p,$c) 0
					#clear all cmds above new max
					set newnumcmd [expr {$bases($cdest($p,$c),1)>=1000 ? 100:(1+$bases($cdest($p,$c),1)/10)}]
					for {set c2 $newnumcmd;incr c2} {$c2<=$numcmd($p)} {incr c2} {
						set ctype($p,$c2) 0 ;set cloca($p,$c2) 0 ;set ctime($p,$c2) 0
						set cship($p,$c2) 0 ;set cdest($p,$c2) 0 ;set cdist($p,$c2) 0
						set cecnmc($p,$c2) 0;set cweapn($p,$c2) 0;set carmor($p,$c2) 0
						set cengin($p,$c2) 0
						.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
						.map coords cmdmrk($c) 0 0 0 0
					}
			} elseif {$owned($cdest($p,$c),1)!=$p && $cdist($p,$c)<=0} {
			
				set cloca($p,$c) $cdest($p,$c)
				
				#find cdest, closest owned planet to cloca
				global ux;global uy
				set mindist [expr {hypot($ux,$uy)}]
				for {set s 0} {$s<=$tstar} {incr s} {
					if {$owned($s,1)==$p && [dist $cloca($p,$c) $s]<$mindist} {
						set cdest($p,$c) $s
						set mindist [dist $cloca($p,$c) $s]
					}
				}
				set cdist($p,$c) [dist $cloca($p,$c) $cdest($p,$c)]
				
				set newnumcmd [expr {$bases($cdest($p,$c),1)>=1000 ? 100:(1+$bases($cdest($p,$c),1)/10)}]
				for {set c2 $newnumcmd;incr c2} {$c2<=$numcmd($p)} {incr c2} {
					set ctype($p,$c2) 0 ;set cloca($p,$c2) 0 ;set ctime($p,$c2) 0
					set cship($p,$c2) 0 ;set cdest($p,$c2) 0 ;set cdist($p,$c2) 0
					set cecnmc($p,$c2) 0;set cweapn($p,$c2) 0;set carmor($p,$c2) 0
					set cengin($p,$c2) 0
					.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
					.map coords cmdmrk($c) 0 0 0 0
				}
				set numcmd($p) $newnumcmd
				
				if {$cdest($p,$c)==$cloca($p,$c)} {set home($p) -1
					for {set c2 1} {$c2<=$numcmd($p)} {incr c2} {
						set ctype($p,$c2) 0;set cloca($p,$c2) 0;set ctime($p,$c2) 0
						set cship($p,$c2) 0;set cdest($p,$c2) 0;set cdist($p,$c2) 0
						set cecnmc($p,$c2) 0;set cweapn($p,$c2) 0;set carmor($p,$c2) 0
						set cengin($p,$c2) 0
					}
				}
			}
		}
	}
###############################################################
	proc cbldcmd {} {
		uplevel #0 {
			if {$owned($cloca($p,$c),1)==$p} {
				set shpbld [expr {int($cship($p,$c)/100.*$ships($cloca($p,$c),1))}];#num ships to be converting
				set ships($cloca($p,$c),1) [expr {$ships($cloca($p,$c),1)-$shpbld}]
				set basecred [expr {$shpbld*0.2}] 
				set basecost [expr {($bases($cloca($p,$c),1)**2)*0.05}];#cost for 1 base
				while {$basecred>$basecost} {
					set basecred [expr {$basecred-$basecost}]
					set bases($cloca($p,$c),1) [expr {$bases($cloca($p,$c),1)+1}]
					set basecost [expr {($bases($cloca($p,$c),1)**2)*0.05}]
				}
			}
			set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
			set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
			set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
			set cengin($p,$c) 0
		}
	}
###############################################################
	proc cscrcmd {} {
		uplevel #0 {
			if {$owned($cloca($p,$c),1)==$p} {
				#cecnmc, cweapn, carmor, cengin (1=tech to scrap)
				#cships=% tech to scrap
				#cloca=location
				      if {$cecnmc($p,$c)==1} {set techscrap [expr {int($cship($p,$c)/100.*$ecnmc($cloca($p,$c),1))}];#tech to scrap
					set ecnmc($cloca($p,$c),1) [expr {$ecnmc($cloca($p,$c),1)-$techscrap}]
					
				} elseif {$cweapn($p,$c)==1} {set techscrap [expr {int($cship($p,$c)/100.*$weapn($cloca($p,$c),1))}]
					set weapn($cloca($p,$c),1) [expr {$weapn($cloca($p,$c),1)-$techscrap}]
					
				} elseif {$carmor($p,$c)==1} {set techscrap [expr {int($cship($p,$c)/100.*$armor($cloca($p,$c),1))}]
					set armor($cloca($p,$c),1) [expr {$armor($cloca($p,$c),1)-$techscrap}]
					
				} elseif {$cengin($p,$c)==1} {set techscrap [expr {int($cship($p,$c)/100.*$engin($cloca($p,$c),1))}]
					set engin($cloca($p,$c),1) [expr {$engin($cloca($p,$c),1)-$techscrap}]
				}
			}
			set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
			set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
			set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
			set cengin($p,$c) 0
		}
	}
###############################################################
	proc cpcncmd {} {
		uplevel #0 {
			if {$owned($cloca($p,$c),1)==$p} {
				set trnpc($cloca($p,$c),1) $cship($p,$c)
				set bldpc($cloca($p,$c),1) $cdest($p,$c)
				set resch($cloca($p,$c),1) [expr {$cecnmc($p,$c)==1 ? 0:$cweapn($p,$c)==1 ? 1:$carmor($p,$c)==1 ? 2:3}]
			}
			set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
			set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
			set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
			set cengin($p,$c) 0
		}
	}
###############################################################
	proc cmvecmd {} {
		uplevel #0 {
			if {$owned($cloca($p,$c),1)==$p} {
				set chtype($p,$c) "MOVE"
				set chdist($p,$c) [dist $cloca($p,$c) $cdest($p,$c)]
				set chship($p,$c) [expr {int($cship($p,$c)/100.*$ships($cloca($p,$c),1))}]
				set ships($cloca($p,$c),1) [expr {$ships($cloca($p,$c),1)-$chship($p,$c)}]
				set checnmc($p,$c) [expr {int($ecnmc($cloca($p,$c),1)*rand()**0.2)}]
				set chweapn($p,$c) [expr {int($weapn($cloca($p,$c),1)*rand()**0.2)}]
				set charmor($p,$c) [expr {int($armor($cloca($p,$c),1)*rand()**0.2)}]
				set chengin($p,$c) [expr {int($engin($cloca($p,$c),1)*rand()**0.2)}]
			} else {
				set chtype($p,$c) 0
				set chship($p,$c) 0;set chdist($p,$c) 0
				set checnmc($p,$c) 0;set chweapn($p,$c) 0;set charmor($p,$c) 0
				set chengin($p,$c) 0
			}
			set ctype($p,$c) "MOV?"
			set chturn($p,$c) $turn
			if {$home($p)>=0} {set chdlay($p,$c) [expr {[dist $home($p) $cloca($p,$c)]/10}]} else {set chdlay($p,$c) [expr {$maxhist*$histacc-1}]}
			
			set cship($p,$c) [expr {int($cship($p,$c)/100.*$iships($p,$cloca($p,$c)))}]
			set cecnmc($p,$c) $iecnmc($p,$cloca($p,$c))
			set cweapn($p,$c) $iweapn($p,$cloca($p,$c))
			set carmor($p,$c) $iarmor($p,$cloca($p,$c))
			set cengin($p,$c) $iengin($p,$cloca($p,$c))
		}
	}
###############################################################
	proc movecmd {} {
		uplevel #0 {
			#IF WE OWN DESTINATION
			if {$owned($cdest($p,$c),1)==$p} {
				set ships($cdest($p,$c),1) [expr {$ships($cdest($p,$c),1)+$cship($p,$c)}]
				set owned($cdest($p,$c),1) $p
				set ecnmc($cdest($p,$c),1) [expr {$cecnmc($p,$c)>$ecnmc($cdest($p,$c),1) ? $cecnmc($p,$c):$ecnmc($cdest($p,$c),1)}]
				set weapn($cdest($p,$c),1) [expr {$cweapn($p,$c)>$weapn($cdest($p,$c),1) ? $cweapn($p,$c):$weapn($cdest($p,$c),1)}]
				set armor($cdest($p,$c),1) [expr {$carmor($p,$c)>$armor($cdest($p,$c),1) ? $carmor($p,$c):$armor($cdest($p,$c),1)}]
				set engin($cdest($p,$c),1) [expr {$cengin($p,$c)>$engin($cdest($p,$c),1) ? $cengin($p,$c):$engin($cdest($p,$c),1)}]
			} else {
				#ENEMY DESTINATION
				#BATTLES
					#WORK OUT BATTLE RESULTS FOR FLEETS AT DESTINATION, DESTROY BASES AND CHANGE SYSTEM OWNER IF NECESSARY
					set result [battle $cship($p,$c) $cweapn($p,$c) $carmor($p,$c) $ships($cdest($p,$c),1) $weapn($cdest($p,$c),1) $armor($cdest($p,$c),1)]
					set cship($p,$c) [lindex $result 0]
					set ships($cdest($p,$c),1) [lindex $result 1]
					#DEFENDER HAS NO SHIPS ON BASE
					if {$ships($cdest($p,$c),1)==0} {
						#DEFAULT TO NEUTRAL OWNER
						set owned($cdest($p,$c),1) 0
						#CHECK IF IT IS A HOME OF ANYONE & IF SO FIND THEM NEW HOME IF POSSIBLE
						for {set p2 1} {$p2<=$nplay} {incr p2} {
							if {$home($p2)==$cdest($p,$c)} {
								losthome $p2
								break
							}
						}
						if {$cship($p,$c)>0} {
							#WE HAVE SOME SHIPS; IT'S OURS
							set bases($cdest($p,$c),1) 1
							set owned($cdest($p,$c),1) $p
							set ships($cdest($p,$c),1) $cship($p,$c)
							set ecnmc($cdest($p,$c),1) $cecnmc($p,$c)
							set weapn($cdest($p,$c),1) $cweapn($p,$c)
							set armor($cdest($p,$c),1) $carmor($p,$c)
							set engin($cdest($p,$c),1) $cengin($p,$c)
							set resch($cdest($p,$c),1) [expr {int(rand()*4)}]
							set bldpc($cdest($p,$c),1) 33
							set trnpc($cdest($p,$c),1) 33
						}
					}
			}
			set ctype($p,$c) 0;set cloca($p,$c) 0;set ctime($p,$c) 0
			set cship($p,$c) 0;set cdest($p,$c) 0;set cdist($p,$c) 0
			set cecnmc($p,$c) 0;set cweapn($p,$c) 0;set carmor($p,$c) 0
			set cengin($p,$c) 0
		}
	}
##############################################################################################################################
proc updateinfo {p s} {
	upvar home($p) home
	global maxhist;global histacc
	upvar iowned($p,$s) iowned;upvar ibases($p,$s) ibases;upvar iincom($p,$s) iincom
	upvar iships($p,$s) iships;upvar itrnpc($p,$s) itrnpc;upvar ibldpc($p,$s) ibldpc
	upvar iecnmc($p,$s) iecnmc;upvar iweapn($p,$s) iweapn;upvar iarmor($p,$s) iarmor
	upvar iengin($p,$s) iengin;upvar iresch($p,$s) iresch
	global owned;global bases;global incom
	global ships;global trnpc;global bldpc
	global ecnmc;global weapn;global armor
	global engin;global resch
	global speed
	
	set delay [expr {int(([dist $home $s]/10)/$histacc)+1}]
	
	if {$delay>$maxhist} {set delay $maxhist}
	
	set iowned $owned($s,$delay);set ibases $bases($s,$delay);
	set iships $ships($s,$delay);
	if {$iowned==$p} {
		set iincom $incom($s,$delay)
		set itrnpc $trnpc($s,$delay);set ibldpc $bldpc($s,$delay)
		set iecnmc $ecnmc($s,$delay);set iweapn $weapn($s,$delay);set iarmor $armor($s,$delay)
		set iengin $engin($s,$delay);set iresch $resch($s,$delay)
	} else {
		set iincom 0
		set itrnpc 33;set ibldpc 33
		set iecnmc 0;set iweapn 0;set iarmor 0
		set iengin 0;set iresch 0
	}
}
###############################################################
proc addtotals {p} {
	global tstar
	upvar tinco($p) tinco;upvar tshbl($p) tshbl;upvar tbsbl($p) tbsbl
	upvar trese($p) trese;upvar tship($p) tship;upvar tbase($p) tbase
	global iincom
	global trnpc ;global bldpc
	global iships;global ibases
	global iowned
	for {set s 0} {$s<=$tstar} {incr s} {
		if {$iowned($p,$s)==$p} {
			set tinco [expr {$tinco+$iincom($p,$s)}]
			set tshbl [expr {int(($tshbl+$iincom($p,$s)*$trnpc($s,1)/100.)*100)/100.}]
			set tbsbl [expr {int(($tbsbl+$iincom($p,$s)*$bldpc($s,1)/100.)*100)/100.}]
			set trese [expr {int(($trese+$iincom($p,$s)*(1-$trnpc($s,1)/100.-$bldpc($s,1)/100.))*100)/100.}]
			set tship [expr {$tship+$iships($p,$s)}]
			set tbase [expr {$tbase+$ibases($p,$s)}]
		}
	}
	global numcmd
	global ctype
	global cship
	for {set c 1} {$c<=$numcmd($p)} {incr c} {
		if {$ctype($p,$c)=="MOVE" || $ctype($p,$c)=="MOV?"} {
			set tship [expr {$tship+$cship($p,$c)}]
		}
	}
}
###############################################################
proc rebellion {s} {
	global nplay
	upvar home home
	upvar owned owned;upvar ships($s,1) ships
	upvar bases($s,1) bases
	upvar ecnmc($s,1) ecnmc;upvar weapn($s,1) weapn
	upvar armor($s,1) armor;upvar engin($s,1) engin
	upvar AIcode AIcode
	
	if {$ships>1} {
		set rships [expr {int(rand()*$ships+5)}]
		incr ships -$rships
		set rweapn [expr {int(rand()*$weapn+1)}]
		set rarmor [expr {int(rand()*$armor+1)}]
		set result [battle $ships $weapn $armor $rships $rweapn $rarmor]
		set ships [lindex $result 0]
		set rships [lindex $result 1]
	} else {set rships 5;set rweapn [expr {int(rand()*$weapn)}];set rarmor [expr {int(rand()*$armor)}]}
	if {$rships>0} {;#rebellion success
		set owner $owned($s,1)
		set owned($s,1) 0
		for {set p 1} {$p<=$nplay} {incr p} {
			if {$home($p)==-1} {
				upvar resch($s,1) resch;set resch 0
				upvar trnpc($s,1) trnpc;set trnpc 33
				upvar bldpc($s,1) bldpc;set bldpc 33
				upvar pcnflt($p) pcnflt ;set pcnflt 5
				set home($p) $s
				set owned($s,1) $p
				break
			}
		}
		if {$home($owner)==$s} {losthome $owner}
		if {$owner==0 && $p<=$nplay} {set AIcode($p) [mutate $AIcode($p)]} elseif {$p<=$nplay} {set pos($p) 0;set AIcode($p) [mutate $AIcode($owner)]}
		set ships $rships
		set bases [expr {int(rand()*$bases)+1}]
		#set ecnmc [expr {int(rand()*$ecnmc*0.5)}]
		#set weapn [expr {int($rweapn*0.5)}]
		#set armor [expr {int($rarmor*0.5)}]
		#set engin [expr {int(rand()*$engin*0.5)}]
		#set ecnmc [expr {$bases/20+1}]
		set ecnmc 1
		set weapn $ecnmc
		set armor $ecnmc
		set engin $ecnmc
	} else {;#rebellion failed, damage tech and bases
		set ecnmc [expr {int($ecnmc*rand()**0.2)}]
		set weapn [expr {int($weapn*rand()**0.2)}]
		set armor [expr {int($armor*rand()**0.2)}]
		set engin [expr {int($engin*rand()**0.2)}]
		set bases [expr {int($bases*rand()**0.2)}]
		upvar bldpc($s,1) bldpc;upvar trnpc($s,1) trnpc
		set bldpc 33;set trnpc 33
		if {$home($owned($s,1))==$s} {
			upvar numcmd($owned($s,1)) numcmd
			set newnumcmd [expr {$bases>=1000 ? 100:(1+$bases/10)}]
			for {set c $newnumcmd;incr c} {$c<=$numcmd} {incr c} {
				upvar #0 ctype($owned($s,1),$c) ctype  ;upvar #0 cloca($owned($s,1),$c) cloca  ;upvar #0 ctime($owned($s,1),$c) ctime
				upvar #0 cship($owned($s,1),$c) cship  ;upvar #0 cdest($owned($s,1),$c) cdest  ;upvar #0 cdist($owned($s,1),$c) cdist
				upvar #0 cecnmc($owned($s,1),$c) cecnmc;upvar #0 cweapn($owned($s,1),$c) cweapn;upvar #0 carmor($owned($s,1),$c) carmor
				upvar #0 cengin($owned($s,1),$c) cengin
				set ctype 0 ;set cloca 0 ;set ctime 0
				set cship 0 ;set cdest 0 ;set cdist 0
				set cecnmc 0;set cweapn 0;set carmor 0
				set cengin 0
				.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
				.map coords cmdmrk($c) 0 0 0 0
			}
			set numcmd $newnumcmd
		}
	}
}
###############################################################
proc starincome {s} {
	global speed
	global owned
	upvar trnpc($s,1) trnpc;upvar bldpc($s,1) bldpc;
	upvar incom($s,1) incom
	upvar ships($s,1) ships
	upvar bases($s,1) bases
		global inhab;global nohab
	upvar ecnmc($s,1) ecnmc;upvar weapn($s,1) weapn;upvar armor($s,1) armor;upvar engin($s,1) engin
	upvar resch($s,1) resch
	
	if {$owned($s,1)==0} {set trnpc 1;set bldpc 0;set ships [expr {int($ships+($incom*$trnpc/100.)*$speed)}]
	} else {
		if {$trnpc<1} {set trnpc 1}
		if {$bldpc<1} {set bldpc 1}
		if {$trnpc+$bldpc>100} {set trnpc [expr {int(100/($trnpc+$bldpc)*$trnpc)}];set bldpc [expr {int(100/($trnpc+$bldpc)*$bldpc)}]}
		#INCOME
			set incom [expr {int([income $s])}]
		#TRAINING
			set ships [expr {int($ships+($incom*$trnpc/100.)*$speed)}]
			
		for {set t 1} {$t<=$speed} {incr t} {
			#BUILDING
				set basecred [expr {$incom*$bldpc/100.}]
				set basecost [expr {(($bases**2)*0.05)*(1-(0.5-0.6**$inhab($s))-(0.5-0.4**$nohab($s)))}];#cost for 1 bases
				#ease of base build (1-2)=1-((0.5-0.5**(inhab*3))-(0.5-0.5**(nohab/3.+1)))
				for {set t2 1} {$t2<=$speed} {incr t2} {if {($basecred/($basecost==0 ? 0.001:$basecost))>=(rand()*5)} {
					incr bases
					set basecred [expr {$basecred-$basecost}]
					set basecost [expr {(($bases**2)*0.05)*(1-(0.5-0.6**$inhab($s))-(0.5-0.4**$nohab($s)))}]
				}}
			#RESEARCH
				set resecred [expr {$incom*(1-$trnpc/100.-$bldpc/100.)}]
				set resecost [expr {(($ecnmc+$weapn+$armor+$engin)**1.7)*0.25}];#cost for 1 tech
				for {set t2 1} {$t2<=$speed} {incr t2} {if {($resecred/($resecost==0 ? 0.001:$resecost))>=(rand()*1000)} {
					if {$resch==0} {incr ecnmc} elseif {$resch==1} {incr weapn} elseif {$resch==2} {
									incr armor} elseif {$resch==3} {incr engin}
					set resecred [expr {$resecred-$resecost}]
					set resecost [expr {(($ecnmc+$weapn+$armor+$engin)**1.7)*0.25}]
				}}
		}
	}
}
###############################################################
proc movehistback {s} {
	global maxhist
	for {set n $maxhist} {$n>1} {incr n -1} {
		upvar owned owned;upvar bases bases;upvar incom incom
		upvar ships ships;upvar trnpc trnpc;upvar bldpc bldpc
		upvar ecnmc ecnmc;upvar weapn weapn;upvar armor armor
		upvar engin engin;upvar resch resch
		global speed
		set n2 [expr {$n-$speed}]
		if {$n2<1} {set n2 1}
		set owned($s,$n) $owned($s,$n2);set bases($s,$n) $bases($s,$n2);set incom($s,$n) $incom($s,$n2)
		set ships($s,$n) $ships($s,$n2);set trnpc($s,$n) $trnpc($s,$n2);set bldpc($s,$n) $bldpc($s,$n2)
		set ecnmc($s,$n) $ecnmc($s,$n2);set weapn($s,$n) $weapn($s,$n2);set armor($s,$n) $armor($s,$n2)
		set engin($s,$n) $engin($s,$n2);set resch($s,$n) $resch($s,$n2)
	}
}
###############################################################
proc drawstar {s} {
	global iowned;global col;global ibases;global iships;global iincom
	global watchp
	if {[.map itemcget star($s) -fill]!=$col($iowned($watchp,$s))} {
		.map itemconfigure mmstar($s) -fill $col($iowned($watchp,$s))
		.map itemconfigure star($s) -fill $col($iowned($watchp,$s))
	}
	.map itemconfigure scrbase($s) -text $ibases($watchp,$s)
	.map itemconfigure scrship($s) -text $iships($watchp,$s)
	.map itemconfigure scrinco($s) -text $iincom($watchp,$s)
}
###############################################################
proc drawstarperfect {s} {
	global owned;global col;global bases;global ships;global incom
	if {[.map itemcget star($s) -fill]!=$col($owned($s,1))} {
		.map itemconfigure mmstar($s) -fill $col($owned($s,1))
		.map itemconfigure star($s) -fill $col($owned($s,1))
	}
	.map itemconfigure scrbase($s) -text $bases($s,1)
	.map itemconfigure scrship($s) -text $ships($s,1)
	.map itemconfigure scrinco($s) -text $incom($s,1)
}
###############################################################
proc drawcmdline {c} {
	global ctype
	global home;global scrx;global scry;global watchp
	global ctime;global cdist;global starx;global stary
	global tstar
	upvar cdest cdest;upvar cloca cloca;
	set cdest($watchp,$c) [expr {int($cdest($watchp,$c))}];set cloca($watchp,$c) [expr {int($cloca($watchp,$c))}]
	
	.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
	.map coords cmdmrk($c) 0 0 0 0
	
	if {$cdest($watchp,$c)>0 && $cdest($watchp,$c)<=$tstar} {
		set x1 $starx($cdest($watchp,$c));set y1 $stary($cdest($watchp,$c))
		set x2 $starx($cloca($watchp,$c));set y2 $stary($cloca($watchp,$c))
		set a [expr {atan(($y2-$y1)/(($x2==$x1) ? 1:($x2-"$x1.")))}]
		if {$x2>$x1} {
			set x3 [expr {$x1+$cdist($watchp,$c)*cos($a)-$scrx}]
			set y3 [expr {$y1+$cdist($watchp,$c)*sin($a)-$scry}]
		} else {
			set x3 [expr {$x1-$cdist($watchp,$c)*cos($a)-$scrx}]
			set y3 [expr {$y1-$cdist($watchp,$c)*sin($a)-$scry}]
		}
		.map coords cmdmrk($c)   [expr {$x3+2}] [expr {$y3+2}] [expr {$x3-2}] [expr {$y3-2}]
	}
			
	if {$ctype($watchp,$c)!=0 && $home($watchp)>=0} {
		.map coords cmdlne($c,1) [expr {$starx($home($watchp))-$scrx}] [expr {$stary($home($watchp))-$scry}] \
								 [expr {$starx($cloca($watchp,$c))-$scrx}] [expr {$stary($cloca($watchp,$c))-$scry}]
								 			
		if {$ctype($watchp,$c)=="CMVE"} { 
			.map coords cmdlne($c,2) [expr {$starx($cloca($watchp,$c))-$scrx}] [expr {$stary($cloca($watchp,$c))-$scry}] \
									 [expr {$starx($cdest($watchp,$c))-$scrx}] [expr {$stary($cdest($watchp,$c))-$scry}]
			.map itemconfigure cmdlne($c,1) -fill #ff8888
			.map itemconfigure cmdlne($c,2) -fill #ffffff
		} elseif {$ctype($watchp,$c)=="MOVE"} {
			.map coords cmdlne($c,1) [expr {$starx($cloca($watchp,$c))-$scrx}] [expr {$stary($cloca($watchp,$c))-$scry}] \
									 [expr {$starx($cdest($watchp,$c))-$scrx}] [expr {$stary($cdest($watchp,$c))-$scry}]
			.map itemconfigure cmdlne($c,1) -fill #ff0000
		} elseif {$ctype($watchp,$c)=="MOV?"} {
			.map coords cmdlne($c,1) [expr {$starx($cloca($watchp,$c))-$scrx}] [expr {$stary($cloca($watchp,$c))-$scry}] \
									 [expr {$starx($cdest($watchp,$c))-$scrx}] [expr {$stary($cdest($watchp,$c))-$scry}]
			.map itemconfigure cmdlne($c,1) -fill #ff8888
		} elseif {$ctype($watchp,$c)=="CPCN"} {
			.map itemconfigure cmdlne($c,1) -fill #00ff00
		} elseif {$ctype($watchp,$c)=="CBLD"} {
			.map itemconfigure cmdlne($c,1) -fill #00ffff
		}
	} elseif {$ctype($watchp,$c)=="HOME"} {
		.map coords cmdlne($c,1) [expr {$starx($cloca($watchp,$c))-$scrx}] [expr {$stary($cloca($watchp,$c))-$scry}] \
								 [expr {$starx($cdest($watchp,$c))-$scrx}] [expr {$stary($cdest($watchp,$c))-$scry}]
		.map itemconfigure cmdlne($c,1) -fill #ff00ff
	}
}
proc setwatchp {p} {upvar watchp watchp;set watchp $p;clearcmdline}
proc clearcmdline {} {for {set c 1} {$c<=100} {incr c} {
	.map coords cmdlne($c,1) 0 0 0 0;.map coords cmdlne($c,2) 0 0 0 0
	.map coords cmdmrk($c) 0 0 0 0
}}
##############################################################################################################################
##############################################################################################################################
proc mutate {cde} {
	global codelength
	for {set n 1} {$n<500} {incr n} {
		if {rand()<0.01} {
			set pos [expr {int(rand()*[llength $cde])}]
			set rnd [expr {rand()}]
			#replace, insert, delete
			if {$rnd<0.33} {lset cde $pos [rndcom]
			} elseif {$rnd<0.67} {set cde [lreplace [linsert $cde $pos [rndcom]] $codelength $codelength]
			} else {set cde [lreplace $cde $pos $pos];lappend cde 0}
		}
	}
	return $cde
}
#Get a random command
proc rndcom {} {
			#CMD	RESULT (x=p, y=p+1)
			#01:n		x=n
			#02:#n		none
			#03:JMP	pos=#x if y!=0
			#04:MPR	ptr++
			#05:MPL	ptr--
			#06:ADD	x=x+y
			#07:SUB	x=x-y
			#08:MUL	x=x*y
			#09:DIV	x=x/y
			#10:MOD	x=x%y
			#11:LND	x=x&&y
			#12:LOR	x=x||y
			#13:EQU	x=x==y
			#14:LES	x=x<y
			#15:GRE	x=x>y
			#16-26:RvarP	x=varP(p)
				#Rtinco , Rtshbl , Rtbsbl , Rtrese, Rtship, Rtbase, Rpcnflt
				#Rstrnpc, Rsbldpc, Rsresch, Rsstar
			#27-47:RvarPX	x=varPX(p,x)
				#Rctype , Rcloca , Rctime , Rcship , Rcdest , Rcdist
				#Rcecnmc, Rcweapn, Rcarmor, Rcengin
				#Riowned, Ribases, Riincom, Riships, Ritrnpc, Ribldpc
				#Riecnmc, Riweapn, Riarmor, Riengin, Riresch
			#48-52:RvarX	x=varX(x)
				#Rstarx , Rstary , Rinhab , Rnohab , Rmetal
			#53:RVAR	x=var(x)
			#54-58:WvarP	varP(p,y)=x
				#Wsstar, Wpcnflt, Wstrnpc, Wsbldpc, Wsresch
			#59:WVAR	var(y)=x
			#60-62:PrcP	proc p
				#Pbuild, Pnewhome, Pchngpcnt, Pscrap
			#62:PrcPX	proc p x
				#Pmove, Pdist
			#63:END	ptr=0, break
	set rnd [expr {int(rand()*100)}]
	if       {$rnd== 0 || $rnd>69} {set num [expr {int(rand()*100)}];set cmd $num} elseif {$rnd== 1} {set num [expr {int(rand()*100)}];set cmd "#$num"
	} elseif {$rnd== 2} {set cmd "JMP"} elseif {$rnd== 3} {set cmd "MPR"} elseif {$rnd== 4} {set cmd "MPL"
	} elseif {$rnd== 5} {set cmd "ADD"} elseif {$rnd== 6} {set cmd "SUB"} elseif {$rnd== 7} {set cmd "MUL"} elseif {$rnd== 8} {set cmd "DIV"} elseif {$rnd== 9} {set cmd "MOD"
	} elseif {$rnd==10} {set cmd "LND"} elseif {$rnd==11} {set cmd "LOR"} elseif {$rnd==12} {set cmd "EQU"} elseif {$rnd==13} {set cmd "LES"} elseif {$rnd==14} {set cmd "GRE"
	
	} elseif {$rnd==15} {set cmd "Rtinco"} elseif {$rnd==16} {set cmd "Rtshbl"} elseif {$rnd==17} {set cmd "Rtbsbl"} elseif {$rnd==18} {set cmd "Rtrese"} elseif {$rnd==19} {set cmd "Rtship"
	} elseif {$rnd==20} {set cmd "Rtbase"} elseif {$rnd==21} {set cmd "Rpcnflt"} elseif {$rnd==22} {set cmd "Rstrnpc"} elseif {$rnd==23} {set cmd "Rsbldpc"} elseif {$rnd==24} {set cmd "Rsresch"
	} elseif {$rnd==25} {set cmd "Rsstar"} elseif {$rnd==26} {set cmd "Rnumcmd"} elseif {$rnd==27} {set cmd "Rhome"} elseif {$rnd==28} {set cmd "Rtstar"} elseif {$rnd==29} {set cmd "Rplay"
	
	} elseif {$rnd==30} {set cmd "Rctype"}  elseif {$rnd==31} {set cmd "Rcloca"} elseif {$rnd==32} {set cmd "Rctime"}   elseif {$rnd==33} {set cmd "Rcship"}  elseif {$rnd==34} {set cmd "Rcdest"
	} elseif {$rnd==35} {set cmd "Rcdist"
	} elseif {$rnd==36} {set cmd "Rcecnmc"} elseif {$rnd==37} {set cmd "Rcweapn"} elseif {$rnd==38} {set cmd "Rcarmor"} elseif {$rnd==39} {set cmd "Rcengin"} elseif {$rnd==40} {set cmd "Riowned"
	} elseif {$rnd==41} {set cmd "Ribases"} elseif {$rnd==42} {set cmd "Riincom"} elseif {$rnd==43} {set cmd "Riships"} elseif {$rnd==44} {set cmd "Ritrnpc"} elseif {$rnd==45} {set cmd "Ribldpc"
	} elseif {$rnd==46} {set cmd "Riecnmc"} elseif {$rnd==47} {set cmd "Riweapn"} elseif {$rnd==48} {set cmd "Riarmor"} elseif {$rnd==49} {set cmd "Riengin"} elseif {$rnd==50} {set cmd "Riresch"
	
	} elseif {$rnd==51} {set cmd "Rstarx"} elseif {$rnd==52} {set cmd "Rstary"} elseif {$rnd==53} {set cmd "Rinhab"} elseif {$rnd==54} {set cmd "Rnohab"} elseif {$rnd==55} {set cmd "Rmetal"
	
	} elseif {$rnd==56} {set cmd "Rvar"
	
	} elseif {$rnd==57} {set cmd "Wsstar"} elseif {$rnd==58} {set cmd "Wpcnflt"} elseif {$rnd==59} {set cmd "Wstrnpc"} elseif {$rnd==60} {set cmd "Wsbldpc"
	} elseif {$rnd==61} {set cmd "Wsresch"
	
	} elseif {$rnd==62} {set cmd "Wvar"
	
	} elseif {$rnd==63} {set cmd "Pbuild"} elseif {$rnd==64} {set cmd "Pnewhome"} elseif {$rnd==65} {set cmd "Pchngpcnt"
	} elseif {$rnd==66} {set cmd "Pscrap"
	
	} elseif {$rnd==67} {set cmd "Pmove"} elseif {$rnd==68} {set cmd "Pdist"} elseif {$rnd==69} {set cmd "END"}
	return $cmd
}
