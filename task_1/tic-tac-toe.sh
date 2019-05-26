#!/bin/bash


FIELD='         '
CURSOR_X=0
CURSOR_Y=0
CHAR='x'
ENEMY_CHAR='o'
TURN='x'

function main() {
    stty -echo    
    mkfifo channel 

    if [ $? = 0 ]; then 
        connect_first_player
    else 
        connect_second_player
    fi

    while true; do
        draw_grid
        if [ $TURN = $CHAR ]; then 
            make_move
        else 
            wait_enemy
        fi
        exit_if_finished
    done
}

function connect_first_player() {
    trap 'rm channel; reset' EXIT
    echo 'ждём второго игрока'
    
    CHAR='x'
    ENEMY_CHAR='o'

    # получить pid противника
    enemy_pid=`cat channel`

    trap 'kill -INT -'$enemy_pid' &>/dev/null; reset; exit' INT

    # отправить противнику свой pid
    echo $$ > channel 
}

function connect_second_player() {
    CHAR='o'
    ENEMY_CHAR='x'
    # отправить противнику свой pid
    echo $$ > channel

    # получить pid противника
    enemy_pid=`cat channel`

    trap 'kill -INT -'$enemy_pid' &>/dev/null; reset; exit' INT
    trap 'reset' EXIT
}

function draw_grid() {
    tput reset
    echo 'ваш символ: '${CHAR}
    if [ $CHAR = $TURN ]; then 
        echo 'ваш ход'
    else 
        echo 'ход противника'
    fi


    for i in 0 1 2; do
        for j in 0 1 2; do
            m=${FIELD:3 * i + j:1}
            if [ $i = $CURSOR_Y ] && [ $j = $CURSOR_X ]; then 
                echo -n '('${m}')'
            else 
                echo -n ' '${m}' '
            fi

	    if [ $j != 2 ]; then 
                echo -n '┃'
	    fi    
        done
	echo ''

        if [ $i != 2 ]; then 
            echo '━━━╋━━━╋━━━'
        fi
    done
}


function fill_cell() {
    cursor=$2
    FIELD=${FIELD:0:cursor}${1}${FIELD:cursor + 1}
}

function write_char() {
    cursor=$((3 * $CURSOR_Y + $CURSOR_X))

    if [[ ${FIELD:cursor:1} = ' ' ]]; then
        fill_cell $CHAR $cursor
        echo $cursor > channel
        TURN=$ENEMY_CHAR
    fi
}

function make_move() {
    read -r -sn1 t

    case $t in
        A) CURSOR_Y=$(((CURSOR_Y + 2) % 3));;
        B) CURSOR_Y=$(((CURSOR_Y + 1) % 3));;
        C) CURSOR_X=$(((CURSOR_X + 1) % 3));;
        D) CURSOR_X=$(((CURSOR_X + 2) % 3));;
        '') write_char;;
    esac
}

function wait_enemy() {
    enemy_move=`cat channel`
    fill_cell $ENEMY_CHAR $enemy_move
    TURN=$CHAR
}

function exit_if_finished() {
    winner=`is_finished`
    if [ $winner != '' ] || [ ! $FIELD =~ " " ]; then
	draw_grid
        if [ $winner = $CHAR ];
            then echo 'вы выиграли'
        elif [ $winner = $ENEMY_CHAR ];
            then echo 'вы проиграли'
        fi
        sleep 5
        exit
    fi
}

function is_finished() {
    ways_to_win=(0 1 2 3 4 5 6 7 8 0 3 6 1 4 7 2 5 8 0 4 8 2 4 6)

    for i in 0 3 6 9 12 15 18 21; do
        a=${FIELD:ways_to_win[i]:1}
        b=${FIELD:ways_to_win[i + 1]:1}
        c=${FIELD:ways_to_win[i + 2]:1}

        if [[ $a = $b ]] && [[ $b = $c ]]; then
            echo $a
            break
        fi
    done
}

main
