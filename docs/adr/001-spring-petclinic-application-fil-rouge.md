# ADR-001 : spring-petclinic comme application fil rouge

## Statut
Accepté

## Contexte
La formation nécessite une application realiste pour illustrer
CI/CD, K8s, GitOps et observabilite.

## Decision
Utiliser le fork tahararib/spring-petclinic (Java 21 / Spring Boot 3.x
/ PostgreSQL) enrichi avec OTel, Testcontainers et Flyway.

## Consequences
+ Application connue, code realiste, documentation abondante
- Docker requis pour les tests d integration (Testcontainers)
