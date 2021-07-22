FROM google/dart-runtime-base

WORKDIR /project/app
ADD pkg /project/pkg

ADD samsung-microservice/pubspec.* /project/app/
RUN pub get
ADD samsung-microservice /project/app
RUN pub get --offline
