# sh-tetris

The pure shell script (sh) that implements the Tetris game following the Tetris Guideline (2009).

The aim is to understand more about shell script and Tetris algorithms.

[Tetris Guideline. Tetris Wiki. accessed at 2020-05-23](https://tetris.fandom.com/wiki/Tetris_Guideline).

This script is based on [dkorolev/bash-tetris](https://github.com/dkorolev/bash-tetris).<br>
Thank you!

I've implemented the following

* Hold Queue
* Next Queue
* Random Generation with Bag System
* Score System
* Variable Goal System
* T-Spin / Mini T-Spin
* Back-to-Back Bonus
* Extended Placement / Infinite Placement / Classic Lock Down
* Super / Classic Rotation System
* Changing the Starting Level

## Usage

```sh
# Download (v2.1.0)
wget https://raw.githubusercontent.com/ContentsViewer/sh-tetris/v2.1.0/tetris
chmod +x tetris

./tetris
```

<details>
<summary>Show Help</summary>

```shellsession
$ ./tetris -h

Usage: tetris [options]

Options:
 -d, --debug          debug mode
 -l, --level <LEVEL>  game level (default=1). range from 1 to 15
 --rotation <MODE>    use 'Super' or 'Classic' rotation system
                      MODE can be 'super'(default) or 'classic'
 --lockdown <RULE>    Three rulesets —Infinite Placement, Extended, and Classic—
                      dictate the conditions for Lock Down.
                      RULE can be 'extended'(default), 'infinite', 'classic'
 --no-color           don't display colors
 --no-beep            disable beep
 --hide-help          don't show help on start

 -h, --help     display this help and exit
 -V, --version  output version infromation and exit

Version:
 2.1.0
```

</details>

![Tetris](https://contentsviewer.work/Master/ShellScript/Apps/Tetris/Images/tetris.jpg)

Enjoy :-)

## Supported Environments

| Environment | Support? |
| :---------: | :------: |
| Linux   sh  | o        |
| FreeBSD sh  | o        |
| BusyBox sh  | o        |
| Solaris sh  | x        |

## Author

IOE <Github: [@ContentsViewer](https://github.com/ContentsViewer)>
