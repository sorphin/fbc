''
''
'' iupkey -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
#ifndef __iupkey_bi__
#define __iupkey_bi__

#define K_exclam asc("!")
#define K_quotedbl asc(""")
#define K_numbersign asc("#")
#define K_dollar asc("$")
#define K_percent asc("%")
#define K_ampersand asc("&")
#define K_quoteright asc("'")
#define K_parentleft asc("(")
#define K_parentright asc(")")
#define K_asterisk asc("*")
#define K_plus asc("+")
#define K_comma asc(",")
#define K_minus asc("-")
#define K_period asc(".")
#define K_slash asc("/")
#define K_0 asc("0")
#define K_1 asc("1")
#define K_2 asc("2")
#define K_3 asc("3")
#define K_4 asc("4")
#define K_5 asc("5")
#define K_6 asc("6")
#define K_7 asc("7")
#define K_8 asc("8")
#define K_9 asc("9")
#define K_colon asc(":")
#define K_semicolon asc(";")
#define K_less asc("<")
#define K_equal asc("=")
#define K_greater asc(">")
#define K_question asc("?")
#define K_at asc("@")
#define K_A asc("A")
#define K_B asc("B")
#define K_C asc("C")
#define K_D asc("D")
#define K_E asc("E")
#define K_F asc("F")
#define K_G asc("G")
#define K_H asc("H")
#define K_I asc("I")
#define K_J asc("J")
#define K_K asc("K")
#define K_L asc("L")
#define K_M asc("M")
#define K_N asc("N")
#define K_O asc("O")
#define K_P asc("P")
#define K_Q asc("Q")
#define K_R asc("R")
#define K_S asc("S")
#define K_T asc("T")
#define K_U asc("U")
#define K_V asc("V")
#define K_W asc("W")
#define K_X asc("X")
#define K_Y asc("Y")
#define K_Z asc("Z")
#define K_bracketleft asc("[")
#define K_backslash asc($"\")
#define K_bracketright asc("]")
#define K_circum asc("^")
#define K_underscore asc("_")
#define K_quoteleft asc("`")
#define K_a_ asc("a")
#define K_b_ asc("b")
#define K_c_ asc("c")
#define K_d_ asc("d")
#define K_e_ asc("e")
#define K_f_ asc("f")
#define K_g_ asc("g")
#define K_h_ asc("h")
#define K_i_ asc("i")
#define K_j_ asc("j")
#define K_k_ asc("k")
#define K_l_ asc("l")
#define K_m_ asc("m")
#define K_n_ asc("n")
#define K_o_ asc("o")
#define K_p_ asc("p")
#define K_q_ asc("q")
#define K_r_ asc("r")
#define K_s_ asc("s")
#define K_t_ asc("t")
#define K_u_ asc("u")
#define K_v_ asc("v")
#define K_w_ asc("w")
#define K_x_ asc("x")
#define K_y_ asc("y")
#define K_z_ asc("z")
#define K_braceleft asc("{")
#define K_bar asc("|")
#define K_braceright asc("}")
#define K_tilde asc("~")
#define K_cA 1
#define K_cB 2
#define K_cC 3
#define K_cD 4
#define K_cE 5
#define K_cF 6
#define K_cG 7
#define K_cH 8
#define K_cI 9
#define K_cJ 10
#define K_cK 11
#define K_cL 12
#define K_cM 13
#define K_cN 14
#define K_cO 15
#define K_cP 16
#define K_cQ 17
#define K_cR_ 18
#define K_cS 19
#define K_cT 20
#define K_cU 21
#define K_cV 22
#define K_cW 23
#define K_cX 24
#define K_cY 25
#define K_cZ 26
#define K_mA ((30) or &h0100)
#define K_mB ((48) or &h0100)
#define K_mC ((46) or &h0100)
#define K_mD ((32) or &h0100)
#define K_mE ((18) or &h0100)
#define K_mF ((33) or &h0100)
#define K_mG ((34) or &h0100)
#define K_mH ((35) or &h0100)
#define K_mI ((23) or &h0100)
#define K_mJ ((36) or &h0100)
#define K_mK ((37) or &h0100)
#define K_mL ((38) or &h0100)
#define K_mM ((50) or &h0100)
#define K_mN ((49) or &h0100)
#define K_mO ((24) or &h0100)
#define K_mP ((25) or &h0100)
#define K_mQ ((16) or &h0100)
#define K_mR ((19) or &h0100)
#define K_mS ((31) or &h0100)
#define K_mT ((20) or &h0100)
#define K_mU ((22) or &h0100)
#define K_mV ((47) or &h0100)
#define K_mW ((17) or &h0100)
#define K_mX ((45) or &h0100)
#define K_mY ((21) or &h0100)
#define K_mZ ((44) or &h0100)
#define K_BS 8
#define K_CR 13
#define K_sCR ((14) or &h0100)
#define K_ESC 27
#define K_SP 32
#define K_TAB 9
#define K_sTAB ((15) or &h0100)
#define K_cTAB ((148) or &h0100)
#define K_mTAB ((165) or &h0100)
#define K_PAUSE ((70) or &h0100)
#define K_HOME ((71) or &h0100)
#define K_UP ((72) or &h0100)
#define K_PGUP ((73) or &h0100)
#define K_LEFT ((75) or &h0100)
#define K_MIDDLE ((76) or &h0100)
#define K_RIGHT ((77) or &h0100)
#define K_END ((79) or &h0100)
#define K_DOWN ((80) or &h0100)
#define K_PGDN ((81) or &h0100)
#define K_INS ((82) or &h0100)
#define K_DEL ((83) or &h0100)
#define K_sHOME ((200) or &h0100)
#define K_sUP ((201) or &h0100)
#define K_sPGUP ((202) or &h0100)
#define K_sLEFT ((203) or &h0100)
#define K_sRIGHT ((204) or &h0100)
#define K_sEND ((205) or &h0100)
#define K_sDOWN ((206) or &h0100)
#define K_sPGDN ((207) or &h0100)
#define K_sSP ((208) or &h0100)
#define K_cHOME ((119) or &h0100)
#define K_cPGUP ((132) or &h0100)
#define K_cLEFT ((115) or &h0100)
#define K_cRIGHT ((116) or &h0100)
#define K_cEND ((117) or &h0100)
#define K_cPGDN ((118) or &h0100)
#define K_cUP ((141) or &h0100)
#define K_cMIDDLE ((143) or &h0100)
#define K_cDOWN ((145) or &h0100)
#define K_cINS ((146) or &h0100)
#define K_cDEL ((147) or &h0100)
#define K_cSP ((209) or &h0100)
#define K_mHOME ((151) or &h0100)
#define K_mPGUP ((153) or &h0100)
#define K_mLEFT ((155) or &h0100)
#define K_mRIGHT ((157) or &h0100)
#define K_mEND ((159) or &h0100)
#define K_mPGDN ((161) or &h0100)
#define K_mUP ((152) or &h0100)
#define K_mDOWN ((160) or &h0100)
#define K_mINS ((162) or &h0100)
#define K_mDEL ((163) or &h0100)
#define K_F1 ((59) or &h0100)
#define K_F2 ((60) or &h0100)
#define K_F3 ((61) or &h0100)
#define K_F4 ((62) or &h0100)
#define K_F5 ((63) or &h0100)
#define K_F6 ((64) or &h0100)
#define K_F7 ((65) or &h0100)
#define K_F8 ((66) or &h0100)
#define K_F9 ((67) or &h0100)
#define K_F10 ((68) or &h0100)
#define K_F11 ((133) or &h0100)
#define K_F12 ((134) or &h0100)
#define K_sF1 ((84) or &h0100)
#define K_sF2 ((85) or &h0100)
#define K_sF3 ((86) or &h0100)
#define K_sF4 ((87) or &h0100)
#define K_sF5 ((88) or &h0100)
#define K_sF6 ((89) or &h0100)
#define K_sF7 ((90) or &h0100)
#define K_sF8 ((91) or &h0100)
#define K_sF9 ((92) or &h0100)
#define K_sF10 ((93) or &h0100)
#define K_sF11 ((135) or &h0100)
#define K_sF12 ((136) or &h0100)
#define K_cF1 ((94) or &h0100)
#define K_cF2 ((95) or &h0100)
#define K_cF3 ((96) or &h0100)
#define K_cF4 ((97) or &h0100)
#define K_cF5 ((98) or &h0100)
#define K_cF6 ((99) or &h0100)
#define K_cF7 ((100) or &h0100)
#define K_cF8 ((101) or &h0100)
#define K_cF9 ((102) or &h0100)
#define K_cF10 ((103) or &h0100)
#define K_cF11 ((137) or &h0100)
#define K_cF12 ((138) or &h0100)
#define K_mF1 ((104) or &h0100)
#define K_mF2 ((105) or &h0100)
#define K_mF3 ((106) or &h0100)
#define K_mF4 ((107) or &h0100)
#define K_mF5 ((108) or &h0100)
#define K_mF6 ((109) or &h0100)
#define K_mF7 ((110) or &h0100)
#define K_mF8 ((111) or &h0100)
#define K_mF9 ((112) or &h0100)
#define K_mF10 ((113) or &h0100)
#define K_mF11 ((139) or &h0100)
#define K_mF12 ((140) or &h0100)
#define K_m1 ((120) or &h0100)
#define K_m2 ((121) or &h0100)
#define K_m3 ((122) or &h0100)
#define K_m4 ((123) or &h0100)
#define K_m5 ((124) or &h0100)
#define K_m6 ((125) or &h0100)
#define K_m7 ((126) or &h0100)
#define K_m8 ((127) or &h0100)
#define K_m9 ((128) or &h0100)
#define K_m0 ((129) or &h0100)

#endif