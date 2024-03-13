FROM alpine:3.19

RUN apt-get update && apt-get install -y \
	jq \
	curl 

ARG GITHUB_REF_NAME
ENV APP_VERSION=$GITHUB_REF_NAME
WORKDIR /app

COPY ./src/monitor.sh /app/
CMD /app/monitor.sh
