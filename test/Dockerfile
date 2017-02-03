FROM alpine:3.4

RUN apk update \
    && apk add nodejs docker python3
RUN npm install -g triton json

# install dependencies
RUN pip3 install \
    docker-compose==1.10.0 \
    python-Consul==0.4.7 \
    IPy==0.83

# install test targets
COPY examples/triton/docker-compose.yml /src/triton/docker-compose.yml
COPY examples/compose/docker-compose.yml /src/compose/docker-compose.yml

# install tests
COPY test/testing/testcases.py /src/testcases.py
COPY test/tests.py /src/tests.py
