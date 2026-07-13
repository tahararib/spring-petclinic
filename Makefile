build:
	./mvnw spring-javaformat:apply -q && ./mvnw clean package -DskipTests

test:
	./mvnw spring-javaformat:apply -q && ./mvnw test

docker-build:
	docker build -t spring-petclinic:local .

docker-push:
	docker push registry.k3d.localhost:5000/spring-petclinic:$(TAG)

deploy:
	helm upgrade petclinic ./spring-petclinic -f values-$(ENV).yaml

precommit-install:
	pre-commit install
