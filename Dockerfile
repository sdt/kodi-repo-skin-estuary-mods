FROM python:3.14 AS build

COPY self-hosted-addons-repository/_repo_generator.py /usr/local/bin/

COPY addons/skin.estuary-sdt /repo/skin.estuary-sdt/

RUN cd / \
 && python /usr/local/bin/_repo_generator.py

FROM nginx:stable

COPY --from=build /repo/zips /usr/share/nginx/html/repo/zips/
