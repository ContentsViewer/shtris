# sh-tetris

Tetris game written in pure sh.

I tried to follow the Tetris Guideline(2009).
URL: [Tetris Guideline. Tetris Wiki. accessed at 2020-05-23](https://tetris.fandom.com/wiki/Tetris_Guideline)

I implemented

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

not implemented

* Ghost Piece

This script is based on bash-tetris (Author: Kirill Timofeev)
Thank you!

## Usage

### From source

```sh
git clone https://github.com/ContentsViewer/sh-tetris.git
cd sh-tetris
chmod 755 ./tetris
./tetris
```

### From Docker

```sh
wget https://raw.githubusercontent.com/ContentsViewer/sh-tetris/master/Dockerfile
docker build -t sh-tetris .
docker run --rm -it sh-tetris
```

### From DockerHub

```sh
docker run --rm -it eggplanter/sh-tetris
```

![Tetris](https://contentsviewer.work/Master/ShellScript/Apps/Tetris/Images/tetris.jpg)

Enjoy :-)

## Supported Environments

| Environment | ? |
|-------------|---|
| Linux   sh  | o |
| FreeBSD sh  | o |
| BusyBox sh  | o |
| Solaris sh  | x |

## Author

IOE <Github: ContentsViewer>
