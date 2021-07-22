FROM google/dart-runtime-base

WORKDIR /project/app
ADD pkg /project/pkg

ADD presence-microservice/pubspec.* /project/app/
RUN pub get
ADD presence-microservice /project/app
RUN pub get --offline
