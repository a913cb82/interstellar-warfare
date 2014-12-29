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
	#RVAR	x=var(p,x)
	#WvarP	varP(p)=x
		#Wsstar, Wpcnflt, Wstrnpc, Wsbldpc, Wsresch
	#WVAR	var(p,x)=y
	#PrcP	proc p
		#Pbuild, Pnewhome, Pchngpcnt, Pscrap
	#PrcPX	proc p x
		#Pmove, Pdist
	#END	ptr=0, break

#Compiler basics
	#x + y					-	y MPL x ADD (same for cmd ADD to GRE)
	#x + y * z				-	y MPL x ADD MPR z MPL MUL
	#incr var {y}			-	y MPL R(var) ADD W(var)			(AIvar's)									(vartype 1)
	#incr var {x} {y}		-	y MPL x R(var) ADD MPL x W(var)	(all writeable non-AIvar's) 				(vartype 2)
	#set var {x} {y}		-	y MPL x WVAR					(AIvar's)									(vartype 1)
	#set var {y}			-	y W(var)						(all writeable non-AIvar's) 				(vartype 2)
	#var					-	R(var)							(Rtinco-Rplay)								(vartype 2)
	#var {x}				-	x R(var)						(AIvar's, Rctype-Riresch, Rstarx-Rmetal)	(vartype 1,3,4)
	#END					-	END
	#HOME					-	1
	#CBLD					-	2
	#CPCN					-	3
	#CMOV					-	4
	#MOVE					-	5
	#MOV?					-	6
	#ifnot {cond} {body}	-	cond MPL (cJMPnum) JMP body #(cJMPnum)
	#whilenot {cond} {body}	-	#(cJMPnum) cond MPL (cJMPnum+1) JMP body 1 MPL (cJMPnum) JMP #(cJMPnum+1)
	#proc					-	P(proc)
	#proc {x}				-	x P(proc)

#Compiler tests+results
	#compile "ifnot {1 == 2} {1 + 1}"
	#{2 MPL 1 EQU} MPL 1 JMP {1 MPL 1 ADD} #1
	
	#compile "whilenot {1 == 2} {1 + 1}"
	#{#1} {2 MPL 1 EQU} MPL 2 JMP {1 MPL 1 ADD} 1 MPL 1 JMP #2

	#compile "ifnot {1 + 2 > 3} {4 + 5 * 6}"
	#{2 MPL 1 ADD MPR 3 MPL GRE} MPL 1 JMP {5 MPL 4 ADD MPR 6 MPL MUL} #1

	#compile "whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#{#2} 0 MPL 3 JMP {{2 MPL 1 EQU} MPL 1 JMP {2 MPL 1 ADD} #1} 1 MPL 2 JMP #3
	
	#compile "tinco + 1"
	#1 MPL Rtinco ADD														yes
	#compile "1 + tinco"
	#Rtinco MPL 1 ADD														yes
	
	#compile "starx 1 + 1"
	#1 MPL 1 Rstarx ADD														yes
	#compile "1 + starx 1"
	#1 Rstarx MPL 1 ADD														yes
	
	#compile "tinco + starx 1"
	#1 Rstarx MPL Rtinco ADD												yes
	#compile "starx 1 + tinco"
	#Rtinco MPL 1 Rstarx ADD												yes
	
	#compile "stary 2 + starx 1"
	#1 Rstarx MPL 2 Rstary ADD												yes
	#compile "stary 2 + starx 1 ifnot {0} {5 + 6}"
	#1 Rstarx MPL 2 Rstary ADD {0} MPL 1 JMP {6 MPL 5 ADD} #1				yes
	#compile "stary 2 + starx 1 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#1 Rstarx MPL 2 Rstary ADD {#2} 0 MPL 3 JMP {{2 MPL 1 EQU} MPL 1 JMP {2 MPL 1 ADD} #1} 1 MPL 2 JMP #3
	#																		yes
	
	#compile "1 + starx 1 * 2"
	#1 Rstarx MPL 1 ADD MPR 2 MPL MUL										yes
	#compile "1 + starx 1 * stary 2"
	#1 Rstarx MPL 1 ADD MPR 2 Rstary MPL MUL								yes
	
	#compile "metal 3 + starx 1 * stary 2"
	#1 Rstarx MPL 3 Rmetal ADD MPR 2 Rstary MPL MUL							yes
	
	#compile "metal 3 + starx 1 * stary 2 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#1 Rstarx MPL 3 Rmetal ADD MPR 2 Rstary MPL MUL {#2} 0 MPL 3 JMP {{2 MPL 1 EQU} MPL 1 JMP {2 MPL 1 ADD} #1} 1 MPL 2 JMP #3
	#																		yes
	
	#compile "incr sstar 1"
	#1 MPL Rsstar ADD Wsstar												yes
	#compile "incr var 1 2"
	#2 MPL {1 Rvar} ADD MPL {1 Wvar}										yes
	#compile "incr sstar 1 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#1 MPL Rsstar ADD Wsstar #8 0 MPL 9 JMP {{2 MPL 1 EQU} MPL 7 JMP {2 MPL 1 ADD} #7} 1 MPL 8 JMP #9
	#																		yes
	#compile "incr var 1 2 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#2 MPL {1 Rvar} ADD MPL {1 Wvar} #2 0 MPL 3 JMP {{2 MPL 1 EQU} MPL 1 JMP {2 MPL 1 ADD} #1} 1 MPL 2 JMP #3
	#																		yes
	
	#compile "set sstar 1"
	#1 Wsstar																yes
	#compile "set var 1 2"
	#2 MPL {1 Wvar}															yes
	#compile "set sstar 1 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#1 Wsstar #11 0 MPL 12 JMP {{2 MPL 1 EQU} MPL 10 JMP {2 MPL 1 ADD} #10} 1 MPL 11 JMP #12
	#																		yes
	#compile "set var 1 2 whilenot 0 {ifnot {1 == 2} {1 + 2}}"
	#2 MPL {1 Wvar} #5 0 MPL 6 JMP {{2 MPL 1 EQU} MPL 4 JMP {2 MPL 1 ADD} #4} 1 MPL 5 JMP #6
	#																		yes
	
set cJMPnum 1
proc compile {cde} {
	set newcde ""
	set pos 0
	upvar cJMPnum cJMPnum
	while {$pos<[llength $cde]} {
		if {[issym [lindex $cde $pos]]} {
			if {[issym [lindex $cde $pos-2]] || [issym [lindex $cde $pos-3]]} {
				lappend newcde "MPR"
				lset cde $pos+1 [getnum [lindex $cde $pos+1]]
				if {[vartype [lindex $cde $pos+1]]==0 && [vartype [lindex $cde $pos+2]]==0} {lappend newcde [lindex $cde $pos+1]
				} else {lappend newcde [Rvarcode [lindex $cde $pos+1] [lindex $cde $pos+2]]}
				lappend newcde "MPL"
				lappend newcde "[symtoword [lindex $cde $pos]]"
				if {[vartype [lindex $cde $pos+1]]!=2} {incr pos}
			} else {
				lset cde $pos+1 [getnum [lindex $cde $pos+1]]
				if {[vartype [lindex $cde $pos+1]]==0 && [vartype [lindex $cde $pos+2]]==0} {lappend newcde [lindex $cde $pos+1]
				} else {lappend newcde [Rvarcode [lindex $cde $pos+1] [lindex $cde $pos+2]]}
				lappend newcde "MPL"
				lset cde $pos-1 [getnum [lindex $cde $pos-1]]
				if {[vartype [lindex $cde $pos-2]]==0 && [vartype [lindex $cde $pos-1]]==0} {lappend newcde [lindex $cde $pos-1]
				} elseif {[vartype [lindex $cde $pos-1]]} {lappend newcde [Rvarcode [lindex $cde $pos-1] [lindex $cde $pos-2]]
				} elseif {[vartype [lindex $cde $pos-2]]} {lappend newcde [Rvarcode [lindex $cde $pos-2] [lindex $cde $pos-1]]}
				lappend newcde "[symtoword [lindex $cde $pos]]"
				if {[vartype [lindex $cde $pos+1]]!=2} {incr pos}
			}
			incr pos
		} elseif {[lindex $cde $pos]=="incr"} {
			set vartype [vartype [lindex $cde $pos+1]]
			if {$vartype==2} {
				lappend newcde [compile [lindex $cde $pos+2]]
				lappend newcde "MPL"
				lappend newcde [Rvarcode [lindex $cde $pos+1] 1]
				lappend newcde "ADD"
				lappend newcde [Wvarcode [lindex $cde $pos+1] 1]
				incr pos 2
			} elseif {$vartype==1} {
				lappend newcde [compile [lindex $cde $pos+3]]
				lappend newcde "MPL"
				lappend newcde [Rvarcode [lindex $cde $pos+1] [lindex $cde $pos+2]]
				lappend newcde "ADD"
				lappend newcde "MPL"
				lappend newcde [Wvarcode [lindex $cde $pos+1] [lindex $cde $pos+2]]
				incr pos 3
			}
		} elseif {[lindex $cde $pos]=="set"} {
			set vartype [vartype [lindex $cde $pos+1]]
			if {$vartype==2} {
				lappend newcde [compile [lindex $cde $pos+2]]
				lappend newcde [Wvarcode [lindex $cde $pos+1] 1]
				incr pos 2
			} elseif {$vartype==1} {
				lappend newcde [compile [lindex $cde $pos+3]]
				lappend newcde "MPL"
				lappend newcde [Wvarcode [lindex $cde $pos+1] [lindex $cde $pos+2]]
				incr pos 3
			}
		} elseif {[proctype [lindex $cde $pos]]} {
			lappend newcde [proccode [lindex $cde $pos] [lindex $cde $pos+1]]
			if {[proctype [lindex $cde $pos]]==2} {incr pos}
		} elseif {[lindex $cde $pos]=="END"} {
			lappend newcde [lindex $cde $pos]
		} elseif {[lindex $cde $pos]=="ifnot"} {
			set cond [compile [lindex $cde $pos+1]]
			set body [compile [lindex $cde $pos+2]]
			lappend newcde $cond
			lappend newcde "MPL"
			lappend newcde $cJMPnum
			lappend newcde "JMP"
			lappend newcde $body
			lappend newcde #$cJMPnum
			incr cJMPnum
			incr pos 2
		} elseif {[lindex $cde $pos]=="whilenot"} {
			set cond [compile [lindex $cde $pos+1]]
			set body [compile [lindex $cde $pos+2]]
			lappend newcde #$cJMPnum
			lappend newcde $cond
			lappend newcde "MPL"
			lappend newcde [expr {$cJMPnum+1}]
			lappend newcde "JMP"
			lappend newcde $body
			lappend newcde 1
			lappend newcde "MPL"
			lappend newcde $cJMPnum
			lappend newcde "JMP"
			lappend newcde #[expr {$cJMPnum+1}]
			incr cJMPnum 2
			incr pos 2
		}
		incr pos
	}
	if {$newcde==""} {set newcde $cde}
	return $newcde
}


proc symtoword {sym} {
	set word 0
	if       {$sym== "+"} {set word "ADD"
	} elseif {$sym== "-"} {set word "SUB"
	} elseif {$sym== "*"} {set word "MUL"
	} elseif {$sym== "/"} {set word "DIV"
	} elseif {$sym== "%"} {set word "MOD"
	} elseif {$sym=="&&"} {set word "LND"
	} elseif {$sym=="||"} {set word "LOR"
	} elseif {$sym=="=="} {set word "EQU"
	} elseif {$sym== "<"} {set word "LES"
	} elseif {$sym== ">"} {set word "GRE"}
	return $word
}
proc issym {sym} {
	set issym 0
	if       {$sym== "+"} {set issym 1
	} elseif {$sym== "-"} {set issym 1
	} elseif {$sym== "*"} {set issym 1
	} elseif {$sym== "/"} {set issym 1
	} elseif {$sym== "%"} {set issym 1
	} elseif {$sym=="&&"} {set issym 1
	} elseif {$sym=="||"} {set issym 1
	} elseif {$sym=="=="} {set issym 1
	} elseif {$sym== "<"} {set issym 1
	} elseif {$sym== ">"} {set issym 1}
	return $issym
}


proc vartype {var} {
	set vartype 0
	if       {$var=="var"} {
		   set vartype 1
	} elseif {$var=="tinco"  || $var=="tshbl"  || $var=="tbsbl"  || $var=="trese" || $var=="tship"  || $var=="tbase" || $var=="pcnflt" \
		   || $var=="strnpc" || $var=="sbldpc" || $var=="sresch" || $var=="sstar" || $var=="numcmd" || $var=="home"  || $var=="tstar" \
		   || $var=="play"} {
		   set vartype 2
	} elseif {$var=="ctype"  || $var=="cloca"  || $var=="ctime"  || $var=="cship"  || $var=="cdest"  || $var=="cdist" \
		   || $var=="cecnmc" || $var=="cweapn" || $var=="carmor" || $var=="cengin" \
		   || $var=="iowned" || $var=="ibases" || $var=="iincom" || $var=="iships" || $var=="itrnpc" || $var=="ibldpc" \
		   || $var=="iecnmc" || $var=="iweapn" || $var=="iarmor" || $var=="iengin" || $var=="iresch"} {
		   set vartype 3
	} elseif {$var=="starx" || $var=="stary" || $var=="inhab" || $var=="nohab" || $var=="metal"} {
		   set vartype 4
	}
	return $vartype
}
proc Rvarcode {var num} {
	set Rvarcode ""
	set vartype [vartype $var]
	if {$vartype==2} {
		lappend Rvarcode "R$var"
	} else {
		lappend Rvarcode [compile $num]
		lappend Rvarcode "R$var"
	}
	return $Rvarcode
}
proc Wvarcode {var num} {
	set Rvarcode ""
	set vartype [vartype $var]
	if {$vartype==2} {
		lappend Rvarcode "W$var"
	} else {
		lappend Rvarcode [compile $num]
		lappend Rvarcode "W$var"
	}
	return $Rvarcode
}

proc proctype {prc} {
	set proctype 0
	if       {$prc=="build" || $prc=="newhome" || $prc=="chngpcnt" || $prc=="scrap"} {set proctype 1
	} elseif {$prc=="move"  || $prc=="dist"} {set proctype 2}
	return $proctype
}
proc proccode {prc num} {
	set Pproc ""
	if       {$prc=="build" || $prc=="newhome" || $prc=="chngpcnt" || $prc=="scrap"} {set Pproc P$prc
	} elseif {$prc=="move"  || $prc=="dist"} {lappend Pproc [compile $num];lappend Pproc P$prc}
	return $Pproc
}

proc getnum {cmd} {
	set num $cmd
	if       {$cmd=="HOME"} {set num 1
	} elseif {$cmd=="CBLD"} {set num 2
	} elseif {$cmd=="CPCN"} {set num 3
	} elseif {$cmd=="CMOV"} {set num 4
	} elseif {$cmd=="MOVE"} {set num 5
	} elseif {$cmd=="MOV?"} {set num 6}
	return $num
}