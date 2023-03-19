FROM julia:1.8.5-buster

RUN apt update
RUN apt install -y git \
&&  git config --global --add safe.directory /ws

CMD [ "/bin/bash" ]