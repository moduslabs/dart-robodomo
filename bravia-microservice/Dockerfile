FROM google/dart-runtime-base

WORKDIR /project/app
ADD pkg /project/pkg

ADD bravia-microservice/pubspec.* /project/app/
RUN pub get
ADD bravia-microservice /project/app
RUN pub get --offline
