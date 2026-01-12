ARG BASE_URL=http://localhost:8188/

#----
FROM python:3.14 AS build

COPY self-hosted-addons-repository/_repo_generator.py /usr/local/bin/

COPY addons/skin.estuary-local /repo/skin.estuary-local/
COPY self-hosted-addons-repository/repository.local /repo/repository.local/

RUN cd / \
 && python /usr/local/bin/_repo_generator.py

#----
FROM pandoc/core:3.8 AS html

COPY self-hosted-addons-repository/index.md /input/

WORKDIR /output

RUN pandoc -s -f markdown -t html5 -o index.html /input/index.md -c style.css

#----
FROM nginx:stable AS envsubst

ARG BASE_URL
ENV BASE_URL=$BASE_URL

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      gettext \
 && true

COPY --from=build /repo/zips /opt/in/repo/zips/
COPY --from=html /output/ /opt/in/

RUN mkdir -p /opt/out/ \
 && cd /opt/in/ \
 && find . -type f | while read path; do \
      inpath=/opt/in/${path#./} ; \
      outpath=/opt/out/${path#./} ; \
      mkdir -p "$( dirname "$outpath" )"; \
      envsubst '${BASE_URL}' < "$inpath" > "$outpath"; \
    done

#----
FROM nginx:stable AS repo

COPY --from=envsubst /opt/out/ /usr/share/nginx/html/
RUN find /usr/share/nginx/html -type f
