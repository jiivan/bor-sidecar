FROM alpine:3.19

RUN apk update && apk add \
	jq \
	curl 

ARG GITHUB_REF_NAME
ENV APP_VERSION=$GITHUB_REF_NAME
WORKDIR /app

COPY ./src/monitor.bash /app/
CMD /app/monitor.bash
