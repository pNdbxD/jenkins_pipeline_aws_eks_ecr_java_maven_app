FROM amazoncorretto:21-alpine-jdk

WORKDIR /usr/app

COPY ./target/java-maven-app-*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]