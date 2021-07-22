FROM google/dart-runtime-base

WORKDIR /project/app
ADD pkg /project/pkg
ADD weather-microservice/pubspec.* /project/app/
RUN pub get
ADD weather-microservice /project/app
RUN pub get --offline
