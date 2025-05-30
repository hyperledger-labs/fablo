
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /chaincode
COPY . .

RUN chmod +x ./gradlew

RUN ./gradlew clean build shadowJar

CMD ["java", "-jar", "build/libs/java-chaincode-1.0-SNAPSHOT.jar"] 