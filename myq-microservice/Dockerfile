FROM google/dart-runtime-base

WORKDIR /project/app

ADD pkg /project/pkg

ADD myq-microservice/pubspec.* /project/app/
RUN pub get
ADD myq-microservice /project/app
RUN pub get --offline
