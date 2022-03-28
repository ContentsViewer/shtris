#!/bin/sh

# The pure shell script (sh) that implements the Tetris game following the Tetris Guideline (2009).
#
# The aim is to understand more about shell script and Tetris algorithms.
#
# [Tetris Guideline. Tetris Wiki. accessed at 2020-05-23](https://tetris.fandom.com/wiki/Tetris_Guideline).
#
# This script is based on bash-tetris (Author: Kirill Timofeev <kt97679@gmail.com>)
# Thank you!
#
# I've implemented the following
#
# * Hold Queue
# * Next Queue
# * Random Generation with Bag System
# * Score System
# * Variable Goal System
# * T-Spin / Mini T-Spin
# * Back-to-Back Bonus
# * Extended Placement / Infinite Placement / Classic Lock Down
# * Super / Classic Rotation System
# * Changing the Starting Level
# * Ghost Piece
#
# Enjoy :-)
#
# Supported Environments:
#   Linux   sh | o
#   FreeBSD sh | o
#   BusyBox sh | o
#   Solaris sh | o (Almost works)
#
# Github Page:
#   <https://github.com/ContentsViewer/shtris>
#
# Author:
#   IOE <Github: ContentsViewer>
#
# Scripting NOTE:
#   * We cannot use `read -s -n 1`
#   * Any process cannot send signals to control(main) process
#     * stty issues error -> cannot read keyboard inputs
#
#   * Avoid using `trap` and background `sleep` together.
#     ```
#       trap 'printf .' USR1
#
#       while true; do
#         sleep 0.01 & wait $!
#       done
#     ```
#
#     On macOS (bash 3.2.57), an "Illegal instruction: 4" error occured
#     and program stopped.
#
#   * Delete extra spaces
#     `sed 's/ *$//' shtris >_ && mv _ shtris && chmod +x shtris`
#
#   * Peformance test
#     `time sh -c 'i=0; while [ $i -lt 1000 ]; do i=$((i+1)); <TEST CODE>; done'`
#

set -u # non initialized variable is an error
set -f # disable pathname expansion

# game versioin
# should follow "Semantic Versioning 2.0.0" <https://semver.org/>
# so that users have a clear indicator of when an upgrade will introduce breaking changes.
VERSION='3.0.0'

# program name
PROG=${0##*/}

# Explicitly reset to the default value to prevent the import of IFS
# from the environment. The following shells will work more safely.
#   dash <= 0.5.10.2, FreeBSD sh <= 10.4, etc.
IFS=$(printf '\n\t') && SP=' ' TAB=${IFS#?} LF=${IFS%?} && IFS=" ${TAB}${LF}"

# Force POSIX mode if available
( set -o posix ) 2>/dev/null && set -o posix
if [ "${ZSH_VERSION:-}" ]; then
  IFS="$IFS"$'\0'    # Default IFS value for zsh.
  emulate -R sh      # Required for zsh support.
fi

# Some ancient shells have an issue with empty position parameter references.
# There is a well-known workaround for this, ${1+"$@"}, but it is
# easy to miss and cumbersome to deal with, we disable nounset (set -u).
#
# What does ${1+"$@"} mean
# ref: <https://www.in-ulm.de/~mascheck/various/bourne_args/>
(set --; : "$@") 2>/dev/null || set +u

# NOTICE: alias is FAKE.
#   This is only used to make the local variables stand out.
#   Since ksh does not support local, local will be ignored by all shells
if [ -z "${POSH_VERSION:-}" ]; then # alias is not implemented in posh.
  alias local=""
fi

# Log file to be written for debug.
# the contents in the file will not be deleted,
# but always written in appending.
LOG='.log'

# these signals are used for communicating with each process(i.e. reader, timer, ticker, controller).
# Note:
#   in shell enviroment, should Drop the SIG prefix, just input the signal name.
SIGNAL_TERM=TERM
SIGNAL_INT=INT
SIGNAL_STOP=STOP
SIGNAL_CONT=CONT
SIGNAL_LEVEL_UP=USR1
SIGNAL_RESET_LEVEL=USR2
SIGNAL_RESTART_LOCKDOWN_TIMER=USR1
SIGNAL_RELEASE_INPUT=USR1
SIGNAL_CAPTURE_INPUT=USR2

# Those are commands sent to controller by key press processing code
# In controller they are used as index to retrieve actual function from array
QUIT=0
RIGHT=1
LEFT=2
FALL=3
SOFT_DROP=4
HARD_DROP=5
ROTATE_CW=6
ROTATE_CCW=7
HOLD=8
TOGGLE_BEEP=9
TOGGLE_COLOR=10
TOGGLE_HELP=11
REFRESH_SCREEN=12
LOCKDOWN=13
PAUSE=14
NOTIFY_PID=15

PROCESS_CONTROLLER=0
PROCESS_TICKER=1
PROCESS_TIMER=2
PROCESS_READER=3
PROCESS_INKEY=4

# The normal Fall Speed is defined here to be the time it takes a Tetrimino to fall by one line.
# The current level of the game determines the normal Fall Speed using the following equation:
# (0.8 - ((level - 1) * 0.007))^(level-1)
FALL_SPEED_LEVEL_1=1
FALL_SPEED_LEVEL_2=0.793
FALL_SPEED_LEVEL_3=0.618
FALL_SPEED_LEVEL_4=0.473
FALL_SPEED_LEVEL_5=0.355
FALL_SPEED_LEVEL_6=0.262
FALL_SPEED_LEVEL_7=0.190
FALL_SPEED_LEVEL_8=0.135
FALL_SPEED_LEVEL_9=0.094
FALL_SPEED_LEVEL_10=0.064
FALL_SPEED_LEVEL_11=0.043
FALL_SPEED_LEVEL_12=0.028
FALL_SPEED_LEVEL_13=0.018
FALL_SPEED_LEVEL_14=0.011
FALL_SPEED_LEVEL_15=0.007
LEVEL_MAX=15

# Those are Tetrimino type (and empty)
EMPTY=0
O_TETRIMINO=1
I_TETRIMINO=2
T_TETRIMINO=3
L_TETRIMINO=4
J_TETRIMINO=5
S_TETRIMINO=6
Z_TETRIMINO=7

# Those are the facing
# Tetrimino has four facings
NORTH=0
EAST=1
SOUTH=2
WEST=3

ACTION_NONE=0
ACTION_SINGLE=1
ACTION_DOUBLE=2
ACTION_TRIPLE=3
ACTION_TETRIS=4
ACTION_SOFT_DROP=5
ACTION_HARD_DROP=6
ACTION_TSPIN=7
ACTION_TSPIN_SINGLE=8
ACTION_TSPIN_DOUBLE=9
ACTION_TSPIN_TRIPLE=10
ACTION_MINI_TSPIN=11
ACTION_MINI_TSPIN_SINGLE=12
ACTION_MINI_TSPIN_DOUBLE=13

eval SCORE_FACTOR_"$ACTION_NONE"=0
eval SCORE_FACTOR_"$ACTION_SINGLE"=100
eval SCORE_FACTOR_"$ACTION_DOUBLE"=300
eval SCORE_FACTOR_"$ACTION_TRIPLE"=500
eval SCORE_FACTOR_"$ACTION_TETRIS"=800
eval SCORE_FACTOR_"$ACTION_TSPIN"=400
eval SCORE_FACTOR_"$ACTION_TSPIN_SINGLE"=800
eval SCORE_FACTOR_"$ACTION_TSPIN_DOUBLE"=1200
eval SCORE_FACTOR_"$ACTION_TSPIN_TRIPLE"=1600
eval SCORE_FACTOR_"$ACTION_MINI_TSPIN"=100
eval SCORE_FACTOR_"$ACTION_MINI_TSPIN_SINGLE"=200
eval SCORE_FACTOR_"$ACTION_MINI_TSPIN_DOUBLE"=300
eval SCORE_FACTOR_"$ACTION_SOFT_DROP"=1
eval SCORE_FACTOR_"$ACTION_HARD_DROP"=2
SCORE_FACTOR_COMBO=50
SCORE_FACTOR_SINGLE_LINE_PERFECT_CLEAR=800
SCORE_FACTOR_DOUBLE_LINE_PERFECT_CLEAR=1200
SCORE_FACTOR_TRIPLE_LINE_PERFECT_CLEAR=1800
SCORE_FACTOR_TETRIS_PERFECT_CLEAR=2000

# A Tetrimino that is Hard Dropped Locks Down immediately. However, if a Tetrimino naturally falls
# or Soft Drops onto a Surface, it is given 0.5 seconds on a Lock Down Timer before it actually
# Locks Down. Three rulesets -Infinite Placement, Extended, and Classic- dictate the conditions
# for Lock Down. The default is Extended Placement.
#
# Extended Placement Lock Down
#   This is the default Lock Down setting.
#   Once the Tetrimino in play lands on a Surface in the Matrix, the Lock Down Timer starts counting
#   down from 0.5 seconds. Once it hits zero, the Tetrimino Locks Down and the Next Tetrimino's
#   generation phase starts. The Lock Down Timer resets to 0.5 seconds if the player simply moves
#   or rotates the Tetrimino. In Extended Placement, a Tetrimino gets 15 left/right movements or
#   rotations before it Locks Down, regardless of the time left on the Lock Down Timer. However, if
#   the Tetrimino falls one row below the lowest row yet reached, this counter is reset. In all other
#   cases, it is not reset.
#
# Infinite Placement Lock Down
#   Once the Tetrimino in play lands on a Surface in the Matrix, the Lock Down Timer starts counting
#   down from 0.5 seconds. Once it hits zero, the Tetrimino Locks Down and the Next Tetrimino's
#   generation phase starts. However, the Lock Down Timer resets to 0.5 seconds if the player simply
#   moves or rotates the Tetrimino. Thus, Infinite Placement allows the player to continue movement
#   and rotation of a Tetrimino as long as there is an actual change in its position or orientation
#   before the timer expires.
#
# Classic Lock Down
#   Classic Lock Down rules apply if Infinite Placement and Extended Placement are turned off.
#   Like Infinite Placement, the Lock Down Timer starts counting down from 0.5 seconds once the
#   Tetrimino in play lands on a Surface. The y-coordinate of the Tetrimino must decrease (i.e., the
#   Tetrimino falls further down in the Matrix) in order for the timer to be reset.
LOCKDOWN_RULE_EXTENDED=0
LOCKDOWN_RULE_INFINITE=1
LOCKDOWN_RULE_CLASSIC=2
LOCKDOWN_ALLOWED_MANIPULATIONS=15

# Location and size of playfield and border
PLAYFIELD_W=10
PLAYFIELD_H=20
PLAYFIELD_X=18
PLAYFIELD_Y=2

# Location of error logs
ERRLOG_Y=$((PLAYFIELD_Y + PLAYFIELD_H + 2))

# Location of score information
SCORE_X=3
SCORE_Y=6

# Location of help information
HELP_X=52
HELP_Y=8

# Next piece location
NEXT_X=41
NEXT_Y=2
NEXT_MAX=7

# Hold piece location
HOLD_X=7
HOLD_Y=2

# Location of center of play field
CENTER_X=$((PLAYFIELD_X + PLAYFIELD_W)) # 1 width equals 2 character
CENTER_Y=$((PLAYFIELD_Y + PLAYFIELD_H / 2 - 1))

# piece starting location
# Tetriminos are all generated North Facing (just as they appear in the Next Queue) on the 21st
# and 22nd rows, just above the Skyline. There are 10 cells across the Matrix, and every Tetrimino
# that is three Minos wide is generated on the 4th cell across and stretches to the 6th. This
# includes the T-Tetrimino, L-Tetrimino, J-Tetrimino, S-Tetrimino and Z-Tetrimino. The I-Tetrimino and
# O-Tetrimino are exactly centered at generation. The I-Tetrimino is generated on the 21st row
# (not 22nd), stretching from the 4th to 7th cells. The O-Tetrimino is generated on the 5th and
# 6th cell.
START_X=3
START_Y=21

# assured over 3 blocks above START_Y
BUFFER_ZONE_Y=24

# constant chars
BEL="$(printf '\007')"
ESC="$(printf '\033')"

# exit information format
EXIT_FORMAT="\033[$((PLAYFIELD_Y + PLAYFIELD_H + 1));1H\033[K> %s\n"

# Minos:
#   this array holds all possible pieces that can be used in the game
#   each piece consists of 4 cells(minos)
#   each string is sequence of relative xy coordinates
#   Format:
#     piece_<TETRIMINO>_minos_<FACING>='<mino_0_x> <mino_1_y> ...'
#       (0, 0) is top left
#
# Rotaion point:
#   Each Tetrimino has five possible rotation points. If the Tetrimino cannot rotate on the first point, it
#   will try to rotate on the second. If it cannot rotate on the second, it will try the third and so on. If
#   it cannot rotate on any of the points, then it cannot rotate.
#   Format:
#     piece_<TETRIMINO>_rchifts_<FACING>='<POINT_1> <POINT_2> ...'
#       <POINT_<NO>>: <ROTATION_LEFT_shifts> <ROTATION_RIGHT_shifts>
#       <ROTATION_<DIR>_shifts>: <shift_x> <shift_y>

# O-Tetrimino
#
#    .[][]   .[][]   .[][]   .[][]
#    .[][]   .[][]   .[][]   .[][]
#    . . .   . . .   . . .   . . .
eval piece_"$O_TETRIMINO"_minos_"$NORTH"=\'1 0  2 0  1 1  2 1\'
eval piece_"$O_TETRIMINO"_minos_"$EAST"=\' 1 0  2 0  1 1  2 1\'
eval piece_"$O_TETRIMINO"_minos_"$SOUTH"=\'1 0  2 0  1 1  2 1\'
eval piece_"$O_TETRIMINO"_minos_"$WEST"=\' 1 0  2 0  1 1  2 1\'
eval piece_"$O_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0\"
eval piece_"$O_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0\"
eval piece_"$O_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0\"
eval piece_"$O_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0   0  0  0  0\"
eval piece_"$O_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$O_TETRIMINO"_lowest_"$EAST"=\' 1\'
eval piece_"$O_TETRIMINO"_lowest_"$SOUTH"=\'1\'
eval piece_"$O_TETRIMINO"_lowest_"$WEST"=\' 1\'

# I-Tetrimino
#    . . . .   . .[] .   . . . .   .[] . .
#   [][][][]   . .[] .   . . . .   .[] . .
#    . . . .   . .[] .  [][][][]   .[] . .
#    . . . .   . .[] .   . . . .   .[] . .
eval piece_"$I_TETRIMINO"_minos_"$NORTH"=\'0 1  1 1  2 1  3 1\'
eval piece_"$I_TETRIMINO"_minos_"$EAST"=\' 2 0  2 1  2 2  2 3\'
eval piece_"$I_TETRIMINO"_minos_"$SOUTH"=\'0 2  1 2  2 2  3 2\'
eval piece_"$I_TETRIMINO"_minos_"$WEST"=\' 1 0  1 1  1 2  1 3\'
eval piece_"$I_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0  -1  0 -2  0   2  0  1  0  -1  2 -2 -1   2 -1  1  2\"
eval piece_"$I_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   2  0 -1  0  -1  0  2  0   2  1 -1  2  -1 -2  2 -1\"
eval piece_"$I_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0   1  0  2  0  -2  0 -1  0   1 -2  2  1  -2  1 -1 -2\"
eval piece_"$I_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -2  0  1  0   1  0 -2  0  -2 -1  1 -2   1  2 -2  1\"
eval piece_"$I_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$I_TETRIMINO"_lowest_"$EAST"=\' 3\'
eval piece_"$I_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$I_TETRIMINO"_lowest_"$WEST"=\' 3\'

# T-Tetrimino
#
#    .[] .   .[] .   . . .   .[] .
#   [][][]   .[][]  [][][]  [][] .
#    . . .   .[] .   .[] .   .[] .
eval piece_"$T_TETRIMINO"_minos_"$NORTH"=\'1 0  0 1  1 1  2 1\'
eval piece_"$T_TETRIMINO"_minos_"$EAST"=\' 1 0  1 1  2 1  1 2\'
eval piece_"$T_TETRIMINO"_minos_"$SOUTH"=\'0 1  1 1  2 1  1 2\'
eval piece_"$T_TETRIMINO"_minos_"$WEST"=\' 1 0  0 1  1 1  1 2\'
eval piece_"$T_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   1  0 -1  0   1  1 -1  1   n  n  n  n   1 -2 -1 -2\"
eval piece_"$T_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   1  0  1  0   1 -1  1 -1   0  2  0  2   1  2  1  2\"
eval piece_"$T_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0  -1  0  1  0   n  n  n  n   0 -2  0 -2  -1 -2  1 -2\"
eval piece_"$T_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -1  0 -1  0  -1 -1 -1 -1   0  2  0  2  -1  2 -1  2\"
eval piece_"$T_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$T_TETRIMINO"_lowest_"$EAST"=\' 2\'
eval piece_"$T_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$T_TETRIMINO"_lowest_"$WEST"=\' 2\'

# L-Tetrimino
#
#    . .[]   .[] .   . . .  [][] .
#   [][][]   .[] .  [][][]   .[] .
#    . . .   .[][]  [] . .   .[] .
eval piece_"$L_TETRIMINO"_minos_"$NORTH"=\'2 0  0 1  1 1  2 1\'
eval piece_"$L_TETRIMINO"_minos_"$EAST"=\' 1 0  1 1  1 2  2 2\'
eval piece_"$L_TETRIMINO"_minos_"$SOUTH"=\'0 1  1 1  2 1  0 2\'
eval piece_"$L_TETRIMINO"_minos_"$WEST"=\' 0 0  1 0  1 1  1 2\'
eval piece_"$L_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   1  0 -1  0   1  1 -1  1   0 -2  0 -2   1 -2 -1 -2\"
eval piece_"$L_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   1  0  1  0   1 -1  1 -1   0  2  0  2   1  2  1  2\"
eval piece_"$L_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0  -1  0  1  0  -1  1  1  1   0 -2  0 -2  -1 -2  1 -2\"
eval piece_"$L_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -1  0 -1  0  -1 -1 -1 -1   0  2  0  2  -1  2 -1  2\"
eval piece_"$L_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$L_TETRIMINO"_lowest_"$EAST"=\' 2\'
eval piece_"$L_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$L_TETRIMINO"_lowest_"$WEST"=\' 2\'

# J-Tetrimino
#   [] . .   .[][]   . . .   .[] .
#   [][][]   .[] .  [][][]   .[] .
#    . . .   .[] .   . .[]  [][] .
eval piece_"$J_TETRIMINO"_minos_"$NORTH"=\'0 0  0 1  1 1  2 1\'
eval piece_"$J_TETRIMINO"_minos_"$EAST"=\' 1 0  2 0  1 1  1 2\'
eval piece_"$J_TETRIMINO"_minos_"$SOUTH"=\'0 1  1 1  2 1  2 2\'
eval piece_"$J_TETRIMINO"_minos_"$WEST"=\' 1 0  1 1  0 2  1 2\'
eval piece_"$J_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   1  0 -1  0   1  1 -1  1   0 -2  0 -2   1 -2 -1 -2\"
eval piece_"$J_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   1  0  1  0   1 -1  1 -1   0  2  0  2   1  2  1  2\"
eval piece_"$J_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0  -1  0  1  0  -1  1  1  1   0 -2  0 -2  -1 -2  1 -2\"
eval piece_"$J_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -1  0 -1  0  -1 -1 -1 -1   0  2  0  2  -1  2 -1  2\"
eval piece_"$J_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$J_TETRIMINO"_lowest_"$EAST"=\' 2\'
eval piece_"$J_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$J_TETRIMINO"_lowest_"$WEST"=\' 2\'

# S-Tetrimino
#    .[][]   .[] .   . . .  [] . .
#   [][] .   .[][]   .[][]  [][] .
#    . . .   . .[]  [][] .   .[] .
eval piece_"$S_TETRIMINO"_minos_"$NORTH"=\'1 0  2 0  0 1  1 1\'
eval piece_"$S_TETRIMINO"_minos_"$EAST"=\' 1 0  1 1  2 1  2 2\'
eval piece_"$S_TETRIMINO"_minos_"$SOUTH"=\'1 1  2 1  0 2  1 2\'
eval piece_"$S_TETRIMINO"_minos_"$WEST"=\' 0 0  0 1  1 1  1 2\'
eval piece_"$S_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   1  0 -1  0   1  1 -1  1   0 -2  0 -2   1 -2 -1 -2\"
eval piece_"$S_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   1  0  1  0   1 -1  1 -1   0  2  0  2   1  2  1  2\"
eval piece_"$S_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0  -1  0  1  0  -1  1  1  1   0 -2  0 -2  -1 -2  1 -2\"
eval piece_"$S_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -1  0 -1  0  -1 -1 -1 -1   0  2  0  2  -1  2 -1  2\"
eval piece_"$S_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$S_TETRIMINO"_lowest_"$EAST"=\' 2\'
eval piece_"$S_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$S_TETRIMINO"_lowest_"$WEST"=\' 2\'

# Z-Tetrimino
#   [][] .   . .[]   . . .   .[] .
#    .[][]   .[][]  [][] .  [][] .
#    . . .   .[] .   .[][]  [] . .
eval piece_"$Z_TETRIMINO"_minos_"$NORTH"=\"0 0  1 0  1 1  2 1\"
eval piece_"$Z_TETRIMINO"_minos_"$EAST"=\" 2 0  1 1  2 1  1 2\"
eval piece_"$Z_TETRIMINO"_minos_"$SOUTH"=\"0 1  1 1  1 2  2 2\"
eval piece_"$Z_TETRIMINO"_minos_"$WEST"=\" 1 0  0 1  1 1  0 2\"
eval piece_"$Z_TETRIMINO"_rshifts_"$NORTH"=\"0  0  0  0   1  0 -1  0   1  1 -1  1   0 -2  0 -2   1 -2 -1 -2\"
eval piece_"$Z_TETRIMINO"_rshifts_"$EAST"=\" 0  0  0  0   1  0  1  0   1 -1  1 -1   0  2  0  2   1  2  1  2\"
eval piece_"$Z_TETRIMINO"_rshifts_"$SOUTH"=\"0  0  0  0  -1  0  1  0  -1  1  1  1   0 -2  0 -2  -1 -2  1 -2\"
eval piece_"$Z_TETRIMINO"_rshifts_"$WEST"=\" 0  0  0  0  -1  0 -1  0  -1 -1 -1 -1   0  2  0  2  -1  2 -1  2\"
eval piece_"$Z_TETRIMINO"_lowest_"$NORTH"=\'1\'
eval piece_"$Z_TETRIMINO"_lowest_"$EAST"=\' 2\'
eval piece_"$Z_TETRIMINO"_lowest_"$SOUTH"=\'2\'
eval piece_"$Z_TETRIMINO"_lowest_"$WEST"=\' 2\'

# the side of a Mino in the T-Tetrimino:
# Format:
#   T_TETRIMINO_<FACING>_SIDES='<SIDE_A> <SIDE_B> <SIDE_C> <SIDE_D>'
#     <SIDE_<NO>>: <pos_x> <pos_y>
#     (0, 0) is top left
#
# T-Spin:
#   A rotation is considered a T-Spin if any of the following conditions are met:
#   * Sides A and B + (C or D) are touching a Surface when the Tetrimino Locks Down.
#   * The T-Tetrimino fills a T-Slot completely with no holes.
#   * Rotation Point 5 is used to rotate the Tetrimino into the T-Slot.
#     Any further rotation will be considered a T-Spin, not a Mini T-Spin
#
# Mini T-Spin:
#   A rotation is considered a Mini T-Spin if either of the following conditions are met:
#   * Sides C and D + (A or B) are touching a Surface when the Tetrimino Locks Down.
#   * The T-Tetrimino creates holes in a T-Slot. However, if Rotation Point 5 was used to rotate
#     the Tetrimino into the T-Slot, the rotation is considered a T-Spin.
#
eval T_TETRIMINO_"$NORTH"_SIDES=\"0 0  2 0  0 2  2 2\"
eval T_TETRIMINO_"$EAST"_SIDES=\" 2 0  2 2  0 0  0 2\"
eval T_TETRIMINO_"$SOUTH"_SIDES=\"2 2  0 2  2 0  0 0\"
eval T_TETRIMINO_"$WEST"_SIDES=\" 0 2  0 0  2 2  2 0\"

EMPTY_CELL=' .'     # how we draw empty cell
FILLED_CELL='[]'    # how we draw filled cell
INACTIVE_CELL='_]'  # how we draw inactive cell
GHOST_CELL='░░'     # how we draw ghost cell
DRY_CELL='  '       # how we draw dry cell

HELP="
Move Left       ←
Move Right      →
Rotate Left     z
Rotate Right    x, ↑
Hold            c
Soft Drop       ↓
Hard Drop       Space
${SP}
Pause / Resume  TAB, F1
Refresh Screen  R
Toggle Color    C
Toggle Beep     B
Toggle Help     H
Quit            Q, ESCx2
"

USAGE="
Usage: $PROG [options]

Options:
 -d, --debug          debug mode
 -l, --level <LEVEL>  game level (default=1). range from 1 to $LEVEL_MAX
 --rotation <MODE>    use 'Super' or 'Classic' rotation system
                      MODE can be 'super'(default) or 'classic'
 --lockdown <RULE>    Three rulesets -Infinite Placement, Extended, and Classic-
                      dictate the conditions for Lock Down.
                      RULE can be 'extended'(default), 'infinite', 'classic'
 --seed <SEED>        random seed to determine the order of Tetriminos.
                      range from 1 to 4294967295.
 --theme <THEME>      color theme 'standard'(default), 'system'
 --no-color           don't display colors
 --no-beep            disable beep
 --hide-help          don't show help on start

 -h, --help     display this help and exit
 -V, --version  output version infromation and exit

Version:
 $VERSION
"

# the queue of the next tetriminos to be placed.
# the reference says the next six tetrimonos should be shown.
next_queue=''

# the hold queue allows the player to hold a falling tetrimino for as long as they wish.
hold_queue=''

# Tetris uses a "bag" system to determine the sequence of Tetriminos that appear during game
# play. This system allows for equal distribution among the seven Tetriminos.
#
# The seven different Tetriminos are placed into a virtual bag, then shuffled into a random order.
# This order is the sequence that the bag "feeds" the Next Queue. Every time a new Tetrimino is
# generated and starts its fall within the Matrix, the Tetrimino at the front of the line in the bag is
# placed at the end of the Next Queue, pushing all Tetriminos in the Next Queue forward by one.
# The bag is refilled and reshuffled once it is empty.
bag=''

# Note: In most competitive multiplayer variants, all players should receive the same order of
# Tetriminos (random for each game played), unless the variant is specifically designed not to
# do this.
#
# Tetriminoes will appear in the same order in games started with the same number.
# 0 means not set, and the range is from 1 to 4294967295.
bag_random=0

# the Variable Goal System requires that the player clears 5 lines at level 1, 10 lines at
# level 2, 15 at level 3 and so on, adding an additional five lines to the Goal each level through 15.
# with the Variable Goal System of adding 5 lines per level, the player is required to clear 600 lines
# by level 15.
#
# This system also includes line bonuses to help speed up the game.
# To speed up the process of "clearing" 600 lines, in the Variable Goal System the number of Line
# Clears awarded for any action is directly based off the score of the action performed (score
# at level 1 / 100 = Total Line Clears
adding_lines_per_level=5

# There is a special bonus for Back-to-Backs, which is when two actions
# such as a Tetris and T-Spin Double take place without a Single, Double, or Triple Line Clear
# occurring between them.
#
# Back-to-Back Bonus
#   Bonus for Tetrises, T-Spin Line Clears, and Mini T-Spin Line Clears
#   performed consecutively in a B2B sequence.
b2b_sequence_continues=false

# The player can perform the same actions on a Tetrimino in this phase as he/she can in the
# Falling Phase, as long as the Tetrimino is not yet Locked Down. A Tetrimino that is Hard Dropped
# Locks Down immediately. However, if a Tetrimino naturally falls or Soft Drops onto a landing
# Surface, it is given 0.5 seconds on a Lock Down Timer before it actually Locks Down.
#
# There are three rulesets - Infinite Placement, Extended, and Classic.
# For more details, see LOCKDOWN_RULE
#
# LOCKDOWN command is valid only when lock_phase=true
lock_phase=false

# Combos are bonuses which rewards multiple line clears in quick succession.
# This type of combos is used in almost every official Tetris client that
# follows the Tetris Guideline. For every placed piece that clears at least one line,
# the combo counter is increased by +1. If a placed piece doesn't clear a line,
# the combo counter is reset to -1. That means 2 consecutive line clears result
# in a 1-combo, 3 consecutive line clears result in a 2-combo and so on.
# Each time the combo counter is increased beyond 0, the player receives a reward:
# In singleplayer modes, the reward is usually combo-counter*50*level points.
combo_counter=-1

# The variable to preserve last actions.
# Each action is put on divided section by ':'.
# draw_action() draws these actions.
#
# Actions will be drawn as follows:
#   ---
#   <REN>
#   <EMPTY>
#   <ACTION-1>
#   <ACTION-2>
#   <EMPTY>
#   <BACK-to-BACK>
#   ---
last_actions=''

# A Perfect Clear (PC) means having no filled cells left after a line clear.
# Scoring:
#   Single-line perfect clear         | 800  x level
#   Double-line perfect clear         | 1200 x level
#   Triple-line perfect clear         | 1800 x level
#   Tetris perfect clear              | 2000 x level
#   Back-to-back Tetris perfect clear | 3200 x level
#
#   ex)
#     Back-to-back Tetris perfect clear 3200 * level pt
#
#     Tetris (800 * level pt) + B2B-Bonus (800 / 2 * level pt) + Tetris-PC (2000 * level)
#     = 3200 * level pt
#
#   details:
#     * <https://n3twork.zendesk.com/hc/en-us/articles/360046263052-Scoring>
#     * <https://tetris.wiki/Scoring>
perfect_clear=false

lockdown_rule=$LOCKDOWN_RULE_EXTENDED
score=0                    # score variable initialization
level=0                    # level variable initialization
goal=0                     # goal variable initialization
lines_completed=0          # completed lines counter initialization
already_hold=false         #
help_on=true               # if this flag is true help is shown, if false, hide
beep_on=true               #
no_color=false             # do we use color or not
running=true               # controller runs while this flag is true
manipulation_counter=0     #
lowest_line=$START_Y       #
current_tspin=$ACTION_NONE #
theme='standard'
lands_on=false
pause=false
gameover=false

# Game Over Conditions
#
# Lock Out
#   This Game Over Condition occurs when a whole Tetrimino Locks Down above the Skyline.
#
# Block Out
#   This Game Over Condition occurs when part of a newly-generated Tetrimino is blocked due to
#   an existing Block in the Matrix

debug() {
  [ $# -eq 0 ] && return
  "$@" >> "$LOG"
}

# Arguments:
#   1 - varname
#   2 - str to repeat
#   3 - count
str_repeat() {
  set -- "$1" "${2:-}" "${3:-0}" ""
  while [ "$3" -gt 0 ]; do
    set -- "$1" "$2" $(($3 - 1)) "$4$2"
  done
  eval "$1=\$4"
}

str_lpad() {
  set -- "$1" "$2" "$3" "${4:- }"
  while [ "${#2}" -lt "$3" ]; do
    set -- "$1" "${4}${2}" "$3" "$4"
  done
  eval "$1=\$2"
}

str_rpad() {
  set -- "$1" "$2" "$3" "${4:- }"
  while [ "${#2}" -lt "$3" ]; do
    set -- "$1" "${2}${4}" "$3" "$4"
  done
  eval "$1=\$2"
}

switch_color_theme() {
  local i=''

  SCORE_COLOR='' HELP_COLOR='' BORDER_COLOR='' FLASH_COLOR='' HOLD_COLOR=''
  eval "TETRIMINO_${EMPTY}_COLOR=''"
  for i in I J L O S T Z; do
    eval "TETRIMINO_${i}_COLOR=''"
  done

  "color_theme_$1"

  for i in SCORE_COLOR HELP_COLOR BORDER_COLOR FLASH_COLOR HOLD_COLOR; do
    eval "set -- $i \$${i}"
    eval "${1}='${ESC}[${2};${3}m'"
  done

  eval "TETRIMINO_${EMPTY}_COLOR='${ESC}[39;49m'"
  for i in I J L O S T Z; do
    eval "set -- \$${i}_TETRIMINO \$TETRIMINO_${i}_COLOR"
    eval "TETRIMINO_${1}_COLOR='${ESC}[${2};${3}m'"
    eval "GHOST_${1}_COLOR='${ESC}[${4};${5}m'"
  done
}

# Color Codes
#   39 - default foreground color
#   49 - default background color
#
# 8 Colors
#   30-37 - foreground color
#     30:BLACK 31:RED 32:GREEN 33:YELLOW 34:BLUE 35:MAGENTA 36:CYAN 37:WHITE
#   40-47 - background color
#     40:BLACK 41:RED 42:GREEN 43:YELLOW 44:BLUE 45:MAGENTA 46:CYAN 47:WHITE
#
# 16 Colors (additional 8 colors)
#    90- 97 - bright foreground color
#     90:BLACK 91:RED 92:GREEN 93:YELLOW 94:BLUE 95:MAGENTA 96:CYAN 97:WHITE
#   100-107 - bright background color
#     100:BLACK 101:RED 102:GREEN 103:YELLOW 104:BLUE 105:MAGENTA 106:CYAN 107:WHITE
#
# 256 Colors
#   38;5;<N> - foreground color
#   48;5;<N> - background color
#     N=  0-  7: standard colors
#           0:BLACK 1:RED  2:GREEN  3:YELLOW  4:BLUE  5:MAGENTA  6:CYAN  7:WHITE
#         8- 15: high intensity colors
#           8:BLACK 9:RED 10:GREEN 11:YELLOW 12:BLUE 13:MAGENTA 14:CYAN 15:WHITE
#        16-231: 216 colors (6 * 6 * 6)
#                R*36 + G*6 + B + 16 (0 <= R, G, B <= 5)
#       232-255: grayscale from black to white in 24 steps
#
# 16777216 Colors (256 * 256 * 256)
#   38;2;<R>;<G>;<B> - foreground color
#   48;2;<R>;<G>;<B> - background color
#
# Format:
#   <N>_COLOR='<FG> <BG>'
#   TETRIMINO_<T>_COLOR='<FG> <BG> <GHOST_FG> <GHOST_BG>'

color_theme_system() {
  SCORE_COLOR='32  49' # GREEN
  HELP_COLOR=' 33  49' # YELLOW
  HOLD_COLOR=' 90 100' # BRIGHT BLACK

  #  not specify color (e.g., WHITE) to match terminal color theme (dark or light)
  BORDER_COLOR='39 49' # default
  FLASH_COLOR=' 39 49' # default

  TETRIMINO_I_COLOR='36  46  36 49' # CYAN
  TETRIMINO_J_COLOR='34  44  34 49' # BLUE
  TETRIMINO_L_COLOR='91 101  91 49' # BRIGHT RED
  TETRIMINO_O_COLOR='33  43  33 49' # YELLOW
  TETRIMINO_S_COLOR='32  42  32 49' # GREEN
  TETRIMINO_T_COLOR='35  45  35 49' # MAGENTA
  TETRIMINO_Z_COLOR='31  41  31 49' # RED
}

color_theme_standard() {
  SCORE_COLOR='38;5;70  49'       # green  (r:1 g:3 b:0)
  HELP_COLOR=' 38;5;220 49'       # yellow (r:5 g:4 b:0)
  HOLD_COLOR=' 38;5;245 48;5;245' # gray

  #  not specify color (e.g., WHITE) to match terminal color theme (dark or light)
  BORDER_COLOR='39 49' # default
  FLASH_COLOR=' 39 49' # default

  TETRIMINO_I_COLOR='38;5;39  48;5;39   38;5;39  49' # light blue (r:0 g:3 b:5)
  TETRIMINO_J_COLOR='38;5;25  48;5;25   38;5;25  49' # dark blue  (r:0 g:1 b:3)
  TETRIMINO_L_COLOR='38;5;208 48;5;208  38;5;208 49' # orange     (r:5 g:2 b:0)
  TETRIMINO_O_COLOR='38;5;220 48;5;220  38;5;220 49' # yellow     (r:5 g:4 b:0)
  TETRIMINO_S_COLOR='38;5;70  48;5;70   38;5;70  49' # green      (r:1 g:3 b:0)
  TETRIMINO_T_COLOR='38;5;90  48;5;90   38;5;90  49' # purple     (r:2 g:0 b:2)
  TETRIMINO_Z_COLOR='38;5;160 48;5;160  38;5;160 49' # red        (r:4 g:0 b:0)
}

# screen_buffer is variable, that accumulates all screen changes
# this variable is printed in controller once per game cycle
screen_buffer=''
puts() {
  screen_buffer="$screen_buffer""$1"
}

flush_screen() {
  [ -z "$screen_buffer" ] && return
  # $debug printf "${#screen_buffer} " # For debugging. survey the output size
  echo "$screen_buffer"
  screen_buffer=''
}

# move cursor to (x,y) and print string
# (1,1) is upper left corner of the screen
xyprint() {
  puts "${ESC}[${2};${1}H${3:-}"
}

clear_screen() {
  puts "${ESC}[H${ESC}[2J"
}

set_color() {
  $no_color && return
  puts "$1"
}

set_piece_color() {
  eval set_color "\$TETRIMINO_${1}_COLOR"
}

set_ghost_color() {
  eval set_color "\$GHOST_${1}_COLOR"
}

reset_colors() {
  puts "${ESC}[m"
}

set_style() {
  while [ $# -gt 0 ]; do
    case $1 in
      bold)      puts "${ESC}[1m" ;;
      underline) puts "${ESC}[4m" ;;
      reverse)   puts "${ESC}[7m" ;;
      *) echo "other styles are not supported" >&2 ;;
    esac
    shift
  done
}

beep() {
  $beep_on || return
  puts "$BEL"
}

send_cmd() {
  echo "$1"
}

# Get pid of current process regardless of subshell
#
# $$:
#   Expands to the process ID of the shell.
#   In a () subshell, it expands to the process ID of the current shell, not the subshell.
#
# Notice that some shells (eg. zsh or ksh93) do NOT start a subprocess
# for each subshell created with (...); in that case, $pid may be end up
# being the same as $$, which is just right, because that's the PID of
# the process getpid was called from.
#
# ref: <https://unix.stackexchange.com/questions/484442/how-can-i-get-the-pid-of-a-subshell>
#
# usage: getpid [varname]
get_pid(){
  set -- "${1:-}" "$(exec sh -c 'echo "$PPID"')"
  [ "$1" ] && eval "$1=\$2" && return
  echo "$2"
}

send_signal() {
  local signal=$1
  shift
  set -- $@ # remove empty pid

  # If implemented correctly, there should be no need to discard the error,
  # but it's a little hard and not that important, so we output only in debug mode.
  if $debug; then
    kill -"$signal" "$@" || echo "send signal failed: $signal:" "$@" >&2
  else
    { kill -"$signal" "$@"; } 2>/dev/null
  fi
}

exist_process() {
  send_signal 0 "$@" 2>/dev/null
}

stop_at_start() {
  sleep 0.1 # wait a bit because the too fast(?) ksh will output an error "Stopped (SIGSTOP)".
  $debug echo "stop at start: $1"
  send_signal "$SIGNAL_STOP" "$1"
}

wakeup_ticker() {
  send_signal "$SIGNAL_CONT" "$ticker_pid"
  # $debug echo 'wakeup ticker'
}

stop_ticker() {
  send_signal "$SIGNAL_STOP" "$ticker_pid"
  # $debug echo 'stop ticker'
}

wakeup_lockdown_timer() {
  send_signal "$SIGNAL_CONT" "$timer_pid"
  # $debug echo 'wakeup lockdown timer'
}

restart_lockdown_timer() {
  send_signal "$SIGNAL_RESTART_LOCKDOWN_TIMER" $timer_pid
  # $debug echo 'send_signal: RESTART_LOCKDOWN_TIMER'
}

stop_lockdown_timer() {
  send_signal "$SIGNAL_STOP" "$timer_pid"
  # $debug echo 'stop lockdown timer'
}

capture_input() {
  send_signal "$SIGNAL_CAPTURE_INPUT" "$reader_pid"
  # $debug echo 'capture input'
}

release_input() {
  send_signal "$SIGNAL_RELEASE_INPUT" "$reader_pid"
  # $debug echo 'release input'
}

terminate_process() {
  send_signal "$SIGNAL_CONT" "$@" 2>/dev/null
  send_signal "$SIGNAL_TERM" "$@" 2>/dev/null
  $debug echo 'terminate process:' "$@"
}

# return random value (0 ~ 4294967295)
# using /dev/urandom as random seed.
# Although /dev/urandom is not defined in POSIX,
# it is enough for almost shell environment (maybe).
# (if not, considering to use `ps` as seed)
rand() {
  od -A n -t u4 -N 4 /dev/urandom | sed 's/[^0-9]//g; s/^0*//'
}

# Generate next random value
#
# Using xorshift32 to generate random number.
# xorshit32 are a class of pseudorandom number generators.
#
# It is the recommendation of the authors of the xoshiro
# paper to initialize the state of the generators using
# a generator which is radically different from the initialized
# generators, as well as one which will never give the
# "all-zero" state; for shift-register generators,
# this state is impossible to escape from.
#
# about xorshift32:
#   * <https://en.wikipedia.org/wiki/Xorshift>
#
# Arguments:
#   1 - varname
randnext() {
  # RAND_VALUE: 32-bit (possibly signed) integer excluding 0.
  #   the sign is implementation-dependent (e.g. mksh is signed 32-bit integer).
  eval "$1=$(( $1 ^ (($1 << 13) & 4294967295) ))" # 4294967295 (0x FFFF FFFF)
  eval "$1=$(( $1 ^ (($1 >> 17) & 131071) ))"     # 131071     (0x 0001 FFFF)
  eval "$1=$(( $1 ^ (($1  << 5) & 4294967295) ))" # 4294967295 (0x FFFF FFFF)
}

# Shuffle args
#
# Using Fisher-Yates shuffle.
# details:
#   * <https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle>
#
# Arguments:
#   1    - varname to be written shuffled args
#   2    - current random value
#   3... - args to be shuffled.
shuffle() {
  local varname="$1" random_value="$2" random_shift=0 shuffled=''

  shift 2 # shift to target args.

  # pick up one arg randomly and push it into 'shuffled'.
  while [ $# -gt 1 ]; do
    # get random shift (0 ~ len-1) to select arg randomly.
    randnext "$random_value"
    random_shift=$(( $random_value % $# ))

    random_shift=${random_shift#-}          # take the absolute value
    while [ $random_shift -gt 0 ]; do       # rotate args until selected arg comes up at head.
      set -- "$@" "$1"; shift               # push first arg
      random_shift=$(( random_shift - 1 ))  # pop first arg
    done

    shuffled="${shuffled}${1} " # push selected arg

    shift # next selection
  done

  eval "$varname=\${shuffled}\${1}" # set result
}

reset_level() {
  level=0 goal=0 lines_completed=0
  while [ "$level" -lt "$starting_level" ]; do
    increment_level
  done
  # send reset level signal to ticker (please see ticker for more details)
  send_signal "$SIGNAL_RESET_LEVEL" "$ticker_pid"
}

level_up() {
  increment_level
  # send level-up signal to ticker (please see ticker for more details)
  [ "$level" -lt "$LEVEL_MAX" ] && {
    send_signal "$SIGNAL_LEVEL_UP" "$ticker_pid"
  }
}

increment_level() {
  level=$((level + 1))                            # increment level
  goal=$((goal + level * adding_lines_per_level)) # adding an additional lines to the Goal
}

fill_bag() {
  shuffle bag bag_random $O_TETRIMINO $I_TETRIMINO $T_TETRIMINO $L_TETRIMINO $J_TETRIMINO $S_TETRIMINO $Z_TETRIMINO
}

#  the Tetrimino at the front of the line in the bag is placed at the end of the Next Queue
feed_next_queue() {
  [ -z "$bag" ] && fill_bag   # if bag is empty, then fill the bag.
  set -- $bag
  next_queue="$next_queue $1" # place tetrimino at the end of the Next Queue
  shift; bag="$*"             # pop the tetrimino
}

get_next() {
  set -- $next_queue

  # next piece becomes current
  # place current at the top of play field.
  generate_tetrimino "$1" # peek the next piece

  # check if piece can be placed at this location, if not - game over
  new_piece_location_ok $current_piece_x $current_piece_y || gameover
  show_current

  # now let's shift next queue
  clear_next
  shift; next_queue="$*" # pop the next piece from the front of queue
  feed_next_queue        # push tetrimino into queue; keep queue size
  show_next
}

hold_tetrimino() {
  #  Between Holds, A Lock Down must take place. reset this flag in move_piece().
  "$already_hold" && return
  already_hold=true

  clear_current
  clear_ghost

  # if hold queue is empty,
  [ -z "$hold_queue" ] && {
    hold_queue="$current_piece" # hold current tetrimino
    get_next                    # the Next Tetrimino is generated from the Next Queue and begins to fall
    show_hold
    return
  }
  clear_hold

  # swap piece
  held_piece="$hold_queue"
  hold_queue="$current_piece"

  generate_tetrimino "$held_piece"
  show_hold
}

# generate tetrimino in play field
# Arguments:
#   1 - tetrimino to generate
generate_tetrimino() {
  # $debug echo "generate"
  current_piece="$1"

  # beginning from its generation position and North Facing orientation.
  current_piece_rotation="$NORTH"
  current_piece_x=$START_X
  current_piece_y=$((START_Y + 1)) # so that update_location() can process the update correctly
  lowest_line=$current_piece_y     # ...
  lands_on=false                   # ...
  update_location $START_X $START_Y false

  current_tspin=$ACTION_NONE
  show_ghost
}

# Arguments:
#   1 - x
#   2 - y
#   3 - rotation
#   4 - rotation point
what_type_tspin() {
  local pos_x="$1" pos_y="$2" rotation="$3" side=0 side_x=0 side_y=0 field_cell=-1

  # Rotation Point 5 is used to rotate the Tetrimino into the T-Slot.
  # Any further rotation will be considered a T-Spin, not a Mini T-Spin
  [ ${4:-0} -ge 5 ] && {
    return $ACTION_TSPIN
  }

  eval set -- \$T_TETRIMINO_"$rotation"_SIDES # 1: A; 2: B; 3: C; 4: D

  while [ $# -gt 0 ]; do
    side=$((side + 1))
    side_x=$1 side_y=$2
    side_x=$((pos_x + side_x)) side_y=$((pos_y - side_y))

    [ $side_x -lt 0 ]            ||
    [ $side_x -ge $PLAYFIELD_W ] ||
    [ $side_y -lt 0 ]            && {
      # touching wall
      eval is_touched_${side}=true
      shift 2; continue
    }

    field_cell=$((playfield_${side_y}_${side_x}))
    if [ $field_cell -ne "$EMPTY" ]; then
      eval is_touched_${side}=true
    else
      eval is_touched_${side}=false
    fi

    shift 2
  done

  # if Sides A and B + (C or D) are touching a Surface
  # considered a T-Spin
  $is_touched_3 || $is_touched_4 && $is_touched_1 && $is_touched_2 && {
    return $ACTION_TSPIN
  }

  # if Sides C and D + (A or B) are touching a Surface
  # considered a Mini T-Spin
  $is_touched_1 || $is_touched_2 && $is_touched_3 && $is_touched_4 && {
    return $ACTION_MINI_TSPIN
  }

  return $ACTION_NONE
}

# test if piece can be moved to new location
# Arguments:
#   1 - new x coordinate of the piece
#   2 - new y coordinate of the piece
new_piece_location_ok() {
  local x_test="$1" y_test="$2" x=0 y=0 field_cell=-1

  # set minos coordinates into parameters
  # $1 - x, $2 - y
  eval set -- \$piece_"$current_piece"_minos_"$current_piece_rotation"

  # loop through tetrimino minos: 4 minos, each has 2 coordinates
  while [ $# -gt 0 ]; do
    x=$((x_test + $1)) # new x coordinate of piece cell
    y=$((y_test - $2)) # new y coordinate of piece cell

    [ "$y" -lt 0 ]              ||
    [ "$x" -lt 0 ]              ||
    [ "$x" -ge "$PLAYFIELD_W" ] && return 1 # false; check if we are out of the play field

    field_cell=$((playfield_${y}_${x}))
    [ "$field_cell" -ne "$EMPTY" ] && return 1 # false; check if location is already occupied

    shift 2 # shift to next minos coordinates
  done
  return 0
}

# this function updated occupied cells in playfield array after piece is dropped
flatten_playfield() {
  local x=0 y=0

  # set minos coordinates into parameters
  # $1 - x, $2 - y
  eval set -- \$piece_"$current_piece"_minos_"$current_piece_rotation"

  # loop through tetrimino minos: 4 minos, each has 2 coordinates
  while [ $# -gt 0 ]; do
    x=$((current_piece_x + $1))
    y=$((current_piece_y - $2))
    eval playfield_"$y"_"$x"="$current_piece"
    shift 2 # shift to next minos coordinates
  done
}

# check the line is completed
# Arguments:
#   1 - line y of playfield you want to check
is_line_completed() {
  local line_y="$1" x=0 field_cell=-1

  x=$((PLAYFIELD_W - 1))
  while [ "$x" -ge 0 ]; do
    field_cell=$((playfield_${line_y}_${x}))
    [ "$field_cell" -eq "$EMPTY" ] && return 1 # false
    x=$((x - 1))
  done

  return 0 # true
}

# This function checks if the lines in the hot zone are complete
# and fall the upper blocks down.
#
# Arguments:
#   1 - hot zone y min
#   2 - hot zone y max (inclusive)
# Globals:
#   completed_lines
#   perfect_clear
process_complete_lines() {
  local y="$1" yi="$2" x=0 field_cell=-1

  completed_lines='' perfect_clear=false
  [ $y -lt 0 ] && y=0

  while [ "$y" -le "$yi" ]; do
    is_line_completed "$y" && completed_lines="$completed_lines $y"
    y=$((y + 1))
  done

  set -- $completed_lines

  [ $# -eq 0 ] && return # no line clear

  [ $1 -eq 0 ] && perfect_clear=true

  # move lines down. move cells from y to yi
  y=$1; shift; yi=$y
  while [ "$y" -lt "$BUFFER_ZONE_Y" ]; do
    y=$((y + 1))
    [ "${1:-}" = "$y" ] && {
      shift # line y is completed.
      continue
    }

    # move line y to y1
    x=$((PLAYFIELD_W - 1))
    while [ "$x" -ge 0 ]; do
      field_cell=$((playfield_${y}_${x}))
      eval playfield_"$yi"_"$x"=\"$field_cell\"
      [ $field_cell -ne $EMPTY ] && perfect_clear=false
      x=$((x - 1))
    done
    yi=$((yi + 1))
  done

  # now let's mark lines from line yi to top line of the playfield as free.
  free_playfield "$yi"
}

# Arguments:
#   1 - number of cleared lines
what_action() {
  local action="$ACTION_NONE"

  case $1 in
    1) action="$ACTION_SINGLE" ;;
    2) action="$ACTION_DOUBLE" ;;
    3) action="$ACTION_TRIPLE" ;;
    4) action="$ACTION_TETRIS" ;;
  esac

  [ $current_piece -eq $T_TETRIMINO ] && {
    case $current_tspin in
      $ACTION_TSPIN)
        case $action in
          $ACTION_SINGLE) action=$ACTION_TSPIN_SINGLE ;;
          $ACTION_DOUBLE) action=$ACTION_TSPIN_DOUBLE ;;
          $ACTION_TRIPLE) action=$ACTION_TSPIN_TRIPLE ;;
          $ACTION_NONE)   action=$ACTION_TSPIN        ;;
          *) echo "invalid tspin action: $action" >&2 ;;
        esac
        ;;
      $ACTION_MINI_TSPIN)
        case $action in
          $ACTION_SINGLE) action=$ACTION_MINI_TSPIN_SINGLE ;;
          $ACTION_DOUBLE) action=$ACTION_MINI_TSPIN_DOUBLE ;;
          $ACTION_NONE)   action=$ACTION_MINI_TSPIN        ;;
          *) echo "invalid mini-tspin action: $action" >&2 ;;
        esac
        ;;
    esac
  }
  return "$action"
}

process_fallen_piece() {
  local action=''

  $perfect_clear && clear_perfect_clear
  flatten_playfield

  # There should be a line clear between current_y - 4 ~ current_y
  process_complete_lines $((current_piece_y - 4)) $current_piece_y
  set -- $completed_lines
  what_action $#; action=$?

  update_score_on_completion "$action" "$perfect_clear" && {
    draw_action true # if last_actions changed, perform flash effect
  }

  # flash piece effect
  flash_current
  flush_screen
  sleep 0.03

  show_current
  draw_action false
  flush_screen

  [ "$action" -eq $ACTION_NONE ]       ||
  [ "$action" -eq $ACTION_MINI_TSPIN ] ||
  [ "$action" -eq $ACTION_TSPIN ]      && return

  release_input
  beep

  $perfect_clear && flash_perfect_clear
  flash_line "$@"
  flush_screen
  sleep 0.045

  $perfect_clear && draw_perfect_clear
  clear_line "$@"
  flush_screen
  sleep 0.5

  capture_input
  redraw_playfield
  $perfect_clear && draw_perfect_clear # Keep showing it for a while.
}

draw_scoreboard() {
  set_style bold
  set_color "$SCORE_COLOR"
  xyprint "$SCORE_X" "$SCORE_Y"       "│SCORE:"
  xyprint "$SCORE_X" $((SCORE_Y + 1)) "│"
  xyprint "$SCORE_X" $((SCORE_Y + 2)) "│"
  xyprint "$SCORE_X" $((SCORE_Y + 3)) "│LINES"
  xyprint "$SCORE_X" $((SCORE_Y + 4)) "│LEVEL"
  xyprint "$SCORE_X" $((SCORE_Y + 5)) "│GOAL"
  reset_colors
}

# update score while falling phase
# Arguments:
#   1 - drop action name. ACTION_SOFT_DROP or ACTION_HARD_DROP
#   2 - (ACTION_HARD_DROP) lines
update_score_on_drop() {
  local factor=0 score_to_add=0

  eval factor=\"\$SCORE_FACTOR_"$1"\"

  case "$1" in
    "$ACTION_SOFT_DROP") score_to_add=$factor ;;
    "$ACTION_HARD_DROP") score_to_add=$((factor * $2)) ;;
    *) echo "update_score_on_drop: invalid action($1) given" >&2 ;;
  esac

  score=$((score + score_to_add))

  # It is enough to update the score
  set_style bold
  set_color "$SCORE_COLOR"
  xyprint $((SCORE_X + 1)) $((SCORE_Y + 1)) "$score"
  reset_colors
}

# update score on completion phase
# Arguments:
#   1 - ACTION name. ex: ACTION_SINGLE
# Returns:
#   0 if actions updated, 1 not
update_score_on_completion() {
  local factor=0 score_to_add=0 lines_to_add=0 action_updated=1 new_combo_counter=$combo_counter

  eval factor=\"\$SCORE_FACTOR_"$1"\"

  # A Back-to-Back sequence is only broken by a Single, Double, or Triple Line Clear.
  # Locking down a Tetrimino without clearing a line or holding a Tetrimino does not
  # break the Back-to-Back sequence.
  case "$1" in
    "$ACTION_SINGLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      b2b_sequence_continues=false
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Single:'; action_updated=0
      ;;
    "$ACTION_DOUBLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      b2b_sequence_continues=false
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Double:'; action_updated=0
      ;;
    "$ACTION_TRIPLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      b2b_sequence_continues=false
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Triple:'; action_updated=0
      ;;
    "$ACTION_TETRIS")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Tetris:'; action_updated=0
      ;;
    "$ACTION_MINI_TSPIN")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=-1
      last_actions='::Mini T-Spin:'; action_updated=0
      ;;
    "$ACTION_MINI_TSPIN_SINGLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Mini T-Spin: Single'; action_updated=0
      ;;
    "$ACTION_MINI_TSPIN_DOUBLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::Mini T-Spin: Double'; action_updated=0
      ;;
    "$ACTION_TSPIN")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=-1
      last_actions='::T-Spin:'; action_updated=0
      ;;
    "$ACTION_TSPIN_SINGLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::T-Spin: Single'; action_updated=0
      ;;
    "$ACTION_TSPIN_DOUBLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::T-Spin: Double'; action_updated=0
      ;;
    "$ACTION_TSPIN_TRIPLE")
      score_to_add=$((level * factor)) # Awarded Line Clears
      lines_to_add=$((factor / 100))
      new_combo_counter=$((combo_counter + 1))
      last_actions='::T-Spin: Triple'; action_updated=0
      ;;
    "$ACTION_NONE")
      new_combo_counter=-1
      ;;
    *) echo "update_score_on_completion: invalid action($1) given" >&2 ;;
  esac

  # Awarded Back-to-Back Bonus
  # start a Back-to-Back sequence after Awarded b2b bonus
  # The first Line Clear in the Back-to-Back sequence does not receive the Back-to-Back
  # Bonus. Only consecutive qualifying Back-to-Back Line Clears after the first in the sequence
  # receive the Back-to-Back Bonus.
  case $1 in
    "$ACTION_TETRIS"|\
    "$ACTION_TSPIN_SINGLE"|"$ACTION_TSPIN_DOUBLE"|"$ACTION_TSPIN_TRIPLE"|\
    "$ACTION_MINI_TSPIN_SINGLE")
      $b2b_sequence_continues && {
        score_to_add=$((score_to_add + score_to_add / 2))
        lines_to_add=$((lines_to_add + lines_to_add / 2))
        last_actions="$last_actions::Back-to-Back"; action_updated=0
      }
      b2b_sequence_continues=true;;
  esac

  $perfect_clear && {
    case $1 in
      "$ACTION_SINGLE")
        score_to_add=$((score_to_add + SCORE_FACTOR_SINGLE_LINE_PERFECT_CLEAR * level))
      ;;
      "$ACTION_DOUBLE"|"$ACTION_MINI_TSPIN_DOUBLE"|"$ACTION_TSPIN_DOUBLE")
        score_to_add=$((score_to_add + SCORE_FACTOR_DOUBLE_LINE_PERFECT_CLEAR * level))
      ;;
      "$ACTION_TRIPLE"|"$ACTION_TSPIN_TRIPLE")
        score_to_add=$((score_to_add + SCORE_FACTOR_TRIPLE_LINE_PERFECT_CLEAR * level))
      ;;
      "$ACTION_TETRIS")
        score_to_add=$((score_to_add + SCORE_FACTOR_TETRIS_PERFECT_CLEAR * level))
      ;;
    esac
  }


  [ "$new_combo_counter" -ne "$combo_counter" ] && {
    combo_counter=$new_combo_counter

    last_actions=${last_actions#*:} # pop first line

    [ $combo_counter -gt 0 ] && {
      # Combo Bonus
      score_to_add=$((score_to_add + SCORE_FACTOR_COMBO * combo_counter * level))
      last_actions="$combo_counter REN:$last_actions"
    } || {
      last_actions=":$last_actions" # clear REN
    }
  }

  score=$((score + score_to_add))
  lines_completed=$((lines_completed + lines_to_add))

  [ "$lines_completed" -ge "$goal" ] && level_up

  draw_score

  return $action_updated
}

draw_score() {
  set_style bold
  set_color "$SCORE_COLOR"
  xyprint $((SCORE_X + 1)) $((SCORE_Y + 1)) "$score"
  str_lpad text "$lines_completed" 4
  xyprint $((SCORE_X + 8)) $((SCORE_Y + 3)) "$text"
  str_lpad text "$level" 4
  xyprint $((SCORE_X + 8)) $((SCORE_Y + 4)) "$text"
  str_lpad text "$goal" 4
  xyprint $((SCORE_X + 8)) $((SCORE_Y + 5)) "$text"
  reset_colors
}

# Arguments:
#   1 - flash. true or false
draw_action() {
  local flash="$1" i=0 text=''

  set_style bold
  set_color "$SCORE_COLOR"

  IFS_SAVE=$IFS; IFS=:
  set -- $last_actions
  IFS=$IFS_SAVE

  # We should clear at least 6 lines (see last_actions).
  i=7
  for text in "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"; do
    $flash && str_repeat text '█' ${#text}
    str_rpad text " $text" 13 # max width 13 ' Back-to-Back'
    xyprint "$SCORE_X" $((SCORE_Y + i)) "$text"
    i=$((i + 1))
  done

  reset_colors
}

# Arguments:
#   1 - new x
#   2 - new y
#   3 - rotation changed (true or false)
update_location() {
  local lowest=0

  lowest=$(($2 - piece_${current_piece}_lowest_${current_piece_rotation}))
  [ $lowest -lt $lowest_line ] && {
    # when the tetromino drops below the lowest line
    # $debug echo "lowest line" $lowest

    manipulation_counter=0 # reset manipulation counter
    lock_phase=false       # exit lock phase
    lowest_line=$lowest    # update lowest_line y
  }

  # Clear the "perfect clear" when a piece is close to it.
  $perfect_clear && [ $(($2 - 4)) -lt $((PLAYFIELD_H / 2)) ] && {
    perfect_clear=false
    clear_perfect_clear
  }

  #test lands on
  if ! new_piece_location_ok "$1" $(($2 - 1)); then
    if $3 || ! $lands_on; then
      # $debug echo "lands on"
      lands_on=true
      if ! $lock_phase; then
        # start lock Phase
        wakeup_lockdown_timer
        restart_lockdown_timer
        lock_phase=true
      else
        # already in Lock Phase
        wakeup_lockdown_timer
      fi

      # Once these movements/rotations have been used, the Lock Down
      # Timer will not be reset and the Tetrimino will Lock Down immediately on the first Surface it
      # touches.
      can_maniqulate || lockdown
    fi
  else
    $lands_on && { # currently not lands on but previously lands on - lifts up
      # $debug echo 'lifts up'
      stop_lockdown_timer
    }
    lands_on=false
  fi

  current_piece_x="$1"
  current_piece_y="$2"
}

# this function called when player manipulate tetrimino.
on_manipulation() {
  case $lockdown_rule in
    $LOCKDOWN_RULE_INFINITE)
      $lock_phase && {
        # when the tetromino moves or rotates, the lockdown timer is reset
        restart_lockdown_timer
      }
      ;;
    $LOCKDOWN_RULE_EXTENDED)
      [ $manipulation_counter -lt $LOCKDOWN_ALLOWED_MANIPULATIONS ] && {
        manipulation_counter=$((manipulation_counter + 1))
        # $debug echo "mc: $manipulation_counter" # For Debugging. to check counter
        [ $manipulation_counter -eq $LOCKDOWN_ALLOWED_MANIPULATIONS ] && {
          # last manipulation
          lockdown # if possible
        } || {
          $lock_phase && {
            # when the tetromino moves or rotates, the lockdown timer is reset
            restart_lockdown_timer
          }
        }
      }
      ;;
  esac
}

can_maniqulate() {
  case $lockdown_rule in
    $LOCKDOWN_RULE_EXTENDED)
      [ $manipulation_counter -ge $LOCKDOWN_ALLOWED_MANIPULATIONS ] && return 1 # false
      ;;
  esac
  return 0
}

# moves the piece to the new location if possible
# Arguments:
#   1 - new x coordinate
#   2 - new y coordinate
# Returns:
#   can move piece
move_piece() {
  if new_piece_location_ok "$1" "$2"; then # if new location is ok
    clear_current                          # let's wipe out piece current location
    update_location $1 $2 false            # update location
    update_ghost                           # update ghost with new pose of current piece
    show_current                           # and draw piece in new location
    return 0                               # nothing more to do here
  fi                                       # if we could not move piece to new location

  return 1
}

# Check a whole Tetrimino is above the Skyline. if yes - Game Over
# Returns:
#   0 - yes
#   1 - no
test_lockout() {
  eval set -- \$piece_"$current_piece"_minos_"$current_piece_rotation"

  while [ $# -gt 0 ]; do
    [ $((current_piece_y - $2)) -lt $PLAYFIELD_H ] && return 1
    shift 2 # shift to next minos coordinates
  done
  return 0
}

lockdown() {
  $lock_phase || {
    # $debug echo 'not lock_phase'
    return
  }

  # if can fall, dont lock down
  new_piece_location_ok "$current_piece_x" $((current_piece_y - 1)) && {
    # $debug echo 'can fall'
    return
  }

  # $debug echo 'lockdown'

  lock_phase=false # exit lock Phase, then start Pattern Phase

  # stop sub process until next the Generation Phase of the Next Tetrimino.
  stop_ticker
  stop_lockdown_timer

  process_fallen_piece # let's finalize this piece

  test_lockout && { # a whole Tetrimino Locks Down above the Skyline - Game Over
    # now lets sub process continue...
    gameover; return # ... Quit
  }

  get_next # and start the new one
  if "$already_hold"; then
    already_hold=false # player can hold the falling tetrimino.
    show_hold
  fi

  # now lets sub process continue...
  wakeup_ticker
}

pause() {
  if "$pause"; then
    release_input
    ready
    capture_input

    redraw_playfield
    show_ghost
    show_current
    show_next
    show_hold
    pause=false
    wakeup_ticker
    $lock_phase && wakeup_lockdown_timer
    return
  fi

  stop_ticker
  $lock_phase && stop_lockdown_timer
  draw_pause
  clear_next
  clear_hold
  pause=true
}

# Arguments:
#   1 - rotation direction; 1: clockwise; -1: counter-clockwise
rotate_piece_classic() {
  local direction="$1" old_rotation=0 new_rotation=0

  old_rotation=$current_piece_rotation                             # preserve current orientation
  new_rotation=$((old_rotation + direction + 4))
  new_rotation=$((new_rotation % 4))                               # calculate new orientation
  current_piece_rotation=$new_rotation                             # set orientation to new
  if new_piece_location_ok $current_piece_x $current_piece_y; then # check if new orientation is ok
    [ $current_piece -eq $T_TETRIMINO ] && {
      what_type_tspin $current_piece_x $current_piece_y $new_rotation; current_tspin=$?
    }
    current_piece_rotation=$old_rotation                           # if yes - restore old rotation ...
    clear_current                                                  # ... clear piece image
    current_piece_rotation=$new_rotation                           # ... set new orientation
    update_ghost
    show_current                                                   # ... draw piece with new orientation
    return 0
  fi
  # if new orientation is not ok
  current_piece_rotation=$old_rotation # restore old orientation
  return 1
}

# Arguments:
#   1 - rotation direction; 1: clockwise; -1: counter-clockwise
rotate_piece_super() {
  local direction="$1" old_rotation=0 new_rotation=0 new_x=0 new_y=0 rpoint=0

  old_rotation=$current_piece_rotation # preserve current orientation

  new_rotation=$((old_rotation + direction + 4)) #
  new_rotation=$((new_rotation % 4))             # calculate new orientation

  current_piece_rotation=$new_rotation

  # test each rotation point. Each Tetrimino has five possible rotation points.
  eval set -- \$piece_${current_piece}_rshifts_${old_rotation}
  # now parameters setted like below
  # '<POINT1> <POINT2> <POINT3> <POINT4> <POINT5>'
  #   <POINT<NO>>: '<LEFT_SHIFT_X> <LEFT_SHIFT_Y> <RIGHT_SHIFT_X> <RIGHT_SHIFT_Y>'
  [ $direction -eq 1 ] && shift 2 # if rotate clockwise(RIGHT) shift 2 to next xy-coordinates of RIGHT
  while [ $# -gt 0 ]; do
    rpoint=$((rpoint + 1))
    [ $1 = 'n' ] && {        # if 'not used' appears, skip this point
      [ $# -lt 4 ] && break;
      shift 4; continue;
    }

    new_x=$((current_piece_x + $1)) # 1: shift x
    new_y=$((current_piece_y + $2)) # 2: shift y
    if new_piece_location_ok $new_x $new_y; then # check if new orientation is ok
      [ $current_piece -eq $T_TETRIMINO ] && {
        what_type_tspin $new_x $new_y $new_rotation $rpoint; current_tspin=$?
      }
      current_piece_rotation=$old_rotation       # if yes - restore old rotation ...
      clear_current                              # ... clear piece image
      current_piece_rotation=$new_rotation       # ... set new orientation
      update_location $new_x $new_y true         # ... set new location
      update_ghost
      show_current                               # ... draw piece with new pose
      return 0                                   # nothing to do more here
    fi

    [ $# -lt 4 ] && break;
    shift 4 # test next rotation point
  done

  # if new orientation is not ok
  current_piece_rotation=$old_rotation # restore old orientation
  return 1
}

move_right() {
  can_maniqulate || return
  move_piece $((current_piece_x + 1)) "$current_piece_y" && on_manipulation
}

move_left() {
  can_maniqulate || return
  move_piece $((current_piece_x - 1)) "$current_piece_y" && on_manipulation
}

rotate_cw() {
  can_maniqulate || return
  $rotate_piece_func 1 && on_manipulation
}

rotate_ccw() {
  can_maniqulate || return
  $rotate_piece_func -1 && on_manipulation
}

fall() {
  move_piece "$current_piece_x" $((current_piece_y - 1))
}

soft_drop() {
  move_piece "$current_piece_x" $((current_piece_y - 1)) && {
    update_score_on_drop "$ACTION_SOFT_DROP"
  }
}

# Arguments:
#   1 - x
#   2 - y
# Returns:
#   steps. 0 - no space to fall.
test_hard_drop() {
  local steps=1

  while new_piece_location_ok $1 $(($2 - steps)); do
    steps=$((steps + 1))
  done
  return $((steps - 1)) # return value must be within 0 ~ 255
}

hard_drop() {
  local steps=0

  # move piece all way down
  test_hard_drop $current_piece_x $current_piece_y; steps=$?

  update_score_on_drop "$ACTION_HARD_DROP" $steps
  move_piece $current_piece_x $((current_piece_y - steps))
  lockdown # A Tetrimino that is Hard Dropped Locks Down immediately
}

hold() {
  hold_tetrimino
}

# playfield is 2-dimensional array, data is stored as follows:
# a_{y,x}
#   x - 0, ..., (PLAYFIELD_W-1)
#   y - 0, ..., (PLAYFIELD_H-1), ..., (START_Y-1)
# each array element contains tetrimino type or empty cell
redraw_playfield() {
  local x=0 y=0 yp=0 field_cell=-1

  while [ "$y" -lt "$PLAYFIELD_H" ]; do
    yp=$((PLAYFIELD_Y + PLAYFIELD_H - y - 1))
    xyprint "$PLAYFIELD_X" "$yp" # put the cursor on the front of line
    x=0
    while [ "$x" -lt "$PLAYFIELD_W" ]; do
      if [ "$field_cell" -ne $((playfield_${y}_${x})) ]; then
        field_cell=$((playfield_${y}_${x}))
        set_piece_color "$field_cell"
      fi
      if [ "$field_cell" -eq "$EMPTY" ]; then
        puts "$EMPTY_CELL"
      else
        puts "$FILLED_CELL"
      fi
      x=$((x + 1))
    done
    y=$((y + 1))
  done
  reset_colors
}

# Arguments:
#   1 - x
#   2 - y
#   3 - type
#   4 - rotation
#   5 - cell content
draw_piece() {
  local posx="$1" posy="$2" type="$3" rotation="$4" content="$5"

  # set minos coordinates.
  eval set -- \$piece_"$type"_minos_"$rotation"

  # loop through tetrimino minos: 4 minos, each has 2 coordinates
  while [ $# -gt 0 ]; do
    # relative coordinates are retrieved based on orientation and added to absolute coordinates
    # the width of cell is 2 characters thick
    xyprint $((posx + $1 * 2)) $((posy + $2)) "$content"
    shift 2
  done
}

# Arguments:
#   1 - x
#   2 - y
#   3 - type
#   4 - rotation
#   5 - cell content
draw_playfield_piece() {
  local posx="$1" posy="$2" type="$3" rotation="$4" content="$5" x=0 y=0

  # set minos coordinates.
  eval set -- \$piece_"$type"_minos_"$rotation"

  # loop through tetrimino minos: 4 minos, each has 2 coordinates
  while [ $# -gt 0 ]; do
    # relative coordinates are retrieved based on orientation and added to absolute coordinates
    x=$((posx + $1))
    y=$((PLAYFIELD_H - 1 - posy + $2))

    [ "$y" -ge 0 ]              &&
    [ "$y" -lt "$PLAYFIELD_H" ] &&
    [ "$x" -ge 0 ]              &&
    [ "$x" -lt "$PLAYFIELD_W" ] && {
      # the width of cell is 2 characters thick
      xyprint $((PLAYFIELD_X + x * 2)) $((PLAYFIELD_Y + y)) "$content"
    }

    shift 2
  done
}

show_current() {
  set_piece_color "$current_piece"
  draw_playfield_piece $current_piece_x $current_piece_y $current_piece $current_piece_rotation "$FILLED_CELL"
  reset_colors
}

flash_current() {
  set_style reverse
  set_color "$FLASH_COLOR"
  draw_playfield_piece $current_piece_x $current_piece_y $current_piece $current_piece_rotation "$DRY_CELL"
  reset_colors
}

clear_current() {
  draw_playfield_piece $current_piece_x $current_piece_y $current_piece $current_piece_rotation "$EMPTY_CELL"
}

# Update ghost piece with new location according to current piece.
show_ghost() {
  if [ $# -gt 0 ]; then
    ghost_piece_y=$1
  else
    test_hard_drop $current_piece_x $current_piece_y
    ghost_piece_y=$((current_piece_y - $?))
  fi
  ghost_piece=$current_piece
  ghost_piece_x=$current_piece_x
  ghost_piece_rotation=$current_piece_rotation

  set_ghost_color "$current_piece"
  draw_playfield_piece $ghost_piece_x $ghost_piece_y $ghost_piece $ghost_piece_rotation "$GHOST_CELL"
  reset_colors
}

clear_ghost() {
  ${ghost_piece+:} return

  draw_playfield_piece $ghost_piece_x $ghost_piece_y $ghost_piece $ghost_piece_rotation "$EMPTY_CELL"
}

update_ghost() {
  local new_ghost_piece_y=0

  test_hard_drop $current_piece_x $current_piece_y
  new_ghost_piece_y=$((current_piece_y - $?))

  [ "$ghost_piece_x" -eq "$current_piece_x" ]               &&
  [ "$ghost_piece_y" -eq "$new_ghost_piece_y" ]             &&
  [ "$ghost_piece" -eq "$current_piece" ]                   &&
  [ "$ghost_piece_rotation" -eq "$current_piece_rotation" ] && return

  clear_ghost
  show_ghost "$new_ghost_piece_y"
}

flash_line() {
  local line=''

  set_style reverse underline
  set_color "$FLASH_COLOR"
  str_repeat line "$DRY_CELL" $PLAYFIELD_W
  while [ $# -gt 0 ]; do
    xyprint "$PLAYFIELD_X" $((PLAYFIELD_Y + PLAYFIELD_H - 1 - $1)) "$line"
    shift
  done
  reset_colors
}

clear_line() {
  local line=''

  set_piece_color "$EMPTY"
  str_repeat line "$EMPTY_CELL" $PLAYFIELD_W
  while [ $# -gt 0 ]; do
    xyprint "$PLAYFIELD_X" $((PLAYFIELD_Y + PLAYFIELD_H - 1 - $1)) "$line"
    shift
  done
  reset_colors
}

show_next() {
  local next_y="$NEXT_Y"

  set -- $next_queue

  while [ $# -gt 0 ]; do
    set_piece_color "$1"
    draw_piece "$NEXT_X" "$next_y" "$1" "$NORTH" "$FILLED_CELL"
    shift
    next_y=$((next_y + 3))
  done
  reset_colors
}

clear_next() {
  local next_y="$NEXT_Y"

  set -- $next_queue

  while [ $# -gt 0 ]; do
    draw_piece "$NEXT_X" "$next_y" "$1" "$NORTH" '  '
    shift
    next_y=$((next_y + 3))
  done
}

show_hold() {
  [ -z "$hold_queue" ] && return
  if "$already_hold"; then
    set_color "$HOLD_COLOR"
    draw_piece $((HOLD_X)) $((HOLD_Y)) $hold_queue "$NORTH" "$INACTIVE_CELL"
  else
    set_piece_color "$hold_queue"
    draw_piece $((HOLD_X)) $((HOLD_Y)) $hold_queue "$NORTH" "$FILLED_CELL"
  fi
  reset_colors
}

clear_hold() {
  [ -z "$hold_queue" ] && return
  draw_piece $((HOLD_X)) $((HOLD_Y)) $hold_queue "$NORTH" '  '
}

draw_border() {
  local x1=0 x2=0 y1=0 y2=0 i=0 x=0 y=0

  set_style bold
  set_color "$BORDER_COLOR"

  x1=$((PLAYFIELD_X - 1))               # 1 here is because border is 1 characters thick
  x2=$((PLAYFIELD_X + PLAYFIELD_W * 2)) # 2 here is because each cell on play field is 2 characters wide
  y1=$((PLAYFIELD_Y - 1))
  y2=$((PLAYFIELD_Y + PLAYFIELD_H))

  i=0
  while [ "$i" -lt "$PLAYFIELD_H" ]; do
    y=$((i + PLAYFIELD_Y))
    xyprint $x1 $y "│"
    xyprint $x2 $y "│"
    i=$((i + 1))
  done

  i=0
  while [ "$i" -lt "$PLAYFIELD_W" ]; do
    x=$((i * 2 + PLAYFIELD_X)) # 2 here is because each cell on play field is 2 characters width
    xyprint $x $y1 '──'
    xyprint $x $y2 '──'
    i=$((i + 1))
  done

  xyprint $x1 $y1 "┌"; xyprint $x2 $y1 "┐" # draw the corners
  xyprint $x1 $y2 "└"; xyprint $x2 $y2 "┘"

  reset_colors
}

draw_help() {
  local help_x="$HELP_X" help_y="$HELP_Y" line=''

  set_style bold
  set_color "$HELP_COLOR"

  IFS_SAVE=$IFS; IFS=$LF
  set -- $HELP
  IFS=$IFS_SAVE

  for line in "$@"; do
    "$help_on" || str_repeat line " " ${#line}
    xyprint "$help_x" "$help_y" "$line"
    help_y=$((help_y + 1))
  done
  reset_colors
}

draw_pause() {
  local y=0 line=''

  str_repeat line "  " "$PLAYFIELD_W"
  while [ "$y" -lt "$PLAYFIELD_H" ]; do
    xyprint "$PLAYFIELD_X" $((PLAYFIELD_Y + y)) "$line"
    y=$((y + 1))
  done

  set_style bold
  xyprint $((CENTER_X - 3)) $CENTER_Y 'PAUSE'
  reset_colors
}

flash_perfect_clear() {
  set_style reverse
  draw_perfect_clear
}

draw_perfect_clear() {
  set_style bold
  xyprint $((CENTER_X - 3)) "$CENTER_Y"       'PERFECT'
  xyprint $((CENTER_X - 2)) $((CENTER_Y + 1))  'CLEAR'
  reset_colors
}

clear_perfect_clear() {
  local line=''
  str_repeat line "$EMPTY_CELL" "$PLAYFIELD_W"
  xyprint "$PLAYFIELD_X" "$CENTER_Y"       "$line"
  xyprint "$PLAYFIELD_X" $((CENTER_Y + 1)) "$line"
}

refresh_screen() {
  clear_screen
  redraw_screen
}

redraw_screen() {
  draw_help # should first. draw help on the lowest layer
  show_next
  show_hold
  draw_scoreboard
  draw_score
  draw_action false
  draw_border
  redraw_playfield
  [ ${current_piece:-} ] && {
    # There is Tetrimino in Play
    show_ghost
    show_current
  }
}

toggle_help() {
  $help_on && help_on=false || help_on=true
  draw_help
}

toggle_beep() {
  $beep_on && beep_on=false || beep_on=true
  beep
}

toggle_color() {
  $no_color && no_color=false || no_color=true
  redraw_screen
}

gameover() {
  gameover=true
  quit
}

quit() {
  running=false # let's stop controller ...
  xyprint $((CENTER_X - 5)) $CENTER_Y 'Game Over!'
  flush_screen
}

init() {
  local x=0 y=0 i=0

  switch_color_theme "$theme"

  # Initialize random generator.
  [ $bag_random -eq 0 ] && {
    # if not set
    bag_random=$(rand 2>/dev/null)
    [ ${bag_random:-0} -eq 0 ] && bag_random=$(date +%s)
  }
  $debug echo "seed: $bag_random" # It is useful for reproducing the situation.

  # playfield is initialized with EMPTY (0)
  free_playfield

  # prepare next queue filled with NEXT_MAX tetrimino
  i=0
  while [ "$i" -lt "$NEXT_MAX" ]; do
    feed_next_queue
    i=$((i + 1))
  done

  # receive subprocess pids
  receive_pids

  # reset to starting level
  reset_level

  # now setup play screen
  clear_screen
  redraw_screen

  ready

  wakeup_ticker
  capture_input

  redraw_playfield
  get_next
  flush_screen
}

# Free playfield with EMPTY (0)
# Arguments:
#   1 - start of y
free_playfield() {
  local y=${1:-0} x=0

  # x of playfield - 0, ..., (PLAYFIELD_W-1)
  # y of playfield - 0, ..., (PLAYFIELD_H-1), ..., (START_Y), ..., (BUFFER_ZONE_Y)
  # (0, 0) is bottom left
  while [ "$y" -le "$BUFFER_ZONE_Y" ]; do
    x=0
    while [ "$x" -lt "$PLAYFIELD_W" ]; do
      eval playfield_"$y"_"$x"="$EMPTY"
      x=$((x + 1))
    done
    y=$((y + 1))
  done
}

receive_pids() {
  local cmd='' from='' pid=''

  get_pid pid
  $debug echo "controller pid: $pid"
  $debug echo 'Checking subprocess pid'
  while [ -z $ticker_pid ] || [ -z $timer_pid ] || [ -z $reader_pid ] || [ -z $inkey_pid ]; do
    read cmd from pid
    [ "$cmd" = "$NOTIFY_PID" ] || continue
    case $from in
      $PROCESS_TICKER) ticker_pid=$pid from='ticker' ;;
      $PROCESS_TIMER)  timer_pid=$pid  from='timer ' ;;
      $PROCESS_READER) reader_pid=$pid from='reader' ;;
      $PROCESS_INKEY)  inkey_pid=$pid  from='inkey ' ;;
      *) echo "invalid process number: $from" >&2; continue ;;
    esac
    $debug echo "> $from $pid ...OK"
  done
}

ready() {
  # show 'READY' for 1 second.
  xyprint $((CENTER_X - 3)) $CENTER_Y 'READY'
  flush_screen
  sleep 1

  # counting down 3 seconds
  i=3
  while [ $i -gt 0 ]; do
    xyprint $((CENTER_X - 1)) $((CENTER_Y + 1)) $i
    flush_screen
    sleep 1
    i=$((i - 1))
  done
}

# this function runs in separate process
lockdown_timer() {
  game_pid=$1
  trigger_counter=-1 # -1: already triggerd, 0: triggered, >0: count to trigger

  # on SIGTERM this process should exit
  trap exit $SIGNAL_TERM
  # on this signal reset the timer. lockdown 0.5~0.6(0.5 is correct) sec after receiving signal
  trap 'trigger_counter=5' $SIGNAL_RESTART_LOCKDOWN_TIMER

  get_pid my_pid
  send_cmd "$NOTIFY_PID $PROCESS_TIMER $my_pid"
  stop_at_start "$my_pid"

  while exist_process "$game_pid"; do
    sleep 0.1

    trigger_counter=$((trigger_counter >= 0 ? trigger_counter - 1 : trigger_counter))
    # $debug echo "trigger_counter: $trigger_counter"

    [ "$trigger_counter" -eq 0 ] && {
      # $debug echo "send_cmd: LOCKDOWN"
      send_cmd "$LOCKDOWN"
    }

    # The following code will cause an error ("Illegal instruction: 4") on macOS(bash 3.2.57).
    #   sleep 0.1 & # wait in background for receiving the signal
    #   wait $!
  done
}

# this function runs in separate process
# it sends FALL commands to controller with appropriate delay
ticker() {
  game_pid=$1 level=0

  # on SIGTERM this process should exit
  trap exit $SIGNAL_TERM
  # on this signal fall speed should be increased, this happens during level ups
  trap 'level=$((level + 1))' $SIGNAL_LEVEL_UP
  trap 'level=$starting_level' $SIGNAL_RESET_LEVEL

  get_pid my_pid
  send_cmd "$NOTIFY_PID $PROCESS_TICKER $my_pid"

  # wait for the level to reset, then stop
  while exist_process "$game_pid" && [ "$level" -eq 0 ]; do
    sleep 0.1
  done
  stop_at_start "$my_pid"

  # the game level, which levelup-signal counts up.
  while exist_process "$game_pid"; do
    eval sleep \"\$FALL_SPEED_LEVEL_$level\"

    # The following code will cause an error ("Illegal instruction: 4") on macOS(bash 3.2.57).
    #   eval sleep \"\$FALL_SPEED_LEVEL_$level\" &
    #   wait $!

    send_cmd "$FALL"

    # $debug echo "$level" # For debuging. check level variable
  done
}

# this function processes keyboard input
reader() {
  local game_pid="$1" my_pid='' inkey_pid='' key_sequence='' key='' capture=false

  # Output the error via FD3 to avoid the problem of FreeBSD sh outputting "Terminated" on exit.
  exec 3>&2 2>/dev/null

  {
    get_pid
    while dd ibs=1 count=1; do
      echo # insert a newline: convert one character to one line
    done 2>/dev/null
  } 2>&3 | { # Do not use '(' here
    # Do not use subshell to make it work correctly with Solaris 11 sh (ksh).
    # It will not respond to keystrokes.

    # this process exits on SIGTERM
    trap 'exit' $SIGNAL_TERM
    trap 'capture=true' $SIGNAL_CAPTURE_INPUT
    trap 'capture=false' $SIGNAL_RELEASE_INPUT

    read inkey_pid
    send_cmd "$NOTIFY_PID $PROCESS_INKEY $inkey_pid"

    get_pid my_pid
    send_cmd "$NOTIFY_PID $PROCESS_READER $my_pid"

    key_sequence='-------' # preserve previous 7 keys

    while exist_process "$game_pid"; do
      # There is a bug in bash < 4.3.0 that ignores temporary IFS assignments when signal is
      # received during read. Therefore, do not read and assign IFS at the same time here,
      # since the space immediately after the signal will be ignored.
      IFS_SAVE=$IFS; IFS=''
      # When a signal is received, the read command may be aborted with an error (e.g. 1 or USR1 + 256).
      read -r key || { IFS=$IFS_SAVE; continue; } # read one key
      IFS=$IFS_SAVE

      # echo "$key" >> $LOG # For debug to check input char.
      # printf '%s' "$key" | od -An -tx1 >> $LOG # For debug to check input char as hex value.

      # the key will be empty when you type enter
      key_sequence="${key_sequence#?}${key:-"$LF"}"

      "$capture" || continue

      case "$key_sequence" in
        # Ignore (incompleted) modifier + arrow keys
        *"${ESC}[1" | *"${ESC}[1;"[0-9] | *"${ESC}[1;"[0-9][A-D]) ;;
        *"${ESC}[1;"[0-9][0-9] | *"${ESC}[1;"[0-9][0-9][A-D]) ;;

        *[4]      | *"${ESC}[D") send_cmd "$LEFT"           ;; # Numpad 4, Left
        *[6]      | *"${ESC}[C") send_cmd "$RIGHT"          ;; # Numpad 6, Right
        *[x159]   | *"${ESC}[A") send_cmd "$ROTATE_CW"      ;; # x, Numpad 1 5 9, Up
        *[z37]                 ) send_cmd "$ROTATE_CCW"     ;; # z, Numpad 3, 7
        *[c0]                  ) send_cmd "$HOLD"           ;; # c, Numpad 0
        *[2]      | *"${ESC}[B") send_cmd "$SOFT_DROP"      ;; # Numpad 2, Down
        *[8${SP}]              ) send_cmd "$HARD_DROP"      ;; # Space Bar, Numpad 8
        *[${TAB}] | *"${ESC}OP") send_cmd "$PAUSE"          ;; # TAB, F1
        *[R]                   ) send_cmd "$REFRESH_SCREEN" ;; # R
        *[C]                   ) send_cmd "$TOGGLE_COLOR"   ;; # C
        *[B]                   ) send_cmd "$TOGGLE_BEEP"    ;; # B
        *[H]                   ) send_cmd "$TOGGLE_HELP"    ;; # H
        *[Q]  | *"${ESC}${ESC}") send_cmd "$QUIT"; break    ;; # Q, ESCx2
      esac
    done
  } 2>&3
}

# Even if the game is finished, dd is still waiting for input, so we need to find it and kill it.
killdd() {
  local parent_pid="$1" pid="" ppid="" comm=""
  ps -o pid= -o ppid= -o comm= 2>/dev/null | {
    while IFS="${SP}${TAB}" read -r pid ppid comm; do
      if [ "$ppid" = "$parent_pid" ] && [ "$comm" = "dd" ]; then
        $debug echo "kill dd: $pid"
        terminate_process "$pid"
      fi
    done
  }
}

controller() {
  local cmd='' ticker_pid='' timer_pid='' reader_pid='' inkey_pid=''

  # These signals are ignored
  trap '' $SIGNAL_TERM
  trap 'controller_interrupt' "$SIGNAL_INT"

  # initialization of commands array with appropriate functions
  eval commands_"$QUIT"=quit
  eval commands_"$RIGHT"=move_right
  eval commands_"$LEFT"=move_left
  eval commands_"$ROTATE_CW"=rotate_cw
  eval commands_"$ROTATE_CCW"=rotate_ccw
  eval commands_"$FALL"=fall
  eval commands_"$SOFT_DROP"=soft_drop
  eval commands_"$HARD_DROP"=hard_drop
  eval commands_"$HOLD"=hold
  eval commands_"$REFRESH_SCREEN"=refresh_screen
  eval commands_"$TOGGLE_BEEP"=toggle_beep
  eval commands_"$TOGGLE_COLOR"=toggle_color
  eval commands_"$TOGGLE_HELP"=toggle_help
  eval commands_"$LOCKDOWN"=lockdown
  eval commands_"$PAUSE"=pause

  init

  while $running; do           # run while this variable is true, it is changed to false in quit function
    read cmd                   # read next command from stdout
    "$pause" && [ "$cmd" -ne "$PAUSE" ] && continue
    eval "\"\$commands_$cmd\"" # run command
    flush_screen
  done

  terminate_process "$timer_pid" "$ticker_pid" "$reader_pid"
  killdd "$inkey_pid"

  "$gameover" && return 1
  return 0
}

controller_interrupt() {
  # The process that is being stopped does not terminate on WSL1
  terminate_process "$timer_pid" "$ticker_pid"
  exit 143
}

game() {
  # output of ticker, timer and reader is joined and piped into controller
  (
    ticker "$$"         & # runs as separate process
    lockdown_timer "$$" &
    reader "$$"
  ) | (
    controller
  )

  case $? in
      0) return ;; # When Q (ESCx2) is pressed, do nothing and return.
    143) return ;; # When CTRL-C is pressed, do nothing and return.
  esac

  # Prevent the input after the game over from being output to the terminal.
  printf "$EXIT_FORMAT" "Press enter to continue ..."
  read _
}

# Exit with error message and usage
# Arguments:
#   Error message
die_usage() {
  echo "$PROG: $1" 1>&2
  echo "$USAGE" 1>&2; exit 1
}

main() {
  rotate_piece_func=rotate_piece_super
  starting_level=1
  debug=false

  while [ $# -gt 0 ]; do
    case $1 in
      -d|--debug)
        debug="debug"
        shift; continue
        ;;
      -l|--level)
        [ $# -le 1 ] && { # if next arg not exists
          die_usage "option '$1' requires an argument"
        }

        { expr "$2" + 1 > /dev/null 2>&1; [ $? -gt 1 ]; } || # if not number
        [ "$2" -lt 1 ]                                    || # ...less than 1
        [ "$2" -gt $LEVEL_MAX ]                           && # ...greater than LEVEL_MAX, then
        {
          die_usage "invalid level '$2'"
        }

        starting_level=$2
        shift 2; continue
        ;;
      --rotation)
        [ $# -le 1 ] && { # if next arg not exists
          die_usage "option '$1' requires an argument"
        }
        case $2 in
          classic) rotate_piece_func=rotate_piece_classic ;;
          super)   rotate_piece_func=rotate_piece_super   ;;
          *)       die_usage "unrecognized rotation mode '$2'" ;;
        esac
        shift 2; continue
        ;;
      --lockdown)
        [ $# -le 1 ] && { # if next arg not exists
          die_usage "option '$1' requires an argument"
        }
        case $2 in
          extended) lockdown_rule=$LOCKDOWN_RULE_EXTENDED ;;
          infinite) lockdown_rule=$LOCKDOWN_RULE_INFINITE ;;
          classic)  lockdown_rule=$LOCKDOWN_RULE_CLASSIC  ;;
          *)        die_usage "unrecognized lockdown rule '$2'" ;;
        esac
        shift 2; continue
        ;;
      --seed)
        [ $# -le 1 ] && { # if next arg not exists
          die_usage "option '$1' requires an argument"
        }

        { expr "$2" + 1 > /dev/null 2>&1; [ $? -gt 1 ]; } || # if not number
        [ "$2" -lt 1 ]                                    || # ...less than 1
        [ "$2" -gt 4294967295 ]                           && # ...greater than LEVEL_MAX, then
        {
          die_usage "invalid seed '$2'"
        }
        bag_random=$2
        shift 2; continue
        ;;
      --theme)
        [ $# -le 1 ] && { # if next arg not exists
          die_usage "option '$1' requires an argument"
        }
        case $2 in
          system | standard) theme=$2 ;;
          *) die_usage "unrecognized color theme '$2'" ;;
        esac
        shift 2; continue
        ;;
      --no-beep)
        beep_on=false
        shift; continue
        ;;
      --no-color)
        no_color=true
        shift; continue
        ;;
      --hide-help)
        help_on=false
        shift; continue
        ;;
      --help|-h)    echo "$USAGE";   exit ;;
      --version|-V) echo "$VERSION"; exit ;;
      *)            die_usage "unrecognized option '$1'" ;;
    esac
  done

  $debug echo "=== Debug mode enabled ==="
  initialize
  ( game 2>&1 >&3 | errlogger ) 3>&1
  cleanup
}

initialize() {
  stty_g=$(stty -g) # let's save terminal state
  interrupt=false
  trap 'interrupt=true' "$SIGNAL_INT"

  printf '\033[?25l' # hide cursor
  printf '\033[2J'   # clear full screen

  # save error log position
  printf '\033[%dH\0337' "$ERRLOG_Y"

  # disable terminal local echo (echoback) and canonical input mode
  stty -echo -icanon -ixon time 0 min 1
}

cleanup() {
  local msg=''

  stty "$stty_g" # let's restore terminal state

  # put message at bottom of playfield so that game screen will keep its shape.
  "$interrupt" && msg="Abort" || msg="Quit"
  printf "$EXIT_FORMAT" "$msg"
  printf '\0338'     # restore cursor position
  printf '\033[?25h' # show cursor

  "$interrupt" && exit 130 # SIGINT (2) + 128
  return 0
}

errlogger() {
  local i=0 line='' pre='' post=''

  pre="${pre}${ESC}[${ERRLOG_Y}r" # set scroll region
  pre="${pre}${ESC}8"             # restore cursor position
  post="${post}${ESC}7"           # save cursor position
  post="${post}${ESC}[r"          # unset scroll region

  while IFS= read -r line; do
    i=$((i + 1))
    printf '%s[%d] %s\n%s' "$pre" "$i" "$line" "$post"
    $debug printf '%s\n' "$line"
  done
}

main "$@"
