# ── Stage 1 : Build ──────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /app

# Copier pom.xml en premier pour cacher le telechargement des dependances
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN ./mvnw dependency:go-offline -q 2>/dev/null || true

# Copier les sources et compiler
COPY src/ src/
RUN chmod +x mvnw && ./mvnw spring-javaformat:apply -q && ./mvnw clean package -DskipTests -q

# ── Stage 2 : Runtime ────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Utilisateur non-root (securite)
RUN addgroup -S petclinic && adduser -S petclinic -G petclinic
USER petclinic

# Copier uniquement le WAR depuis le stage build
COPY --from=build /app/target/*.war app.war
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.war"]