10 REM
20 REM                     B e r r y B a s i C   N i b b l e s
30 REM
40 REM                     Port of QBasic Nibbles by Microsoft
50 REM
60 REM Nibbles is a game for one or two players.  Navigate your snakes
70 REM around the game board trying to eat up numbers while avoiding
80 REM running into walls or other snakes.  The more numbers you eat up,
90 REM the more points you gain and the longer your snake becomes.
100 REM
110 REM To run this game, load it and then type: RUN
120 REM
130 REM For more information about BerryBasiC, visit the BerryBasiC project
140 REM on GitHub: https://github.com/fritzone/berrybasic
150 REM
160 REM User-defined TYPEs
170 TYPE snakeBody: row%, col%: ENDTYPE
180 REM This type defines the player's snake
190 TYPE snaketype: head%, length%, row%, col%, direction%, lives%, score%, scolor%, alive%: ENDTYPE
200 REM This type is used to represent the playing screen in memory
210 REM It is used to simulate graphics in text mode, and has some interesting,
220 REM and slightly advanced methods to increasing the speed of operation.
230 REM Instead of the normal 80x25 text graphics using chr$(219), we will be
240 REM using chr$(220) and chr$(223) and chr$(219) to mimic an 80x50
250 REM pixel screen.
260 REM Check out sub-programs SETARENA and POINTISTHERE to see how this is implemented
270 REM feel free to copy these (as well as arenaType and the DIM ARENA stmt and the
280 REM initialization code in the DrawScreen subprogram) and use them in your own
290 REM programs
300 REM - realRow: Maps the 80x50 point into the real 80x25
310 REM - acolor: Stores the current color of the point
320 REM - sister: Each char has 2 points in it.  .SISTER is -1 if sister point is above, +1 if below
330 TYPE arenaType: realRow%, acolor%, sister%: ENDTYPE
340 REM "Constants"
350 MAXSNAKELENGTH% = 1000
360 STARTOVER% = 1: REM Parameters to 'Level' PROC
370 SAMELEVEL% = 2: REM
380 NEXTLEVEL% = 3: REM
390 REM Seed RNG
400 A = RND(-TIME - 1)
410 REM Global Variables
420 DIM arena(50 * 80) AS arenaType
430 curLevel% = 0
440 DIM colorTable%(10)
450 DIM sammyBody(MAXSNAKELENGTH% * 2) AS snakeBody
460 DIM sammy(2) AS snaketype
470 TYPE PlayerInputs: NumPlayers%, speed%, diff$, monitor$: ENDTYPE
480 DIM inputs AS PlayerInputs
490 PROCIntro
500 PROCGetInputs(inputs)
510 REM SetColors
520 IF inputs.monitor$ = "M" THEN RESTORE 600 ELSE RESTORE 620
530 FOR a% = 1 TO 6: READ colorTable%(a%): NEXT a%
540 PROCDrawScreen
550 REPEAT
560   PROCPlayNibbles
570 UNTIL KeepRunning% = 0
580 END
590 REM  snake1      snake2   Walls  Background  Dialogs-Fore  Back
600 REM  -- Monochrome ------
610 DATA 15,         15,      15,    0,          15,           0
620 REM  -- Colour ----------
630 DATA 3,          6,       1,     4,          15,           1
1098 REM Center:
1099 REM   Centers text on given row
1100 DEF PROC Center(row%, text$)
1110   col% = 40 - LEN(text$) / 2
1120   VDU 31, col%, row% - 1
1130   IF LEN(text$) = 0 THEN GOTO 1180
1140   REM Force literal character output
1150   FOR i% = 1 TO LEN(text$)
1160     VDU 27, ASC(MID$(text$, i%, 1))
1170   NEXT i%
1180 ENDPROC
1198 REM DrawScreen:
1199 REM   Draws playing field
1200 DEF PROC DrawScreen
1210   REM initialize screen
1220   VDU 17, colorTable%(1), 17, colorTable%(4) OR 128
1230   CLS
1240   REM Print title & message
1250   PROCCenter(1, "Nibbles!")
1260   PROCCenter(11, "Initializing Playing Field...")
1270   REM Initialize arena array
1280   FOR row% = 1 TO 50
1290     FOR col% = 1 TO 80
1300       arena(AO%(row%, col%)).realRow% = INT((row% + 1) / 2)
1310       arena(AO%(row%, col%)).sister% = (row% MOD 2) * 2 - 1
1320     NEXT col%
1330   NEXT row%
1340 ENDPROC
1398 REM EraseSnake:
1399 REM   Erases snake to facilitate moving through playing field
1400 DEF PROC EraseSnake (snakeNum%)
1410   FOR c% = 0 TO 9
1420     IF sammy(snakenum%).length% - c% < 0 THEN GOTO 1480
1430     FOR b% = sammy(snakeNum%).length% - c% TO 0 STEP -10
1440       tail% = (sammy(snakeNum%).head% + MAXSNAKELENGTH% - b%) MOD MAXSNAKELENGTH%
1450       bodyofs% = SO%(tail%, snakeNum%)
1460       PROCSetArena(sammyBody(bodyofs%).row%, sammyBody(bodyofs%).col%, colorTable%(4))
1470     NEXT b%
1480     DELAY 2
1490   NEXT c%
1500 ENDPROC
1598 REM GetInputs:
1599 REM   Gets player inputs
1600 DEF PROC GetInputs(i AS PlayerInputs)
1610   VDU 17, 7, 17, 128
1620   CLS
1630   REM Number of players
1640   REPEAT
1650     VDU 31, 46, 4: PRINT "                                  ";
1660     VDU 31, 19, 4
1670     INPUT "How many players (1 or 2)"; num$
1680   UNTIL VAL(num$) = 1 OR VAL(num$) = 2
1690   i.NumPlayers% = VAL(num$)
1700   REM Skill level (speed)
1710   VDU 31, 20, 7: PRINT "Skill level (1 to 100)"
1720   VDU 31, 21, 8: PRINT "1   = Novice"
1730   VDU 31, 21, 9: PRINT "90  = Expert"
1740   VDU 31, 21, 10: PRINT "100 = Twiddle Fingers"
1750   VDU 31, 14, 11: PRINT "(Computer speed may affect your skill level)"
1760   REPEAT
1770     VDU 31, 43, 7: PRINT "                                   ";
1780     VDU 31, 42, 7
1790     INPUT gamespeed$
1800   UNTIL VAL(gamespeed$) >= 1 AND VAL(gamespeed$) <= 100
1810   i.speed% = VAL(gamespeed$)
1820   i.speed% = (100 - i.speed%) + 8
1830   REM Sliding difficulty
1840   REPEAT
1850     VDU 31, 55, 14: PRINT "                         ";
1860     VDU 31, 14, 14
1870     INPUT "Increase game speed during play (Y or N)"; diff$
1880     diff$ = UCASE$(diff$)
1890   UNTIL diff$ = "Y" OR diff$ = "N"
1900   i.diff$ = diff$
1910   REM Monitor type (colour mode)
1920   REPEAT
1930     VDU 31, 45, 16: PRINT "                                  ";
1940     VDU 31, 16, 16
1950     INPUT "Monochrome or color monitor (M or C)"; monitor$
1960     monitor$ = UCASE$(monitor$)
1970   UNTIL monitor$ = "M" OR monitor$ = "C"
1980   i.monitor$ = monitor$
1990 ENDPROC
2098 REM InitColors:
2099 REM Initializes playing field colors
2100 DEF PROC InitColors
2110   FOR row% = 1 TO 50
2120     FOR col% = 1 TO 80
2130       arena(AO%(row%, col%)).acolor% = colorTable%(4)
2140     NEXT col%
2150   NEXT row%
2160   CLS
2170   REM Set (turn on) pixels for screen border
2180   FOR col% = 1 TO 80
2190     PROCSetArena(3, col%, colorTable%(3))
2200     PROCSetArena(50, col%, colorTable%(3))
2210   NEXT col%
2220   FOR row% = 4 TO 49
2230     PROCSetArena(row%, 1, colorTable%(3))
2240     PROCSetArena(row%, 80, colorTable%(3))
2250   NEXT row%
2260 ENDPROC
2298 REM Intro:
2299 REM   Displays game introduction
2300 DEF PROC Intro
2310   MODE 2
2320   VDU 17, 7, 17, 128
2330   CLS
2340   PROCCenter(4, "B e r r y B a s i C   N i b b l e s")
2350   PROCCenter(6, "Based on QBasic Nibbles by Microsoft Corporation")
2360   PROCCenter(8, "Nibbles is a game for one or two players.  Navigate your snakes")
2370   PROCCenter(9, "around the game board trying to eat up numbers while avoiding")
2380   PROCCenter(10, "running into walls or other snakes.  The more numbers you eat up,")
2390   PROCCenter(11, "the more points you gain and the longer your snake becomes.")
2400   PROCCenter(13, " Game Controls ")
2410   PROCCenter(15, "       General             Player 1               Player 2        ")
2420   PROCCenter(16, "                             (Up)                   (Up)          ")
2430   PROCCenter(17, "      P - Pause               " + CHR$(24) + "                      W            ")
2440   PROCCenter(18, "                     (Left) " + CHR$(27) + "   " + CHR$(26) + " (Right)   (Left) A   D (Right)  ")
2450   PROCCenter(19, "                              " + CHR$(25) + "                      S            ")
2460   PROCCenter(20, "                            (Down)                 (Down)         ")
2470   PROCCenter(24, "Press any key to continue")
2480   PROCSoundIntroDitty
2490   PROCSparklePause
2500 ENDPROC
2598 REM Level:
2599 REM Sets game level
2600 DEF PROC Level (WhatToDO%)
2610   CASE WhatToDo% OF
2620     WHEN STARTOVER%: curLevel% = 1
2630     WHEN NEXTLEVEL%: curLevel% = curLevel% + 1
2640   ENDCASE
2650   REM Initialize Snakes
2660   sammy(1).head% = 1
2670   sammy(1).length% = 2
2680   sammy(1).alive% = TRUE
2690   sammy(2).head% = 1
2700   sammy(2).length% = 2
2710   sammy(2).alive% = TRUE
2720   REM Playing field
2730   PROCInitColors
2740   CASE curLevel% OF
2750     WHEN 1
2760       sammy(1).row% = 25: sammy(2).row% = 25
2770       sammy(1).col% = 50: sammy(2).col% = 30
2780       sammy(1).direction% = 4: sammy(2).direction% = 3
2790     WHEN 2
2800       FOR i% = 20 TO 60
2810         PROCSetArena(25, i%, colorTable%(3))
2820       NEXT i%
2830       sammy(1).row% = 7: sammy(2).row% = 43
2840       sammy(1).col% = 60: sammy(2).col% = 20
2850       sammy(1).direction% = 3: sammy(2).direction% = 4
2860     WHEN 3
2870       FOR i% = 10 TO 40
2880         PROCSetArena(i%, 20, colorTable%(3))
2890         PROCSetArena(i%, 60, colorTable%(3))
2900       NEXT i%
2910       sammy(1).row% = 25: sammy(2).row% = 25
2920       sammy(1).col% = 50: sammy(2).col% = 30
2930       sammy(1).direction% = 1: sammy(2).direction% = 2
2940     WHEN 4
2950       FOR i% = 4 TO 30
2960         PROCSetArena(i%, 20, colorTable%(3))
2970         PROCSetArena(53 - i%, 60, colorTable%(3))
2980       NEXT i%
2990       FOR i% = 2 TO 40
3000         PROCSetArena(38, i%, colorTable%(3))
3010         PROCSetArena(15, 81 - i%, colorTable%(3))
3020       NEXT i%
3030       sammy(1).row% = 7: sammy(2).row% = 43
3040       sammy(1).col% = 60: sammy(2).col% = 20
3050       sammy(1).direction% = 3: sammy(2).direction% = 4
3060     WHEN 5
3070       FOR i% = 13 TO 39
3080         PROCSetArena(i%, 21, colorTable%(3))
3090         PROCSetArena(i%, 59, colorTable%(3))
3100       NEXT i%
3110       FOR i% = 23 TO 57
3120         PROCSetArena(11, i, colorTable%(3))
3130         PROCSetArena(41, i, colorTable%(3))
3140       NEXT i%
3150       sammy(1).row% = 25: sammy(2).row% = 25
3160       sammy(1).col% = 50: sammy(2).col% = 30
3170       sammy(1).direction% = 1: sammy(2).direction% = 2
3180     WHEN 6
3190       FOR i% = 4 TO 49
3200         IF i% >= 23 AND i% <= 30 THEN CONTINUE FOR: REM Middle gap
3210         PROCSetArena(i%, 10, colorTable%(3))
3220         PROCSetArena(i%, 20, colorTable%(3))
3230         PROCSetArena(i%, 30, colorTable%(3))
3240         PROCSetArena(i%, 40, colorTable%(3))
3250         PROCSetArena(i%, 50, colorTable%(3))
3260         PROCSetArena(i%, 60, colorTable%(3))
3270         PROCSetArena(i%, 70, colorTable%(3))
3280       NEXT i%
3290       sammy(1).row% = 7: sammy(2).row% = 43
3300       sammy(1).col% = 65: sammy(2).col% = 15
3310       sammy(1).direction% = 2: sammy(2).direction% = 1
3320     WHEN 7
3330       FOR i% = 4 TO 49 STEP 2
3340         PROCSetArena(i%, 40, colorTable%(3))
3350       NEXT i%
3360       sammy(1).row% = 7: sammy(2).row% = 43
3370       sammy(1).col% = 65: sammy(2).col% = 15
3380       sammy(1).direction% = 2: sammy(2).direction% = 1
3390     WHEN 8
3400       FOR i% = 4 TO 40
3410         PROCSetArena(i%, 10, colorTable%(3))
3420         PROCSetArena(53 - i%, 20, colorTable%(3))
3430         PROCSetArena(i%, 30, colorTable%(3))
3440         PROCSetArena(53 - i%, 40, colorTable%(3))
3450         PROCSetArena(i%, 50, colorTable%(3))
3460         PROCSetArena(53 - i%, 60, colorTable%(3))
3470         PROCSetArena(i%, 70, colorTable%(3))
3480       NEXT i%
3490       sammy(1).row% = 7: sammy(2).row% = 43
3500       sammy(1).col% = 65: sammy(2).col% = 15
3510       sammy(1).direction% = 2: sammy(2).direction% = 1
3520     WHEN 9
3530       FOR i% = 6 TO 47
3540         PROCSetArena(i%, i%, colorTable%(3))
3550         PROCSetArena(i%, i% + 28, colorTable%(3))
3560       NEXT i%
3570       sammy(1).row% = 40: sammy(2).row% = 15
3580       sammy(1).col% = 75: sammy(2).col% = 5
3590       sammy(1).direction% = 1: sammy(2).direction% = 2
3600     OTHERWISE
3610       FOR i% = 4 TO 49 STEP 2
3620         PROCSetArena(i%, 10, colorTable%(3))
3630         PROCSetArena(i% + 1, 20, colorTable%(3))
3640         PROCSetArena(i%, 30, colorTable%(3))
3650         PROCSetArena(i% + 1, 40, colorTable%(3))
3660         PROCSetArena(i%, 50, colorTable%(3))
3670         PROCSetArena(i% + 1, 60, colorTable%(3))
3680         PROCSetArena(i%, 70, colorTable%(3))
3690       NEXT i%
3700       sammy(1).row% = 7: sammy(2).row% = 43
3710       sammy(1).col% = 65: sammy(2).col% = 15
3720       sammy(1).direction% = 2: sammy(2).direction% = 1
3730   ENDCASE
3740 ENDPROC
3798 REM PlayNibbles:
3799 REM   Main routine that controls game play
3800 DEF PROC PlayNibbles
3810   LOCAL curSpeed%
3820   LOCAL number%, nonum%, numRow%, NumCol%, sisRow%
3830   LOCAL playerDied%
3840   LOCAL kbd$
3850   LOCAL sofs%, tofs%, probe%, probe1%, probe2%
3860   REM Initialize Snakes
3870   sammy(1).lives% = 5
3880   sammy(1).score% = 0
3890   sammy(1).scolor% = colorTable%(1)
3900   sammy(2).lives% = 5
3910   sammy(2).score% = 0
3920   sammy(2).scolor% = colorTable%(2)
3930   REM Initialize level
3940   PROCLevel(STARTOVER%)
3950   curSpeed% = inputs.speed%
3960   REM play Nibbles until finished
3970   PROCSpacePause("     Level " + STR$(curLevel%) + ",  Push Space")
3980   REPEAT
3990     IF inputs.NumPlayers% = 1 THEN sammy(2).row% = 0
4000     number% = 1: REM Current number that snakes are trying to run into
4010     nonum% = TRUE: REM nonum = TRUE if a number is not on the screen
4020     playerDied% = FALSE
4030     PROCPrintScore(inputs.NumPlayers%, sammy(1).score%, sammy(2).score%, sammy(1).lives%, sammy(2).lives%)
4040     PROCSoundLevelStartDitty
4050     REPEAT
4060       REM Print number if no number exists
4070       IF nonum% <> TRUE THEN GOTO 4220
4080       REPEAT
4090         numRow% = INT(RND(1) * 47 + 3)
4100         NumCol% = INT(RND(1) * 78 + 2)
4110         sisRow% = numRow% + arena(AO%(numRow%, NumCol%)).sister%
4120         probe1% = PointIsThere%(numRow%, NumCol%, colorTable%(4))
4130         probe2% = PointIsThere%(sisRow%, NumCol%, colorTable%(4))
4140       UNTIL (probe1% = 0) AND (probe2% = 0)
4150       numRow% = arena(AO%(numRow%, NumCol%)).realRow%
4160       nonum% = FALSE
4170       VDU 17, colorTable%(1), 17, colorTable%(4) OR 128
4180       VDU 31, NumCol% - 1, numRow% - 1
4190       PRINT STR$(number%);
4200       count% = 0
4210       REM End of no number handling; Delay game
4220       DELAY INT(curSpeed% / 4)
4230       REM Get keyboard input & Change direction accordingly
4240       kbd$ = INKEY$(0)
4250       CASE kbd$ OF
4260         WHEN "w", "W": IF sammy(2).direction% <> 2 THEN sammy(2).direction% = 1
4270         WHEN "s", "S": IF sammy(2).direction% <> 1 THEN sammy(2).direction% = 2
4280         WHEN "a", "A": IF sammy(2).direction% <> 4 THEN sammy(2).direction% = 3
4290         WHEN "d", "D": IF sammy(2).direction% <> 3 THEN sammy(2).direction% = 4
4300         WHEN CHR$(19), "8": IF sammy(1).direction% <> 2 THEN sammy(1).direction% = 1
4310         WHEN CHR$(20), "2", "5": IF sammy(1).direction% <> 1 THEN sammy(1).direction% = 2
4320         WHEN CHR$(17), "4": IF sammy(1).direction% <> 4 THEN sammy(1).direction% = 3
4330         WHEN CHR$(18), "6": IF sammy(1).direction% <> 3 THEN sammy(1).direction% = 4
4340         WHEN "p", "P": PROCSpacePause " Game Paused ... Push Space  "
4350       ENDCASE
4360       REM Movement
4370       FOR a% = 1 TO inputs.NumPlayers%
4380         REM Move Snake
4390         CASE sammy(a%).direction% OF
4400           WHEN 1: sammy(a%).row% = sammy(a%).row% - 1
4410           WHEN 2: sammy(a%).row% = sammy(a%).row% + 1
4420           WHEN 3: sammy(a%).col% = sammy(a%).col% - 1
4430           WHEN 4: sammy(a%).col% = sammy(a%).col% + 1
4440         ENDCASE
4450         REM If snake hits number, respond accordingly
4460         IF numRow% <> INT((sammy(a%).row% + 1) / 2) OR NumCol% <> sammy(a%).col% THEN GOTO 4710
4470         PROCSoundAte
4480         IF sammy(a%).length% < (MAXSNAKELENGTH% - 30) THEN sammy(a%).length% = sammy(a%).length% + number% * 4
4490         sammy(a%).score% = sammy(a%).score% + number%
4500         PROCPrintScore(inputs.NumPlayers%, sammy(1).score%, sammy(2).score%, sammy(1).lives%, sammy(2).lives%)
4510         number% = number% + 1
4520         IF number% < 10 THEN GOTO 4690
4530         REM Last number collected; end of level
4540         PROCEraseSnake(1)
4550         PROCEraseSnake(2)
4560         VDU 31, NumCol% - 1, numRow% - 1: PRINT " "
4570         PROCLevel(NEXTLEVEL%)
4580         PROCPrintScore(inputs.NumPlayers%, sammy(1).score%, sammy(2).score%, sammy(1).lives%, sammy(2).lives%)
4590         PROCSpacePause("     Level " + STR$(curLevel%) + ",  Push Space")
4600         IF inputs.NumPlayers% = 1 THEN sammy(2).row% = 0
4610         number% = 1
4620         IF diff$ <> "Y" THEN GOTO 4690
4630         REM Gradually increase speed as levels progress
4640         IF inputs.speed% > 40 THEN inputs.speed% = inputs.speed% - 10: GOTO 4670
4650         IF inputs.speed% > 12 THEN inputs.speed% = inputs.speed% - INT((inputs.speed% - 4) / 4): GOTO 4670
4660         IF inputs.speed% > 6 THEN inputs.speed% = inputs.speed% - 1
4670         curSpeed% = inputs.speed%
4680         REM End of speed change
4690         nonum% = TRUE
4700         REM End of snake hits number
4710         IF curSpeed% < 1 THEN curSpeed% = 1
4720       NEXT a%
4730       FOR a% = 1 TO inputs.NumPlayers%
4740         REM If player runs into any point, or the head of the other snake, it dies.
4750         probe% = PointIsThere%(sammy(a%).row%, sammy(a%).col%, colorTable%(4))
4760         IF (probe% = 0) AND (sammy(1).row% <> sammy(2).row% OR sammy(1).col% <> sammy(2).col%) THEN GOTO 4870
4770         REM Collision!
4780         PROCSoundDied
4790         VDU 17, colorTable%(4) OR 128
4800         VDU 31, NumCol% - 1, numRow% - 1
4810         PRINT " "
4820         playerDied% = TRUE
4830         sammy(a%).alive% = FALSE
4840         sammy(a%).lives% = sammy(a%).lives% - 1
4850         CONTINUE FOR
4860         REM Otherwise, move the snake, and erase the tail
4870         sammy(a%).head% = (sammy(a%).head% + 1) MOD MAXSNAKELENGTH%
4880         sofs% = SO%(sammy(a%).head%, a%)
4890         sammyBody(sofs%).row% = sammy(a%).row%
4900         sammyBody(sofs%).col% = sammy(a%).col%
4910         tail% = (sammy(a%).head% + MAXSNAKELENGTH% - sammy(a%).length%) MOD MAXSNAKELENGTH%
4920         tofs% = SO%(tail%, a%)
4930         PROCSetArena(sammyBody(tofs%).row%, sammyBody(tofs%).col%, colorTable%(4))
4940         sammyBody(tofs%).row% = 0
4950         PROCSetArena(sammy(a%).row%, sammy(a%).col%, sammy(a%).scolor%)
4960       NEXT a%
4970     UNTIL playerDied%
4980     REM reset speed to initial value
4990     curSpeed% = inputs.speed%
5000     FOR a% = 1 TO inputs.NumPlayers%
5010       PROCEraseSnake(a%): REM If dead, then erase snake in really cool way
5020       IF sammy(a%).alive% <> FALSE THEN CONTINUE FOR
5030       REM Update score
5040       sammy(a%).score% = sammy(a%).score% - 10
5050       PROCPrintScore(inputs.NumPlayers%, sammy(1).score%, sammy(2).score%, sammy(1).lives%, sammy(2).lives%)
5060       IF a% = 1 THEN PROCSpacePause(" Sammy Dies! Push Space! --->") ELSE PROCSpacePause(" <---- Jake Dies! Push Space ")
5070     NEXT a%
5080     PROCLevel(SAMELEVEL%)
5090     PROCPrintScore%(inputs.NumPlayers%, sammy(1).score%, sammy(2).score%, sammy(1).lives%, sammy(2).lives%)
5100     REM Play next round, until either of snake's lives have run out.
5110   UNTIL sammy(1).lives% = 0 OR sammy(2).lives% = 0
5120 ENDPROC
5198 REM PointIsThere:
5199 REM   Checks the global arena array to see if the boolean flag is set
5200 DEF FN PointIsThere%(row%, col%, acolor%)
5210   IF row% = 0 THEN GOTO 5230
5220   IF arena(AO%(row%, col%)).acolor% <> acolor% THEN PointIsThere% = TRUE ELSE PointIsThere% = FALSE
5230 END FN
5298 REM PrintScore:
5299 REM   Prints players scores and number of lives remaining
5300 DEF PROC PrintScore(NumPlayers%, score1%, score2%, lives1%, lives2%)
5310   VDU 17, 7, 17, colorTable%(4) OR 128
5320   IF NumPlayers% <> 2 THEN GOTO 5380
5330   VDU 31, 0, 0
5340   IF score2% < 1000000 PRINT " "; : REM bug workaround
5350   PRINT USING "#,###,#"; score2%; : PRINT "00";
5360   PRINT "  Lives: "; STR$(lives2%); "  <--JAKE"
5370   REM End of 2nd player
5380   VDU 31, 48, 0
5390   PRINT "SAMMY-->  Lives: "; STR$(lives1%); "     ";
5400   IF score1% < 1000000 PRINT " "; : REM bug workaround
5410   PRINT USING "#,###,#"; score1%; : PRINT "00";
5420 ENDPROC
5497 REM SetArena:
5498 REM   Sets row and column on playing field to given color to facilitate moving
5499 REM   of snakes around the field.
5500 DEF PROC SetArena (row%, col%, acolor%)
5510   IF row% = 0 THEN GOTO 5690
5520   arena(AO%(row%, col%)).acolor% = acolor%: REM assign color to arena
5530   realRow% = arena(AO%(row%, col%)).realRow%: REM Get real row of pixel
5540   topFlag% = arena(AO%(row%, col%)).sister% > 0: REM Deduce whether pixel is on top or bottom
5550   sisRow% = row% + arena(AO%(row%, col%)).sister%: REM Get arena row of sister
5560   sisCol% = arena(AO%(sisRow%, col%)).acolor%: REM Determine sister's color
5570   fg% = acolor%: bg% = sisCol%
5580   IF bg% = 3 AND fg% <> 3 THEN fg% = bg%: bg% = acolor%: topFlag% = NOT topFlag%
5590   VDU 31, col% - 1, realRow% - 1
5600   CASE acolor% OF
5610     WHEN sisCol%
5620       REM If both points are same
5630       VDU 17, acolor%
5640       PRINT CHR$(219);
5650     OTHERWISE
5660       VDU 17, fg%, 17, bg% OR 128
5670       IF topFlag% THEN PRINT CHR$(223); ELSE PRINT CHR$(220);
5680   ENDCASE
5690 ENDPROC
5698 REM SpacePause:
5699 REM   Pauses game play and waits for space bar to be pressed before continuing
5700 DEF PROC SpacePause(text$)
5710   VDU 17, colorTable%(5), 17, colorTable%(6) OR 128
5720   PROCCenter(11, CHR$(219) + STRING$(31, CHR$(223)) + CHR$(219))
5730   PROCCenter(12, CHR$(219) + " " + LEFT$(text$ + "                             ", 29) + " " + CHR$(219))
5740   PROCCenter(13, CHR$(219) + STRING$(31, CHR$(220)) + CHR$(219))
5750   WHILE INKEY$(0) <> "": ENDWHILE
5760   WHILE INKEY$(0) <> " ": ENDWHILE
5770   VDU 17, 7, 17, colorTable%(4) OR 128
5780   REM Restore the screen background
5790   FOR i% = 21 TO 26
5800     FOR j% = 24 TO 56
5810       PROCSetArena(i%, j%, arena(AO%(i%, j%)).acolor%)
5820     NEXT j%
5830   NEXT i%
5840 ENDPROC
5898 REM SparklePause:
5899 REM  Creates flashing border for intro screen
5900 DEF PROC SparklePause
5910   VDU 17, 1, 17, 128
5920   a$ = "*    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    *    "
5930   REM Clear keyboard buffer
5940   WHILE INKEY$(0) <> "": ENDWHILE
5950   WHILE INKEY$(0) = ""
5960     FOR a% = 1 TO 5
5970       REM print horizontal sparkles
5980       VDU 31, 0, 0
5990       PRINT MID$(a$, a%, 80);
6000       VDU 31, 0, 21
6010       PRINT MID$(a$, 6 - a%, 80);
6020       REM Print Vertical sparkles
6030       FOR b% = 2 TO 21
6040         CASE (a% + b%) MOD 5 OF
6050           WHEN 1
6060             VDU 31, 79, b% - 1
6070             PRINT "*";
6080             VDU 31, 0, 22 - b%
6090             PRINT "*";
6100           OTHERWISE
6110             VDU 31, 79, b% - 1
6120             PRINT " ";
6130             VDU 31, 0, 22 - b%
6140             PRINT " ";
6150         ENDCASE
6160       NEXT b%
6170       DELAY 5
6180     NEXT a%
6190   ENDWHILE
6200 ENDPROC
6298 REM KeepRunning
6299 REM Determines if users want to play game again.
6300 DEF FN KeepRunning%
6310   VDU 17, colorTable%(5), 17, colorTable%(6) OR 128
6320   PROCCenter(10, CHR$(219) + STRING$(31, CHR$(223)) + CHR$(219))
6330   PROCCenter(11, CHR$(219) + "       G A M E   O V E R       " + CHR$(219))
6340   PROCCenter(12, CHR$(219) + "                               " + CHR$(219))
6350   PROCCenter(13, CHR$(219) + "      Play Again?   (Y/N)      " + CHR$(219))
6360   PROCCenter(14, CHR$(219) + STRING$(31, CHR$(220)) + CHR$(219))
6370   WHILE INKEY$(0) <> "": ENDWHILE
6380   REPEAT
6390     kbd$ = UCASE$(INKEY$(0))
6400   UNTIL kbd$ = "Y" OR kbd$ = "N"
6410   VDU 17, 7, 17, colorTable%(4) OR 128
6420   PROCCenter(10, "                                 ")
6430   PROCCenter(11, "                                 ")
6440   PROCCenter(12, "                                 ")
6450   PROCCenter(13, "                                 ")
6460   PROCCenter(14, "                                 ")
6470   IF kbd$ = "Y" THEN KeepRunning% = TRUE: GOTO 6510
6480   KeepRunning% = FALSE
6490   VDU 17, 7, 17, 128
6500   CLS
6510 END FN
6599 REM Sound effect: Intro ditty
6600 DEF PROC SoundIntroDitty
6610   SOUND 1, 15, 5, 2: SOUND 1, 0, 5, 1
6620   SOUND 1, 15, 13, 2: SOUND 1, 0, 5, 1
6630   SOUND 1, 15, 21, 2: SOUND 1, 0, 5, 1
6640   SOUND 1, 15, 13, 2: SOUND 1, 0, 5, 1
6650   SOUND 1, 15, 5, 2: SOUND 1, 0, 5, 1
6660   SOUND 1, 15, 13, 2: SOUND 1, 0, 5, 1
6670   SOUND 1, 15, 21, 5: SOUND 1, 0, 5, 1
6680   SOUND 1, 15, 5, 5: SOUND 1, 0, 5, 1
6690   SOUND 1, 15, 5, 5: SOUND 1, 0, 5, 1
6700 ENDPROC
6799 REM Sound effect: Level start ditty
6800 DEF PROC SoundLevelStartDitty
6810   SOUND 1, 15, 53, 2
6820   SOUND 1, 15, 61, 2
6830   SOUND 1, 15, 69, 2
6840   SOUND 1, 15, 61, 2
6850   SOUND 1, 15, 53, 2
6860   SOUND 1, 15, 61, 2
6870   SOUND 1, 15, 69, 3
6880   SOUND 1, 15, 53, 3: SOUND 1, 0, 5, 1
6890   SOUND 1, 15, 53, 3
6900 ENDPROC
6999 REM Sound effect: Ate a number
7000 DEF PROC SoundAte
7010   SOUND 1, 15, 5, 1: SOUND 1, 0, 5, 1
7020   SOUND 1, 15, 5, 1: SOUND 1, 0, 5, 1
7030   SOUND 1, 15, 5, 1: SOUND 1, 0, 5, 1
7040   SOUND 1, 15, 21, 1
7050 ENDPROC
7099 REM Sound effect: Died
7100 DEF PROC SoundDied
7110   SOUND 1, 15, 21, 1
7120   SOUND 1, 15, 25, 1
7130   SOUND 1, 15, 33, 1
7140   SOUND 1, 15, 21, 1
7150   SOUND 1, 15, 25, 1
7160   SOUND 1, 15, 13, 1
7170   SOUND 1, 15, 5, 1
7180 ENDPROC
7199 REM UCASE$(a$): Return a copy of a$ where every lowercase letter has been made uppercase
7200 DEF FN UCASE$(a$)
7210   b$ = ""
7220   IF LEN(a$) = 0 THEN GOTO 7280
7230   FOR i% = 1 TO LEN(a$)
7240     c% = ASC(MID$(a$, i%, 1))
7250     IF c% >= 97 AND c% <= 122 THEN c% = c% - 32
7260     b$ = b$ + CHR$(c%)
7270   NEXT i%
7280   UCASE$ = b$
7290 END FN
7299 REM STRING$(count%, ch$): Return a string that repeats ch$ count% times
7300 DEF FN STRING$(count%, ch$)
7310   b$ = ch$
7320   bit% = 1
7330   o$ = ""
7340   REPEAT
7350     IF count% AND bit% THEN o$ = o$ + b$
7360     b$ = b$ + b$
7370     bit% = bit% + bit%
7380   UNTIL bit% > count%
7390   STRING$ = o$
7400 END FN
7499 REM Compute arena array offset
7500 DEF FN AO%(row%, col%)
7510   AO% = (row% - 1) * 80 + (col% - 1)
7520 END FN
7599 REM Compute sammy body array offset
7600 DEF FN SO%(position%, whichsnake%)
7610   SO% = (whichsnake% - 1) * MAXSNAKELENGTH% + position%
7620 END FN
