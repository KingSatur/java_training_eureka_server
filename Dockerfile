FROM gradle:jdk11 as cache
ARG commit=0
ENV commit=$commit
RUN echo "Stage 1, generating build with cache"
RUN mkdir -p /home/gradle/cache_home
ENV GRADLE_USER_HOME /home/gradle/cache_home
COPY build.gradle /home/gradle/java-code/
WORKDIR /home/gradle/java-code
RUN gradle clean build -PcommitArgument=$commit -i -x bootJar

FROM gradle:jdk11 as builder
ARG commit=0
ENV commit=$commit
RUN echo "Stage 2, generating bootJar"
COPY --from=cache /home/gradle/cache_home /home/gradle/.gradle
COPY . /usr/src/java-code/
WORKDIR /usr/src/java-code
RUN gradle bootJar -PcommitArgument=$commit -i

FROM openjdk:11-slim as build
RUN echo "Stage 3, defining entry image entry point"
USER root
WORKDIR /usr/src/java-app
COPY --from=builder /usr/src/java-code/build/libs/*.jar ./app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]