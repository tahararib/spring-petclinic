# ?? Stage 1 : Build ??????????????????????????????????????
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copier pom.xml en premier pour profiter du cache Maven
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .

# Télécharger les dépendances (layer cachée)
RUN ./mvnw dependency:go-offline -q 2>/dev/null || true

# Copier les sources et builder
COPY src/ src/
RUN ./mvnw spring-javaformat:apply -q && ./mvnw clean package -DskipTests -q

# ?? Stage 2 : Runtime ?????????????????????????????????????
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Utilisateur non-root (sécurité)
RUN addgroup -S petclinic && adduser -S petclinic -G petclinic
USER petclinic

# Copier uniquement le WAR depuis le stage build
COPY --from=build /app/target/*.war app.war

# Actuator health endpoint
EXPOSE 8080

# Démarrage
ENTRYPOINT ["java", "-jar", "app.war"]
