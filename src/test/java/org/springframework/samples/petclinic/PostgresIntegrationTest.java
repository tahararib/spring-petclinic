package org.springframework.samples.petclinic;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * Classe de base pour les tests d'intégration avec PostgreSQL réel via Testcontainers.
 * Formation DevOps ? Lab 07 (pipeline Jenkins + tests d'intégration).
 */
@SpringBootTest
@Testcontainers
@ActiveProfiles("postgres")
public abstract class PostgresIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres =
        new PostgreSQLContainer<>("postgres:16-alpine")
            .withDatabaseName("petclinic")
            .withUsername("petclinic")
            .withPassword("petclinic");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

}
