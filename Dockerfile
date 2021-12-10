FROM alpine:3.15.0

RUN wget -nv https://raw.githubusercontent.com/ContentsViewer/sh-tetris/master/tetris \
    && chmod +x ./tetris \
    && mv ./tetris /usr/local/bin/

CMD ["tetris"]
